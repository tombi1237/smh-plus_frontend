import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/settings.dart';

class SettingsService extends ChangeNotifier {
  SettingsModel _settings = SettingsModel();

  SettingsModel get settings => _settings;

  void updateDarkMode(bool value) {
    _settings = _settings.copyWith(isDarkModeEnabled: value);
    _saveSettings();
    notifyListeners();
  }

  void updateLocation(bool value) {
    _settings = _settings.copyWith(isLocationEnabled: value);
    _saveSettings();
    notifyListeners();
  }

  void updateLanguage(String language) {
    _settings = _settings.copyWith(selectedLanguage: language);
    _saveSettings();
    notifyListeners();
  }

  void _saveSettings() {
    // Ici, vous pouvez implémenter la sauvegarde avec SharedPreferences
    // Pour l'exemple, on utilise juste print
    print('Settings saved: ${jsonEncode(_settings.toJson())}');
  }

  Future<void> loadSettings() async {
    // Ici, vous pouvez implémenter le chargement avec SharedPreferences
    // Pour l'exemple, on garde les valeurs par défaut
    notifyListeners();
  }

  Future<void> logout() async {
    // Logique de déconnexion
    print('Utilisateur déconnecté');
    // Ici vous pouvez nettoyer les données, naviguer vers la page de connexion, etc.
  }
}
