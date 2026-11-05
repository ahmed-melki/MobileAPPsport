import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/api/app_repositories.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/hub_screen.dart';
import 'screens/onboarding/onboarding_flow_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'viewmodels/app_view_model.dart';

/// Root widget. Architecture: MVVM + Provider.
///  - Model      : repositories (core/api) + data classes (data/)
///  - ViewModel  : ChangeNotifier classes (viewmodels/)
///  - View       : widgets (screens/) that watch their ViewModel with Provider
class ApexApp extends StatefulWidget {
  const ApexApp({super.key});

  @override
  State<ApexApp> createState() => _ApexAppState();
}

class _ApexAppState extends State<ApexApp> {
  late final AppRepositories _repositories;
  late final AppViewModel _appViewModel;
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _redirectingToLogin = false;
  bool _redirectingToVerify = false;

  @override
  void initState() {
    super.initState();
    _repositories = AppRepositories(onUnauthorized: _goToLogin, onEmailNotVerified: _goToVerifyEmail);
    _appViewModel = AppViewModel(_repositories)..checkAuth();
  }

  @override
  void dispose() {
    _appViewModel.dispose();
    super.dispose();
  }

  Future<void> _authenticatedNow() async {
    _redirectingToLogin = false;
    _redirectingToVerify = false;
    final completed = await _appViewModel.refreshOnboarding();
    _appViewModel.markAuthenticated(onboardingCompleted: completed);
    if (!completed) {
      _navigateTo(OnboardingFlowScreen(onFinished: _navigateToHub), 'Onboarding');
      return;
    }
    _navigateToHub();
  }

  void _goToLogin() {
    if (_redirectingToLogin) return;
    _redirectingToLogin = true;
    _redirectingToVerify = false;
    _appViewModel.markLoggedOut();
    _navigateTo(LoginScreen(onAuthenticated: _authenticatedNow), 'Login');
  }

  /// Called from ApiClient when a 403 email_not_verified response arrives.
  void _goToVerifyEmail(String email) {
    if (_redirectingToVerify) return;
    _redirectingToVerify = true;
    _repositories.client.resetEmailNotVerified();
    _navigateTo(VerifyEmailScreen(email: email, emailSent: true, onVerified: _authenticatedNow), 'VerifyEmail');
  }

  Future<void> _onLogout() async {
    await _appViewModel.logout();
    _goToLogin();
  }

  void _navigateToHub() => _navigateTo(HubScreen(onLogout: _onLogout), 'Hub');

  void _navigateTo(Widget screen, String destination) {
    final navigator = _navigatorKey.currentState;
    debugPrint('[Auth] navigation: $destination');
    if (navigator == null) return;
    navigator.pushAndRemoveUntil<void>(MaterialPageRoute(builder: (_) => screen), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppRepositories>.value(value: _repositories),
        ChangeNotifierProvider<AppViewModel>.value(value: _appViewModel),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'APEX',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: AppColors.scaffold,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Consumer<AppViewModel>(
          builder: (context, app, _) {
            final authenticated = app.authenticated;
            if (authenticated == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
            if (!authenticated) return LoginScreen(onAuthenticated: _authenticatedNow);
            return app.onboardingCompleted ? HubScreen(onLogout: _onLogout) : OnboardingFlowScreen(onFinished: _navigateToHub);
          },
        ),
      ),
    );
  }
}
