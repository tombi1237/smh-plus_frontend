import 'package:dio/dio.dart';
import 'package:smh_front/models/model.dart';
import 'package:smh_front/models/neighborhood.dart';
import 'package:smh_front/models/order.dart';
import 'package:smh_front/models/user.dart';
import 'package:smh_front/services/neighborhood_service.dart';
import 'package:smh_front/services/service.dart';
import 'package:smh_front/services/user_service.dart';

class OrderService extends Service {
  final UserService userService;
  final NeighborhoodService neighborhoodService;

  OrderService({required this.userService, required this.neighborhoodService})
    : super(remotePath: '/orders');

  Future<PaginatedData<Order>> getOrders({
    OrderStatus? status,
    bool resolveRelated = true,
  }) {
    return _getOrders(
      remotePath!,
      status: status,
      resolveRelated: resolveRelated,
    );
  }

  Future<PaginatedData<Order>?> getCommercialOrders({
    int? commercialId,
    OrderStatus? status,
    bool resolveRelated = true,
  }) {
    return _getOrders(
      '${remotePath!}/commercial/${commercialId ?? system.user?.id ?? 4}',
      status: status,
      resolveRelated: resolveRelated,
    );
  }

  Future<Order?> getOrder({required int id, bool resolveRelated = true}) async {
    final Response<JsonObject> response = await system.api.get<JsonObject>(
      '$remotePath/$id',
    );

    return (response.data == null
        ? null
        : await _orderFromJson(response.data!));
  }

  Future<Order> createOrder(
    Order order, {
    required String deliveryType,
    required String recipientName,
    required String recipientPhone,
  }) async {
    JsonObject object = {
      'userId': order.user?.id,
      'userType': order.user!.role,
      'deliveryType': deliveryType,
      'recipentName': recipientName,
      'recipientPhone': recipientPhone,
      'neighborhoodId': order.neighborhood?.id,
      'items': order.items?.map((e) => { 'productId': e.id, 'quantity': e.estimatedQuantity, 'amountToSpend': (e.estimatedUnitPrice ?? 0) * (e.estimatedQuantity ?? 0) }).toList(),
    };

    try {
      final response = system.api.post<JsonObject>(
        remotePath!,
        data: object,
      );

      return response.then((value) => _orderFromJson(data(value.data)));
    } catch (e) {
      throw Exception('Erreur inconnue: $e');
    }
  }

  Future<Order> updateOrder(Order order) async {
    if (order.id == null) {
      throw Exception('L\'identifiant de la commande est requis');
    }

    final JsonObject object = {
      'neighborhoodId': order.neighborhood?.id,
      'items': order.items?.map((e) => { 'productId': e.id, 'quantity': e.estimatedQuantity, 'amountToSpend': (e.estimatedUnitPrice ?? 0) * (e.estimatedQuantity ?? 0) }).toList(),
    };

    try {
      final response = system.api.put<JsonObject>(
        '$remotePath/${order.id}',
        data: object,
      );

      return response.then((value) => _orderFromJson(data(value.data)));
    } catch (e) {
      throw Exception('Erreur inconnue: $e');
    }
  }

  Future<bool> deleteOrder({required int id}) async {
    try {
      await system.api.delete('$remotePath/$id');
      return true;
    } catch (e) {
      throw Exception('Erreur inconnue: $e');
    }
  }

  Future<Order> routeOrderToStation({
    required int orderId,
    required int stationId,
  }) {
    try {
      final response = system.api.post<JsonObject>(
        '$remotePath/$orderId/route',
        data: {'stationId': stationId},
      );

      return response.then((value) => _orderFromJson(data(value.data)));
    } catch (e) {
      throw Exception('Erreur inconnue: $e');
    }
  }

  Future<Order> assignOrderToShopper({
    required int orderId,
    required int shopperId,
  }) {
    try {
      final response = system.api.post<JsonObject>(
        '$remotePath/$orderId/shopper',
        data: {'shopperId': shopperId},
      );

      return response.then((value) => _orderFromJson(data(value.data)));
    } catch (e) {
      throw Exception('Erreur inconnue: $e');
    }
  }

  Future<Order> assignOrderToProducer({
    required int orderId,
    required int producerId,
  }) {
    try {
      final response = system.api.post<JsonObject>(
        '$remotePath/$orderId/producer',
        data: {'producerId': producerId},
      );

      return response.then((value) => _orderFromJson(data(value.data)));
    } catch (e) {
      throw Exception('Erreur inconnue: $e');
    }
  }

  Future<Order> addMerchantToOrder({
    required int orderId,
    required String productId,
    required int merchantId,
  }) {
    try {
      final response = system.api.post<JsonObject>(
        '$remotePath/$orderId/merchant',
        data: {'productId': productId, 'merchantId': merchantId},
      );

      return response.then((value) => _orderFromJson(data(value.data)));
    } catch (e) {
      throw Exception('Erreur inconnue: $e');
    }
  }

  Future<Order> assignOrderToDriver({
    required int orderId,
    required int driverId,
  }) {
    try {
      final response = system.api.post<JsonObject>(
        '$remotePath/$orderId/driver',
        data: {'driverId': driverId},
      );

      return response.then((value) => _orderFromJson(data(value.data)));
    } catch (e) {
      throw Exception('Erreur inconnue: $e');
    }
  }

  Future<PaginatedData<Order>> _getOrders(
    String path, {
    OrderStatus? status,
    bool resolveRelated = true,
  }) async {
    JsonObject? parameters;
    if (status != null) {
      parameters = {
        'sort': status.toString().replaceAll('OrderStatus.', '').toUpperCase(),
      };
    }

    try {
      Response<JsonObject> response = await system.api.get<JsonObject>(
        path,
        queryParameters: parameters,
      );

      if (resolveRelated) {
        List<Order> orders = List.empty(growable: true);

        final array = data(response.data)['content'] as JsonArray;
        for (JsonObject object in array) {
          orders.add(await _orderFromJson(object));
        }

        return PaginatedData<Order>.fromData(
          Pageable.fromJson(response.data!),
          orders,
        );
      } else {
        return PaginatedData<Order>.fromJson(
          response.data!,
          (JsonObject object) => Order.fromJson(object),
        );
      }
    } catch (e) {
      throw Exception('Erreur inconnue: $e');
    }
  }

  Future<Order> _orderFromJson(
    JsonObject object, {
    bool resolveRelated = true,
  }) async {
    if (resolveRelated) {
      final User user = await userService.getUser(id: object['userId']);
      final Neighborhood neighborhood = await neighborhoodService
          .getNeighborhood(id: object['neighborhoodId']);

      return Order.fromJson(object, user: user, neighborhood: neighborhood);
    } else {
      return Order.fromJson(object);
    }
  }
}
