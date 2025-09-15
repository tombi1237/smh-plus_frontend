class User {
  final String email;
  final String? oldPassword;
  final String? newPassword;

  User({required this.email, this.oldPassword, this.newPassword});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    };
  }

  User copyWith({String? email, String? oldPassword, String? newPassword}) {
    return User(
      email: email ?? this.email,
      oldPassword: oldPassword ?? this.oldPassword,
      newPassword: newPassword ?? this.newPassword,
    );
  }
}
