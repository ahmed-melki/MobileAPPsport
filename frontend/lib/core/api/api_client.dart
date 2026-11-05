import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import 'config.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});
  final String message;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;
  @override
  String toString() => message;
}

/// Called when the server returns 403 with code "email_not_verified".
typedef OnEmailNotVerified = void Function(String email);

class ApiClient {
  ApiClient({TokenStorage? tokenStorage, Dio? dio, this.onUnauthorized, this.onEmailNotVerified})
      : _tokenStorage = tokenStorage ?? TokenStorage(),
        _dio = dio ?? Dio(BaseOptions(baseUrl: apiBaseUrl, headers: {'Accept': 'application/json'})) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final isAuthenticationRequest = options.path == '/auth/login' || options.path == '/auth/register';
        if (!isAuthenticationRequest) {
          final token = await _tokenStorage.read();
          if (token != null && token.isNotEmpty) options.headers['Authorization'] = 'Bearer $token';
        } else {
          options.headers.remove('Authorization');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('[ApiClient] HTTP ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) async {
        debugPrint('[ApiClient] HTTP ${error.response?.statusCode ?? 'network error'} ${error.requestOptions.path}');
        final path = error.requestOptions.path;
        final isAuthenticationRequest = path == '/auth/login' || path == '/auth/register';

        if (error.response?.statusCode == 401 && !isAuthenticationRequest) {
          await _tokenStorage.clear();
          if (!_unauthorizedHandled) {
            _unauthorizedHandled = true;
            onUnauthorized?.call();
          }
        }

        // 403 email_not_verified — route to verification screen (no loops)
        if (error.response?.statusCode == 403) {
          final body = error.response?.data;
          final code = body is Map ? body['code']?.toString() : null;
          if (code == 'email_not_verified' && !_emailNotVerifiedHandled) {
            _emailNotVerifiedHandled = true;
            // Extract email from request data if available
            final requestData = error.requestOptions.data;
            String email = '';
            if (requestData is Map && requestData.containsKey('email')) {
              email = requestData['email'].toString();
            }
            onEmailNotVerified?.call(email);
          }
        }

        handler.next(error);
      },
    ));
  }

  final TokenStorage _tokenStorage;
  final Dio _dio;
  final void Function()? onUnauthorized;
  final OnEmailNotVerified? onEmailNotVerified;
  bool _unauthorizedHandled = false;
  bool _emailNotVerifiedHandled = false;

  void resetUnauthorized() => _unauthorizedHandled = false;
  void resetEmailNotVerified() => _emailNotVerifiedHandled = false;

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async => _send(() => _dio.get(path, queryParameters: queryParameters));
  Future<dynamic> post(String path, {Object? data}) async => _send(() => _dio.post(path, data: data));
  Future<dynamic> put(String path, {Object? data}) async => _send(() => _dio.put(path, data: data));
  Future<dynamic> patch(String path, {Object? data}) async => _send(() => _dio.patch(path, data: data));
  Future<dynamic> delete(String path) async => _send(() => _dio.delete(path));

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      final body = response.data;
      return body is Map<String, dynamic> && body.containsKey('data') ? body['data'] : body;
    } on DioException catch (error) {
      final body = error.response?.data;
      final statusCode = error.response?.statusCode;
      if (statusCode == 422) {
        debugPrint('[ApiClient] 422 response body: $body');
        debugPrint('[ApiClient] 422 request payload: ${error.requestOptions.data}');
      }
      final errors = <String, List<String>>{};
      if (body is Map && body['errors'] is Map) {
        for (final entry in (body['errors'] as Map).entries) {
          errors[entry.key.toString()] = (entry.value is List ? entry.value as List : [entry.value]).map((value) => value.toString()).toList();
        }
      }
      final firstFieldError = errors.values.expand((messages) => messages).firstOrNull;
      final message = firstFieldError ?? (body is Map && body['message'] != null ? body['message'].toString() : (error.type == DioExceptionType.connectionError ? 'Erreur réseau. Vérifie ta connexion.' : 'Requête échouée.'));
      throw ApiException(message, statusCode: statusCode, fieldErrors: errors);
    }
  }
}
