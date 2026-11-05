import '../core/api/nutrition_coach_repositories.dart';
import '../core/api/repositories.dart';
import '../data/profile_models.dart';
import '../data/training_models.dart';
import 'base_view_model.dart';

/// Training module: catalog (exercises, programs, history) + filters.
class TrainingViewModel extends BaseViewModel {
  TrainingViewModel(this._training, this._profile);
  final TrainingRepository _training;
  final ProfileRepository _profile;

  TrainingCatalog? _catalog;
  SportLevel _userLevel = SportLevel.beginner;
  bool _loading = true;
  int _tab = 0;

  // Exercise filters
  String _search = '';
  String? _muscleGroup;
  bool _homeOnly = false;
  bool _myLevelOnly = true;

  TrainingCatalog? get catalog => _catalog;
  bool get loading => _loading;
  int get tab => _tab;
  SportLevel get userLevel => _userLevel;
  String get search => _search;
  String? get muscleGroup => _muscleGroup;
  bool get homeOnly => _homeOnly;
  bool get myLevelOnly => _myLevelOnly;

  int get userRank => levelRank(_userLevel.name); // beginner 0, intermediate 1, advanced 2

  Future<void> load() async {
    _loading = _catalog == null;
    notify();
    await guard(() async {
      final results = await Future.wait([_training.loadCatalog(), _profile.loadMe()]);
      _catalog = results[0] as TrainingCatalog;
      _userLevel = (results[1] as SportProfile).level;
    });
    _loading = false;
    notify();
  }

  void selectTab(int index) {
    _tab = index;
    notify();
  }

  void setSearch(String value) {
    _search = value;
    notify();
  }

  void setMuscleGroup(String? group) {
    _muscleGroup = group;
    notify();
  }

  void setHomeOnly(bool value) {
    _homeOnly = value;
    notify();
  }

  void setMyLevelOnly(bool value) {
    _myLevelOnly = value;
    notify();
  }

  bool isForMyLevel(CatalogExercise e) => levelRank(e.level) <= userRank;

  List<String> get muscleGroups =>
      muscleGroupLabels.keys.where((g) => _catalog?.exercises.any((e) => e.muscleGroup == g) ?? false).toList();

  List<CatalogExercise> get exercises {
    final q = _search.trim().toLowerCase();
    return (_catalog?.exercises ?? const <CatalogExercise>[]).where((e) {
      if (_muscleGroup != null && e.muscleGroup != _muscleGroup) return false;
      // Only the exercises of the user's level (débutant / intermédiaire / avancé).
      if (levelRank(e.level) != userRank) return false;
      // Switch on = home workouts only, switch off = gym workouts only.
      if (e.atHome != _homeOnly) return false;
      if (q.isNotEmpty && !e.name.toLowerCase().contains(q) && !e.muscles.toLowerCase().contains(q) && !e.equipment.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Programs of the user's level first, then the closest levels.
  List<TrainingProgram> get programs {
    final all = [...?_catalog?.programs];
    final mine = all.where((p) => levelRank(p.level) == userRank).toList();
    final list = mine.isEmpty ? all : mine;
    list.sort((a, b) {
      final da = (levelRank(a.level) - userRank).abs();
      final db = (levelRank(b.level) - userRank).abs();
      return da != db ? da.compareTo(db) : a.title.compareTo(b.title);
    });
    return list;
  }

  bool isMyLevel(TrainingProgram p) => levelRank(p.level) == userRank;

  Future<SessionLog> saveSession(WorkoutSession session, String programId, List<Map<String, dynamic>> sets) {
    return _training.createSessionLog(
      sessionId: session.id,
      programId: programId,
      completedAt: DateTime.now().toUtc(),
      durationMin: session.durationMin,
      highlight: '${session.title} terminée',
      sets: sets,
    );
  }

  void addLog(SessionLog log) {
    final c = _catalog;
    if (c == null) return;
    _catalog = c.copyWith(logs: [log, ...c.logs]);
    _tab = 2;
    notify();
  }
}

/// Exercise detail: instructions, video, real history.
class ExerciseDetailViewModel extends BaseViewModel {
  ExerciseDetailViewModel(this._repo, this.initial);
  final ExerciseRepository _repo;
  final CatalogExercise initial;

  ExerciseDetail? _detail;
  bool _loading = true;

  ExerciseDetail? get detail => _detail;
  bool get loading => _loading;
  CatalogExercise get exercise => _detail?.exercise ?? initial;

  String get videoUrl =>
      exercise.videoUrl ?? 'https://www.youtube.com/results?search_query=${Uri.encodeComponent('${exercise.name} exercice technique')}';

  Future<void> load() async {
    await guard(() async => _detail = await _repo.detail(initial.id));
    _loading = false;
    notify();
  }
}
