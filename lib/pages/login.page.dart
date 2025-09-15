import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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

        // Récupération et stockage de toutes les informations utilisateur
        final token = userData['token'];
        final userId = userData['userId'];

        // Stocker le token et l'ID utilisateur
        await _storage.write(key: 'auth_token', value: token);
        await _storage.write(key: 'user_id', value: userId.toString());

        // Stocker toutes les autres informations utilisateur disponibles
        if (userData['name'] != null) {
          await _storage.write(key: 'user_name', value: userData['name']);
        }
        if (userData['email'] != null) {
          await _storage.write(key: 'user_email', value: userData['email']);
        }
        if (userData['phone'] != null) {
          await _storage.write(key: 'user_phone', value: userData['phone']);
        }
        if (userData['profile_picture'] != null) {
          await _storage.write(
            key: 'user_profile_picture',
            value: userData['profile_picture'],
          );
        }

        // Stocker toutes les données utilisateur en JSON pour un accès facile
        await _storage.write(key: 'user_data', value: jsonEncode(userData));

        _showSnackBar('Connexion réussie !', Colors.green);

        // Récupérer les informations utilisateur après connexion
        await _fetchUserProfile(userId, token);

        // Redirection vers la page d'accueil
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {'userId': userId, 'userData': userData},
        );
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

          // Stocker les informations complètes du profil
          await _storage.write(
            key: 'user_profile',
            value: jsonEncode(userProfile),
          );

          // Stocker les informations spécifiques si elles existent
          if (userProfile['name'] != null) {
            await _storage.write(key: 'user_name', value: userProfile['name']);
          }
          if (userProfile['email'] != null) {
            await _storage.write(
              key: 'user_email',
              value: userProfile['email'],
            );
          }
          if (userProfile['phone'] != null) {
            await _storage.write(
              key: 'user_phone',
              value: userProfile['phone'],
            );
          }
          if (userProfile['address'] != null) {
            await _storage.write(
              key: 'user_address',
              value: userProfile['address'],
            );
          }
          if (userProfile['profile_picture'] != null) {
            await _storage.write(
              key: 'user_profile_picture',
              value: userProfile['profile_picture'],
            );
          }
        }
      }
    } catch (e) {
      print('Profile fetch error: $e');
      // Ne pas afficher d'erreur à l'utilisateur car la connexion a réussi
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
                          decoration: InputDecoration(
                            hintText: 'Votre identifiant',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: primaryBlue),
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
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: primaryBlue),
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

                        const SizedBox(height: 24),

                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 2,
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

                        const SizedBox(height: 20),

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
