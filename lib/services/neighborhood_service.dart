import 'package:smh_front/models/model.dart';
import 'package:smh_front/models/neighborhood.dart';
import 'package:smh_front/services/service.dart';

class NeighborhoodService extends Service {
  NeighborhoodService() : super(remotePath: '/geography/neighborhoods');

  Future<Neighborhood> getNeighborhood({int? id}) async {
    if (id == null) {
      throw Exception('Neighborhood ID is required');
    }
    
    try {
      final response = await system.api.get<JsonObject>('${remotePath!}/$id');
      return Neighborhood.fromJson(data(response.data));
    } catch (e) {
      rethrow;
    }
  }
}
