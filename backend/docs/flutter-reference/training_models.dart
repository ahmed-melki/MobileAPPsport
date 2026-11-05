import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum ExerciseCategory { strength, olympic, hyrox, cardio, mobility, core }

extension ExerciseCategoryX on ExerciseCategory {
  String get label => switch (this) {
        ExerciseCategory.strength => 'Force',
        ExerciseCategory.olympic => 'Haltéro',
        ExerciseCategory.hyrox => 'Hyrox',
        ExerciseCategory.cardio => 'Cardio',
        ExerciseCategory.mobility => 'Mobilité',
        ExerciseCategory.core => 'Core',
      };

  Color get accent => switch (this) {
        ExerciseCategory.strength => AppColors.volt,
        ExerciseCategory.olympic => AppColors.amber,
        ExerciseCategory.hyrox => AppColors.cyan,
        ExerciseCategory.cardio => AppColors.coral,
        ExerciseCategory.mobility => AppColors.mint,
        ExerciseCategory.core => AppColors.violet,
      };
}

enum RxKind { load, distance, bodyweight }

class CatalogExercise {
  const CatalogExercise({
    required this.id,
    required this.name,
    required this.category,
    required this.equipment,
    required this.muscles,
    required this.cue,
    required this.lastPerf,
  });

  final String id;
  final String name;
  final ExerciseCategory category;
  final String equipment;
  final String muscles;
  final String cue;
  final String lastPerf;
}

class SessionExercise {
  const SessionExercise({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.loadKg,
    required this.restSec,
    required this.kind,
    this.unitNote,
  });

  final String exerciseId;
  final int sets;
  final int reps;
  final double loadKg;
  final int restSec;
  final RxKind kind;
  final String? unitNote;
}

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.title,
    required this.durationMin,
    required this.focus,
    required this.exercises,
  });

  final String id;
  final String title;
  final int durationMin;
  final String focus;
  final List<SessionExercise> exercises;
}

class TrainingProgram {
  const TrainingProgram({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.weeks,
    required this.daysPerWeek,
    required this.level,
    required this.sessionIds,
  });

  final String id;
  final String title;
  final String subtitle;
  final int weeks;
  final int daysPerWeek;
  final String level;
  final List<String> sessionIds;
}

class SessionLog {
  const SessionLog({
    required this.date,
    required this.sessionTitle,
    required this.programTitle,
    required this.durationMin,
    required this.volumeKg,
    required this.highlight,
  });

  final DateTime date;
  final String sessionTitle;
  final String programTitle;
  final int durationMin;
  final int volumeKg;
  final String highlight;
}

class LiftProgress {
  const LiftProgress({
    required this.name,
    required this.unit,
    required this.points,
  });

  final String name;
  final String unit;
  final List<double> points;
}

class TrainingCatalog {
  const TrainingCatalog({
    required this.exercises,
    required this.programs,
    required this.sessions,
    required this.logs,
    required this.lifts,
  });

  final List<CatalogExercise> exercises;
  final List<TrainingProgram> programs;
  final List<WorkoutSession> sessions;
  final List<SessionLog> logs;
  final List<LiftProgress> lifts;

  CatalogExercise exerciseById(String id) =>
      exercises.firstWhere((e) => e.id == id);

  WorkoutSession sessionById(String id) =>
      sessions.firstWhere((e) => e.id == id);

  TrainingCatalog copyWith({List<SessionLog>? logs}) {
    return TrainingCatalog(
      exercises: exercises,
      programs: programs,
      sessions: sessions,
      logs: logs ?? this.logs,
      lifts: lifts,
    );
  }
}
