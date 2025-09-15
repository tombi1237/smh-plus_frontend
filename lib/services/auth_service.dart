import 'package:dio/dio.dart';
import 'package:smh_front/models/model.dart';
import 'package:smh_front/services/service.dart';
import 'package:smh_front/services/user_service.dart';

import '../models/user.dart';

class AuthService extends Service {
  final UserService userService;

  AuthService({required this.userService}) : super(remotePath: '/auth');

  Future<User> logIn(String identifier, String password) async {
    final JsonObject body = {'identifier': identifier, 'password': password};

    try {
      final Response<JsonObject> response = await system.api.post<JsonObject>(
        '${remotePath!}/login',
        data: body,
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {'Accept': 'application/json'},
        ),
      );

      if (isOk(response)) {
        final data = this.data(response.data);
        final userId = data['userId'] as int?;
        final token = data['token'] as String?;

        if (userId == null || token == null) {
          throw Exception('Invalid response from server');
        }

        final user = await userService.getUser(id: userId);
        system.registerUser(user, token);
        return system.user!;
      } else {
        throw Exception('Failed to log in');
      }
      // Catch Dio exceptions
    } on DioException catch (e) {
      switch (e.response!.statusCode) {
        case 400:
          throw Exception('Une erreur est survenue. Veuillez réessayer.');
        case 401:
          throw Exception('Identifiants invalides. Veuillez réessayer.');
        case 500:
          throw Exception('Erreur serveur. Veuillez réessayer plus tard.');
        default:
          throw Exception('Erreur inconnue. Veuillez réessayer.');
      }
    } catch (e) {
      throw Exception('Erreur inconnue: $e');
    }
  }

  Future<bool> changePassword(
    User user,
    String newPassword,
    String oldPassword,
  ) async {
    final Response<JsonObject> response = await system.api.post(
      '${remotePath!}/reset-password',
      data: {
        'userId': user.id,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );
    return isOk(response);
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool validatePassword(String password) {
    return password.length >= 6;
  }

  bool passwordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }
}
