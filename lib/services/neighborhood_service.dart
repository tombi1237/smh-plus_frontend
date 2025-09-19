import 'package:dio/dio.dart';
import 'package:smh_front/models/model.dart';
import 'package:smh_front/models/neighborhood.dart';
import 'package:smh_front/services/service.dart';

class NeighborhoodService extends Service {
  NeighborhoodService() : super(remotePath: '/geography/neighborhoods');

  Future<Neighborhood> getNeighborhood({required int id}) async {
    try {
      final response = await system.api.get<JsonObject>('${remotePath!}/$id');
      return Neighborhood.fromJson(data(response));
    } on DioException catch (e) {
      throw exception(e, defaultCrudMessages: true);
    }
  }
}
