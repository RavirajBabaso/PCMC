import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Base URL for all API requests.
///
/// Override at build time with --dart-define=API_BASE_URL=https://...
/// In GitHub Codespaces, forward port 5000 and set:
///   API_BASE_URL=https://<codespace-name>-5000.app.github.dev
class Constants {
  static String get baseUrl => 'https://pcmc.onrender.com';
}
