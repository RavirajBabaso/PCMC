import 'package:flutter/material.dart';
import 'package:main_ui/theme/app_theme.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.illustration,
    this.icon,
    required this.title,
    required this.description,
    this.cta,
    this.maxWidth = 420,
    this.backgroundColor,
  });

  final Widget? illustration;
  final IconData? icon;
  final String title;
  final String description;
  final Widget? cta;
  final double maxWidth;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: EdgeInsets.all(spacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              illustration ?? _DefaultIllustration(icon: icon ?? Icons.inbox_rounded),
              SizedBox(height: spacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: spacing.sm),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha:0.72),
                  height: 1.4,
                ),
              ),
              if (cta != null) ...[
                SizedBox(height: spacing.xl),
                cta!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultIllustration extends StatelessWidget {
  const _DefaultIllustration({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.primaryContainer,
      ),
      child: Icon(icon, size: 46, color: scheme.onPrimaryContainer),
    );
  }
}
