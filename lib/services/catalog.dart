import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ======================
///        MODELS
/// ======================

// --- Produit ---
class Product {
  final String productId;
  final String name;
  final String description;
  final String unit;
  final double pricePerUnit;
  final String subCategoryId;
  final List<ProductImage> images;
  final int districtId;
  final String sellerType;
  final String availabilityStatus;

  Product({
    required this.productId,
    required this.name,
    required this.description,
    required this.unit,
    required this.pricePerUnit,
    required this.subCategoryId,
    required this.images,
    required this.districtId,
    required this.sellerType,
    required this.availabilityStatus,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json["productId"] ?? "",
      name: json["name"] ?? "Produit inconnu",
      description: json["description"] ?? "",
      unit: json["unit"] ?? "KG",
      pricePerUnit: (json["pricePerUnit"] ?? 0).toDouble(),
      subCategoryId: json["subCategoryId"] ?? "",
      images:
          (json["images"] as List?)
              ?.map((img) => ProductImage.fromJson(img))
              .toList() ??
          [],
      districtId: json["districtId"] ?? 0,
      sellerType: json["sellerType"] ?? "MERCHANT",
      availabilityStatus: json["availabilityStatus"] ?? "IN_STOCK",
    );
  }
}

class ProductImage {
  final String url;
  ProductImage({required this.url});
  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(url: json["url"] ?? "");
  }
}

// --- Sous-catégorie ---
class SubCategory {
  final String id;
  final String name;
  final String categoryId;
  SubCategory({required this.id, required this.name, required this.categoryId});
  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json["id"] ?? "",
      name: json["name"] ?? "Sous-catégorie inconnue",
      categoryId: json["categoryId"] ?? "",
    );
  }
}

// --- Catégorie ---
class Category {
  final String id;
  final String name;
  final String description;
  final int productCount;
  Category({
    required this.id,
    required this.name,
    required this.description,
    this.productCount = 0,
  });
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json["id"] ?? "",
      name: json["name"] ?? "Catégorie inconnue",
      description: json["description"] ?? "",
      productCount: json["productCount"] ?? 0,
    );
  }
}

/// ======================
///        SERVICE API
/// ======================

class CatalogService {
  static const String baseUrl = "http://49.13.197.63:8004/api/products";
  static final _storage = const FlutterSecureStorage();

  /// Récupérer toutes les catégories
  static Future<List<Category>> fetchCategories() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) throw Exception("Token manquant");

    final res = await http.get(
      Uri.parse("$baseUrl/categories/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data["data"] as List).map((c) => Category.fromJson(c)).toList();
    } else {
      throw Exception("Erreur lors du chargement des catégories");
    }
  }

  /// Récupérer les sous-catégories
  static Future<List<SubCategory>> fetchSubCategories(String categoryId) async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) throw Exception("Token manquant");

    final res = await http.get(
      Uri.parse("$baseUrl/subCategories"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data["data"] as List)
          .map((sc) => SubCategory.fromJson(sc))
          .where((sc) => sc.categoryId == categoryId)
          .toList();
    } else {
      throw Exception("Erreur lors du chargement des sous-catégories");
    }
  }

  /// Récupérer les produits par sous-catégories
  static Future<List<Product>> fetchProducts(
    List<String> subCategoryIds,
  ) async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) throw Exception("Token manquant");

    final res = await http.get(
      Uri.parse("$baseUrl/products"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data["data"] as List)
          .map((p) => Product.fromJson(p))
          .where((p) => subCategoryIds.contains(p.subCategoryId))
          .toList();
    } else {
      throw Exception("Erreur lors du chargement des produits");
    }
  }
}
