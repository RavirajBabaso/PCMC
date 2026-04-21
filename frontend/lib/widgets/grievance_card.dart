import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/widgets/app/status_badge.dart';
import 'package:main_ui/theme/app_theme.dart';

/// Standard grievance card — used in citizen, admin, and staff list screens.
class GrievanceCard extends StatelessWidget {
  const GrievanceCard({
    super.key,
    required this.grievance,
    this.onTap,
    this.showAssignee = false,
  });

  final Grievance grievance;
  final VoidCallback? onTap;
  /// When true shows assigned-to information (used in admin / staff views).
  final bool showAssignee;

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final status = grievance.status ?? 'new';
    final color  = AppStatus.fromStatus(status);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
        // Left accent bar
        boxShadow: const [],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colored accent bar
            Container(width: 4, color: color),

            // Content
            Expanded(
              child: InkWell(
                onTap: onTap ?? () => Navigator.pushNamed(
                  context,
                  '/citizen/detail',
                  arguments: grievance.id,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base, AppSpacing.md,
                    AppSpacing.base, AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              grievance.title,
                              style: theme.textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          StatusBadge(status: status),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      // Complaint ID
                      Text(
                        grievance.complaintId,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Description
                      Text(
                        grievance.description,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Meta row
                      Row(
                        children: [
                          if (grievance.createdAt != null) ...[
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(grievance.createdAt!),
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                          if (grievance.areaName != null) ...[
                            const SizedBox(width: AppSpacing.base),
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                grievance.areaName!,
                                style: theme.textTheme.labelSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (grievance.priority != null) ...[
                            const Spacer(),
                            _PriorityChip(priority: grievance.priority!),
                          ],
                        ],
                      ),

                      // Assignee (admin / staff view)
                      if (showAssignee && grievance.assignedTo != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded,
                                size: 12,
                                color: theme.colorScheme.onSurface.withOpacity(0.4)),
                            const SizedBox(width: 4),
                            Text(
                              grievance.assignee?.name ?? grievance.assignedTo!.toString(),
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});
  final String priority;

  Color _color() {
    switch (priority.toLowerCase()) {
      case 'high':   return AppTheme.error;
      case 'medium': return AppTheme.warning;
      default:       return AppTheme.textSecond;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
