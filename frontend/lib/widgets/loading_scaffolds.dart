import 'package:flutter/material.dart';
import 'package:main_ui/layouts/app_shell.dart';
import 'package:main_ui/theme/app_theme.dart';
import 'package:main_ui/widgets/loading_indicator.dart';
import 'package:main_ui/widgets/skeleton_screens.dart';
import 'package:main_ui/widgets/enhanced_empty_states.dart';
import 'package:main_ui/widgets/error_states.dart';

/// Loading states scaffold with app shell
class LoadingScaffold extends StatelessWidget {
  final String title;
  final String? currentRoute;
  final LoadingType loadingType;
  final String? message;
  final double loadingSize;
  final Color? backgroundColor;

  const LoadingScaffold({
    super.key,
    required this.title,
    this.currentRoute,
    this.loadingType = LoadingType.spinner,
    this.message,
    this.loadingSize = 48,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: title,
      currentRoute: currentRoute,
      backgroundColor: backgroundColor ?? dsBackground,
      child: Center(
        child: LoadingIndicator(
          type: loadingType,
          size: loadingSize,
          message: message,
        ),
      ),
    );
  }
}

/// Skeleton scaffold for list loading
class ListLoadingScaffold extends StatelessWidget {
  final String title;
  final String? currentRoute;
  final int itemCount;
  final Color? backgroundColor;

  const ListLoadingScaffold({
    super.key,
    required this.title,
    this.currentRoute,
    this.itemCount = 6,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: title,
      currentRoute: currentRoute,
      backgroundColor: backgroundColor ?? dsBackground,
      child: ListSkeleton(itemCount: itemCount),
    );
  }
}

/// Skeleton scaffold for form loading
class FormLoadingScaffold extends StatelessWidget {
  final String title;
  final String? currentRoute;
  final int fieldCount;
  final Color? backgroundColor;

  const FormLoadingScaffold({
    super.key,
    required this.title,
    this.currentRoute,
    this.fieldCount = 4,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: title,
      currentRoute: currentRoute,
      backgroundColor: backgroundColor ?? dsBackground,
      child: FormSkeleton(fieldCount: fieldCount),
    );
  }
}

/// Skeleton scaffold for card-based loading
class CardLoadingScaffold extends StatelessWidget {
  final String title;
  final String? currentRoute;
  final int cardCount;
  final Color? backgroundColor;

  const CardLoadingScaffold({
    super.key,
    required this.title,
    this.currentRoute,
    this.cardCount = 3,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: title,
      currentRoute: currentRoute,
      backgroundColor: backgroundColor ?? dsBackground,
      child: CardSkeleton(count: cardCount),
    );
  }
}

/// Empty state scaffold
class EmptyScaffold extends StatelessWidget {
  final String title;
  final String? currentRoute;
  final EmptyStateType type;
  final String emptyTitle;
  final String emptyDescription;
  final VoidCallback? onAction;
  final String? actionLabel;
  final VoidCallback? onRetry;
  final Color? backgroundColor;

  const EmptyScaffold({
    super.key,
    required this.title,
    this.currentRoute,
    required this.type,
    required this.emptyTitle,
    required this.emptyDescription,
    this.onAction,
    this.actionLabel,
    this.onRetry,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: title,
      currentRoute: currentRoute,
      backgroundColor: backgroundColor ?? dsBackground,
      child: EnhancedEmptyState(
        type: type,
        title: emptyTitle,
        description: emptyDescription,
        onAction: onAction,
        actionLabel: actionLabel,
        onRetry: onRetry,
      ),
    );
  }
}

/// Error state scaffold
class ErrorScaffold extends StatelessWidget {
  final String title;
  final String? currentRoute;
  final String errorTitle;
  final String errorMessage;
  final String? errorCode;
  final VoidCallback onRetry;
  final VoidCallback? onDismiss;
  final Color? backgroundColor;

  const ErrorScaffold({
    super.key,
    required this.title,
    this.currentRoute,
    required this.errorTitle,
    required this.errorMessage,
    this.errorCode,
    required this.onRetry,
    this.onDismiss,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: title,
      currentRoute: currentRoute,
      backgroundColor: backgroundColor ?? dsBackground,
      child: ErrorState(
        title: errorTitle,
        message: errorMessage,
        errorCode: errorCode,
        onRetry: onRetry,
        onDismiss: onDismiss,
      ),
    );
  }
}

/// Async data builder scaffold
class AsyncScaffold<T> extends StatelessWidget {
  final String title;
  final String? currentRoute;
  final Future<T> future;
  final Widget Function(BuildContext, T) builder;
  final Widget Function(BuildContext, Object)? errorBuilder;
  final bool showSkeleton;
  final Color? backgroundColor;
  final RefreshCallback? onRefresh;

  const AsyncScaffold({
    super.key,
    required this.title,
    this.currentRoute,
    required this.future,
    required this.builder,
    this.errorBuilder,
    this.showSkeleton = true,
    this.backgroundColor,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: title,
      currentRoute: currentRoute,
      backgroundColor: backgroundColor ?? dsBackground,
      child: FutureBuilder<T>(
        future: future,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return showSkeleton
                ? const DetailPageSkeleton()
                : const Center(child: LoadingIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            final error = snapshot.error;
            if (errorBuilder != null) {
              return errorBuilder!(context, error ?? 'Unknown error');
            }
            return MinimalErrorState(
              message: error.toString(),
              onRetry: () {
                // Trigger rebuild
              },
            );
          }

          // Success state
          if (snapshot.hasData) {
            return onRefresh != null
                ? RefreshIndicator(
                    onRefresh: onRefresh!,
                    color: dsAccent,
                    backgroundColor: dsSurface,
                    child: builder(context, snapshot.data as T),
                  )
                : builder(context, snapshot.data as T);
          }

          // Default fallback
          return const Center(
            child: LoadingIndicator(),
          );
        },
      ),
    );
  }
}

/// Stream data builder scaffold
class StreamScaffold<T> extends StatelessWidget {
  final String title;
  final String? currentRoute;
  final Stream<T> stream;
  final Widget Function(BuildContext, T) builder;
  final Widget Function(BuildContext, Object)? errorBuilder;
  final bool showSkeleton;
  final Color? backgroundColor;

  const StreamScaffold({
    super.key,
    required this.title,
    this.currentRoute,
    required this.stream,
    required this.builder,
    this.errorBuilder,
    this.showSkeleton = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: title,
      currentRoute: currentRoute,
      backgroundColor: backgroundColor ?? dsBackground,
      child: StreamBuilder<T>(
        stream: stream,
        builder: (context, snapshot) {
          // Waiting state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return showSkeleton
                ? const CardSkeleton()
                : const Center(child: LoadingIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            final error = snapshot.error;
            if (errorBuilder != null) {
              return errorBuilder!(context, error ?? 'Unknown error');
            }
            return MinimalErrorState(
              message: error.toString(),
            );
          }

          // Data available
          if (snapshot.hasData) {
            return builder(context, snapshot.data as T);
          }

          // Default fallback
          return const Center(
            child: LoadingIndicator(),
          );
        },
      ),
    );
  }
}
