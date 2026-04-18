import 'package:flutter/material.dart';

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
  static StatusColors fromStatus(String status, ColorScheme scheme) {
    final normalized = status.toLowerCase();

    if (normalized == 'resolved') {
      return _fromBase(scheme.secondary);
    }
    if (normalized == 'rejected') {
      return _fromBase(scheme.error);
    }
    if (normalized == 'new') {
      return _fromBase(scheme.primary);
    }
    if (normalized == 'in_progress') {
      return _fromBase(scheme.tertiary);
    }
    if (normalized == 'on_hold') {
      return _fromBase(scheme.secondaryContainer);
    }
    if (normalized == 'closed') {
      return StatusColors(
        foreground: scheme.onSurfaceVariant,
        background: scheme.surfaceContainerHighest,
        border: scheme.outlineVariant,
      );
    }

    return StatusColors(
      foreground: scheme.onSurface,
      background: scheme.surface,
      border: scheme.outlineVariant,
    );
  }

  static StatusColors _fromBase(Color base) {
    return StatusColors(
      foreground: base,
      background: base.withValues(alpha: 0.12),
      border: base.withValues(alpha: 0.35),
    );
  }
}
