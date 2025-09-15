import 'package:smh_front/models/model.dart';

class Product extends Model {
  final String? id;
  final String? name;
  final String? description;
  final String? unit;
  final double? pricePerUnit;
  final String? subCategoryId;
  final List<ProductImage>? images;
  final int? districtId;
  final String? sellerType;
  final String? availabilityStatus;

  const Product({
    this.id,
    this.name,
    this.description,
    this.unit,
    this.pricePerUnit,
    this.subCategoryId,
    this.images,
    this.districtId,
    this.sellerType,
    this.availabilityStatus,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['productId'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      unit: json['unit'] as String?,
      pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble(),
      subCategoryId: json['subCategoryId'] as String?,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      districtId: json['districtId'] as int?,
      sellerType: json['sellerType'] as String?,
      availabilityStatus: json['availabilityStatus'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'productId': id,
      'name': name,
      'description': description,
      'unit': unit,
      'pricePerUnit': pricePerUnit,
      'subCategoryId': subCategoryId,
      'images': images?.map((e) => e.toJson()).toList(),
      'districtId': districtId,
      'sellerType': sellerType,
      'availabilityStatus': availabilityStatus,
    };
  }
}

class ProductImage {
  final String? url;

  const ProductImage({this.url});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
    };
  }
}

class Category extends Model {
  final String? id;
  final String name;
  final String? description;

  const Category({
    this.id,
    required this.name,
    this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String?,
      name: json['name'] ?? '',
      description: json['description'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

class SubCategory extends Category {
  final Category? category;

  const SubCategory({
    super.id,
    required super.name,
    super.description,
    this.category,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'] as String?,
      name: json['name'] ?? '',
      description: json['description'] as String?,
      category: json['category'] != null
          ? Category.fromJson(json['category'] as JsonObject)
          : null,
    );
  }

  @override
  JsonObject toJson() {
    final data = super.toJson();
    data['category'] = category?.toJson();
    return data;
  }
}