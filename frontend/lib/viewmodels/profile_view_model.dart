import '../core/api/api_client.dart';
import '../core/api/repositories.dart';
import '../data/profile_models.dart';
import 'base_view_model.dart';

/// Profile module: identity, level, sports, goals, measurements.
class ProfileViewModel extends BaseViewModel {
  ProfileViewModel(this._repo);
  final ProfileRepository _repo;

  ProfileBundle? _data;
  bool _loading = true;
  int _tab = 0;

  /// One-shot message for a SnackBar (read with [takeMessage]).
  String? _message;

  ProfileBundle? get data => _data;
  bool get loading => _loading;
  int get tab => _tab;

  String? takeMessage() {
    final m = _message;
    _message = null;
    return m;
  }

  void selectTab(int index) {
    _tab = index;
    notify();
  }

  Future<void> load() async {
    _loading = _data == null;
    notify();
    await guard(() async => _data = await _repo.loadProfile());
    _loading = false;
    notify();
  }

  Future<void> _mutate(Future<void> Function(ProfileBundle current) action) async {
    final current = _data;
    if (current == null) return;
    try {
      await action(current);
    } on ApiException catch (e) {
      _message = e.message;
    }
    notify();
  }

  Future<void> saveProfile(SportProfile updated) => _mutate((current) async {
        final saved = await _repo.updateProfile(updated);
        _data = current.copyWith(profile: saved);
        _message = 'Profil enregistré';
      });

  Future<void> setLevel(SportLevel level) => _mutate((current) async {
        final saved = await _repo.updateProfile(current.profile.copyWith(level: level));
        _data = current.copyWith(profile: saved);
        _message = 'Niveau : ${saved.level.label}';
      });

  Future<void> toggleSport(String sport) => _mutate((current) async {
        final next = {...current.profile.sports};
        if (!next.contains(sport) || next.length <= 1) return;
        next.remove(sport);
        final saved = await _repo.updateProfile(current.profile.copyWith(sports: next));
        _data = current.copyWith(profile: saved);
      });

  SportGoal? _goalOf(ProfileBundle current, GoalKind kind) {
    final matches = current.goals.where((g) => g.kind == kind);
    return matches.isEmpty ? null : matches.first;
  }

  Future<void> setPrimaryGoal(GoalKind kind) => _mutate((current) async {
        final goal = _goalOf(current, kind);
        if (goal?.id == null) return;
        final saved = await _repo.updateGoal(goal!.copyWith(primary: true, active: true));
        _data = current.copyWith(goals: current.goals.map((g) => g.id == saved.id ? saved : g.copyWith(primary: false)).toList());
      });

  Future<void> toggleGoal(GoalKind kind) => _mutate((current) async {
        final goal = _goalOf(current, kind);
        if (goal?.id == null) return;
        final saved = await _repo.updateGoal(goal!.copyWith(active: !goal.active, primary: goal.active ? false : goal.primary));
        _data = current.copyWith(goals: current.goals.map((g) => g.id == saved.id ? saved : g).toList());
      });

  Future<void> addGoal(SportGoal goal) => _mutate((current) async {
        await _repo.createGoal(goal);
        _data = current.copyWith(goals: await _repo.loadGoals());
      });

  Future<void> deleteGoal(SportGoal goal) => _mutate((current) async {
        if (goal.id == null) return;
        await _repo.deleteGoal(goal.id!);
        _data = current.copyWith(goals: current.goals.where((g) => g.id != goal.id).toList());
      });

  Future<void> addMeasure(BodySnapshot snapshot) => _mutate((current) async {
        await _repo.addMeasurement(snapshot);
        _data = current.copyWith(measurements: await _repo.loadMeasurements());
        _message = 'Relevé enregistré';
      });
}
