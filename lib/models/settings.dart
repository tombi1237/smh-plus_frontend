class SettingsModel {
  bool isDarkModeEnabled;
  bool isLocationEnabled;
  String selectedLanguage;

  SettingsModel({
    this.isDarkModeEnabled = true,
    this.isLocationEnabled = true,
    this.selectedLanguage = 'English',
  });

  SettingsModel copyWith({
    bool? isDarkModeEnabled,
    bool? isLocationEnabled,
    String? selectedLanguage,
  }) {
    return SettingsModel(
      isDarkModeEnabled: isDarkModeEnabled ?? this.isDarkModeEnabled,
      isLocationEnabled: isLocationEnabled ?? this.isLocationEnabled,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isDarkModeEnabled': isDarkModeEnabled,
      'isLocationEnabled': isLocationEnabled,
      'selectedLanguage': selectedLanguage,
    };
  }

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      isDarkModeEnabled: json['isDarkModeEnabled'] ?? true,
      isLocationEnabled: json['isLocationEnabled'] ?? true,
      selectedLanguage: json['selectedLanguage'] ?? 'English',
    );
  }
}
