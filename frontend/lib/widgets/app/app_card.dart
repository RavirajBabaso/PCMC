import 'package:flutter/material.dart';
import 'package:main_ui/theme/app_theme.dart';

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
    final theme = Theme.of(context);
    final spacing = context.appSpacing;
    final effects = context.appEffects;
    final cardRadius = radius ?? effects.radiusMd;

    final card = Card(
      elevation: elevation ?? effects.cardElevation,
      margin: margin ?? EdgeInsets.all(spacing.sm),
      color: color,
      clipBehavior: clipBehavior,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: border == null
            ? BorderSide.none
            : BorderSide(color: border!.color, width: border!.width),
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(spacing.lg),
        child: child,
      ),
    );

    if (onTap == null) return card;

    return Card(
      elevation: elevation ?? effects.cardElevation,
      margin: margin ?? EdgeInsets.all(spacing.sm),
      color: color,
      clipBehavior: clipBehavior,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: border == null
            ? BorderSide.none
            : BorderSide(color: border!.color, width: border!.width),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cardRadius),
        child: Padding(
          padding: padding ?? EdgeInsets.all(spacing.lg),
          child: child,
        ),
      ),
    );
  }
}
