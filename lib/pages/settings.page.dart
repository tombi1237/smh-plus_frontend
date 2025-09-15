// settings_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  final int? userId;

  const SettingPage({Key? key, this.userId}) : super(key: key);

  @override
  State<SettingPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingPage> {
  bool isDarkMode = false;
  bool isLocationEnabled = false;
  String selectedLanguage = 'Français';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Charger les paramètres sauvegardés
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        isDarkMode = prefs.getBool('dark_mode') ?? false;
        isLocationEnabled = prefs.getBool('location_enabled') ?? false;
        selectedLanguage = prefs.getString('selected_language') ?? 'Français';
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des paramètres: $e');
    }
  }

  // Sauvegarder les paramètres
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', isDarkMode);
      await prefs.setBool('location_enabled', isLocationEnabled);
      await prefs.setString('selected_language', selectedLanguage);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des paramètres: $e');
    }
  }

  // Basculer le mode sombre
  Future<void> _toggleDarkMode(bool value) async {
    setState(() {
      isDarkMode = value;
    });
    await _saveSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDarkMode ? 'Mode sombre activé' : 'Mode clair activé',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Basculer la localisation
  Future<void> _toggleLocation(bool value) async {
    setState(() {
      isLocationEnabled = value;
    });
    await _saveSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLocationEnabled
                ? 'Localisation activée'
                : 'Localisation désactivée',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Naviguer vers le profil
  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  // Naviguer vers la page de changement de mot de passe
  void _navigateToResetPassword() {
    Navigator.pushNamed(context, '/reset-password');
  }

  // Naviguer vers la sélection de langue
  void _navigateToLanguageSelection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LanguageSelectionPage(currentLanguage: selectedLanguage),
      ),
    );

    if (result != null && result != selectedLanguage) {
      setState(() {
        selectedLanguage = result;
      });
      await _saveSettings();
    }
  }

  // Dialog de confirmation de déconnexion
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Déconnexion
  Future<void> _logout() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Effacer les données de session
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('user_data');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Déconnexion réussie'),
            backgroundColor: Colors.green,
          ),
        );

        // Rediriger vers la page de connexion
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login', // Remplacez par votre route de login
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF1F2937)),
          onPressed: () {
            // Ouvrir le drawer ou menu
            Scaffold.of(context).openDrawer();
          },
        ),
        title: const Text(
          'Paramètres',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Container principal des paramètres
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profil
                        _buildSettingItem(
                          title: 'Profil',
                          onTap: _navigateToProfile,
                          showArrow: true,
                        ),

                        _buildDivider(),

                        // Changement de mot de passe
                        _buildSettingItem(
                          title: 'Changer le mot de passe',
                          onTap: _navigateToResetPassword,
                          showArrow: true,
                        ),

                        _buildDivider(),

                        // Dark Mode
                        _buildSettingItem(
                          title: 'Dark Mode',
                          trailing: _buildToggleSwitch(
                            value: isDarkMode,
                            onChanged: _toggleDarkMode,
                          ),
                        ),

                        _buildDivider(),

                        // Location
                        _buildSettingItem(
                          title: 'Location',
                          trailing: _buildToggleSwitch(
                            value: isLocationEnabled,
                            onChanged: _toggleLocation,
                          ),
                        ),

                        _buildDivider(),

                        // Language
                        _buildSettingItem(
                          title: 'Language',
                          subtitle: selectedLanguage,
                          onTap: _navigateToLanguageSelection,
                          showArrow: true,
                        ),

                        _buildDivider(),

                        // Privacy Policy
                        _buildSettingItem(
                          title: 'Privacy Policy',
                          onTap: () => {},
                          showArrow: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Bouton de déconnexion
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          spreadRadius: 0,
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _showLogoutConfirmation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Déconnexion',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Navigation Bar
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    bool showArrow = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (showArrow)
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFD1D5DB),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSwitch({
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: const Color(0xFF3B82F6),
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: const Color(0xFFE5E7EB),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      color: const Color(0xFFE5E7EB).withOpacity(0.5),
    );
  }
}

// language_selection_page.dart
class LanguageSelectionPage extends StatefulWidget {
  final String currentLanguage;

  const LanguageSelectionPage({Key? key, required this.currentLanguage})
    : super(key: key);

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  late String selectedLanguage;

  final List<Map<String, String>> languages = [
    {'name': 'Français', 'code': 'fr'},
    {'name': 'English', 'code': 'en'},
  ];

  @override
  void initState() {
    super.initState();
    selectedLanguage = widget.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sélectionner la langue',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListView.separated(
          itemCount: languages.length,
          separatorBuilder: (context, index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 1,
            color: const Color(0xFFE5E7EB).withOpacity(0.5),
          ),
          itemBuilder: (context, index) {
            final language = languages[index];
            final isSelected = selectedLanguage == language['name'];

            return ListTile(
              title: Text(
                language['name']!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF1F2937),
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Color(0xFF3B82F6))
                  : null,
              onTap: () {
                Navigator.pop(context, language['name']);
              },
            );
          },
        ),
      ),
    );
  }
}
