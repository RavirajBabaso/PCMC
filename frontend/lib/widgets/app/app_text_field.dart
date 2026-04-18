import 'package:flutter/material.dart';
import 'package:main_ui/theme/app_theme.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.validator,
    this.onTap,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool? enabled;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final radius = context.appEffects.radiusMd;
    final isSingleLine = (maxLines ?? 1) == 1;

    return Semantics(
      textField: true,
      label: label,
      hint: hintText,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      onChanged: onChanged,
      validator: validator,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing.lg,
          vertical: isSingleLine ? spacing.lg : spacing.md,
        ),
        constraints: isSingleLine ? const BoxConstraints(minHeight: 56) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
      ),
    );
  }
}
