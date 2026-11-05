import 'dart:async';

import '../core/api/api_client.dart';
import '../core/api/auth_repository.dart';
import '../core/validators.dart';
import 'base_view_model.dart';

String _friendlyCodeError(ApiException e) {
  if (e.statusCode == 429) return 'Trop de tentatives. Réessaie dans quelques minutes.';
  final m = e.message.toLowerCase();
  if (m.contains('invalid') || m.contains('incorrect')) return 'Code incorrect ou expiré.';
  return e.message;
}

/// Login form.
class LoginViewModel extends BaseViewModel {
  LoginViewModel(this._auth, {String? successMessage}) : _successMessage = successMessage;
  final AuthRepository _auth;

  String? _successMessage;
  String? get successMessage => _successMessage;

  void showSuccess(String message) {
    _successMessage = message;
    notify();
  }

  /// Returns the session when the login succeeded, null otherwise ([error] is set).
  Future<AuthSession?> login(String email, String password) async {
    final invalid = Validators.email(email);
    if (invalid != null) {
      setError(invalid);
      return null;
    }
    _successMessage = null;
    AuthSession? session;
    await guard(() async => session = await _auth.login(email, password));
    return session;
  }
}

/// Registration form.
class RegisterViewModel extends BaseViewModel {
  RegisterViewModel(this._auth);
  final AuthRepository _auth;

  Future<AuthSession?> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmation,
  }) async {
    final invalid = Validators.email(email) ?? Validators.password(password) ?? Validators.confirmation(confirmation, password);
    if (invalid != null) {
      setError(invalid);
      return null;
    }
    AuthSession? session;
    await guard(
      () async => session = await _auth.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        passwordConfirmation: confirmation,
      ),
      errorMessage: (e) {
        final combined = e.fieldErrors.values.expand((items) => items).join('\n');
        return combined.isNotEmpty ? combined : e.message;
      },
    );
    return session;
  }
}

/// Email verification with a 60 s resend countdown.
class VerifyEmailViewModel extends BaseViewModel {
  VerifyEmailViewModel(this._auth, {required this.email, required this.emailSent}) {
    if (emailSent) _startCountdown();
  }

  final AuthRepository _auth;
  final String email;
  final bool emailSent;

  int _countdown = 0;
  bool _resending = false;
  String? _successMessage;
  Timer? _timer;

  int get countdown => _countdown;
  bool get resending => _resending;
  String? get successMessage => _successMessage;
  bool get canResend => _countdown == 0 && !_resending;

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _countdown--;
      if (_countdown <= 0) {
        _countdown = 0;
        t.cancel();
      }
      notify();
    });
  }

  Future<bool> verify(String code) async {
    final invalid = Validators.code(code);
    if (invalid != null) {
      setError(invalid);
      return false;
    }
    _successMessage = null;
    return guard(() => _auth.verifyEmail(email: email, code: code), errorMessage: _friendlyCodeError);
  }

  Future<void> resend() async {
    _resending = true;
    _successMessage = null;
    clearError();
    try {
      await _auth.resendCode(email);
      _successMessage = 'Un nouveau code a été envoyé.';
      _startCountdown();
    } on ApiException catch (e) {
      setError(_friendlyCodeError(e));
    } finally {
      _resending = false;
      notify();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Forgot password: send the code by email.
class ForgotPasswordViewModel extends BaseViewModel {
  ForgotPasswordViewModel(this._auth);
  final AuthRepository _auth;

  Future<bool> sendCode(String email) async {
    final invalid = Validators.email(email);
    if (invalid != null) {
      setError(invalid);
      return false;
    }
    return guard(() => _auth.forgotPassword(email), errorMessage: (e) => e.fieldErrors['email']?.firstOrNull ?? e.message);
  }
}

/// Reset password with the emailed code.
class ResetPasswordViewModel extends BaseViewModel {
  ResetPasswordViewModel(this._auth, {required this.email});
  final AuthRepository _auth;
  final String email;

  bool obscurePassword = true;
  bool obscureConfirmation = true;

  void togglePassword() {
    obscurePassword = !obscurePassword;
    notify();
  }

  void toggleConfirmation() {
    obscureConfirmation = !obscureConfirmation;
    notify();
  }

  Future<bool> reset({required String code, required String password, required String confirmation}) async {
    final invalid = Validators.code(code) ?? Validators.password(password) ?? Validators.confirmation(confirmation, password);
    if (invalid != null) {
      setError(invalid);
      return false;
    }
    return guard(
      () => _auth.resetPassword(email: email, code: code, password: password, passwordConfirmation: confirmation),
      errorMessage: _friendlyCodeError,
    );
  }
}

/// Change password (profile).
class ChangePasswordViewModel extends BaseViewModel {
  ChangePasswordViewModel(this._auth);
  final AuthRepository _auth;

  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirmation = true;
  String? _success;
  String? get success => _success;

  void toggle(String field) {
    switch (field) {
      case 'current':
        obscureCurrent = !obscureCurrent;
      case 'new':
        obscureNew = !obscureNew;
      default:
        obscureConfirmation = !obscureConfirmation;
    }
    notify();
  }

  Future<bool> change({required String current, required String password, required String confirmation}) async {
    _success = null;
    final invalid = (current.isEmpty ? 'Le mot de passe actuel est requis.' : null) ??
        Validators.password(password, label: 'Le nouveau mot de passe') ??
        Validators.confirmation(confirmation, password);
    if (invalid != null) {
      setError(invalid);
      return false;
    }
    final ok = await guard(
      () => _auth.changePassword(currentPassword: current, password: password, passwordConfirmation: confirmation),
      errorMessage: (e) => e.fieldErrors.values.expand((v) => v).firstOrNull ?? e.message,
    );
    if (ok) {
      _success = 'Mot de passe modifié avec succès.';
      notify();
    }
    return ok;
  }
}
