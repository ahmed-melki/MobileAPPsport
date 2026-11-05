import 'onboarding_models.dart';

List<String> _strings(dynamic v) => (v as List? ?? const []).map((e) => e.toString()).toList();
double _num(dynamic v) => (v as num? ?? 0).toDouble();

/// Training plan computed for the user's goal × level.
class AiTrainingPlan {
  const AiTrainingPlan({
    required this.daysPerWeek,
    required this.exercisesPerSession,
    required this.sets,
    required this.reps,
    required this.rest,
    required this.intensity,
    required this.cardio,
    required this.duration,
  });

  final int daysPerWeek;
  final int exercisesPerSession;
  final String sets;
  final String reps;
  final String rest;
  final String intensity;
  final String cardio;
  final String duration;

  factory AiTrainingPlan.fromJson(Map<String, dynamic> j) => AiTrainingPlan(
        daysPerWeek: (j['daysPerWeek'] as num? ?? 3).toInt(),
        exercisesPerSession: (j['exercisesPerSession'] as num? ?? 4).toInt(),
        sets: j['sets']?.toString() ?? '',
        reps: j['reps']?.toString() ?? '',
        rest: j['rest']?.toString() ?? '',
        intensity: j['intensity']?.toString() ?? '',
        cardio: j['cardio']?.toString() ?? '',
        duration: j['duration']?.toString() ?? '',
      );
}

class AiExerciseSuggestion {
  const AiExerciseSuggestion({required this.id, required this.name, required this.muscleGroup, required this.atHome, required this.equipment, required this.why});

  final String id;
  final String name;
  final String muscleGroup;
  final bool atHome;
  final String equipment;
  final String why;

  factory AiExerciseSuggestion.fromJson(Map<String, dynamic> j) => AiExerciseSuggestion(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        muscleGroup: j['muscleGroup']?.toString() ?? '',
        atHome: j['atHome'] == true,
        equipment: j['equipment']?.toString() ?? '',
        why: j['why']?.toString() ?? '',
      );
}

/// GET /me/ai/training
class AiTrainingAdvice {
  const AiTrainingAdvice({
    required this.source,
    required this.goalLabel,
    required this.level,
    required this.levelLabel,
    required this.summary,
    required this.tips,
    required this.plan,
    required this.programs,
    required this.exercises,
    required this.sessionsLast7Days,
  });

  final String source;
  final String goalLabel;
  final String level;
  final String levelLabel;
  final String summary;
  final List<String> tips;
  final AiTrainingPlan plan;
  final List<RecommendedProgramItem> programs;
  final List<AiExerciseSuggestion> exercises;
  final int sessionsLast7Days;

  bool get fromAi => source == 'ai';

  factory AiTrainingAdvice.fromJson(Map<String, dynamic> j) => AiTrainingAdvice(
        source: j['source']?.toString() ?? 'rules',
        goalLabel: j['goalLabel']?.toString() ?? '',
        level: j['level']?.toString() ?? 'beginner',
        levelLabel: j['levelLabel']?.toString() ?? '',
        summary: j['summary']?.toString() ?? '',
        tips: _strings(j['tips']),
        plan: AiTrainingPlan.fromJson(Map<String, dynamic>.from(j['plan'] as Map? ?? const {})),
        programs: (j['programs'] as List? ?? const []).map((e) => RecommendedProgramItem.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        exercises: (j['exercises'] as List? ?? const []).map((e) => AiExerciseSuggestion.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        sessionsLast7Days: (j['sessionsLast7Days'] as num? ?? 0).toInt(),
      );
}

class AiMacros {
  const AiMacros({required this.calories, required this.protein, required this.carbs, required this.fat});
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  factory AiMacros.fromJson(dynamic v) {
    final j = Map<String, dynamic>.from(v as Map? ?? const {});
    return AiMacros(calories: _num(j['calories']), protein: _num(j['protein']), carbs: _num(j['carbs']), fat: _num(j['fat']));
  }
}

class AiRecipeSuggestion {
  const AiRecipeSuggestion({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.duration,
    required this.why,
  });

  final String id;
  final String name;
  final String subtitle;
  final String mealType;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final int duration;
  final String why;

  factory AiRecipeSuggestion.fromJson(Map<String, dynamic> j) => AiRecipeSuggestion(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        subtitle: j['subtitle']?.toString() ?? '',
        mealType: j['mealType']?.toString() ?? 'snack',
        calories: (j['calories'] as num? ?? 0).toInt(),
        protein: _num(j['protein']),
        carbs: _num(j['carbs']),
        fat: _num(j['fat']),
        duration: (j['duration'] as num? ?? 0).toInt(),
        why: j['why']?.toString() ?? '',
      );
}

class AiFoodSuggestion {
  const AiFoodSuggestion({required this.id, required this.name, required this.serving, required this.calories, required this.protein, required this.why});
  final String id;
  final String name;
  final String serving;
  final int calories;
  final double protein;
  final String why;

  factory AiFoodSuggestion.fromJson(Map<String, dynamic> j) => AiFoodSuggestion(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        serving: j['serving']?.toString() ?? '',
        calories: (j['calories'] as num? ?? 0).toInt(),
        protein: _num(j['protein']),
        why: j['why']?.toString() ?? '',
      );
}

/// GET /me/ai/nutrition
class AiNutritionAdvice {
  const AiNutritionAdvice({
    required this.source,
    required this.goalLabel,
    required this.nextMeal,
    required this.summary,
    required this.tips,
    required this.targets,
    required this.today,
    required this.remaining,
    required this.recipes,
    required this.foods,
  });

  final String source;
  final String goalLabel;
  final String nextMeal;
  final String summary;
  final List<String> tips;
  final AiMacros targets;
  final AiMacros today;
  final AiMacros remaining;
  final List<AiRecipeSuggestion> recipes;
  final List<AiFoodSuggestion> foods;

  bool get fromAi => source == 'ai';

  String get nextMealLabel => switch (nextMeal) {
        'breakfast' => 'petit-déjeuner',
        'lunch' => 'déjeuner',
        'snack' => 'collation',
        _ => 'dîner',
      };

  factory AiNutritionAdvice.fromJson(Map<String, dynamic> j) => AiNutritionAdvice(
        source: j['source']?.toString() ?? 'rules',
        goalLabel: j['goalLabel']?.toString() ?? '',
        nextMeal: j['nextMeal']?.toString() ?? 'lunch',
        summary: j['summary']?.toString() ?? '',
        tips: _strings(j['tips']),
        targets: AiMacros.fromJson(j['targets']),
        today: AiMacros.fromJson(j['today']),
        remaining: AiMacros.fromJson(j['remaining']),
        recipes: (j['recipes'] as List? ?? const []).map((e) => AiRecipeSuggestion.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        foods: (j['foods'] as List? ?? const []).map((e) => AiFoodSuggestion.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );
}
