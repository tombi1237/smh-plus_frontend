import 'package:dio/dio.dart';
import 'package:smh_front/models/model.dart';
import 'package:smh_front/models/product.dart';
import 'package:smh_front/services/service.dart';

class ProductService extends Service {
  ProductService() : super(remotePath: '/products/products');

  Future<List<Product>> getProducts({
    String? subCategoryId,
    String? sellerType,
    int? neighborhoodId,
    int? districtId,
  }) {
    // Neighborhood and seller
    if (neighborhoodId != null && sellerType != null) {
      return _getProducts(
        subPath: '/neighborhoodAndSeller',
        parameters: {
          'neighborhoodId': neighborhoodId,
          'sellerType': sellerType,
        },
      );
    }

    // District and seller
    if (districtId != null && sellerType != null) {
      return _getProducts(
        subPath: '/districtAndSeller',
        parameters: {'districtId': districtId, 'sellerType': sellerType},
      );
    }

    // Sub category
    if (subCategoryId != null) {
      return _getProducts(subPath: '/subCategory/$subCategoryId');
    }

    // District
    if (districtId != null) {
      return _getProducts(subPath: '/district/$districtId');
    }

    // All
    return _getProducts();
  }

  Future<Product> getProduct({
    required String id,
    bool resolveRelated = true,
  }) async {
    final Response<JsonObject> response = await system.api.get<JsonObject>(
      '$remotePath/$id',
    );

    if (resolveRelated) {
      return Product.fromJson(response.data ?? JsonObject());
    } else {
      return Product.fromJson(response.data ?? JsonObject());
    }
  }

  // ToDO: add addProduct, updateProduct and deleteProduct

  Future<void> changeProductStatus({
    required String productId,
    required int sellerId,
    required String status,
  }) async {
    try {
      await system.api.post(
        '$remotePath/status',
        data: {'sellerId': sellerId, 'productId': productId, 'status': status},
      );
    } on DioException catch (e) {
      throw exception(
        e,
        messages: {
          400: 'Une erreur est survenu, réesayez plutard',
          404: 'Une erreur est survenu, réesayez plutard',
          500: 'Une erreur est survenu, réesayez plutard',
        },
      );
    }
  }

  Future<List<Product>> _getProducts({
    String? subPath,
    Map<String, dynamic>? parameters,
    bool resolveRelated = true, // ToDo: handle this
  }) async {
    try {
      final Response<JsonObject> response = await system.api.get<JsonObject>(
        '$remotePath$subPath',
        queryParameters: parameters,
      );

      final data = this.data(response) as List;

      return List.generate(
        data.length,
        (index) => Product.fromJson(data[index]),
      );
    } catch (e) {
      throw Exception('Erreur inconnue: $e');
    }
  }
}
