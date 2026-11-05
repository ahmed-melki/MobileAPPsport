import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum SportLevel { beginner, intermediate, advanced }

extension SportLevelX on SportLevel {
  String get label => switch (this) {
        SportLevel.beginner => 'Débutant',
        SportLevel.intermediate => 'Intermédiaire',
        SportLevel.advanced => 'Avancé',
      };

  String get hint => switch (this) {
        SportLevel.beginner => 'Bases, technique, régularité',
        SportLevel.intermediate => 'Volume maîtrisé, objectifs clairs',
        SportLevel.advanced => 'Charge élevée, fine-tuning',
      };
}

enum GoalKind { massGain, weightLoss, endurance, fitness }

extension GoalKindX on GoalKind {
  String get label => switch (this) {
        GoalKind.massGain => 'Prise de masse',
        GoalKind.weightLoss => 'Perte de poids',
        GoalKind.endurance => 'Endurance',
        GoalKind.fitness => 'Remise en forme',
      };

  IconData get icon => switch (this) {
        GoalKind.massGain => Icons.fitness_center_rounded,
        GoalKind.weightLoss => Icons.monitor_weight_outlined,
        GoalKind.endurance => Icons.directions_run_rounded,
        GoalKind.fitness => Icons.self_improvement_rounded,
      };

  Color get accent => switch (this) {
        GoalKind.massGain => AppColors.amber,
        GoalKind.weightLoss => AppColors.coral,
        GoalKind.endurance => AppColors.cyan,
        GoalKind.fitness => AppColors.mint,
      };
}

class SportProfile {
  const SportProfile({
    required this.firstName,
    required this.lastName,
    required this.city,
    required this.age,
    required this.heightCm,
    required this.bio,
    required this.email,
    required this.level,
    required this.sports,
    required this.memberSince,
  });

  final String firstName;
  final String lastName;
  final String city;
  final int age;
  final int heightCm;
  final String bio;
  final String email;
  final SportLevel level;
  final Set<String> sports;
  final String memberSince;

  String get initials => '${firstName[0]}${lastName[0]}';
  String get fullName => '$firstName $lastName';

  SportProfile copyWith({
    String? firstName,
    String? lastName,
    String? city,
    int? age,
    int? heightCm,
    String? bio,
    String? email,
    SportLevel? level,
    Set<String>? sports,
    String? memberSince,
  }) {
    return SportProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      city: city ?? this.city,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      level: level ?? this.level,
      sports: sports ?? this.sports,
      memberSince: memberSince ?? this.memberSince,
    );
  }
}

class SportGoal {
  const SportGoal({
    required this.kind,
    required this.detail,
    required this.target,
    required this.deadline,
    required this.progress,
    required this.active,
    required this.primary,
  });

  final GoalKind kind;
  final String detail;
  final String target;
  final String deadline;
  final double progress;
  final bool active;
  final bool primary;

  SportGoal copyWith({
    bool? active,
    bool? primary,
    double? progress,
  }) {
    return SportGoal(
      kind: kind,
      detail: detail,
      target: target,
      deadline: deadline,
      progress: progress ?? this.progress,
      active: active ?? this.active,
      primary: primary ?? this.primary,
    );
  }
}

class BodySnapshot {
  const BodySnapshot({
    required this.date,
    required this.weightKg,
    required this.chestCm,
    required this.waistCm,
    required this.hipsCm,
    required this.armCm,
    required this.thighCm,
  });

  final DateTime date;
  final double weightKg;
  final double chestCm;
  final double waistCm;
  final double hipsCm;
  final double armCm;
  final double thighCm;
}

class ActivityWeek {
  const ActivityWeek({
    required this.start,
    required this.sessions,
    required this.minutes,
    required this.kcal,
  });

  final DateTime start;
  final int sessions;
  final int minutes;
  final int kcal;
}

class ProfileBundle {
  const ProfileBundle({
    required this.profile,
    required this.goals,
    required this.measurements,
    required this.activity,
  });

  final SportProfile profile;
  final List<SportGoal> goals;
  final List<BodySnapshot> measurements;
  final List<ActivityWeek> activity;

  ProfileBundle copyWith({
    SportProfile? profile,
    List<SportGoal>? goals,
    List<BodySnapshot>? measurements,
    List<ActivityWeek>? activity,
  }) {
    return ProfileBundle(
      profile: profile ?? this.profile,
      goals: goals ?? this.goals,
      measurements: measurements ?? this.measurements,
      activity: activity ?? this.activity,
    );
  }
}
