// lib/theme/status_colors.dart
// Backward-compatible status color helpers — delegate to AppStatus in app_theme.

import 'package:flutter/material.dart';
import 'package:main_ui/theme/app_theme.dart';

/// Backward-compatible color holder used by legacy screens.
class StatusColors {
  final Color foreground;
  final Color background;
  final Color border;
  const StatusColors({
    required this.foreground,
    required this.background,
    required this.border,
  });
}

class StatusPalette {
  static StatusColors fromStatus(String status, [ColorScheme? scheme]) {
    final color = AppStatus.fromStatus(status);
    return StatusColors(
      foreground: color,
      background: color.withValues(alpha:0.12),
      border: color.withValues(alpha:0.35),
    );
  }
}
