import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

double _d(Object? v) => (v as num? ?? 0).toDouble();
int _i(Object? v) => (v as num? ?? 0).toInt();

enum MealType { breakfast, lunch, snack, dinner }

MealType mealTypeFromJson(String? value) =>
    MealType.values.firstWhere((t) => t.name == value, orElse: () => MealType.snack);

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

  /// Default time used when logging a meal of this type.
  String get defaultTime => switch (this) {
        MealType.breakfast => '08:00',
        MealType.lunch => '13:00',
        MealType.snack => '16:30',
        MealType.dinner => '20:30',
      };

  static MealType forHour(int hour) => switch (hour) {
        < 10 => MealType.breakfast,
        < 15 => MealType.lunch,
        < 18 => MealType.snack,
        _ => MealType.dinner,
      };
}

class MealEntry {
  const MealEntry({
    this.id,
    required this.date,
    required this.type,
    required this.name,
    required this.time,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int? id;
  final String date;
  final MealType type;
  final String name;
  final String time;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  factory MealEntry.fromJson(Map<String, dynamic> json) => MealEntry(
        id: (json['id'] as num?)?.toInt(),
        date: json['date']?.toString() ?? '',
        type: mealTypeFromJson(json['type']?.toString()),
        name: json['name']?.toString() ?? '',
        time: json['time']?.toString() ?? '',
        calories: _i(json['calories']),
        protein: _d(json['protein']),
        carbs: _d(json['carbs']),
        fat: _d(json['fat']),
      );
}

class NutritionRecipe {
  const NutritionRecipe({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.duration,
    this.mealType,
    this.goalTags = const [],
    this.ingredients = const [],
    this.steps = const [],
    this.isTunisian = false,
    this.iconKey,
    this.accentKey,
    this.reason,
  });

  final String id;
  final String name;
  final String subtitle;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final int duration;
  final MealType? mealType;
  final List<String> goalTags;
  final List<String> ingredients;
  final List<String> steps;
  final bool isTunisian;
  final String? iconKey;
  final String? accentKey;

  /// Why the AI coach suggested it (only on coach suggestions).
  final String? reason;

  IconData get icon => switch (iconKey) {
        'rice_bowl' => Icons.rice_bowl_rounded,
        'breakfast' => Icons.breakfast_dining_rounded,
        'blender' => Icons.blender_rounded,
        'dinner' => Icons.dinner_dining_rounded,
        'lunch' => Icons.lunch_dining_rounded,
        'snack' => Icons.cookie_rounded,
        _ => Icons.restaurant_rounded,
      };

  Color get accent => switch (accentKey) {
        'mint' => AppColors.mint,
        'amber' => AppColors.amber,
        'violet' => AppColors.violet,
        'coral' => AppColors.coral,
        'cyan' => AppColors.cyan,
        'volt' => AppColors.volt,
        _ => AppColors.mint,
      };

  factory NutritionRecipe.fromJson(Map<String, dynamic> json) => NutritionRecipe(
        id: json['id'].toString(),
        name: json['name']?.toString() ?? '',
        subtitle: json['subtitle']?.toString() ?? '',
        calories: _i(json['calories']),
        protein: _d(json['protein']),
        carbs: _d(json['carbs']),
        fat: _d(json['fat']),
        duration: _i(json['duration']),
        mealType: json['mealType'] == null ? null : mealTypeFromJson(json['mealType'].toString()),
        goalTags: (json['goalTags'] as List? ?? const []).map((e) => e.toString()).toList(),
        ingredients: (json['ingredients'] as List? ?? const []).map((e) => e.toString()).toList(),
        steps: (json['steps'] as List? ?? const []).map((e) => e.toString()).toList(),
        isTunisian: json['isTunisian'] == true,
        iconKey: json['icon']?.toString(),
        accentKey: json['accent']?.toString(),
        reason: json['reason']?.toString(),
      );
}

const foodCategoryLabels = <String, String>{
  'protein': 'Protéines',
  'starch': 'Féculents complets',
  'legume': 'Légumineuses',
  'dairy': 'Laitages',
  'fruit': 'Fruits',
  'vegetable': 'Légumes',
  'nuts': 'Oléagineux',
  'fat': 'Bonnes graisses',
  'snack': 'Snacks sains',
  'drink': 'Boissons',
};

class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.serving,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.isTunisian = false,
  });

  final String id;
  final String name;
  final String category;
  final String serving;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final bool isTunisian;

  String get categoryLabel => foodCategoryLabels[category] ?? category;

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id'].toString(),
        name: json['name']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        serving: json['serving']?.toString() ?? '',
        calories: _i(json['calories']),
        protein: _d(json['protein']),
        carbs: _d(json['carbs']),
        fat: _d(json['fat']),
        isTunisian: json['isTunisian'] == true,
      );
}

class NutritionTargets {
  const NutritionTargets({required this.calories, required this.protein, required this.carbs, required this.fat});

  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  factory NutritionTargets.fromJson(Map<String, dynamic> json) => NutritionTargets(
        calories: _i(json['calories']),
        protein: _d(json['protein']),
        carbs: _d(json['carbs']),
        fat: _d(json['fat']),
      );
}

class DailyNutrition {
  const DailyNutrition({
    required this.date,
    required this.meals,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.targets,
  });

  final String date;
  final List<MealEntry> meals;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final NutritionTargets? targets;

  factory DailyNutrition.fromJson(Map<String, dynamic> json) {
    final totals = Map<String, dynamic>.from(json['totals'] as Map? ?? const {});
    return DailyNutrition(
      date: json['date']?.toString() ?? '',
      meals: (json['meals'] as List? ?? const []).map((e) => MealEntry.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      calories: _i(totals['calories']),
      protein: _d(totals['protein']),
      carbs: _d(totals['carbs']),
      fat: _d(totals['fat']),
      targets: json['targets'] is Map ? NutritionTargets.fromJson(Map<String, dynamic>.from(json['targets'] as Map)) : null,
    );
  }
}

class NutritionDay {
  const NutritionDay({required this.date, required this.calories, required this.protein, required this.meals});

  final DateTime date;
  final int calories;
  final double protein;
  final int meals;

  factory NutritionDay.fromJson(Map<String, dynamic> json) => NutritionDay(
        date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        calories: _i(json['calories']),
        protein: _d(json['protein']),
        meals: _i(json['meals']),
      );
}

class NutritionWeek {
  const NutritionWeek({required this.days, required this.averageCalories, required this.averageProtein, this.targetCalories, this.targetProtein});

  final List<NutritionDay> days;
  final int averageCalories;
  final double averageProtein;
  final int? targetCalories;
  final double? targetProtein;

  factory NutritionWeek.fromJson(Map<String, dynamic> json) => NutritionWeek(
        days: (json['days'] as List? ?? const []).map((e) => NutritionDay.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        averageCalories: _i(json['averageCalories']),
        averageProtein: _d(json['averageProtein']),
        targetCalories: (json['targetCalories'] as num?)?.toInt(),
        targetProtein: (json['targetProtein'] as num?)?.toDouble(),
      );
}

String apiDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String fmtNum(num value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1).replaceAll('.', ',');
}
