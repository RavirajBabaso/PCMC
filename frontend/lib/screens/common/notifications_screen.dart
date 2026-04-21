import 'package:flutter/material.dart';
import 'package:main_ui/layouts/app_shell.dart';
import 'package:main_ui/theme/app_theme.dart';

/// Notifications screen — styled with AppShell and design system tokens.
/// Backend integration: replace [_mockNotifications] with GET /notifications.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // TODO: Replace with backend-driven data via a provider
  static const List<Map<String, String>> _mockNotifications = [
    {'title': 'Grievance Update',  'body': 'Your complaint #123 has been resolved.',      'time': '2 hours ago',  'type': 'success'},
    {'title': 'Reminder',          'body': 'Submit feedback for grievance #101.',          'time': '1 day ago',    'type': 'info'},
    {'title': 'New Message',       'body': 'You have a new message from support.',          'time': '3 days ago',   'type': 'message'},
    {'title': 'System Update',     'body': 'New features have been added to the app.',     'time': '1 week ago',   'type': 'update'},
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Notifications',
      currentRoute: '/notifications',
      child: _mockNotifications.isEmpty
          ? _EmptyNotifications()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base, AppSpacing.base,
                AppSpacing.base, AppSpacing.xxl,
              ),
              itemCount: _mockNotifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) =>
                  _NotificationTile(data: _mockNotifications[i]),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.data});
  final Map<String, String> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type  = data['type'] ?? 'info';

    IconData icon;
    Color color;
    switch (type) {
      case 'success':
        icon = Icons.check_circle_outline_rounded;
        color = AppTheme.success;
        break;
      case 'message':
        icon = Icons.email_outlined;
        color = const Color(0xFF7C3AED);
        break;
      case 'update':
        icon = Icons.system_update_outlined;
        color = AppTheme.warning;
        break;
      default:
        icon = Icons.info_outline_rounded;
        color = theme.colorScheme.primary;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {}, // TODO: navigate to relevant screen
        child: Padding(
          padding: AppSpacing.card,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? '',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      data['body'] ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.65),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      data['time'] ?? '',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),

              // Unread dot — hardcoded; real app would check read state
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 72,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              'No notifications yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "We'll notify you when something arrives",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
