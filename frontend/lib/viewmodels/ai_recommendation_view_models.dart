import '../core/api/nutrition_coach_repositories.dart';
import '../data/ai_recommendation_models.dart';
import 'base_view_model.dart';

/// AI training recommendation (objectif + niveau).
class AiTrainingViewModel extends BaseViewModel {
  AiTrainingViewModel(this._repo);
  final CoachRepository _repo;

  AiTrainingAdvice? advice;
  bool loading = true;

  Future<void> load() async {
    loading = advice == null;
    notify();
    await guard(() async => advice = await _repo.trainingAdvice());
    loading = false;
    notify();
  }
}

/// AI nutrition recommendation (objectif + repas du jour).
class AiNutritionViewModel extends BaseViewModel {
  AiNutritionViewModel(this._repo);
  final CoachRepository _repo;

  AiNutritionAdvice? advice;
  bool loading = true;

  double progress(double eaten, double target) => target <= 0 ? 0 : (eaten / target).clamp(0.0, 1.0);

  Future<void> load() async {
    loading = advice == null;
    notify();
    await guard(() async => advice = await _repo.nutritionAdvice());
    loading = false;
    notify();
  }
}
