import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/user_models.dart';

class UserService {
  static const String baseUrl = 'http://49.13.197.63:8001/api/';
  static String? userToken; // Token dynamique

  // Méthode pour définir le token utilisateur
  static void setUserToken(String token) {
    userToken = token;
  }

  // Récupérer les détails d'un utilisateur connecté (sans ID spécifique)
  static Future<UserData> getCurrentUser() async {
    if (userToken == null || userToken!.isEmpty) {
      throw Exception('Token utilisateur non défini');
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              '${baseUrl}users/me',
            ), // Endpoint pour l'utilisateur connecté
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $userToken',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(utf8.decode(response.bodyBytes));
          if (jsonData['value'] == '200') {
            return UserData.fromJson(jsonData['data']);
          } else {
            throw Exception(jsonData['text'] ?? 'Erreur lors du chargement');
          }
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
          'Erreur lors du chargement de l\'utilisateur: ${response.statusCode} - ${response.body}',
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

  // Récupérer les détails d'un utilisateur par ID
  static Future<User> getUser(int userId) async {
    if (userToken == null || userToken!.isEmpty) {
      throw Exception('Token utilisateur non défini');
    }

    try {
      final response = await http
          .get(
            Uri.parse('${baseUrl}users/$userId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $userToken',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(utf8.decode(response.bodyBytes));
          if (jsonData['value'] == '200') {
            return User.fromJson(jsonData['data']);
          } else {
            throw Exception(jsonData['text'] ?? 'Erreur lors du chargement');
          }
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
          'Erreur lors du chargement de l\'utilisateur: ${response.statusCode} - ${response.body}',
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

  // Récupérer la location de l'utilisateur connecté
  static Future<String> getUserLocation() async {
    try {
      final userData = await getCurrentUser();

      // Vérifier si l'utilisateur a une assignation avec une location
      if (userData.assignment != null &&
          userData.assignment!.location.isNotEmpty &&
          userData.assignment!.active) {
        return userData.assignment!.location;
      }

      // Retourner la valeur par défaut si pas de location
      return 'Poste de Mendong';
    } catch (e) {
      // En cas d'erreur, retourner la valeur par défaut
      print('Erreur lors de la récupération de la location: $e');
      return 'Poste de Mendong';
    }
  }

  // Upload de la photo de profil
  static Future<Map<String, dynamic>> uploadProfilePicture(
    int userId,
    XFile imageFile,
  ) async {
    if (userToken == null || userToken!.isEmpty) {
      throw Exception('Token utilisateur non défini');
    }

    try {
      // Créer la requête multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${baseUrl}users/profile-picture/$userId/'),
      );

      // Ajouter le header d'autorisation
      request.headers['Authorization'] = 'Bearer $userToken';
      request.headers['Accept'] = 'application/json';

      // Ajouter le fichier avec le nom de paramètre correct "file"
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // Nom du paramètre attendu par l'API
          imageFile.path,
          filename: 'profile_$userId.jpg',
        ),
      );

      // Envoyer la requête avec timeout
      final response = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final responseBody = await response.stream.bytesToString();

      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = json.decode(responseBody);
      } catch (e) {
        // Si la réponse n'est pas du JSON valide
        jsonResponse = {'text': responseBody};
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message':
              jsonResponse['text'] ?? 'Photo de profil mise à jour avec succès',
          'data': jsonResponse,
        };
      } else {
        return {
          'success': false,
          'message':
              'Erreur ${response.statusCode}: ${jsonResponse['text'] ?? jsonResponse['message'] ?? 'Erreur inconnue'}',
          'data': jsonResponse,
        };
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
