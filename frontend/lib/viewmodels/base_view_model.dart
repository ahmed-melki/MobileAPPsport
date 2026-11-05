import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';

/// Base class of every ViewModel (MVVM).
///
/// - The View (widget) only reads the state exposed here and calls methods.
/// - The ViewModel talks to the repositories (Model layer) and calls
///   [notifyListeners] so that Provider rebuilds the View.
abstract class BaseViewModel extends ChangeNotifier {
  bool _busy = false;
  String? _error;
  Map<String, List<String>> _fieldErrors = const {};
  bool _disposed = false;

  bool get busy => _busy;
  String? get error => _error;
  Map<String, List<String>> get fieldErrors => _fieldErrors;
  bool get disposed => _disposed;

  String? fieldError(String field) => _fieldErrors[field]?.firstOrNull;

  @protected
  void setBusy(bool value) {
    _busy = value;
    notify();
  }

  @protected
  void setError(String? message, [Map<String, List<String>> fields = const {}]) {
    _error = message;
    _fieldErrors = fields;
    notify();
  }

  void clearError() => setError(null);

  /// Safe notifyListeners (ignored once the ViewModel is disposed).
  @protected
  void notify() {
    if (!_disposed) notifyListeners();
  }

  /// Runs an API call with busy/error handling. Returns true on success.
  @protected
  Future<bool> guard(Future<void> Function() action, {String Function(ApiException e)? errorMessage}) async {
    _busy = true;
    _error = null;
    _fieldErrors = const {};
    notify();
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      _error = errorMessage?.call(e) ?? e.message;
      _fieldErrors = e.fieldErrors;
      return false;
    } finally {
      _busy = false;
      notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
