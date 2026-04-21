import 'package:flutter/material.dart';
import 'package:main_ui/theme/app_theme.dart';

/// Compact pill badge for grievance status — used everywhere uniformly.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  /// When true, shows icon-only to save space.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = AppStatus.fromStatus(status);
    final label = AppStatus.labelFromStatus(status);
    final icon  = AppStatus.iconFromStatus(status);

    return Container(
      padding: compact
          ? const EdgeInsets.all(4)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: compact
          ? Icon(icon, color: color, size: 14)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 12),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
    );
  }
}
