import 'package:flutter/material.dart';
import 'package:main_ui/theme/app_theme.dart';

enum AppButtonVariant { filled, outlined, text, destructive }
enum AppButtonSize { small, medium, large }

/// Standard button used across ALL screens.
/// Enforces ≥ 44px touch target, consistent radius, loading state.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.label,
    this.text,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.fullWidth = true,
    this.isLoading = false,
    this.variant = AppButtonVariant.filled,
    this.size = AppButtonSize.medium,
  }) : assert(label != null || text != null, 'Provide label or text');

  final String? label;
  final String? text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool fullWidth;
  final bool isLoading;
  final AppButtonVariant variant;
  final AppButtonSize size;

  String get _label => label ?? text!;

  double get _height {
    if (size == AppButtonSize.small) return 44;
    if (size == AppButtonSize.large) return 56;
    return 52;
  }

  double get _fontSize {
    if (size == AppButtonSize.small) return 13;
    if (size == AppButtonSize.large) return 16;
    return 15;
  }

  EdgeInsets get _padding {
    if (size == AppButtonSize.small) {
      return const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm);
    }
    if (size == AppButtonSize.large) {
      return const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.base);
    }
    return const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.base);
  }

  Color _resolvedForeground(ColorScheme scheme) {
    switch (variant) {
      case AppButtonVariant.filled:
        return foregroundColor ?? scheme.onPrimary;
      case AppButtonVariant.destructive:
        return foregroundColor ?? scheme.onError;
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return foregroundColor ?? scheme.primary;
    }
  }

  Color _resolvedBackground(ColorScheme scheme) {
    switch (variant) {
      case AppButtonVariant.filled:
        return backgroundColor ?? scheme.primary;
      case AppButtonVariant.destructive:
        return backgroundColor ?? scheme.error;
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return backgroundColor ?? Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectivePressHandler = isLoading ? null : onPressed;
    final minSize = Size(fullWidth ? double.infinity : 0, _height);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md));
    final textStyle = TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w600);
    final resolvedForeground = _resolvedForeground(scheme);
    final resolvedBackground = _resolvedBackground(scheme);

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: resolvedForeground,
            ),
          )
        : IconTheme.merge(
            data: IconThemeData(
              color: effectivePressHandler == null
                  ? resolvedForeground.withOpacity(0.6)
                  : resolvedForeground,
              size: _fontSize + 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Text(
                    _label,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
                ),
              ],
            ),
          );

    return Semantics(
      button: true,
      label: _label,
      enabled: effectivePressHandler != null,
      child: switch (variant) {
        AppButtonVariant.outlined => OutlinedButton(
            onPressed: effectivePressHandler,
            style: OutlinedButton.styleFrom(
              foregroundColor: resolvedForeground,
              side: BorderSide(color: resolvedForeground),
              minimumSize: minSize,
              padding: _padding,
              shape: shape,
              textStyle: textStyle,
              backgroundColor: resolvedBackground,
            ),
            child: child,
          ),
        AppButtonVariant.text => TextButton(
            onPressed: effectivePressHandler,
            style: TextButton.styleFrom(
              foregroundColor: resolvedForeground,
              minimumSize: minSize,
              padding: _padding,
              shape: shape,
              textStyle: textStyle,
              backgroundColor: resolvedBackground,
            ),
            child: child,
          ),
        AppButtonVariant.destructive => ElevatedButton(
            onPressed: effectivePressHandler,
            style: ElevatedButton.styleFrom(
              backgroundColor: resolvedBackground,
              foregroundColor: resolvedForeground,
              elevation: 0,
              minimumSize: minSize,
              padding: _padding,
              shape: shape,
              textStyle: textStyle,
            ),
            child: child,
          ),
        AppButtonVariant.filled => ElevatedButton(
            onPressed: effectivePressHandler,
            style: ElevatedButton.styleFrom(
              backgroundColor: resolvedBackground,
              foregroundColor: resolvedForeground,
              elevation: 0,
              minimumSize: minSize,
              padding: _padding,
              shape: shape,
              textStyle: textStyle,
            ),
            child: child,
          ),
      },
    );
  }
}
