import 'package:flutter/material.dart';

enum MealType { breakfast, lunch, snack, dinner }

extension MealTypeX on MealType {
  String get label => switch (this) {
    MealType.breakfast => 'Petit-déjeuner',
    MealType.lunch => 'Déjeuner',
    MealType.snack => 'Collation',
    MealType.dinner => 'Dîner',
  };

  IconData get icon => switch (this) {
    MealType.breakfast => Icons.wb_sunny_outlined,
    MealType.lunch => Icons.lunch_dining_rounded,
    MealType.snack => Icons.cookie_outlined,
    MealType.dinner => Icons.nightlight_outlined,
  };
}

class MealEntry {
  const MealEntry({
    required this.type,
    required this.name,
    required this.time,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final MealType type;
  final String name;
  final String time;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
}

class NutritionRecipe {
  const NutritionRecipe({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.calories,
    required this.protein,
    required this.duration,
    required this.icon,
    required this.accent,
  });

  final String id;
  final String name;
  final String subtitle;
  final int calories;
  final int protein;
  final int duration;
  final IconData icon;
  final Color accent;
}

class FoodItem {
  const FoodItem({
    required this.name,
    required this.category,
    required this.serving,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final String name;
  final String category;
  final String serving;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
}
