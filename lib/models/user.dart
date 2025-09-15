import 'package:smh_front/models/model.dart';

class User extends Model {
  final int? id;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? email;
  final String? phoneNumber;
  final UserGenre? gender;
  final String? role;
  final double? loyaltyPoints;
  final bool? enabled;
  final String? profilePictureUrl;
  final String? primaryAddress;
  final DateTime? hireDate;
  final String? identityDocumentType;
  final String? identityDocumentNumber;
  final double? shopperAverageRating;
  final String? shopperStatus;

  const User({
    this.id,
    this.firstName,
    this.lastName,
    this.username,
    this.email,
    this.phoneNumber,
    this.gender,
    this.role,
    this.loyaltyPoints,
    this.enabled,
    this.profilePictureUrl,
    this.primaryAddress,
    this.hireDate,
    this.identityDocumentType,
    this.identityDocumentNumber,
    this.shopperAverageRating,
    this.shopperStatus,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      username: json['username'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      gender: json['gender'] != null
          ? UserGenre.values.firstWhere(
              (e) => e.toString().toLowerCase() == 'UserGenre.${(json['gender'] as String).toLowerCase()}',
              orElse: () => UserGenre.other,
            )
          : null,
      role: json['role'] as String?,
      loyaltyPoints: (json['loyaltyPoints'] as num?)?.toDouble(),
      enabled: json['enabled'] as bool?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      primaryAddress: json['primaryAddress'] as String?,
      hireDate: json['hireDate'] != null
          ? DateTime.tryParse(json['hireDate'] as String)
          : null,
      identityDocumentType: json['identityDocumentType'] as String?,
      identityDocumentNumber: json['identityDocumentNumber'] as String?,
      shopperAverageRating: (json['shopperAverageRating'] as num?)?.toDouble(),
      shopperStatus: json['shopperStatus'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'gender': gender?.toString().split('.').last.toUpperCase(),
      'role': role,
      'loyaltyPoints': loyaltyPoints,
      'enabled': enabled,
      'profilePictureUrl': profilePictureUrl,
      'primaryAddress': primaryAddress,
      'hireDate': hireDate?.toIso8601String(),
      'identityDocumentType': identityDocumentType,
      'identityDocumentNumber': identityDocumentNumber,
      'shopperAverageRating': shopperAverageRating,
      'shopperStatus': shopperStatus,
    };
  }
}

enum UserGenre { male, female, other }