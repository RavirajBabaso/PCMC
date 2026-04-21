// lib/widgets/app/app_card.dart
import 'package:flutter/material.dart';
import 'package:main_ui/theme/app_theme.dart';

/// Standard surface card — border-based, no shadows by default.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.radius,
    this.border,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final double? radius;
  final BorderSide? border;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = color ?? Theme.of(context).cardColor;
    final borderColor = border?.color ?? (isDark ? dsBorder : AppTheme.border);
    final r = radius ?? AppRadius.lg;

    final decoration = BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: borderColor, width: border?.width ?? 1),
    );

    final content = Padding(
      padding: padding ?? AppSpacing.card,
      child: child,
    );

    if (onTap == null) {
      return Container(
        margin: margin,
        decoration: decoration,
        clipBehavior: clipBehavior,
        child: content,
      );
    }

    return Container(
      margin: margin,
      decoration: decoration,
      clipBehavior: clipBehavior,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(r),
          child: content,
        ),
      ),
    );
  }
}
