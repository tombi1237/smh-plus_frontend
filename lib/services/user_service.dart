

import 'package:smh_front/models/model.dart';
import 'package:smh_front/models/user.dart';
import 'package:smh_front/services/service.dart';

class UserService extends Service {
  UserService() : super(remotePath: '/users');

  Future<User> getUser({int? id}) async {
    if (id == null) {
      if (system.user == null || system.user!.id == null) {
        throw Exception('No user is currently logged in.');
      }
      id = system.user!.id;
    }
    
    try {
      final response = await system.api.get<JsonObject>('${remotePath!}/$id');
      return User.fromJson(data(response.data));
    } catch (e) {
      rethrow;
    }
  }
}