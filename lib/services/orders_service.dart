import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:smh_front/models/order_models.dart';
import 'package:smh_front/models/user_models.dart';

// Service API avec gestion d'erreurs améliorée
class OrdersService {
  static const String baseUrl = 'http://49.13.197.63:8006/api/';

  // Token d'authentification fourni
  static const String authToken =
      'eyJhbGciOiJIUzM4NCJ9.eyJyb2xlcyI6WyJQUk9EVUNFUiJdLCJtb2JpbGUiOiIrMjM3NjY2NjY2NjYyIiwidXNlcklkIjo4LCJlbWFpbCI6InBhdWwucHJvZHVjdGV1ckBzbWhwbHVzLmNvbSIsInVzZXJuYW1lIjoicGF1bF9wcm9kdWN0ZXVyIiwic3ViIjoicGF1bF9wcm9kdWN0ZXVyIiwiaWF0IjoxNzU3NTc4OTIwLCJleHAiOjE3NTgwMTA5MjB9.MT76WwzAY-U7dw5QswNN7zJmG6YPSIL-HGlZjCBBJLo0bYdiYL9WLOPdpat9fnjb';

  static Future<OrdersResponse> getOrders() async {
    try {
      final response = await http
          .get(
            Uri.parse('${baseUrl}orders/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(utf8.decode(response.bodyBytes));
          return OrdersResponse.fromJson(jsonData);
        } catch (e) {
          throw Exception('Erreur de parsing JSON: $e');
        }
      } else if (response.statusCode == 403) {
        throw Exception(
          'Accès refusé (403). Vérifiez vos identifiants d\'authentification.',
        );
      } else if (response.statusCode == 401) {
        throw Exception(
          'Non autorisé (401). Token d\'accès invalide ou expiré.',
        );
      } else {
        throw Exception(
          'Erreur lors du chargement des commandes: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException {
      throw Exception(
        'La requête a expiré. Veuillez vérifier votre connexion.',
      );
    } on http.ClientException catch (e) {
      throw Exception('Erreur de connexion: $e');
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  // Nouvelle méthode pour récupérer les détails d'une commande spécifique
  static Future<Order> getOrderDetails(int orderId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${baseUrl}orders/$orderId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(utf8.decode(response.bodyBytes));
          return Order.fromJson(jsonData['data']);
        } catch (e) {
          throw Exception('Erreur de parsing JSON: $e');
        }
      } else if (response.statusCode == 403) {
        throw Exception(
          'Accès refusé (403). Vérifiez vos identifiants d\'authentification.',
        );
      } else if (response.statusCode == 401) {
        throw Exception(
          'Non autorisé (401). Token d\'accès invalide ou expiré.',
        );
      } else {
        throw Exception(
          'Erreur lors du chargement des détails de la commande: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException {
      throw Exception(
        'La requête a expiré. Veuillez vérifier votre connexion.',
      );
    } on http.ClientException catch (e) {
      throw Exception('Erreur de connexion: $e');
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  // Nouvelle méthode pour récupérer les livreurs
  static Future<List<UserData>> getLivreurs() async {
    try {
      final response = await http
          .get(
            Uri.parse('${baseUrl}users?role=SHOPPER&page=0&size=100'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(utf8.decode(response.bodyBytes));
          final List<dynamic> usersData = jsonData['data']['content'];

          return usersData
              .where(
                (user) =>
                    user['role'] == 'DELIVERY_DRIVER' &&
                    user['enabled'] == true,
              )
              .map((user) => UserData.fromJson(user))
              .toList();
        } catch (e) {
          throw Exception('Erreur de parsing JSON: $e');
        }
      } else if (response.statusCode == 403) {
        throw Exception(
          'Accès refusé (403). Vérifiez vos identifiants d\'authentification.',
        );
      } else if (response.statusCode == 401) {
        throw Exception(
          'Non autorisé (401). Token d\'accès invalide ou expiré.',
        );
      } else {
        throw Exception(
          'Erreur lors du chargement des livreurs: ${response.statusCode} - ${response.body}',
        );
      }
    } on TimeoutException {
      throw Exception(
        'La requête a expiré. Veuillez vérifier votre connexion.',
      );
    } on http.ClientException catch (e) {
      throw Exception('Erreur de connexion: $e');
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  // Nouvelle méthode pour assigner une commande à un livreur
  static Future<bool> assignOrderToShopper(
    int orderId,
    int shopperId,
    String notes,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${baseUrl}orders/$orderId/assign'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
              'Accept': 'application/json',
            },
            body: json.encode({
              'shopperId': shopperId,
              'notes': notes.isNotEmpty ? notes : null,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return response.statusCode == 200 || response.statusCode == 201;
    } on TimeoutException {
      throw Exception(
        'La requête a expiré. Veuillez vérifier votre connexion.',
      );
    } on http.ClientException catch (e) {
      throw Exception('Erreur de connexion: $e');
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  // Méthode pour tester la connexion
  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode != 403 && response.statusCode != 401;
    } catch (e) {
      return false;
    }
  }
}
