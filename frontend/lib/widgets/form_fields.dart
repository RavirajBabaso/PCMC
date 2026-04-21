import 'package:flutter/material.dart';
import 'package:main_ui/theme/app_theme.dart';

/// Standard text input field with consistent styling
class StandardTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final int maxLines;
  final int minLines;
  final TextInputType keyboardType;
  final bool isRequired;
  final TextInputAction textInputAction;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final String? helperText;

  const StandardTextInput({
    super.key,
    required this.controller,
    required this.label,
    this.focusNode,
    this.hint,
    this.validator,
    this.maxLines = 1,
    this.minLines = 1,
    this.keyboardType = TextInputType.text,
    this.isRequired = false,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final usesMultilineInput = maxLines > 1 ||
        minLines > 1 ||
        textInputAction == TextInputAction.newline;
    final effectiveKeyboardType = usesMultilineInput &&
            keyboardType == TextInputType.text
        ? TextInputType.multiline
        : keyboardType;

    return Semantics(
      textField: true,
      label: label,
      hint: hint,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
        labelText: isRequired ? '${label} *' : label,
        hintText: hint,
        helperText: helperText,
        hintStyle: const TextStyle(color: Color(0xFF5A7A9B)),
        labelStyle: const TextStyle(color: Color(0xFF8BA3BE)),
        filled: true,
        fillColor: dsSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.effects.radiusLg),
          borderSide: const BorderSide(color: Color(0xFF1C3460)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.effects.radiusLg),
          borderSide: const BorderSide(color: Color(0xFF1C3460)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.effects.radiusLg),
          borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.effects.radiusLg),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.effects.radiusLg),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      style: TextStyle(color: dsTextPrimary),
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: effectiveKeyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
    ),
  );
  }
}

/// Standard dropdown field with consistent styling
class StandardDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String label;
  final String? Function(T?)? validator;
  final FocusNode? focusNode;
  final bool isRequired;
  final String? hint;

  const StandardDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.label,
    this.focusNode,
    this.validator,
    this.isRequired = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      child: DropdownButtonFormField<T>(
        focusNode: focusNode,
        value: value,
        decoration: InputDecoration(
        labelText: isRequired ? '${label} *' : label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xFF8BA3BE)),
        filled: true,
        fillColor: dsSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.effects.radiusLg),
          borderSide: const BorderSide(color: Color(0xFF1C3460)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.effects.radiusLg),
          borderSide: const BorderSide(color: Color(0xFF1C3460)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.effects.radiusLg),
          borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.effects.radiusLg),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.effects.radiusLg),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      dropdownColor: dsSurface,
      style: TextStyle(color: dsTextPrimary),
      items: items,
      onChanged: onChanged,
      validator: validator,
    ),
  );
  }
}

/// Section header for form grouping
class FormSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const FormSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: dsAccent, size: 24),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: dsHeadingStyle(18),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              color: dsTextSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}

/// Form step indicator showing progress
class FormProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepTitles;

  const FormProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: currentStep / totalSteps,
            minHeight: 6,
            backgroundColor: dsAccent.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(dsAccent),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Step ${currentStep + 1} of $totalSteps: ${stepTitles[currentStep]}',
          style: TextStyle(
            color: dsTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Info message box
class FormInfoBox extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;

  const FormInfoBox({
    super.key,
    required this.message,
    this.icon = Icons.info,
    this.backgroundColor = const Color(0xFF1C3460),
    this.textColor = const Color(0xFF8BA3BE),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dsAccent.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: dsAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Success message box
class SuccessInfoBox extends StatelessWidget {
  final String message;
  final IconData icon;

  const SuccessInfoBox({
    super.key,
    required this.message,
    this.icon = Icons.check_circle,
  });

  @override
  Widget build(BuildContext context) {
    return FormInfoBox(
      message: message,
      icon: icon,
      backgroundColor: Colors.green.withOpacity(0.1),
      textColor: Colors.green,
    );
  }
}
