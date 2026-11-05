import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum ShopCategory { shoes, apparel, strength, accessories, recovery }

extension ShopCategoryX on ShopCategory {
  String get label => switch (this) {
    ShopCategory.shoes => 'Chaussures',
    ShopCategory.apparel => 'Textile',
    ShopCategory.strength => 'Force',
    ShopCategory.accessories => 'Accessoires',
    ShopCategory.recovery => 'Récupération',
  };

  IconData get icon => switch (this) {
    ShopCategory.shoes => Icons.directions_run_rounded,
    ShopCategory.apparel => Icons.checkroom_rounded,
    ShopCategory.strength => Icons.fitness_center_rounded,
    ShopCategory.accessories => Icons.sports_handball_rounded,
    ShopCategory.recovery => Icons.battery_charging_full_rounded,
  };

  Color get accent => switch (this) {
    ShopCategory.shoes => AppColors.cyan,
    ShopCategory.apparel => AppColors.violet,
    ShopCategory.strength => AppColors.coral,
    ShopCategory.accessories => AppColors.amber,
    ShopCategory.recovery => AppColors.mint,
  };
}

class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.description,
    required this.features,
    required this.rating,
    required this.reviewCount,
    required this.color,
    required this.icon,
    this.badge,
  });

  final String id;
  final String name;
  final String brand;
  final ShopCategory category;
  final double price;
  final String description;
  final List<String> features;
  final double rating;
  final int reviewCount;
  final Color color;
  final IconData icon;
  final String? badge;
}

class ShopReview {
  const ShopReview({
    required this.author,
    required this.date,
    required this.rating,
    required this.comment,
    required this.initials,
  });

  final String author;
  final String date;
  final double rating;
  final String comment;
  final String initials;
}

class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.date,
    required this.status,
    required this.total,
    required this.items,
  });

  final String id;
  final String date;
  final String status;
  final double total;
  final List<String> items;
}

class ShopCartLine {
  const ShopCartLine({required this.product, required this.quantity});

  final ShopProduct product;
  final int quantity;

  ShopCartLine copyWith({int? quantity}) =>
      ShopCartLine(product: product, quantity: quantity ?? this.quantity);
}
