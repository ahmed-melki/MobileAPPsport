// Override this for a physical device, for example with your LAN address.
const String? apiBaseUrlOverride = null;

String get apiBaseUrl => apiBaseUrlOverride ?? 'http://10.0.2.2:8000/api';
