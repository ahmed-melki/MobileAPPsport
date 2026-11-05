import 'package:flutter/foundation.dart';

import '../core/api/app_repositories.dart';

/// Global session state: is the user logged in, did they finish the onboarding.
class AppViewModel extends ChangeNotifier {
  AppViewModel(this._repos);
  final AppRepositories _repos;

  /// null = still checking the stored token.
  bool? _authenticated;
  bool _onboardingCompleted = true;

  bool? get authenticated => _authenticated;
  bool get onboardingCompleted => _onboardingCompleted;

  Future<void> checkAuth() async {
    if (!await _repos.auth.hasToken()) {
      _authenticated = false;
      notifyListeners();
      return;
    }
    await refreshOnboarding();
    _authenticated = true;
    notifyListeners();
  }

  /// Reloads the profile; returns whether the onboarding is completed.
  Future<bool> refreshOnboarding() async {
    try {
      final bundle = await _repos.profile.loadProfile();
      _onboardingCompleted = bundle.profile.onboardingCompleted;
    } catch (_) {
      // Offline: keep the previous value.
    }
    return _onboardingCompleted;
  }

  void markAuthenticated({required bool onboardingCompleted}) {
    _authenticated = true;
    _onboardingCompleted = onboardingCompleted;
    notifyListeners();
  }

  void markLoggedOut() {
    _authenticated = false;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _repos.auth.logout();
    } finally {
      _repos.client.resetUnauthorized();
      markLoggedOut();
    }
  }
}
