class UserData {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String phoneNumber;
  final String gender;
  final String role;
  final String hireDate;
  final String identityDocumentType;
  final String identityDocumentNumber;
  final double shopperAverageRating;
  final String shopperStatus;
  final bool enabled;
  final Assignment? assignment;

  UserData({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.gender,
    required this.role,
    required this.hireDate,
    required this.identityDocumentType,
    required this.identityDocumentNumber,
    required this.shopperAverageRating,
    required this.shopperStatus,
    required this.enabled,
    this.assignment,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    try {
      return UserData(
        id: json['id'] as int? ?? 0,
        firstName: json['firstName']?.toString() ?? '',
        lastName: json['lastName']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phoneNumber: json['phoneNumber']?.toString() ?? '',
        gender: json['gender']?.toString() ?? '',
        role: json['role']?.toString() ?? '',
        hireDate: json['hireDate']?.toString() ?? '',
        identityDocumentType: json['identityDocumentType']?.toString() ?? '',
        identityDocumentNumber:
            json['identityDocumentNumber']?.toString() ?? '',
        shopperAverageRating: (json['shopperAverageRating'] is num)
            ? (json['shopperAverageRating'] as num).toDouble()
            : 0.0,
        shopperStatus: json['shopperStatus']?.toString() ?? 'OFFLINE',
        enabled: json['enabled'] as bool? ?? false,
        assignment: json['assignment'] != null
            ? Assignment.fromJson(json['assignment'])
            : null,
      );
    } catch (e) {
      print('Error parsing UserData: $e');
      return UserData(
        id: 0,
        firstName: '',
        lastName: '',
        username: '',
        email: '',
        phoneNumber: '',
        gender: '',
        role: '',
        hireDate: '',
        identityDocumentType: '',
        identityDocumentNumber: '',
        shopperAverageRating: 0.0,
        shopperStatus: 'OFFLINE',
        enabled: false,
      );
    }
  }
}

class Assignment {
  final int id;
  final int userId;
  final String location;
  final String locationType;
  final String assignedRole;
  final String startDate;
  final String? endDate;
  final String createdAt;
  final bool active;

  Assignment({
    required this.id,
    required this.userId,
    required this.location,
    required this.locationType,
    required this.assignedRole,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    required this.active,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    try {
      return Assignment(
        id: json['id'] as int? ?? 0,
        userId: json['userId'] as int? ?? 0,
        location: json['location']?.toString() ?? '',
        locationType: json['locationType']?.toString() ?? '',
        assignedRole: json['assignedRole']?.toString() ?? '',
        startDate: json['startDate']?.toString() ?? '',
        endDate: json['endDate']?.toString(),
        createdAt: json['createdAt']?.toString() ?? '',
        active: json['active'] as bool? ?? false,
      );
    } catch (e) {
      print('Error parsing Assignment: $e');
      return Assignment(
        id: 0,
        userId: 0,
        location: '',
        locationType: '',
        assignedRole: '',
        startDate: '',
        createdAt: '',
        active: false,
      );
    }
  }
}

class User {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String phoneNumber;
  final String gender;
  final String role;
  final String hireDate;
  final String identityDocumentType;
  final String identityDocumentNumber;
  final bool enabled;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.gender,
    required this.role,
    required this.hireDate,
    required this.identityDocumentType,
    required this.identityDocumentNumber,
    required this.enabled,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['id'] as int? ?? 0,
        firstName: json['firstName']?.toString() ?? '',
        lastName: json['lastName']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phoneNumber: json['phoneNumber']?.toString() ?? '',
        gender: json['gender']?.toString() ?? '',
        role: json['role']?.toString() ?? '',
        hireDate: json['hireDate']?.toString() ?? '',
        identityDocumentType: json['identityDocumentType']?.toString() ?? '',
        identityDocumentNumber:
            json['identityDocumentNumber']?.toString() ?? '',
        enabled: json['enabled'] as bool? ?? false,
      );
    } catch (e) {
      print('Error parsing User: $e');
      return User(
        id: 0,
        firstName: '',
        lastName: '',
        username: '',
        email: '',
        phoneNumber: '',
        gender: '',
        role: '',
        hireDate: '',
        identityDocumentType: '',
        identityDocumentNumber: '',
        enabled: false,
      );
    }
  }
}
