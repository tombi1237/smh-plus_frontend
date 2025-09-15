class UserProfile {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String address;
  final bool isActive;
  final String? avatarUrl;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.address,
    required this.isActive,
    this.avatarUrl,
  });

  // Méthode pour créer un profil vide
  factory UserProfile.empty() {
    return UserProfile(
      id: '',
      fullName: '',
      phone: '',
      email: '',
      address: '',
      isActive: false,
    );
  }

  // Méthode pour créer un profil de démonstration
  factory UserProfile.demo() {
    return UserProfile(
      id: '#PRD-2024-001',
      fullName: 'Jean Paul ATEBA',
      phone: '655......',
      email: 'jean....@gmail.com',
      address: 'Nkolbisson',
      isActive: true,
    );
  }
}
