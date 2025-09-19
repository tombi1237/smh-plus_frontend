

import 'package:smh_front/models/model.dart';
import 'package:smh_front/models/user.dart';
import 'package:smh_front/services/service.dart';

class UserService extends Service {
  UserService() : super(remotePath: '/users');

  Future<User> getUser({required int id}) async {    
    try {
      final response = await system.api.get<JsonObject>('${remotePath!}/$id');
      return User.fromJson(data(response));
    } catch (e) {
      rethrow;
    }
  }
}