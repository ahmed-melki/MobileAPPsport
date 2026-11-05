import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum ExerciseCategory { strength, olympic, hyrox, cardio, mobility, core }

ExerciseCategory exerciseCategoryFromJson(String? value) => ExerciseCategory.values.firstWhere((category) => category.name == value, orElse: () => ExerciseCategory.strength);

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

RxKind rxKindFromJson(String? value) => RxKind.values.firstWhere((kind) => kind.name == value, orElse: () => RxKind.load);

/// Muscle groups returned by the API (`muscleGroup`).
const muscleGroupLabels = <String, String>{
  'chest': 'Pectoraux',
  'back': 'Dos',
  'shoulders': 'Épaules',
  'arms': 'Bras',
  'legs': 'Jambes',
  'glutes': 'Fessiers',
  'core': 'Abdos',
  'full_body': 'Full body',
  'cardio': 'Cardio',
  'mobility': 'Mobilité',
};

String levelLabel(String level) => switch (level) {
      'beginner' => 'Débutant',
      'intermediate' => 'Intermédiaire',
      'expert' || 'advanced' => 'Avancé',
      _ => level,
    };

/// 0 = débutant, 1 = intermédiaire, 2 = avancé (exercise "expert" = avancé).
int levelRank(String level) => switch (level) {
      'beginner' => 0,
      'intermediate' => 1,
      'expert' || 'advanced' => 2,
      _ => 1,
    };

class CatalogExercise {
  const CatalogExercise({
    required this.id,
    required this.name,
    required this.category,
    required this.equipment,
    required this.muscles,
    required this.cue,
    required this.lastPerf,
    this.muscleGroup = 'full_body',
    this.level = 'beginner',
    this.kind = RxKind.load,
    this.atHome = false,
    this.instructions = const [],
    this.videoUrl,
  });

  final String id;
  final String name;
  final ExerciseCategory category;
  final String equipment;
  final String muscles;
  final String cue;

  /// Real last performance of the user ('' = never done).
  final String lastPerf;
  final String muscleGroup;
  final String level;
  final RxKind kind;
  final bool atHome;
  final List<String> instructions;
  final String? videoUrl;

  String get muscleGroupLabel => muscleGroupLabels[muscleGroup] ?? muscleGroup;
  bool get neverDone => lastPerf.isEmpty;

  factory CatalogExercise.fromJson(Map<String, dynamic> json) => CatalogExercise(
        id: json['id'].toString(),
        name: json['name']?.toString() ?? '',
        category: exerciseCategoryFromJson(json['category']?.toString()),
        equipment: json['equipment']?.toString() ?? '',
        muscles: json['muscles']?.toString() ?? '',
        cue: json['cue']?.toString() ?? '',
        lastPerf: json['lastPerf']?.toString() ?? '',
        muscleGroup: json['muscleGroup']?.toString() ?? 'full_body',
        level: json['level']?.toString() ?? 'beginner',
        kind: rxKindFromJson(json['kind']?.toString()),
        atHome: json['atHome'] == true,
        instructions: (json['instructions'] as List? ?? const []).map((e) => e.toString()).toList(),
        videoUrl: json['videoUrl']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'equipment': equipment,
        'muscles': muscles,
        'cue': cue,
        'lastPerf': lastPerf,
        'muscleGroup': muscleGroup,
        'level': level,
        'kind': kind.name,
        'atHome': atHome,
        'instructions': instructions,
        'videoUrl': videoUrl,
      };
}

/// One session of the user's history on an exercise (GET /exercises/{id}).
class ExerciseHistoryPoint {
  const ExerciseHistoryPoint({required this.date, required this.summary, required this.bestLoadKg, required this.totalReps, required this.volumeKg});

  final DateTime? date;
  final String summary;
  final double bestLoadKg;
  final int totalReps;
  final double volumeKg;

  factory ExerciseHistoryPoint.fromJson(Map<String, dynamic> json) => ExerciseHistoryPoint(
        date: DateTime.tryParse(json['date']?.toString() ?? ''),
        summary: json['summary']?.toString() ?? '',
        bestLoadKg: (json['bestLoadKg'] as num? ?? 0).toDouble(),
        totalReps: (json['totalReps'] as num? ?? 0).toInt(),
        volumeKg: (json['volumeKg'] as num? ?? 0).toDouble(),
      );
}

class ExerciseDetail {
  const ExerciseDetail({required this.exercise, required this.history, this.personalBestKg, this.personalBestReps, this.timesPerformed = 0});

  final CatalogExercise exercise;
  final List<ExerciseHistoryPoint> history;
  final double? personalBestKg;
  final int? personalBestReps;
  final int timesPerformed;

  factory ExerciseDetail.fromJson(Map<String, dynamic> json) {
    final history = Map<String, dynamic>.from(json['history'] as Map? ?? const {});
    final pb = history['personalBest'] is Map ? Map<String, dynamic>.from(history['personalBest'] as Map) : null;
    return ExerciseDetail(
      exercise: CatalogExercise.fromJson(Map<String, dynamic>.from(json['exercise'] as Map)),
      history: (history['sessions'] as List? ?? const []).map((e) => ExerciseHistoryPoint.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      personalBestKg: (pb?['loadKg'] as num?)?.toDouble(),
      personalBestReps: (pb?['reps'] as num?)?.toInt(),
      timesPerformed: (history['timesPerformed'] as num? ?? 0).toInt(),
    );
  }
}

/// Quick 4-set session built from one exercise (used by "Séance express").
WorkoutSession expressSessionForExercise(CatalogExercise exercise) {
  final distance = exercise.kind == RxKind.distance;
  final bodyweight = exercise.kind == RxKind.bodyweight;
  return WorkoutSession(
    id: 'express-${exercise.id}',
    title: 'Express · ${exercise.name}',
    durationMin: 20,
    focus: exercise.muscleGroupLabel,
    exercises: [
      SessionExercise(
        exerciseId: exercise.id,
        sets: 4,
        reps: distance ? 400 : (bodyweight ? 12 : 8),
        loadKg: distance || bodyweight ? 0 : 20,
        restSec: 90,
        kind: exercise.kind,
        unitNote: distance ? 'm' : null,
      ),
    ],
  );
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
    this.adaptedFrom,
  });

  final String exerciseId;
  final int sets;
  final int reps;
  final double loadKg;
  final int restSec;
  final RxKind kind;
  final String? unitNote;

  /// Original exercise when the API replaced it with an easier variant for the user's level.
  final String? adaptedFrom;

  factory SessionExercise.fromJson(Map<String, dynamic> json) => SessionExercise(exerciseId: json['exerciseId'].toString(), sets: (json['sets'] as num? ?? 0).toInt(), reps: (json['reps'] as num? ?? 0).toInt(), loadKg: (json['loadKg'] as num? ?? 0).toDouble(), restSec: (json['restSec'] as num? ?? 0).toInt(), kind: rxKindFromJson(json['kind']?.toString()), unitNote: json['unitNote']?.toString(), adaptedFrom: json['adaptedFrom']?.toString());

  Map<String, dynamic> toJson() => {'exerciseId': exerciseId, 'sets': sets, 'reps': reps, 'loadKg': loadKg, 'restSec': restSec, 'kind': kind.name, 'unitNote': unitNote};
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

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(id: json['id'].toString(), title: json['title']?.toString() ?? '', durationMin: (json['durationMin'] as num? ?? 0).toInt(), focus: json['focus']?.toString() ?? '', exercises: (json['exercises'] as List? ?? const []).map((item) => SessionExercise.fromJson(Map<String, dynamic>.from(item as Map))).toList());

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'durationMin': durationMin, 'focus': focus, 'exercises': exercises.map((item) => item.toJson()).toList()};
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

  factory TrainingProgram.fromJson(Map<String, dynamic> json) => TrainingProgram(id: json['id'].toString(), title: json['title']?.toString() ?? '', subtitle: json['subtitle']?.toString() ?? '', weeks: (json['weeks'] as num? ?? 0).toInt(), daysPerWeek: (json['daysPerWeek'] as num? ?? 0).toInt(), level: json['level']?.toString() ?? 'beginner', sessionIds: (json['sessionIds'] as List? ?? const []).map((item) => item.toString()).toList());

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'subtitle': subtitle, 'weeks': weeks, 'daysPerWeek': daysPerWeek, 'level': level, 'sessionIds': sessionIds};
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

  factory SessionLog.fromJson(Map<String, dynamic> json) => SessionLog(date: DateTime.tryParse(json['completedAt']?.toString() ?? json['date']?.toString() ?? '') ?? DateTime.now(), sessionTitle: json['sessionTitle']?.toString() ?? '', programTitle: json['programTitle']?.toString() ?? '', durationMin: (json['durationMin'] as num? ?? 0).toInt(), volumeKg: (json['volumeKg'] as num? ?? 0).toInt(), highlight: json['highlight']?.toString() ?? '');

  Map<String, dynamic> toJson() => {'completedAt': date.toUtc().toIso8601String().replaceFirst('+00:00', 'Z'), 'sessionTitle': sessionTitle, 'programTitle': programTitle, 'durationMin': durationMin, 'volumeKg': volumeKg, 'highlight': highlight};
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

  factory LiftProgress.fromJson(Map<String, dynamic> json) => LiftProgress(name: json['name']?.toString() ?? '', unit: json['unit']?.toString() ?? 'kg', points: (json['points'] as List? ?? const []).map((point) => (point as num).toDouble()).toList());

  Map<String, dynamic> toJson() => {'name': name, 'unit': unit, 'points': points};
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

  CatalogExercise exerciseById(String id) => exercises.firstWhere(
        (e) => e.id == id,
        orElse: () => CatalogExercise(id: id, name: id, category: ExerciseCategory.strength, equipment: '', muscles: '', cue: '', lastPerf: ''),
      );

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
