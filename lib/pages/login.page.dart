import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserLogin extends StatefulWidget {
  const UserLogin({Key? key}) : super(key: key);

  @override
  State<UserLogin> createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Couleurs du thème
  static const Color primaryBlue = Color(0xFF1E3A5F);
  static const Color accentYellow = Color(0xFFFFB800);
  static const Color lightBlue = Color(0xFF4A90E2);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://49.13.197.63:8001/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': _identifierController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['value'] == '200') {
        final userData = responseData['data'];

        final token = userData['token'];
        final userId =
            userData['id'] ?? userData['userId']; // Support both field names
        final role = userData['role'];

        // Stocker token et infos utilisateur
        await _storage.write(key: 'auth_token', value: token);
        await _storage.write(key: 'user_id', value: userId.toString());
        await _storage.write(key: 'user_data', value: jsonEncode(userData));
        await _storage.write(key: 'user_role', value: role);

        // Stocker les informations utilisateur détaillées
        if (userData['firstName'] != null) {
          await _storage.write(
            key: 'user_first_name',
            value: userData['firstName'],
          );
        }
        if (userData['lastName'] != null) {
          await _storage.write(
            key: 'user_last_name',
            value: userData['lastName'],
          );
        }
        if (userData['username'] != null) {
          await _storage.write(
            key: 'user_username',
            value: userData['username'],
          );
        }
        if (userData['email'] != null) {
          await _storage.write(key: 'user_email', value: userData['email']);
        }
        if (userData['phoneNumber'] != null) {
          await _storage.write(
            key: 'user_phone',
            value: userData['phoneNumber'],
          );
        }
        if (userData['profilePictureUrl'] != null) {
          await _storage.write(
            key: 'user_profile_picture',
            value: userData['profilePictureUrl'],
          );
        }
        if (userData['primaryAddress'] != null) {
          await _storage.write(
            key: 'user_address',
            value: userData['primaryAddress'],
          );
        }
        if (userData['gender'] != null) {
          await _storage.write(key: 'user_gender', value: userData['gender']);
        }
        if (userData['loyaltyPoints'] != null) {
          await _storage.write(
            key: 'user_loyalty_points',
            value: userData['loyaltyPoints'].toString(),
          );
        }

        _showSnackBar('Connexion réussie !', Colors.green);

        // Charger profil complet si nécessaire
        await _fetchUserProfile(userId, token);

        // Redirection basée sur le rôle
        _redirectUserByRole(role, userId, userData);
      } else {
        _showSnackBar(
          responseData['text'] ?? 'Erreur de connexion',
          Colors.red,
        );
      }
    } catch (e) {
      print('Login error: $e');
      _showSnackBar(
        'Erreur de connexion. Vérifiez votre connexion internet.',
        Colors.red,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _redirectUserByRole(
    String role,
    dynamic userId,
    Map<String, dynamic> userData,
  ) {
    final arguments = {'userId': userId, 'userData': userData};

    switch (role) {
      case "CLIENT":
        Navigator.pushReplacementNamed(
          context,
          '/client_page',
          arguments: arguments,
        );
        break;

      case "SHOPPER":
        Navigator.pushReplacementNamed(
          context,
          '/client_page',
          arguments: arguments,
        );
        break;

      case "MERCHANT":
        Navigator.pushReplacementNamed(
          context,
          '/merchant_dashboard',
          arguments: arguments,
        );
        break;

      case "DELIVERY_DRIVER":
        Navigator.pushReplacementNamed(
          context,
          '/delivery_dashboard',
          arguments: arguments,
        );
        break;

      case "ADMIN":
        Navigator.pushReplacementNamed(
          context,
          '/admin_dashboard',
          arguments: arguments,
        );
        break;

      case "STATION_CHIEF":
        Navigator.pushReplacementNamed(
          context,
          '/station_chief_dashboard',
          arguments: arguments,
        );
        break;

      case "DISTRICT_CHIEF":
        Navigator.pushReplacementNamed(
          context,
          '/district_chief_dashboard',
          arguments: arguments,
        );
        break;

      case "INTERNAL_TREASURER":
        Navigator.pushReplacementNamed(
          context,
          '/treasurer_dashboard',
          arguments: arguments,
        );
        break;

      default:
        // Rôle non reconnu - redirection vers une page par défaut
        print('Rôle non reconnu: $role');
        _showSnackBar('Rôle utilisateur non reconnu', Colors.orange);
        Navigator.pushReplacementNamed(
          context,
          '/default_dashboard',
          arguments: arguments,
        );
        break;
    }
  }

  Future<void> _fetchUserProfile(int userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('http://49.13.197.63:8001/api/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Profile fetch status: ${response.statusCode}');
      print('Profile fetch body: ${response.body}');

      if (response.statusCode == 200) {
        final profileData = jsonDecode(response.body);

        if (profileData['value'] == '200') {
          final userProfile = profileData['data'];

          await _storage.write(
            key: 'user_profile',
            value: jsonEncode(userProfile),
          );

          // Mettre à jour les informations stockées avec les données du profil
          if (userProfile['firstName'] != null) {
            await _storage.write(
              key: 'user_first_name',
              value: userProfile['firstName'],
            );
          }
          if (userProfile['lastName'] != null) {
            await _storage.write(
              key: 'user_last_name',
              value: userProfile['lastName'],
            );
          }
          if (userProfile['username'] != null) {
            await _storage.write(
              key: 'user_username',
              value: userProfile['username'],
            );
          }
          if (userProfile['email'] != null) {
            await _storage.write(
              key: 'user_email',
              value: userProfile['email'],
            );
          }
          if (userProfile['phoneNumber'] != null) {
            await _storage.write(
              key: 'user_phone',
              value: userProfile['phoneNumber'],
            );
          }
          if (userProfile['primaryAddress'] != null) {
            await _storage.write(
              key: 'user_address',
              value: userProfile['primaryAddress'],
            );
          }
          if (userProfile['profilePictureUrl'] != null) {
            await _storage.write(
              key: 'user_profile_picture',
              value: userProfile['profilePictureUrl'],
            );
          }
          if (userProfile['gender'] != null) {
            await _storage.write(
              key: 'user_gender',
              value: userProfile['gender'],
            );
          }
          if (userProfile['loyaltyPoints'] != null) {
            await _storage.write(
              key: 'user_loyalty_points',
              value: userProfile['loyaltyPoints'].toString(),
            );
          }
          if (userProfile['enabled'] != null) {
            await _storage.write(
              key: 'user_enabled',
              value: userProfile['enabled'].toString(),
            );
          }
        }
      }
    } catch (e) {
      print('Profile fetch error: $e');
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Logo
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Image.asset("assets/images/logo.png"),
                ),

                const SizedBox(height: 60),

                // Titre de connexion avec style amélioré
                Text(
                  'Connexion',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Accédez à votre espace personnel',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),

                const SizedBox(height: 40),

                // Formulaire
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Identifiant',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _identifierController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Email ou nom d\'utilisateur',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: primaryBlue,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Veuillez saisir votre identifiant'
                              : null,
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Mot de passe',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Votre mot de passe',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: primaryBlue,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Veuillez saisir votre mot de passe'
                              : null,
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              shadowColor: primaryBlue.withOpacity(0.3),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Se connecter',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/forgot_password');
                            },
                            child: const Text(
                              'Mot de passe oublié?',
                              style: TextStyle(
                                color: primaryBlue,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Lien vers l'inscription
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Pas encore de compte? ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/register');
                                },
                                child: const Text(
                                  'S\'inscrire',
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
