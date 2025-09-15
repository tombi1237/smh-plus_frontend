typedef JsonObject = Map<String, dynamic>;
typedef JsonArray = List<JsonObject>;

class Model {
  const Model();
  Model.fromJson(JsonObject json);

  JsonObject toJson() {
    return JsonObject();
  }

  static List<T> fromJsonArray<T extends Model>(JsonArray array) {
    return array.map<T>((e) => T.fromJson(e)).toList();
  }
}

extension on Type {
  fromJson<T extends Model>(JsonObject e) {}
}

class Pageable {
  final int pageNumber;
  final int pageSize;
  final List<String>? sort;
  final int? offset;
  final bool? unpaged;
  final bool? paged;

  const Pageable({
    required this.pageNumber,
    this.pageSize = 20,
    this.sort,
    this.offset,
    this.unpaged,
    this.paged,
  });

  factory Pageable.fromJson(Map<String, dynamic> json) {
    return Pageable(
      pageNumber: json['pageNumber'] ?? 1,
      pageSize: json['pageSize'] ?? 0,
      sort: (json['sort'] as List<dynamic>?)?.map((e) => e as String).toList(),
      offset: json['offset'] ?? 0,
      unpaged: json['unpaged'] ?? false,
      paged: json['paged'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      'sort': sort,
      'offset': offset,
      'unpaged': unpaged,
      'paged': paged,
    };
  }
}

class PaginatedData<T> extends Pageable {
  final List<T> items;

  const PaginatedData({
    required super.pageNumber,
    super.pageSize,
    super.sort,
    super.offset,
    super.unpaged,
    super.paged,
    required this.items,
  });

  factory PaginatedData.empty() => PaginatedData(pageNumber: 1, items: List.empty());

  factory PaginatedData.fromData(Pageable pagination, List<T> items) =>
      PaginatedData(
        pageNumber: pagination.pageNumber,
        pageSize: pagination.pageSize,
        sort: pagination.sort,
        offset: pagination.offset,
        unpaged: pagination.unpaged,
        paged: pagination.paged,
        items: items,
      );

  factory PaginatedData.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedData(
      pageNumber: json['pageNumber'] ?? 1,
      pageSize: json['pageSize'] ?? 0,
      sort: (json['sort'] as List<dynamic>?)?.map((e) => e as String).toList(),
      offset: json['offset'] as int?,
      unpaged: json['unpaged'] as bool?,
      paged: json['paged'] as bool?,
      items:
          (json['content'] as JsonArray?)?.map((e) => fromJsonT(e)).toList() ??
          [],
    );
  }
}
