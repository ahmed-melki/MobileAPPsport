import '../core/api/repositories.dart';
import '../data/profile_models.dart';
import 'base_view_model.dart';

/// Home screen: dashboard stats, profile (role), active program.
class HubViewModel extends BaseViewModel {
  HubViewModel(this._profile);
  final ProfileRepository _profile;

  DashboardData? _dashboard;
  SportProfile? _user;
  Map<String, dynamic>? _activeProgram;

  DashboardData? get dashboard => _dashboard;
  SportProfile? get user => _user;
  Map<String, dynamic>? get activeProgram => _activeProgram;

  bool get isAdmin => _user?.isAdmin ?? false;
  String get firstName => _dashboard?.firstName.isNotEmpty == true ? _dashboard!.firstName : (_user?.firstName ?? '');
  int get readiness => _dashboard?.readiness ?? 0;
  int get streakDays => _dashboard?.streakDays ?? 0;
  int get weeklySessions => _dashboard?.weeklySessions ?? 0;

  Future<void> load() => guard(() async {
        _dashboard = await _profile.loadDashboard();
        notify();
        _user = (await _profile.loadProfile()).profile;
        notify();
        final programs = await _profile.loadUserPrograms();
        final active = programs.where((p) => p['status'] == 'active').toList();
        _activeProgram = active.isNotEmpty ? active.first : (programs.isNotEmpty ? programs.first : null);
      }, errorMessage: (_) => 'Impossible de charger le dashboard.');
}
