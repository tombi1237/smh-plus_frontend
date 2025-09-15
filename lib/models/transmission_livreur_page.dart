import 'package:flutter/material.dart';

class ProductCategory {
  final String name;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final int articles;
  final String price;
  final bool isCompleted;

  ProductCategory({
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.articles,
    required this.price,
    required this.isCompleted,
  });
}
