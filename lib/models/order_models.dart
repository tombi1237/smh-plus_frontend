// Modèles de données avec gestion d'erreurs améliorée
class OrderItem {
  final int id;
  final String productId;
  final double quantity;
  final double amountToSpend;

  OrderItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.amountToSpend,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    try {
      return OrderItem(
        id: json['id'] as int? ?? 0,
        productId: (json['productId']?.toString() ?? ''),
        quantity: (json['quantity'] is num)
            ? (json['quantity'] as num).toDouble()
            : 0.0,
        amountToSpend: (json['amountToSpend'] is num)
            ? (json['amountToSpend'] as num).toDouble()
            : 0.0,
      );
    } catch (e) {
      print('Error parsing OrderItem: $e');
      return OrderItem(id: 0, productId: '', quantity: 0.0, amountToSpend: 0.0);
    }
  }
}

class Order {
  final int id;
  final int userId;
  final String userType;
  final String status;
  final String recipientName;
  final String recipientPhone;
  final int neighborhoodId;
  final List<OrderItem> items;
  final double total;
  final double subTotal;

  Order({
    required this.id,
    required this.userId,
    required this.userType,
    required this.status,
    required this.recipientName,
    required this.recipientPhone,
    required this.neighborhoodId,
    required this.items,
    required this.total,
    required this.subTotal,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      // Gestion des données potentiellement manquantes ou incorrectes
      final itemsJson = json['items'];
      List<OrderItem> itemsList = [];

      if (itemsJson is List) {
        itemsList = itemsJson.map<OrderItem>((item) {
          if (item is Map<String, dynamic>) {
            return OrderItem.fromJson(item);
          } else {
            return OrderItem(
              id: 0,
              productId: '',
              quantity: 0.0,
              amountToSpend: 0.0,
            );
          }
        }).toList();
      }

      return Order(
        id: json['id'] as int? ?? 0,
        userId: json['userId'] as int? ?? 0,
        userType: (json['userType']?.toString() ?? ''),
        status: (json['status']?.toString() ?? ''),
        recipientName: (json['recipientName']?.toString() ?? ''),
        recipientPhone: (json['recipientPhone']?.toString() ?? ''),
        neighborhoodId: json['neighborhoodId'] as int? ?? 0,
        items: itemsList,
        total: (json['total'] is num) ? (json['total'] as num).toDouble() : 0.0,
        subTotal: (json['subTotal'] is num)
            ? (json['subTotal'] as num).toDouble()
            : 0.0,
      );
    } catch (e) {
      print('Error parsing Order: $e');
      return Order(
        id: 0,
        userId: 0,
        userType: '',
        status: '',
        recipientName: '',
        recipientPhone: '',
        neighborhoodId: 0,
        items: [],
        total: 0.0,
        subTotal: 0.0,
      );
    }
  }
}

class OrdersResponse {
  final String value;
  final String text;
  final List<Order> orders;
  final int totalElements;
  final int totalPages;

  OrdersResponse({
    required this.value,
    required this.text,
    required this.orders,
    required this.totalElements,
    required this.totalPages,
  });

  factory OrdersResponse.fromJson(Map<String, dynamic> json) {
    try {
      // Gestion des données potentiellement manquantes
      final data = json['data'] as Map<String, dynamic>? ?? {};
      final content = data['content'] is List ? data['content'] as List : [];

      return OrdersResponse(
        value: (json['value']?.toString() ?? ''),
        text: (json['text']?.toString() ?? ''),
        orders: content.map<Order>((order) {
          if (order is Map<String, dynamic>) {
            return Order.fromJson(order);
          } else {
            return Order(
              id: 0,
              userId: 0,
              userType: '',
              status: '',
              recipientName: '',
              recipientPhone: '',
              neighborhoodId: 0,
              items: [],
              total: 0.0,
              subTotal: 0.0,
            );
          }
        }).toList(),
        totalElements: (data['totalElements'] is int)
            ? data['totalElements'] as int
            : 0,
        totalPages: (data['totalPages'] is int) ? data['totalPages'] as int : 0,
      );
    } catch (e) {
      print('Error parsing OrdersResponse: $e');
      return OrdersResponse(
        value: '',
        text: '',
        orders: [],
        totalElements: 0,
        totalPages: 0,
      );
    }
  }
}
