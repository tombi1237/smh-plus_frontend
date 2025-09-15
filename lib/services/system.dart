import 'package:dio/dio.dart';
import 'package:smh_front/models/user.dart';

class System {
  User? user;

  final Dio api;

  static System? _instance;

  // Warning, we must ensure the system is initialized othewise, crashes may occurs
  factory System() => _instance!;

  System.init({required String apiUrl})
    : api = Dio(BaseOptions(baseUrl: apiUrl)) {
    _instance = this;
  }

  void registerUser(User user, String token) {
    this.user = user;
    api.options.headers['Authorization'] = 'Bearer $token';
  }
}
