import 'package:dio/dio.dart';
import 'package:smh_front/models/model.dart';
import 'package:smh_front/services/system.dart';

class Service {
  final String? remotePath;
  final System system = System();

  Service({this.remotePath});

  Exception exception(
    DioException exception, {
    Map<int, String>? messages,
    bool defaultCrudMessages = false,
    bool rethrowAsFallback = true,
  }) {
    final statusCode = exception.response?.statusCode ?? 500;

    if (defaultCrudMessages) {
      messages = {
        400: 'Une erreur est survenue. Veuillez réessayer.',
        401: 'Non autorisé. Veuillez vérifier vos identifiants.',
        403: 'Accès interdit. Vous n\'avez pas les permissions nécessaires.',
        404: 'Ressource non trouvée. Veuillez vérifier votre demande.',
        408: 'Délai d\'attente dépassé. Veuillez réessayer.',
        429: 'Trop de requêtes. Veuillez réessayer plus tard.',
        500: 'Erreur serveur. Veuillez réessayer plus tard.',
        502: 'Passerelle incorrecte. Veuillez réessayer plus tard.',
        503: 'Service indisponible. Veuillez réessayer plus tard.',
      };
    }

    if (messages != null && messages.containsKey(statusCode)) {
      return Exception(messages[statusCode]);
    } else if (rethrowAsFallback) {
      return exception;
    } else {
      final response = exception.response;
      return Exception(
        exception.error?.toString() ??
            exception.message ??
            response?.statusMessage,
      );
    }
  }

  bool isOk(Response response) {
    final code = (response.statusCode ?? 500);
    return code >= 200 && code <= 299;
  }

  JsonObject data(Response response) {
    final object = response.data;
    return object?['data'] ?? object ?? {};
  }
}
