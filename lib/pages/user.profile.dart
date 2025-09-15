import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  String? _profileImageUrl;

  // Couleurs du thème
  static const Color primaryBlue = Color(0xFF1E3A5F);
  static const Color accentYellow = Color(0xFFFFB800);
  static const Color lightBlue = Color(0xFF4A90E2);
  static const Color activeGreen = Color(0xFF00C896);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Récupérer le token et l'ID utilisateur
      final String? token = await _storage.read(key: 'auth_token');
      final String? userId = await _storage.read(key: 'user_id');

      if (token != null && userId != null) {
        // Récupérer les données utilisateur depuis l'API
        final response = await http.get(
          Uri.parse('http://49.13.197.63:8001/api/users/$userId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);

          if (responseData['value'] == '200') {
            setState(() {
              _userData = responseData['data'];
              _isLoading = false;

              // Si vous avez une URL pour l'image de profil, stockez-la ici
              // _profileImageUrl = _userData['profilePictureUrl'];
            });

            // Stocker les données utilisateur pour un accès futur
            await _storage.write(
              key: 'user_profile',
              value: jsonEncode(_userData),
            );
          }
        } else {
          // En cas d'erreur, essayer de récupérer les données stockées localement
          _loadStoredUserData();
        }
      } else {
        _loadStoredUserData();
      }
    } catch (e) {
      print('Error loading user data: $e');
      _loadStoredUserData();
    }
  }

  Future<void> _loadStoredUserData() async {
    try {
      final String? userDataString = await _storage.read(key: 'user_profile');

      if (userDataString != null) {
        setState(() {
          _userData = jsonDecode(userDataString);
          _isLoading = false;
        });
      } else {
        // Si aucune donnée n'est disponible
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading stored user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getGenderText(String gender) {
    switch (gender) {
      case 'FEMALE':
        return 'Femme';
      case 'MALE':
        return 'Homme';
      default:
        return gender;
    }
  }

  String _getDocumentTypeText(String documentType) {
    switch (documentType) {
      case 'NATIONAL_ID_CARD':
        return 'Carte nationale d\'identité';
      case 'PASSPORT':
        return 'Passeport';
      case 'DRIVER_LICENSE':
        return 'Permis de conduire';
      default:
        return documentType;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'AVAILABLE':
        return 'Actif';
      case 'BUSY':
        return 'Occupé(e)';
      case 'OFFLINE':
        return 'Hors ligne';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return activeGreen;
      case 'BUSY':
        return Colors.orange;
      case 'OFFLINE':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: primaryBlue),
            onPressed: () {
              // Action pour éditer le profil
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Section principale avec photo de profil et nom
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: [
                        // Photo de profil avec icône panier
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[100],
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 2,
                                ),
                              ),
                              child: _profileImageUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        _profileImageUrl!,
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.shopping_cart,
                                      size: 40,
                                      color: Colors.black87,
                                    ),
                            ),
                            // Icône caméra pour changer la photo
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: lightBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Nom
                        Text(
                          '${_userData['firstName'] ?? ''}'.isNotEmpty
                              ? '${_userData['firstName'] ?? ''}'
                              : 'Utilisateur',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ID utilisateur
                        Text(
                          'ID: #${_userData['username'] ?? 'PRD-2024-001'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Statut actif
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              _userData['shopperStatus'] ?? 'AVAILABLE',
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getStatusText(
                                  _userData['shopperStatus'] ?? 'AVAILABLE',
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section Informations personnelles
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Informations personnelles',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        _buildModernInfoTile(
                          '${_userData['firstName'] ?? ''} ${_userData['lastName'] ?? ''}',
                          subtitle: 'Nom complet',
                        ),
                        _buildModernInfoTile(
                          _userData['phoneNumber'] ?? '655......',
                          subtitle: 'Téléphone',
                        ),
                        _buildModernInfoTile(
                          _userData['email'] ?? 'jean....@gmail.com',
                          subtitle: 'Email',
                        ),
                        _buildModernInfoTile(
                          _getGenderText(
                            _userData['gender'] ?? 'Non renseigné',
                          ),
                          subtitle: 'Genre',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section Informations professionnelles
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Informations professionnelles',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        _buildModernInfoTile(
                          _userData['role'] == 'SHOPPER' ? 'Shopper' : 'Autre',
                          subtitle: 'Rôle',
                        ),
                        _buildModernInfoTile(
                          (_userData['shopperAverageRating']?.toString() ??
                                  '0.0') +
                              '/5',
                          subtitle: 'Note moyenne',
                        ),
                        _buildModernInfoTile(
                          _userData['hireDate'] ?? 'Non renseigné',
                          subtitle: 'Date d\'embauche',
                        ),
                        _buildModernInfoTile(
                          _getDocumentTypeText(
                            _userData['identityDocumentType'] ??
                                'Non renseigné',
                          ),
                          subtitle: 'Type de document',
                        ),
                        _buildModernInfoTile(
                          _userData['identityDocumentNumber'] ??
                              'Non renseigné',
                          subtitle: 'Numéro de document',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bouton de déconnexion
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _storage.deleteAll();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Déconnexion',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
    );
  }

  Widget _buildModernInfoTile(
    String value, {
    required String subtitle,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }
}
