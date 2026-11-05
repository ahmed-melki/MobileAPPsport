import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum OnboardingSex {
  male,
  female,
  other;

  String get label => switch (this) {
        OnboardingSex.male => 'Homme',
        OnboardingSex.female => 'Femme',
        OnboardingSex.other => 'Autre',
      };

  IconData get icon => switch (this) {
        OnboardingSex.male => Icons.male_rounded,
        OnboardingSex.female => Icons.female_rounded,
        OnboardingSex.other => Icons.transgender_rounded,
      };

  static OnboardingSex fromString(String? value) => switch (value) {
        'male' => OnboardingSex.male,
        'female' => OnboardingSex.female,
        _ => OnboardingSex.other,
      };
}

enum OnboardingGoal {
  loseWeight('lose_weight'),
  gainMuscle('gain_muscle'),
  cleanBulk('clean_bulk'),
  maintain('maintain'),
  endurance('endurance');

  const OnboardingGoal(this.wireValue);
  final String wireValue;

  String get label => switch (this) {
        OnboardingGoal.loseWeight => 'Perdre du poids',
        OnboardingGoal.gainMuscle => 'Prendre du muscle',
        OnboardingGoal.cleanBulk => 'Prise de masse propre',
        OnboardingGoal.maintain => 'Rester en forme',
        OnboardingGoal.endurance => 'Endurance',
      };

  String get description => switch (this) {
        OnboardingGoal.loseWeight => 'Brûler les graisses, affiner la silhouette et garder le tonus.',
        OnboardingGoal.gainMuscle => 'Développer la masse musculaire et maximiser l\'hypertrophie.',
        OnboardingGoal.cleanBulk => 'Gagner du muscle sec en limitant la prise de gras.',
        OnboardingGoal.maintain => 'Conserver sa condition physique, sa santé et son énergie.',
        OnboardingGoal.endurance => 'Améliorer le souffle, le cardio et la résistance à l\'effort.',
      };

  IconData get icon => switch (this) {
        OnboardingGoal.loseWeight => Icons.local_fire_department_rounded,
        OnboardingGoal.gainMuscle => Icons.fitness_center_rounded,
        OnboardingGoal.cleanBulk => Icons.trending_up_rounded,
        OnboardingGoal.maintain => Icons.favorite_rounded,
        OnboardingGoal.endurance => Icons.directions_run_rounded,
      };

  Color get accent => switch (this) {
        OnboardingGoal.loseWeight => AppColors.coral,
        OnboardingGoal.gainMuscle => AppColors.volt,
        OnboardingGoal.cleanBulk => AppColors.amber,
        OnboardingGoal.maintain => AppColors.mint,
        OnboardingGoal.endurance => AppColors.cyan,
      };

  static OnboardingGoal fromString(String? value) => switch (value) {
        'lose_weight' => OnboardingGoal.loseWeight,
        'gain_muscle' => OnboardingGoal.gainMuscle,
        'clean_bulk' => OnboardingGoal.cleanBulk,
        'endurance' => OnboardingGoal.endurance,
        _ => OnboardingGoal.maintain,
      };
}

enum OnboardingExperience {
  beginner('beginner'),
  intermediate('intermediate'),
  expert('expert');

  const OnboardingExperience(this.wireValue);
  final String wireValue;

  String get label => switch (this) {
        OnboardingExperience.beginner => 'Débutant',
        OnboardingExperience.intermediate => 'Intermédiaire',
        OnboardingExperience.expert => 'Expert',
      };

  String get explanation => switch (this) {
        OnboardingExperience.beginner => 'Je découvre ou reprends l\'entraînement',
        OnboardingExperience.intermediate => 'Pratique régulière depuis plusieurs mois',
        OnboardingExperience.expert => 'Pratique intensive et maîtrise technique avancée',
      };

  static OnboardingExperience fromString(String? value) => switch (value) {
        'beginner' => OnboardingExperience.beginner,
        'expert' => OnboardingExperience.expert,
        _ => OnboardingExperience.intermediate,
      };
}

enum OnboardingEquipment {
  gym('gym'),
  home('home'),
  none('none');

  const OnboardingEquipment(this.wireValue);
  final String wireValue;

  String get label => switch (this) {
        OnboardingEquipment.gym => 'Salle',
        OnboardingEquipment.home => 'Maison',
        OnboardingEquipment.none => 'Aucun',
      };

  IconData get icon => switch (this) {
        OnboardingEquipment.gym => Icons.fitness_center_rounded,
        OnboardingEquipment.home => Icons.home_rounded,
        OnboardingEquipment.none => Icons.accessibility_new_rounded,
      };

  static OnboardingEquipment fromString(String? value) => switch (value) {
        'gym' => OnboardingEquipment.gym,
        'home' => OnboardingEquipment.home,
        _ => OnboardingEquipment.none,
      };
}

class OnboardingPayload {
  const OnboardingPayload({
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.mainGoal,
    required this.experienceLevel,
    required this.daysPerWeek,
    required this.equipment,
  });

  final OnboardingSex sex;
  final int age;
  final int heightCm;
  final double weightKg;
  final OnboardingGoal mainGoal;
  final OnboardingExperience experienceLevel;
  final int daysPerWeek;
  final OnboardingEquipment equipment;

  Map<String, dynamic> toJson() => {
        'sex': sex.name,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'mainGoal': mainGoal.wireValue,
        'experienceLevel': experienceLevel.wireValue,
        'daysPerWeek': daysPerWeek,
        'equipment': equipment.wireValue,
      };
}

class RecommendedProgramItem {
  const RecommendedProgramItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.weeks,
    required this.daysPerWeek,
    required this.level,
    required this.score,
    required this.reasons,
    this.equipment,
    this.goalTags = const [],
  });

  final String id;
  final String title;
  final String subtitle;
  final int weeks;
  final int daysPerWeek;
  final String level;
  final int score;
  final List<String> reasons;
  final String? equipment;
  final List<String> goalTags;

  factory RecommendedProgramItem.fromJson(Map<String, dynamic> json) =>
      RecommendedProgramItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        subtitle: json['subtitle']?.toString() ?? '',
        weeks: (json['weeks'] as num? ?? 0).toInt(),
        daysPerWeek: (json['daysPerWeek'] as num? ?? 0).toInt(),
        level: json['level']?.toString() ?? 'beginner',
        score: (json['score'] as num? ?? 0).toInt(),
        reasons: (json['reasons'] as List? ?? const [])
            .map((item) => item.toString())
            .toList(),
        equipment: json['equipment']?.toString(),
        goalTags: (json['goalTags'] as List? ?? const [])
            .map((item) => item.toString())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'weeks': weeks,
        'daysPerWeek': daysPerWeek,
        'level': level,
        'score': score,
        'reasons': reasons,
        'equipment': equipment,
        'goalTags': goalTags,
      };
}
