import 'package:flutter/material.dart';
import 'package:main_ui/widgets/app/app_button.dart';

@Deprecated('Use AppButton from widgets/app/app_button.dart instead.')
enum ButtonVariant { filled, outlined, text }

@Deprecated('Use AppButtonSize from widgets/app/app_button.dart instead.')
enum ButtonSize { small, medium, large }

@Deprecated('Use AppButton from widgets/app/app_button.dart instead.')
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.fullWidth = true,
    this.isLoading = false,
    this.variant = ButtonVariant.filled,
    this.size = ButtonSize.medium,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool fullWidth;
  final bool isLoading;
  final ButtonVariant variant;
  final ButtonSize size;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      fullWidth: fullWidth,
      isLoading: isLoading,
      variant: switch (variant) {
        ButtonVariant.filled => AppButtonVariant.filled,
        ButtonVariant.outlined => AppButtonVariant.outlined,
        ButtonVariant.text => AppButtonVariant.text,
      },
      size: switch (size) {
        ButtonSize.small => AppButtonSize.small,
        ButtonSize.medium => AppButtonSize.medium,
        ButtonSize.large => AppButtonSize.large,
      },
    );
  }
}
