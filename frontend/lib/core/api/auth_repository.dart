import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'token_storage.dart';

class AuthSession {
  const AuthSession({required this.token, required this.user, this.emailVerified = true, this.emailSent = true});
  final String token;
  final Map<String, dynamic> user;
  /// Whether the email was already verified at time of login/register.
  final bool emailVerified;
  /// Whether the backend sent a verification email (register only).
  final bool emailSent;
}

abstract interface class AuthRepository {
  Future<AuthSession> login(String email, String password);
  Future<AuthSession> register({required String firstName, required String lastName, required String email, required String password, required String passwordConfirmation});
  Future<void> logout();
  Future<bool> hasToken();
  Future<void> verifyEmail({required String email, required String code});
  Future<void> resendCode(String email);
  Future<void> forgotPassword(String email);
  Future<void> resetPassword({required String email, required String code, required String password, required String passwordConfirmation});
  Future<void> changePassword({required String currentPassword, required String password, required String passwordConfirmation});
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client, this._storage);
  final ApiClient _client;
  final TokenStorage _storage;

  @override
  Future<AuthSession> login(String email, String password) async {
    _client.resetUnauthorized();
    debugPrint('[Auth] login start');
    final data = Map<String, dynamic>.from(await _client.post('/auth/login', data: {'email': email, 'password': password}) as Map);
    debugPrint('[Auth] login response emailVerified=${data['user']?['emailVerified']}');
    final token = data['token'].toString();
    await _storage.write(token);
    _client.resetUnauthorized();
    final user = Map<String, dynamic>.from(data['user'] as Map);
    final emailVerified = user['emailVerified'] as bool? ?? true;
    return AuthSession(token: token, user: user, emailVerified: emailVerified);
  }

  @override
  Future<AuthSession> register({required String firstName, required String lastName, required String email, required String password, required String passwordConfirmation}) async {
    _client.resetUnauthorized();
    debugPrint('[Auth] register start');
    final data = Map<String, dynamic>.from(await _client.post('/auth/register', data: {'firstName': firstName, 'lastName': lastName, 'email': email, 'password': password, 'passwordConfirmation': passwordConfirmation}) as Map);
    final token = data['token'].toString();
    await _storage.write(token);
    debugPrint('[Auth] token saved, emailSent=${data['emailSent']}, emailVerified=${data['user']?['emailVerified']}');
    _client.resetUnauthorized();
    final user = Map<String, dynamic>.from(data['user'] as Map);
    final emailVerified = user['emailVerified'] as bool? ?? false;
    final emailSent = data['emailSent'] as bool? ?? true;
    return AuthSession(token: token, user: user, emailVerified: emailVerified, emailSent: emailSent);
  }

  @override
  Future<void> logout() async {
    _client.resetUnauthorized();
    try {
      await _client.post('/auth/logout');
    } on ApiException {
      return;
    } finally {
      await _storage.clear();
      _client.resetUnauthorized();
    }
  }

  @override
  Future<bool> hasToken() async => (await _storage.read())?.isNotEmpty ?? false;

  @override
  Future<void> verifyEmail({required String email, required String code}) async {
    debugPrint('[Auth] verifyEmail start email=$email');
    await _client.post('/auth/verify-email', data: {'email': email, 'code': code});
    debugPrint('[Auth] verifyEmail success');
  }

  @override
  Future<void> resendCode(String email) async {
    debugPrint('[Auth] resendCode email=$email');
    await _client.post('/auth/resend-code', data: {'email': email});
    debugPrint('[Auth] resendCode sent');
  }

  @override
  Future<void> forgotPassword(String email) async {
    debugPrint('[Auth] forgotPassword email=$email');
    await _client.post('/auth/forgot-password', data: {'email': email});
    debugPrint('[Auth] forgotPassword sent');
  }

  @override
  Future<void> resetPassword({required String email, required String code, required String password, required String passwordConfirmation}) async {
    debugPrint('[Auth] resetPassword email=$email');
    await _client.post('/auth/reset-password', data: {
      'email': email,
      'code': code,
      'password': password,
      'passwordConfirmation': passwordConfirmation,
    });
    debugPrint('[Auth] resetPassword success');
  }

  @override
  Future<void> changePassword({required String currentPassword, required String password, required String passwordConfirmation}) async {
    debugPrint('[Auth] changePassword start');
    await _client.post('/me/change-password', data: {
      'currentPassword': currentPassword,
      'password': password,
      'passwordConfirmation': passwordConfirmation,
    });
    debugPrint('[Auth] changePassword success');
  }
}
