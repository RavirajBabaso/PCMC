import 'package:flutter/material.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  ({Color background, Color foreground, Color border}) _tone(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      'new' => (
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
        border: scheme.primary,
      ),
      'in_progress' => (
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
        border: scheme.tertiary,
      ),
      'resolved' || 'closed' => (
        background: const Color(0xFFE6F4EA),
        foreground: const Color(0xFF1E7D35),
        border: const Color(0xFF3BA55C),
      ),
      'rejected' => (
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
        border: scheme.error,
      ),
      'on_hold' => (
        background: const Color(0xFFFFF4E5),
        foreground: const Color(0xFF8A6100),
        border: const Color(0xFFF0B429),
      ),
      _ => (
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
        border: scheme.outline,
      ),
    };
  }

  IconData get _icon => switch (status) {
    'new' => Icons.fiber_new_rounded,
    'in_progress' => Icons.autorenew_rounded,
    'resolved' => Icons.check_circle_rounded,
    'rejected' => Icons.cancel_rounded,
    'on_hold' => Icons.pause_circle_rounded,
    'closed' => Icons.done_all_rounded,
    _ => Icons.info_rounded,
  };

  String _label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (status) {
      'new' => l10n.statusNew,
      'in_progress' => l10n.statusInProgress,
      'resolved' => l10n.statusResolved,
      'rejected' => l10n.statusRejected,
      'on_hold' => l10n.statusOnHold,
      'closed' => l10n.statusClosed,
      _ => l10n.statusUnknown,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tone = _tone(context);

    return Semantics(
      label: 'Status ${_label(context)}',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.appSpacing.md, vertical: context.appSpacing.xs + 2),
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(context.appEffects.radiusLg),
          border: Border.all(color: tone.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 14, color: tone.foreground),
            SizedBox(width: context.appSpacing.xs),
            Text(
              _label(context),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tone.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
