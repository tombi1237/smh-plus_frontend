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
    required String uuid,
    bool resolveRelated = true,
  }) async {
    final Response<JsonObject> response = await system.api.get<JsonObject>(
      '$remotePath/$uuid',
    );

    if (resolveRelated) {
      return Product.fromJson(response.data ?? JsonObject());
    } else {
      return Product.fromJson(response.data ?? JsonObject());
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

      return List.generate(data.length, (index) => Product.fromJson(data[index]));
    } catch (e) {
      throw Exception('Erreur inconnue: $e');
    }
  }
}
