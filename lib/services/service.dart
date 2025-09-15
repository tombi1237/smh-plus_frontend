import 'package:dio/dio.dart';
import 'package:smh_front/models/model.dart';
import 'package:smh_front/services/system.dart';

class Service {
  final String ?remotePath;
  final System system = System();

  Service({this.remotePath});

  bool isOk(Response response) {
    final code = (response.statusCode ?? 500);
    return code >= 200 && code <= 299;
  }

  JsonObject data(JsonObject? object) {
    return object?['data'] ?? object ?? {};
  }
}