import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum CoachSpecialty { strength, running, hyrox, nutrition, mobility }

extension CoachSpecialtyX on CoachSpecialty {
  String get label => switch (this) {
    CoachSpecialty.strength => 'Force',
    CoachSpecialty.running => 'Running',
    CoachSpecialty.hyrox => 'Hyrox',
    CoachSpecialty.nutrition => 'Nutrition',
    CoachSpecialty.mobility => 'Mobilité',
  };

  Color get accent => switch (this) {
    CoachSpecialty.strength => AppColors.coral,
    CoachSpecialty.running => AppColors.cyan,
    CoachSpecialty.hyrox => AppColors.volt,
    CoachSpecialty.nutrition => AppColors.mint,
    CoachSpecialty.mobility => AppColors.violet,
  };
}

class CoachProfile {
  const CoachProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.specialties,
    required this.bio,
    required this.rating,
    required this.reviewCount,
    required this.sessions,
    required this.price,
    required this.initials,
    required this.accent,
    required this.isOnline,
  });

  final String id;
  final String name;
  final String role;
  final List<CoachSpecialty> specialties;
  final String bio;
  final double rating;
  final int reviewCount;
  final int sessions;
  final int price;
  final String initials;
  final Color accent;
  final bool isOnline;
}

class CoachBooking {
  const CoachBooking({
    required this.coachName,
    required this.date,
    required this.time,
    required this.type,
    required this.status,
  });

  final String coachName;
  final String date;
  final String time;
  final String type;
  final String status;
}

class AthleteFollowed {
  const AthleteFollowed({
    required this.name,
    required this.initials,
    required this.goal,
    required this.progress,
    required this.lastSession,
    required this.accent,
  });

  final String name;
  final String initials;
  final String goal;
  final double progress;
  final String lastSession;
  final Color accent;
}
