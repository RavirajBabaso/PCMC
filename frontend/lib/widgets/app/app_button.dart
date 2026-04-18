import 'package:flutter/material.dart';
import 'package:main_ui/theme/app_theme.dart';

enum AppButtonVariant { filled, outlined, text }
enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    String? label,
    String? text,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.fullWidth = true,
    this.isLoading = false,
    this.variant = AppButtonVariant.filled,
    this.size = AppButtonSize.medium,
  }) : assert(label != null || text != null, 'Provide label or text'),
       _label = label ?? text!;

  final String _label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool fullWidth;
  final bool isLoading;
  final AppButtonVariant variant;
  final AppButtonSize size;

  double get _height => switch (size) {
    AppButtonSize.small => 44,
    AppButtonSize.medium => 56,
    AppButtonSize.large => 56,
  };

  double get _fontSize => switch (size) {
    AppButtonSize.small => 14,
    AppButtonSize.medium => 16,
    AppButtonSize.large => 17,
  };

  EdgeInsetsGeometry _padding(BuildContext context) => switch (size) {
    AppButtonSize.small => EdgeInsets.symmetric(horizontal: context.appSpacing.md),
    AppButtonSize.medium => EdgeInsets.symmetric(horizontal: context.appSpacing.lg),
    AppButtonSize.large => EdgeInsets.symmetric(horizontal: context.appSpacing.xl),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveOnPressed = isLoading ? null : onPressed;

    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                SizedBox(width: context.appSpacing.sm),
              ],
              Flexible(
                child: Text(
                  _label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: _fontSize),
                ),
              ),
            ],
          );

    final minimumSize = Size(fullWidth ? double.infinity : 0, _height);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(context.appEffects.radiusMd),
    );

    switch (variant) {
      case AppButtonVariant.outlined:
        return OutlinedButton(
          onPressed: effectiveOnPressed,
          style: theme.outlinedButtonTheme.style?.copyWith(
            minimumSize: WidgetStatePropertyAll(minimumSize),
            padding: WidgetStatePropertyAll(_padding(context)),
            shape: WidgetStatePropertyAll(shape),
            foregroundColor: WidgetStatePropertyAll(foregroundColor ?? theme.colorScheme.primary),
          ),
          child: child,
        );
      case AppButtonVariant.text:
        return TextButton(
          onPressed: effectiveOnPressed,
          style: theme.textButtonTheme.style?.copyWith(
            minimumSize: WidgetStatePropertyAll(minimumSize),
            padding: WidgetStatePropertyAll(_padding(context)),
            shape: WidgetStatePropertyAll(shape),
            foregroundColor: WidgetStatePropertyAll(foregroundColor ?? theme.colorScheme.primary),
          ),
          child: child,
        );
      case AppButtonVariant.filled:
        final disabledBackground = theme.colorScheme.onSurface.withValues(alpha: 0.12);
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: theme.elevatedButtonTheme.style?.copyWith(
            minimumSize: WidgetStatePropertyAll(minimumSize),
            padding: WidgetStatePropertyAll(_padding(context)),
            shape: WidgetStatePropertyAll(shape),
            backgroundColor: WidgetStatePropertyAll(
              onPressed == null ? disabledBackground : backgroundColor ?? theme.colorScheme.primary,
            ),
            foregroundColor: WidgetStatePropertyAll(foregroundColor ?? theme.colorScheme.onPrimary),
          ),
          child: child,
        );
    }
  }
}
