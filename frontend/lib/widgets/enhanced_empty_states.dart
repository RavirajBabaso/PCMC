import 'package:flutter/material.dart';
import 'package:main_ui/theme/app_theme.dart';

/// Empty state illustration type
enum EmptyStateType {
  noData,
  noResults,
  noConnection,
  noPermission,
  maintenance,
  comingSoon,
}

/// Illustration for different empty states
class EmptyStateIllustration extends StatelessWidget {
  final EmptyStateType type;
  final double size;
  final Color? primaryColor;
  final Color? secondaryColor;

  const EmptyStateIllustration({
    super.key,
    required this.type,
    this.size = 96,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? dsAccent;
    final secondary = secondaryColor ?? dsAccent.withValues(alpha:0.3);

    switch (type) {
      case EmptyStateType.noData:
        return _NoDataIllustration(
          size: size,
          primaryColor: primary,
          secondaryColor: secondary,
        );
      case EmptyStateType.noResults:
        return _NoResultsIllustration(
          size: size,
          primaryColor: primary,
          secondaryColor: secondary,
        );
      case EmptyStateType.noConnection:
        return _NoConnectionIllustration(
          size: size,
          primaryColor: primary,
          secondaryColor: secondary,
        );
      case EmptyStateType.noPermission:
        return _NoPermissionIllustration(
          size: size,
          primaryColor: primary,
          secondaryColor: secondary,
        );
      case EmptyStateType.maintenance:
        return _MaintenanceIllustration(
          size: size,
          primaryColor: primary,
          secondaryColor: secondary,
        );
      case EmptyStateType.comingSoon:
        return _ComingSoonIllustration(
          size: size,
          primaryColor: primary,
          secondaryColor: secondary,
        );
    }
  }
}

/// No data illustration
class _NoDataIllustration extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;

  const _NoDataIllustration({
    required this.size,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryColor.withValues(alpha:0.1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Document icon background
          Icon(
            Icons.description_outlined,
            size: size * 0.5,
            color: primaryColor.withValues(alpha:0.3),
          ),
          // X mark
          Positioned(
            bottom: size * 0.15,
            right: size * 0.15,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: size * 0.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// No results illustration
class _NoResultsIllustration extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;

  const _NoResultsIllustration({
    required this.size,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryColor.withValues(alpha:0.1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Search icon
          Icon(
            Icons.search,
            size: size * 0.6,
            color: primaryColor,
          ),
          // Slash mark
          Positioned(
            child: Transform.rotate(
              angle: 0.4,
              child: Container(
                width: size * 0.15,
                height: size * 0.8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(size * 0.075),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// No connection illustration
class _NoConnectionIllustration extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;

  const _NoConnectionIllustration({
    required this.size,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryColor.withValues(alpha:0.1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wifi icon
          Icon(
            Icons.wifi_off,
            size: size * 0.5,
            color: primaryColor,
          ),
          // Pulse rings
          ...List.generate(2, (index) {
            final opacity = (1.0 - (index * 0.3)).clamp(0.0, 1.0);
            return Container(
              width: size * (0.7 + (index * 0.15)),
              height: size * (0.7 + (index * 0.15)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withValues(alpha:opacity * 0.4),
                  width: 2,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// No permission illustration
class _NoPermissionIllustration extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;

  const _NoPermissionIllustration({
    required this.size,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryColor.withValues(alpha:0.1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lock icon
          Icon(
            Icons.lock_outline,
            size: size * 0.5,
            color: primaryColor,
          ),
        ],
      ),
    );
  }
}

/// Maintenance illustration
class _MaintenanceIllustration extends StatefulWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;

  const _MaintenanceIllustration({
    required this.size,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  State<_MaintenanceIllustration> createState() =>
      _MaintenanceIllustrationState();
}

class _MaintenanceIllustrationState extends State<_MaintenanceIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.primaryColor.withValues(alpha:0.1),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Wrench icon
              Transform.rotate(
                angle: _controller.value * 0.3,
                child: Icon(
                  Icons.build,
                  size: widget.size * 0.5,
                  color: widget.primaryColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Coming soon illustration
class _ComingSoonIllustration extends StatefulWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;

  const _ComingSoonIllustration({
    required this.size,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  State<_ComingSoonIllustration> createState() =>
      _ComingSoonIllustrationState();
}

class _ComingSoonIllustrationState extends State<_ComingSoonIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.primaryColor.withValues(alpha:0.1),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Star icon with pulse
              Icon(
                Icons.star,
                size: widget.size * 0.5,
                color: widget.primaryColor.withValues(alpha:
                  0.5 + (_controller.value * 0.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Enhanced empty state with illustration
class EnhancedEmptyState extends StatelessWidget {
  final EmptyStateType type;
  final String title;
  final String description;
  final VoidCallback? onRetry;
  final VoidCallback? onAction;
  final String? actionLabel;
  final Color? primaryColor;
  final Color? secondaryColor;
  final double illustrationSize;
  final EdgeInsets padding;

  const EnhancedEmptyState({
    super.key,
    required this.type,
    required this.title,
    required this.description,
    this.onRetry,
    this.onAction,
    this.actionLabel,
    this.primaryColor,
    this.secondaryColor,
    this.illustrationSize = 96,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Illustration
              EmptyStateIllustration(
                type: type,
                size: illustrationSize,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: dsTextPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: dsTextSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              if (onAction != null || onRetry != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (onRetry != null)
                      TextButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    if (onRetry != null && onAction != null)
                      const SizedBox(width: 12),
                    if (onAction != null)
                      ElevatedButton(
                        onPressed: onAction,
                        child: Text(actionLabel ?? 'Action'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state with custom illustration widget
class CustomEmptyState extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String description;
  final VoidCallback? onRetry;
  final VoidCallback? onAction;
  final String? actionLabel;
  final EdgeInsets padding;

  const CustomEmptyState({
    super.key,
    required this.illustration,
    required this.title,
    required this.description,
    this.onRetry,
    this.onAction,
    this.actionLabel,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              illustration,
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: dsTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: dsTextSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              if (onAction != null || onRetry != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (onRetry != null)
                      TextButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    if (onRetry != null && onAction != null)
                      const SizedBox(width: 12),
                    if (onAction != null)
                      ElevatedButton(
                        onPressed: onAction,
                        child: Text(actionLabel ?? 'Action'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
