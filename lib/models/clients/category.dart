class Category {
  final String id;
  final String name;
  final String description;
  final String imageUrl;

  Category({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl = '',
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json["id"] ?? "",
      name: json["name"] ?? "Catégorie inconnue",
      description: json["description"] ?? "",
      imageUrl: json["imageUrl"] ?? '',
    );
  }
}
