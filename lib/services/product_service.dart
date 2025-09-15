import 'package:dio/dio.dart';
import 'package:smh_front/models/model.dart';
import 'package:smh_front/models/product.dart';
import 'package:smh_front/services/service.dart';

class ProductService extends Service {
  ProductService() : super(remotePath: '/products/products');

  Future<PaginatedData<Product>> getProducts() async {
    try {
      final Response<JsonObject> response = await system.api.get<JsonObject>(
        remotePath!,
      );

      return PaginatedData<Product>.fromJson(
        data(response.data),
        (JsonObject object) => Product.fromJson(object),
      );
    } catch (e) {
      throw Exception('Erreur inconnue: $e');
    }
  }

  Future<Product> getProduct(String uuid) async {
    final Response<JsonObject> response = await system.api.get<JsonObject>(
      '$remotePath/$uuid',
    );
    return Product.fromJson(response.data ?? JsonObject());
  }
}
