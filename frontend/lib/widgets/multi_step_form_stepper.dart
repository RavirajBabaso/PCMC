import 'package:flutter/material.dart';
import 'package:main_ui/theme/app_theme.dart';

/// Represents a single step in a multi-step form
class FormStep {
  final String title;
  final String? subtitle;
  final Widget content;
  final bool isValidated;

  FormStep({
    required this.title,
    this.subtitle,
    required this.content,
    this.isValidated = false,
  });
}

/// Multi-step form stepper with validation and navigation
class MultiStepFormStepper extends StatelessWidget {
  final List<FormStep> steps;
  final int currentStep;
  final VoidCallback onNextStep;
  final VoidCallback onPreviousStep;
  final VoidCallback onSubmit;
  final bool isSubmitting;
  final String nextButtonLabel;
  final String previousButtonLabel;
  final String submitButtonLabel;
  final bool canProceedToNext;
  final void Function(int)? onStepChanged;
  final Color backgroundColor;

  MultiStepFormStepper({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.onNextStep,
    required this.onPreviousStep,
    required this.onSubmit,
    this.isSubmitting = false,
    this.nextButtonLabel = 'Next',
    this.previousButtonLabel = 'Back',
    this.submitButtonLabel = 'Submit',
    this.canProceedToNext = true,
    this.onStepChanged,
    Color? backgroundColor,
  }) : backgroundColor = backgroundColor ?? dsBackground;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: dsSurface,
        foregroundColor: dsAccent,
        title: Text(steps[currentStep].title),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: dsPanelDecoration(color: dsSurface),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              _buildProgressIndicator(context),
              const SizedBox(height: 24),

              // Step subtitle if provided
              if (steps[currentStep].subtitle != null) ...[
                Text(
                  steps[currentStep].subtitle!,
                  style: TextStyle(
                    color: dsTextSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Step content
              steps[currentStep].content,
              const SizedBox(height: 32),

              // Navigation buttons
              _buildNavigationButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (currentStep + 1) / steps.length,
            minHeight: 6,
            backgroundColor: dsAccent.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(dsAccent),
          ),
        ),
        const SizedBox(height: 16),

        // Step indicators
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: steps.length,
            separatorBuilder: (context, index) => SizedBox(
              width: 8,
              child: Center(
                child: Container(
                  width: 2,
                  height: 2,
                  decoration: BoxDecoration(
                    color: dsAccent.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            itemBuilder: (context, index) => FocusableActionDetector(
              actions: {
                ActivateIntent: CallbackAction<Intent>(onInvoke: (_) {
                  if (index < currentStep || steps[index].isValidated) {
                    onStepChanged?.call(index);
                  }
                  return null;
                }),
              },
              enabled: index < currentStep || steps[index].isValidated,
              child: Semantics(
                button: true,
                label: 'Step ${index + 1}: ${steps[index].title}',
                enabled: index < currentStep || steps[index].isValidated,
                child: GestureDetector(
                  onTap: index < currentStep || steps[index].isValidated
                      ? () {
                          onStepChanged?.call(index);
                        }
                      : null,
                  child: _buildStepIndicator(context, index),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(BuildContext context, int index) {
    final isCompleted = index < currentStep;
    final isCurrent = index == currentStep;
    final isLocked = index > currentStep && !steps[index].isValidated;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrent
                ? dsAccent
                : isCompleted
                    ? Colors.green
                    : isLocked
                        ? dsAccent.withOpacity(0.2)
                        : dsAccent.withOpacity(0.3),
            border: Border.all(
              color: isCurrent ? dsAccent : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : isLocked
                    ? Icon(
                        Icons.lock,
                        color: dsAccent.withOpacity(0.5),
                        size: 20,
                      )
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isCurrent ? Colors.white : dsTextSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 48,
          child: Text(
            steps[index].title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isCurrent ? dsAccent : dsTextSecondary,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    final isFirstStep = currentStep == 0;
    final isLastStep = currentStep == steps.length - 1;

    return Column(
      children: [
        Row(
          children: [
            if (!isFirstStep)
              Expanded(
                child: _buildButton(
                  label: previousButtonLabel,
                  onPressed: isSubmitting ? null : onPreviousStep,
                  isPrimary: false,
                ),
              ),
            if (!isFirstStep) const SizedBox(width: 12),
            Expanded(
              child: _buildButton(
                label: isLastStep ? submitButtonLabel : nextButtonLabel,
                onPressed: (isSubmitting || !canProceedToNext)
                    ? null
                    : isLastStep
                        ? onSubmit
                        : onNextStep,
                isPrimary: true,
                isLoading: isSubmitting && isLastStep,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isPrimary,
    bool isLoading = false,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isPrimary ? dsAccent : Colors.transparent,
        border: isPrimary ? null : Border.all(color: dsAccent),
      ),
      child: FocusableActionDetector(
        enabled: onPressed != null,
        actions: {
          ActivateIntent: CallbackAction<Intent>(onInvoke: (_) {
            onPressed?.call();
            return null;
          }),
        },
        child: Semantics(
          button: true,
          label: label,
          enabled: onPressed != null,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        label,
                        style: TextStyle(
                          color: isPrimary ? Colors.white : dsAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
