import 'package:smh_front/models/model.dart';

class District extends Model {
  final int? id;
  final String? name;

  const District({this.id, required this.name});

  factory District.fromJson(JsonObject object) {
    return District(
      id: object['id'] as int?,
      name: object['name'] as String?,
    );
  }

  @override
  JsonObject toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}