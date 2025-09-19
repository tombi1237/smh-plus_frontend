import 'package:dio/dio.dart';
import 'package:smh_front/models/product.dart';
import 'package:smh_front/services/service.dart';

class CategoryService extends Service {
  CategoryService(): super(remotePath: '/products/categories');

  Future<List<Category>> getCategories() async {
    try {
      final response = await system.api.get('$remotePath/');
      final data = this.data(response.data) as List;
      return data.map((e) => Category.fromJson(e)).toList();
    } on DioException catch (e) {
      throw exception(e, defaultCrudMessages: true);
    }
  }
}