import 'package:flutter/material.dart';
import 'package:main_ui/widgets/app/empty_state.dart';

@Deprecated('Use AppEmptyState from widgets/app/empty_state.dart instead.')
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionButton,
    this.iconColor,
    this.titleStyle,
    this.messageStyle,
    this.backgroundColor,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? actionButton;
  final Color? iconColor;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    Widget? illustration;
    if (iconColor != null) {
      illustration = Icon(icon, size: 48, color: iconColor);
    }

    return AppEmptyState(
      icon: icon,
      illustration: illustration,
      title: title,
      description: message,
      cta: actionButton,
      backgroundColor: backgroundColor,
    );
  }
}
