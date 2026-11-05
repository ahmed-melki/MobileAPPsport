import 'nutrition_models.dart';
import 'training_models.dart';

int _i(Object? v) => (v as num? ?? 0).toInt();
double _d(Object? v) => (v as num? ?? 0).toDouble();

/// One exercise of the session the coach planned for today (loads already adjusted).
class CoachExercise {
  const CoachExercise({
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.reps,
    required this.loadKg,
    required this.restSec,
    required this.kind,
    this.unitNote,
    this.suggestion,
  });

  final String exerciseId;
  final String name;
  final int sets;
  final int reps;
  final double loadKg;
  final int restSec;
  final RxKind kind;
  final String? unitNote;
  final String? suggestion;

  String get prescription => switch (kind) {
        RxKind.load => '$sets × $reps @ ${fmtNum(loadKg)} kg',
        RxKind.distance => '$sets × $reps ${unitNote ?? 'm'}',
        RxKind.bodyweight => '$sets × $reps${unitNote == 's' ? ' s' : ''}',
      };

  factory CoachExercise.fromJson(Map<String, dynamic> json) => CoachExercise(
        exerciseId: json['exerciseId'].toString(),
        name: json['name']?.toString() ?? '',
        sets: _i(json['sets']),
        reps: _i(json['reps']),
        loadKg: _d(json['loadKg']),
        restSec: _i(json['restSec']),
        kind: rxKindFromJson(json['kind']?.toString()),
        unitNote: json['unitNote']?.toString(),
        suggestion: json['suggestion']?.toString(),
      );

  SessionExercise toSessionExercise() => SessionExercise(
        exerciseId: exerciseId,
        sets: sets,
        reps: reps,
        loadKg: loadKg,
        restSec: restSec,
        kind: kind,
        unitNote: unitNote,
      );
}

class CoachWorkout {
  const CoachWorkout({
    required this.sessionId,
    required this.programId,
    required this.programTitle,
    required this.title,
    required this.focus,
    required this.durationMin,
    required this.light,
    required this.exercises,
  });

  final String sessionId;
  final String programId;
  final String programTitle;
  final String title;
  final String focus;
  final int durationMin;
  final bool light;
  final List<CoachExercise> exercises;

  factory CoachWorkout.fromJson(Map<String, dynamic> json) => CoachWorkout(
        sessionId: json['sessionId'].toString(),
        programId: json['programId']?.toString() ?? '',
        programTitle: json['programTitle']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        focus: json['focus']?.toString() ?? '',
        durationMin: _i(json['durationMin']),
        light: json['light'] == true,
        exercises: (json['exercises'] as List? ?? const []).map((e) => CoachExercise.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );

  /// Session for the player, with the coach's adjusted loads.
  WorkoutSession toWorkoutSession() => WorkoutSession(
        id: sessionId,
        title: title,
        durationMin: durationMin,
        focus: focus,
        exercises: exercises.map((e) => e.toSessionExercise()).toList(),
      );
}

class CoachTask {
  const CoachTask({required this.id, required this.title, required this.detail, required this.icon, required this.done, required this.action});

  final String id;
  final String title;
  final String detail;
  final String icon;
  final bool done;
  final String action;

  factory CoachTask.fromJson(Map<String, dynamic> json) => CoachTask(
        id: json['id'].toString(),
        title: json['title']?.toString() ?? '',
        detail: json['detail']?.toString() ?? '',
        icon: json['icon']?.toString() ?? '',
        done: json['done'] == true,
        action: json['action']?.toString() ?? '',
      );
}

class CoachRecoveryItem {
  const CoachRecoveryItem({required this.exerciseId, required this.name, required this.detail});
  final String exerciseId;
  final String name;
  final String detail;
}

class DailyPlan {
  const DailyPlan({
    required this.date,
    required this.firstName,
    required this.goalLabel,
    required this.headline,
    required this.message,
    required this.tips,
    required this.source,
    required this.aiEnabled,
    required this.dayType,
    required this.readiness,
    required this.streakDays,
    required this.weeklySessions,
    required this.weeklyTarget,
    required this.workout,
    required this.recoveryTitle,
    required this.recoveryItems,
    required this.recommendedProgramId,
    required this.recommendedProgramTitle,
    required this.targetCalories,
    required this.consumedCalories,
    required this.remainingCalories,
    required this.targetProtein,
    required this.consumedProtein,
    required this.remainingProtein,
    required this.nextMeal,
    required this.suggestions,
    required this.waterLiters,
    required this.tasks,
  });

  final String date;
  final String firstName;
  final String goalLabel;
  final String headline;
  final String message;
  final List<String> tips;
  final String source; // ai | rules
  final bool aiEnabled;
  final String dayType; // training | rest | done | no_program
  final int readiness;
  final int streakDays;
  final int weeklySessions;
  final int weeklyTarget;
  final CoachWorkout? workout;
  final String? recoveryTitle;
  final List<CoachRecoveryItem> recoveryItems;
  final String? recommendedProgramId;
  final String? recommendedProgramTitle;
  final int targetCalories;
  final int consumedCalories;
  final int remainingCalories;
  final double targetProtein;
  final double consumedProtein;
  final double remainingProtein;
  final MealType? nextMeal;
  final List<NutritionRecipe> suggestions;
  final double waterLiters;
  final List<CoachTask> tasks;

  bool get isTrainingDay => dayType == 'training';

  factory DailyPlan.fromJson(Map<String, dynamic> json) {
    final n = Map<String, dynamic>.from(json['nutrition'] as Map? ?? const {});
    final recovery = json['recovery'] is Map ? Map<String, dynamic>.from(json['recovery'] as Map) : null;
    final program = json['recommendedProgram'] is Map ? Map<String, dynamic>.from(json['recommendedProgram'] as Map) : null;
    final hydration = Map<String, dynamic>.from(json['hydration'] as Map? ?? const {});

    return DailyPlan(
      date: json['date']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      goalLabel: json['goalLabel']?.toString() ?? '',
      headline: json['headline']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      tips: (json['tips'] as List? ?? const []).map((e) => e.toString()).toList(),
      source: json['source']?.toString() ?? 'rules',
      aiEnabled: json['aiEnabled'] == true,
      dayType: json['dayType']?.toString() ?? 'training',
      readiness: _i(json['readiness']),
      streakDays: _i(json['streakDays']),
      weeklySessions: _i(json['weeklySessions']),
      weeklyTarget: _i(json['weeklyTarget']),
      workout: json['workout'] is Map ? CoachWorkout.fromJson(Map<String, dynamic>.from(json['workout'] as Map)) : null,
      recoveryTitle: recovery?['title']?.toString(),
      recoveryItems: (recovery?['items'] as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .map((e) => CoachRecoveryItem(exerciseId: e['exerciseId'].toString(), name: e['name']?.toString() ?? '', detail: e['detail']?.toString() ?? ''))
          .toList(),
      recommendedProgramId: program?['id']?.toString(),
      recommendedProgramTitle: program?['title']?.toString(),
      targetCalories: _i(n['targetCalories']),
      consumedCalories: _i(n['consumedCalories']),
      remainingCalories: _i(n['remainingCalories']),
      targetProtein: _d(n['targetProtein']),
      consumedProtein: _d(n['consumedProtein']),
      remainingProtein: _d(n['remainingProtein']),
      nextMeal: n['nextMeal'] == null ? null : mealTypeFromJson(n['nextMeal'].toString()),
      suggestions: (n['suggestions'] as List? ?? const []).map((e) => NutritionRecipe.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      waterLiters: _d(hydration['targetLiters']),
      tasks: (json['tasks'] as List? ?? const []).map((e) => CoachTask.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }
}

class ChatMessage {
  const ChatMessage({required this.role, required this.content, this.source});

  final String role; // user | assistant
  final String content;
  final String? source;

  bool get isUser => role == 'user';

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}
