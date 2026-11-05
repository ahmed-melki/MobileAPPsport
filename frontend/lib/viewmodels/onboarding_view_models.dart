import '../core/api/repositories.dart';
import '../data/onboarding_models.dart';
import 'base_view_model.dart';

/// 6-step onboarding wizard.
class OnboardingViewModel extends BaseViewModel {
  OnboardingViewModel(this._repo, {OnboardingPayload? initial}) {
    if (initial != null) {
      sex = initial.sex;
      mainGoal = initial.mainGoal;
      experience = initial.experienceLevel;
      daysPerWeek = initial.daysPerWeek;
      equipment = initial.equipment;
    }
  }

  final ProfileRepository _repo;
  static const int totalSteps = 6;

  int step = 0;
  OnboardingSex? sex = OnboardingSex.male;
  OnboardingGoal? mainGoal = OnboardingGoal.gainMuscle;
  OnboardingExperience? experience = OnboardingExperience.beginner;
  int daysPerWeek = 3;
  OnboardingEquipment? equipment = OnboardingEquipment.gym;

  bool get isLastStep => step == totalSteps - 1;
  double get progress => (step + 1) / totalSteps;

  void setSex(OnboardingSex value) => _set(() => sex = value);
  void setGoal(OnboardingGoal value) => _set(() => mainGoal = value);
  void setExperience(OnboardingExperience value) => _set(() => experience = value);
  void setDays(int value) => _set(() => daysPerWeek = value);
  void setEquipment(OnboardingEquipment value) => _set(() => equipment = value);

  void _set(void Function() change) {
    change();
    clearError();
  }

  String? _validate({required String age, required String height, required String weight}) {
    switch (step) {
      case 0:
        return sex == null ? 'Sélectionne ton sexe.' : null;
      case 1:
        final a = int.tryParse(age.trim());
        if (a == null) return 'Veuillez saisir un âge valide.';
        if (a < 14 || a > 90) return 'L\'âge doit être compris entre 14 et 90 ans.';
        return null;
      case 2:
        final h = int.tryParse(height.trim());
        final w = double.tryParse(weight.trim().replaceAll(',', '.'));
        if (h == null) return 'Veuillez saisir une taille valide (cm).';
        if (h < 120 || h > 230) return 'La taille doit être entre 120 et 230 cm.';
        if (w == null) return 'Veuillez saisir un poids valide (kg).';
        if (w < 30 || w > 300) return 'Le poids doit être entre 30 et 300 kg.';
        return null;
      case 3:
        return mainGoal == null ? 'Choisis ton objectif principal.' : null;
      case 4:
        return experience == null ? 'Sélectionne ton niveau d\'expérience.' : null;
      case 5:
        if (daysPerWeek < 2 || daysPerWeek > 6) return 'Choisis entre 2 et 6 séances par semaine.';
        return equipment == null ? 'Sélectionne ton équipement d\'entraînement.' : null;
      default:
        return null;
    }
  }

  /// Goes to the next step. On the last step, submits and returns the recommendations.
  Future<List<RecommendedProgramItem>?> next({required String age, required String height, required String weight}) async {
    final invalid = _validate(age: age, height: height, weight: weight);
    if (invalid != null) {
      setError(invalid);
      return null;
    }
    clearError();
    if (!isLastStep) {
      step++;
      notify();
      return null;
    }

    final payload = OnboardingPayload(
      sex: sex!,
      age: int.parse(age.trim()),
      heightCm: int.parse(height.trim()),
      weightKg: double.parse(weight.trim().replaceAll(',', '.')),
      mainGoal: mainGoal!,
      experienceLevel: experience!,
      daysPerWeek: daysPerWeek,
      equipment: equipment!,
    );
    List<RecommendedProgramItem>? result;
    await guard(
      () async => result = await _repo.submitOnboarding(payload),
      errorMessage: (e) {
        final combined = e.fieldErrors.values.expand((m) => m).join('\n');
        return combined.isNotEmpty ? combined : e.message;
      },
    );
    return result;
  }

  /// Returns false when already on the first step (the View then closes the screen).
  bool back() {
    if (step == 0) return false;
    step--;
    clearError();
    return true;
  }
}

/// Recommended programs after the onboarding.
class RecommendedProgramsViewModel extends BaseViewModel {
  RecommendedProgramsViewModel(this._repo, this.recommendations);
  final ProfileRepository _repo;
  final List<RecommendedProgramItem> recommendations;

  String? _startingSlug;
  String? get startingSlug => _startingSlug;

  List<RecommendedProgramItem> get topThree => recommendations.take(3).toList();

  Future<bool> start(RecommendedProgramItem program) async {
    _startingSlug = program.id;
    final ok = await guard(() => _repo.startProgram(program.id), errorMessage: (e) => e.message);
    _startingSlug = null;
    notify();
    return ok;
  }
}
