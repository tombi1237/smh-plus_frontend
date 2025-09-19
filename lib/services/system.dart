import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smh_front/models/user.dart';

class System {
  User? user;
  final Dio api;

  static final FlutterSecureStorage _storage = FlutterSecureStorage();
  static System? _instance;

  // Warning, we must ensure the system is initialized othewise, crashes may occurs
  factory System() => _instance!;

  System.init({required String apiUrl})
    : api = Dio(BaseOptions(baseUrl: apiUrl, headers: {
        'Authorization': 'Bearer ${_storage.read(key: 'auth_token')}',
      })) {
    _instance = this;
  }

  Future<void> registerUser(User user, String token) async {
    this.user = user;
    api.options.headers['Authorization'] = 'Bearer $token';

    await _storage.write(key: 'user_id', value: user.id.toString());
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> clearUser() async {
    await _storage.write(key: 'auth_token', value: null);
    await _storage.write(key: 'user_id', value: null);
  }
}
