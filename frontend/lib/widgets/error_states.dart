import 'package:flutter/material.dart';
import 'package:main_ui/theme/app_theme.dart';

/// Error state with retry capability
class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String? errorCode;
  final VoidCallback onRetry;
  final VoidCallback? onDismiss;
  final Color? backgroundColor;
  final EdgeInsets padding;

  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    this.errorCode,
    required this.onRetry,
    this.onDismiss,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor ?? dsSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.red.withValues(alpha:0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withValues(alpha:0.1),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),

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

                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: dsTextSecondary,
                    height: 1.5,
                  ),
                ),

                // Error code if provided
                if (errorCode != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: dsBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Error: $errorCode',
                      style: const TextStyle(
                        fontSize: 12,
                        color: dsTextSecondary,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    if (onDismiss != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDismiss,
                          child: const Text('Dismiss'),
                        ),
                      ),
                    if (onDismiss != null) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimal error state
class MinimalErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const MinimalErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: dsTextSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Server error state
class ServerErrorState extends StatelessWidget {
  final int statusCode;
  final String? statusMessage;
  final VoidCallback onRetry;

  const ServerErrorState({
    super.key,
    required this.statusCode,
    this.statusMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    String title = 'Something went wrong';
    String message = 'Unable to load the requested information.';

    if (statusCode == 404) {
      title = 'Not Found';
      message = 'The resource you\'re looking for doesn\'t exist.';
    } else if (statusCode == 403) {
      title = 'Access Denied';
      message = 'You don\'t have permission to access this resource.';
    } else if (statusCode == 500) {
      title = 'Server Error';
      message = 'The server encountered an error. Please try again later.';
    } else if (statusCode == 503) {
      title = 'Service Unavailable';
      message = 'The service is temporarily unavailable. Please try again later.';
    }

    if (statusMessage != null) {
      message = statusMessage!;
    }

    return ErrorState(
      title: title,
      message: message,
      errorCode: 'HTTP $statusCode',
      onRetry: onRetry,
    );
  }
}

/// Network error state
class NetworkErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const NetworkErrorState({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: 'Network Error',
      message:
          'Unable to connect to the server. Please check your internet connection and try again.',
      errorCode: 'NO_CONNECTION',
      onRetry: onRetry,
    );
  }
}

/// Timeout error state
class TimeoutErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const TimeoutErrorState({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: 'Request Timeout',
      message:
          'The request took too long. Please check your connection and try again.',
      errorCode: 'TIMEOUT',
      onRetry: onRetry,
    );
  }
}
