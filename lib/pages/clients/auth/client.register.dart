import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ClientRegister extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: ClientRegistrationPage());
  }
}

class User {
  final int? id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String phoneNumber;
  final String gender;
  final String role;
  final String? profilePictureUrl;
  final String? primaryAddress;
  final int loyaltyPoints;
  final bool enabled;

  User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.gender,
    this.role = 'CLIENT',
    this.profilePictureUrl,
    this.primaryAddress,
    this.loyaltyPoints = 0,
    this.enabled = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      username: json['username'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      gender: json['gender'],
      role: json['role'],
      profilePictureUrl: json['profilePictureUrl'],
      primaryAddress: json['primaryAddress'],
      loyaltyPoints: json['loyaltyPoints'] ?? 0,
      enabled: json['enabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'primaryAddress': primaryAddress,
    };
  }
}

class RegisterRequest {
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String phoneNumber;
  final String gender;
  final String? primaryAddress;
  final String password;

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.gender,
    this.primaryAddress,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'primaryAddress': primaryAddress,
      'password': password,
    };
  }
}

class AuthService {
  static const String _baseUrl = 'http://49.13.197.63:8001/api/users';

  Future<Map<String, dynamic>> registerUser(RegisterRequest user) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': User.fromJson(jsonDecode(response.body)['data']),
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }
}

class ClientRegistrationPage extends StatefulWidget {
  @override
  _ClientRegistrationPageState createState() => _ClientRegistrationPageState();
}

class _ClientRegistrationPageState extends State<ClientRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _agreeToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Contrôleurs
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _selectedGender = '';
  String _countryCode = '+237';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _professionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      _showErrorDialog('Vous devez accepter les conditions d\'utilisation');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final registerRequest = RegisterRequest(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      username: _usernameController.text,
      email: _emailController.text,
      phoneNumber: _countryCode + _phoneController.text,
      gender: _selectedGender,
      primaryAddress: _professionController.text.isEmpty
          ? null
          : _professionController.text,
      password: _passwordController.text,
    );

    final result = await _authService.registerUser(registerRequest);

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      final User createdUser = result['data'];
      _showSuccessDialog(createdUser);
    } else {
      _showErrorDialog(result['message']);
    }
  }

  void _showSuccessDialog(User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Inscription réussie',
                style: TextStyle(color: Color(0xFF1A365D), fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Compte créé avec succès pour:'),
              SizedBox(height: 8),
              Text(
                '${user.firstName} ${user.lastName}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Username: ${user.username}'),
              Text(user.email),
              Text(user.phoneNumber),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Se connecter',
                style: TextStyle(color: Color(0xFFE6B800)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Erreur', style: TextStyle(color: Colors.red)),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    hintText,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A365D),
          ),
        ),
        SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: TextStyle(fontSize: 19),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Color(0xFF718096), fontSize: 16),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF3182CE), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: suffixIcon,
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Téléphone',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A365D),
          ),
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Text(_countryCode, style: TextStyle(fontSize: 16)),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(fontSize: 19),
                decoration: InputDecoration(
                  hintStyle: TextStyle(color: Color(0xFF718096), fontSize: 16),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFF3182CE),
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: Icon(Icons.phone, color: Color(0xFF718096)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Numéro de téléphone requis';
                  }
                  if (value.length < 8) {
                    return 'Numéro invalide';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sexe',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A365D),
          ),
        ),
        SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _selectedGender.isEmpty ? null : _selectedGender,
          style: TextStyle(fontSize: 16, color: Colors.black),
          decoration: InputDecoration(
            hintText: 'Sélectionnez votre sexe',
            hintStyle: TextStyle(color: Color(0xFF718096), fontSize: 16),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF3182CE), width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(Icons.person, color: Color(0xFF718096)),
          ),
          items: [
            DropdownMenuItem(value: 'MALE', child: Text('Masculin')),
            DropdownMenuItem(value: 'FEMALE', child: Text('Féminin')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedGender = value!;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez sélectionner votre sexe';
            }
            return null;
          },
        ),
        SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) {
            setState(() {
              _agreeToTerms = value!;
            });
          },
          activeColor: Color(0xFFE6B800),
        ),
        Expanded(
          child: Text(
            'J\'accepte les conditions d\'utilisation et la politique de confidentialité',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7FAFC),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFFE6B800)))
            : SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Créer votre nouveau compte',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A365D),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Nom et Prénom en ligne
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _firstNameController,
                              labelText: 'Prénom',

                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Prénom requis'
                                  : null,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _lastNameController,
                              labelText: 'Nom',

                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Nom requis'
                                  : null,
                            ),
                          ),
                        ],
                      ),

                      // Username
                      _buildTextField(
                        controller: _usernameController,
                        labelText: 'Nom d\'utilisateur',

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nom d\'utilisateur requis';
                          }
                          if (value.length < 3) {
                            return 'Au moins 3 caractères requis';
                          }
                          return null;
                        },
                      ),

                      // Profession (facultatif)
                      _buildTextField(
                        controller: _professionController,
                        labelText: 'Profession',
                        hintText: 'facultatif',
                        validator: (value) =>
                            null, // Pas de validation car facultatif
                      ),

                      // Genre
                      _buildGenderDropdown(),

                      // Email
                      _buildTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'exemple@email.com',
                        keyboardType: TextInputType.emailAddress,

                        suffixIcon: Icon(
                          Icons.alternate_email,
                          color: Color(0xFF718096),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email requis';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),

                      // Téléphone
                      _buildPhoneField(),

                      // Mot de passe
                      _buildTextField(
                        controller: _passwordController,
                        labelText: 'Mot de passe',
                        hintText: 'Créez un mot de passe',
                        obscureText: _obscurePassword,

                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Color(0xFF718096),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Mot de passe requis';
                          }
                          if (value.length < 6) {
                            return 'Au moins 6 caractères requis';
                          }
                          return null;
                        },
                      ),

                      // Confirmation mot de passe
                      _buildTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirmer le mot de passe',
                        hintText: 'Répétez votre mot de passe',
                        obscureText: _obscureConfirmPassword,

                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Color(0xFF718096),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirmation requise';
                          }
                          if (value != _passwordController.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),

                      // Conditions d'utilisation
                      _buildTermsCheckbox(),

                      SizedBox(height: 20),

                      // Bouton d'inscription
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _registerUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFE6B800),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Créer mon compte',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Lien vers la connexion
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 16),
                              children: [
                                TextSpan(
                                  text: 'Vous avez déjà un compte? ',
                                  style: TextStyle(color: Color(0xFF718096)),
                                ),
                                TextSpan(
                                  text: 'Se connecter',
                                  style: TextStyle(
                                    color: Color(0xFFE6B800),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
