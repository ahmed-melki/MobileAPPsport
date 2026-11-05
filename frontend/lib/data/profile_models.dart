import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum SportLevel { beginner, intermediate, advanced }

SportLevel sportLevelFromJson(String? value) => SportLevel.values.firstWhere((level) => level.name == value, orElse: () => SportLevel.beginner);

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

String goalKindToJson(GoalKind kind) => switch (kind) {
      GoalKind.massGain => 'mass_gain',
      GoalKind.weightLoss => 'weight_loss',
      GoalKind.endurance => 'endurance',
      GoalKind.fitness => 'fitness',
    };

GoalKind goalKindFromJson(String? value) => switch (value) {
      'mass_gain' => GoalKind.massGain,
      'weight_loss' => GoalKind.weightLoss,
      'endurance' => GoalKind.endurance,
      _ => GoalKind.fitness,
    };

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
    this.onboardingCompleted = true,
    this.sex,
    this.mainGoal,
    this.experienceLevel,
    this.daysPerWeek,
    this.equipment,
    this.role = 'member',
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
  final bool onboardingCompleted;
  final String? sex;
  final String? mainGoal;
  final String? experienceLevel;
  final int? daysPerWeek;
  final String? equipment;
  final String role;

  bool get isAdmin => role == 'admin';

  factory SportProfile.fromJson(Map<String, dynamic> json) => SportProfile(
        firstName: json['firstName']?.toString() ?? '',
        lastName: json['lastName']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        age: (json['age'] as num? ?? 0).toInt(),
        heightCm: (json['heightCm'] as num? ?? 0).toInt(),
        bio: json['bio']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        level: sportLevelFromJson(json['level']?.toString()),
        sports: {...(json['sports'] as List? ?? const []).map((sport) => sport.toString())},
        memberSince: json['memberSince']?.toString() ?? '',
        onboardingCompleted: json['onboardingCompleted'] as bool? ?? true,
        sex: json['sex']?.toString(),
        mainGoal: json['mainGoal']?.toString(),
        experienceLevel: json['experienceLevel']?.toString(),
        daysPerWeek: (json['daysPerWeek'] as num?)?.toInt(),
        equipment: json['equipment']?.toString(),
        role: json['role']?.toString() ?? 'member',
      );

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'city': city,
        'age': age,
        'heightCm': heightCm,
        'bio': bio,
        'level': level.name,
        'sports': sports.toList(),
        if (sex != null) 'sex': sex,
        if (mainGoal != null) 'mainGoal': mainGoal,
        if (daysPerWeek != null) 'daysPerWeek': daysPerWeek,
        if (equipment != null) 'equipment': equipment,
      };

  String get initials {
    final first = firstName.trim();
    final last = lastName.trim();
    final letters = [
      if (first.isNotEmpty) first[0],
      if (last.isNotEmpty) last[0],
    ];
    return letters.isEmpty ? '?' : letters.join().toUpperCase();
  }
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
    bool? onboardingCompleted,
    String? sex,
    String? mainGoal,
    String? experienceLevel,
    int? daysPerWeek,
    String? equipment,
    String? role,
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
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      sex: sex ?? this.sex,
      mainGoal: mainGoal ?? this.mainGoal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      equipment: equipment ?? this.equipment,
      role: role ?? this.role,
    );
  }
}

class SportGoal {
  const SportGoal({
    this.id,
    required this.kind,
    required this.detail,
    required this.target,
    required this.deadline,
    required this.progress,
    required this.active,
    required this.primary,
  });

  final int? id;
  final GoalKind kind;
  final String detail;
  final String target;
  final String deadline;
  final double progress;
  final bool active;
  final bool primary;

  factory SportGoal.fromJson(Map<String, dynamic> json) => SportGoal(
        id: (json['id'] as num?)?.toInt(),
        kind: goalKindFromJson(json['kind']?.toString()),
        detail: json['detail']?.toString() ?? '',
        target: json['target']?.toString() ?? '',
        deadline: json['deadline']?.toString() ?? '',
        progress: (json['progress'] as num? ?? 0).toDouble(),
        active: json['active'] == true,
        primary: json['primary'] == true,
      );

  Map<String, dynamic> toJson() => {'kind': goalKindToJson(kind), 'detail': detail, 'target': target, 'deadline': deadline.isEmpty ? null : deadline, 'progress': progress, 'active': active, 'primary': primary};

  SportGoal copyWith({
    bool? active,
    bool? primary,
    double? progress,
  }) {
    return SportGoal(
      id: id,
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
    this.id,
    required this.date,
    required this.weightKg,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.armCm,
    this.thighCm,
  });

  final int? id;
  final DateTime date;
  final double weightKg;

  /// Mensurations are optional (the onboarding only records the weight).
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final double? armCm;
  final double? thighCm;

  static double? _opt(Object? v) => v == null ? null : (v as num).toDouble();

  factory BodySnapshot.fromJson(Map<String, dynamic> json) => BodySnapshot(
        id: (json['id'] as num?)?.toInt(),
        date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        weightKg: (json['weightKg'] as num? ?? 0).toDouble(),
        chestCm: _opt(json['chestCm']),
        waistCm: _opt(json['waistCm']),
        hipsCm: _opt(json['hipsCm']),
        armCm: _opt(json['armCm']),
        thighCm: _opt(json['thighCm']),
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().split('T').first,
        'weightKg': weightKg,
        if (chestCm != null) 'chestCm': chestCm,
        if (waistCm != null) 'waistCm': waistCm,
        if (hipsCm != null) 'hipsCm': hipsCm,
        if (armCm != null) 'armCm': armCm,
        if (thighCm != null) 'thighCm': thighCm,
      };
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

/// Sports the user can pick in the profile.
const catalogSports = [
  'Hyrox',
  'Force',
  'Course',
  'Mobilité',
  'Boxe',
  'Natation',
  'Vélo',
  'Yoga',
];
