import 'package:dio/dio.dart';
import 'package:smh_front/models/user.dart';

class System {
  User? user;

  final Dio api;

  static System? _instance;

  // Warning, we must ensure the system is initialized othewise, crashes may occurs
  factory System() => _instance!;

  System.init({required String apiUrl})
    : api = Dio(BaseOptions(baseUrl: apiUrl, headers: {
        'Authorization': 'Bearer eyJhbGciOiJIUzM4NCJ9.eyJyb2xlcyI6WyJTSE9QUEVSIl0sIm1vYmlsZSI6IisyMzc2Nzc3Nzc3NzEiLCJ1c2VySWQiOjQsImVtYWlsIjoic2hvcHBlci5zb3BoaWVAc21ocGx1cy5jb20iLCJ1c2VybmFtZSI6InNvcGhpZV9zaG9wcGVyIiwic3ViIjoic29waGllX3Nob3BwZXIiLCJpYXQiOjE3NTc5MzY4NzEsImV4cCI6MTc1ODM2ODg3MX0.7p9d1c2DuKbUq2-osgM0688_AUCvpe26JyHLbRoqymSjacGC2AkiVTO0Gdhq551s',
      })) {
    _instance = this;
  }

  void registerUser(User user, String token) {
    this.user = user;
    api.options.headers['Authorization'] = 'Bearer $token';
  }
}
