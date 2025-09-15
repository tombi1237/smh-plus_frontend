import 'package:smh_front/models/model.dart';

class Neighborhood extends Model {
  final int? id;
  final String? name;
  final String? postalCode;
  final int? arrondissementId;
  final List<dynamic>? markets;
  final String? status;

  const Neighborhood({
    this.id,
    this.name,
    this.postalCode,
    this.arrondissementId,
    this.markets,
    this.status,
  });

  factory Neighborhood.fromJson(Map<String, dynamic> json) {
    return Neighborhood(
      id: json['id'] as int?,
      name: json['name'] as String?,
      postalCode: json['postalCode'] as String?,
      arrondissementId: json['arrondissementId'] as int?,
      markets: json['markets'] as List<dynamic>?,
      status: json['status'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'postalCode': postalCode,
      'arrondissementId': arrondissementId,
      'markets': markets,
      'status': status,
    };
  }
}