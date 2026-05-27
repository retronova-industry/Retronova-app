import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _apiBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    if (_apiBaseUrlFromEnv.isNotEmpty) {
      return _apiBaseUrlFromEnv;
    }

    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api/v1';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://localhost:8000/api/v1';
      case TargetPlatform.fuchsia:
        return 'http://localhost:8000/api/v1';
    }
  }

  static const String stripeReturnScheme = 'retronova';
  static const String stripeReturnHost = 'checkout';
  static const String stripeSuccessPath = '/success';
  static const String stripeCancelPath = '/cancel';

  static Uri get stripeSuccessUri => Uri(
    scheme: stripeReturnScheme,
    host: stripeReturnHost,
    path: stripeSuccessPath,
  );

  static Uri get stripeCancelUri => Uri(
    scheme: stripeReturnScheme,
    host: stripeReturnHost,
    path: stripeCancelPath,
  );

  // Endpoints
  static const String auth = '/auth';
  static const String users = '/users';
  static const String register = '$auth/register';
  static const String me = '$auth/me';
  static const String updateProfile = '$users/me';

  // Headers
  static Map<String, String> getHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}
