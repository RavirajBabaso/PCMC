import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Base URL for all API requests.
///
/// Override at build time with --dart-define=API_BASE_URL=https://...
/// In GitHub Codespaces, forward port 5000 and set:
///   API_BASE_URL=https://<codespace-name>-5000.app.github.dev
class Constants {
  static String get baseUrl {
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );

    if (apiBaseUrl.isNotEmpty) {
      return apiBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulators reach the host machine via 10.0.2.2.
        return 'http://10.0.2.2:5000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://127.0.0.1:5000';
      case TargetPlatform.fuchsia:
        return 'http://localhost:5000';
    }
  }
}
