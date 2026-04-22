import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/models/workproof_model.dart';
import 'package:main_ui/services/api_service.dart';
import 'package:main_ui/theme/app_theme.dart';
import 'package:main_ui/layouts/app_shell.dart';
import 'package:main_ui/widgets/app/status_badge.dart';

// Field staff state-machine: allowed next statuses
List<String> _fieldTransitions(String current) {
  switch (current.toLowerCase()) {
    case 'new':          return ['in_progress'];
    case 'in_progress':  return ['on_hold', 'resolved'];
    case 'on_hold':      return ['in_progress'];
    default:             return [];
  }
}

class AssignedList extends ConsumerStatefulWidget {
  const AssignedList({super.key});

  @override
  ConsumerState<AssignedList> createState() => _AssignedListState();
}

class _AssignedListState extends ConsumerState<AssignedList> {
  late Future<List<Grievance>> _future;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = ApiService.get('/grievances/assigned').then((res) {
        // Backend returns a paginated map: {grievances: [...], total: ..., page: ..., per_page: ...}
        final data = res.data;
        List<dynamic> items;
        if (data is List) {
          items = data;
        } else if (data is Map && data['grievances'] is List) {
          items = data['grievances'] as List;
        } else {
          items = [];
        }
        return items
            .map((e) => Grievance.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    });
  }

  List<Grievance> _filtered(List<Grievance> all) {
    if (_filter == 'all') return all;
    return all.where((g) => g.status?.toLowerCase() == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppShell(
      title: 'My Assignments',
      currentRoute: '/field_staff/home',
      child: Column(
        children: [
          // ── Filter chips ───────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                _FilterChip(label: 'All',         value: 'all',          selected: _filter, onSelected: (v) => setState(() => _filter = v)),
                _FilterChip(label: 'New',         value: 'new',          selected: _filter, onSelected: (v) => setState(() => _filter = v)),
                _FilterChip(label: 'In Progress', value: 'in_progress',  selected: _filter, onSelected: (v) => setState(() => _filter = v)),
                _FilterChip(label: 'On Hold',     value: 'on_hold',      selected: _filter, onSelected: (v) => setState(() => _filter = v)),
                _FilterChip(label: 'Resolved',    value: 'resolved',     selected: _filter, onSelected: (v) => setState(() => _filter = v)),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── List ───────────────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<Grievance>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return _ErrorState(error: snap.error.toString(), onRetry: _reload);

                final items = _filtered(snap.data ?? []);
                if (items.isEmpty) return const _EmptyState();

                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.base, AppSpacing.sm,
                      AppSpacing.base, AppSpacing.xxxl,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _AssignmentCard(
                      grievance: items[i],
                      onRefresh: _reload,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Assignment card
// ─────────────────────────────────────────────────────────────────────────────

class _AssignmentCard extends ConsumerWidget {
  const _AssignmentCard({required this.grievance, required this.onRefresh});

  final Grievance grievance;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme       = Theme.of(context);
    final status      = grievance.status ?? 'new';
    final statusColor = AppStatus.fromStatus(status);
    final transitions = _fieldTransitions(status);
    final hasWorkproof = grievance.workproofs?.isNotEmpty ?? false;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Color dot
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grievance.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        grievance.complaintId,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                StatusBadge(status: status),
              ],
            ),
          ),

          // Description
          if (grievance.description?.isNotEmpty == true) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.sm),
              child: Text(
                grievance.description!,
                style: theme.textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          // Meta row
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.sm),
            child: Wrap(
              spacing: AppSpacing.base,
              children: [
                if (grievance.createdAt != null)
                  _MetaItem(
                    icon: Icons.calendar_today_rounded,
                    label: DateFormat('dd MMM yyyy').format(grievance.createdAt!),
                  ),
                if (grievance.areaName != null)
                  _MetaItem(icon: Icons.location_on_outlined, label: grievance.areaName!),
                if (hasWorkproof)
                  _MetaItem(
                    icon: Icons.attachment_rounded,
                    label: '${grievance.workproofs!.length} proof${grievance.workproofs!.length > 1 ? 's' : ''}',
                    color: AppTheme.success,
                  ),
              ],
            ),
          ),

          // Action row
          if (transitions.isNotEmpty || status != 'resolved') ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.sm),
              child: Row(
                children: [
                  // Upload proof
                  OutlinedButton.icon(
                    onPressed: () => _uploadWorkproofDialog(context, grievance, onRefresh),
                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                    label: const Text('Add Proof'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      minimumSize: const Size(0, 36),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  // Transition buttons
                  ...transitions.map((next) => _TransitionButton(
                    label: AppStatus.labelFromStatus(next),
                    color: AppStatus.fromStatus(next),
                    enabled: next == 'resolved' ? hasWorkproof : true,
                    tooltip: next == 'resolved' && !hasWorkproof ? 'Upload proof first' : null,
                    onTap: () => _doTransition(context, grievance, next, onRefresh),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transition button
// ─────────────────────────────────────────────────────────────────────────────

class _TransitionButton extends StatelessWidget {
  const _TransitionButton({
    required this.label,
    required this.color,
    required this.enabled,
    this.tooltip,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool enabled;
  final String? tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final btn = Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: ElevatedButton(
          onPressed: enabled ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.15),
            foregroundColor: color,
            side: BorderSide(color: color.withOpacity(0.6)),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            minimumSize: const Size(0, 36),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
          child: Text(label),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Upload work proof dialog
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _uploadWorkproofDialog(
    BuildContext context, Grievance g, VoidCallback onRefresh) async {
  final notesCtrl = TextEditingController();
  List<PlatformFile> picked = [];

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.base),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).dividerColor,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),

            Text('Upload Work Proof', style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Attach images or video as evidence of work done',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xl),

            // File picker
            OutlinedButton.icon(
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(picked.isEmpty ? 'Select Files' : 'Change Files (${picked.length} selected)'),
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'pdf'],
                  withData: kIsWeb,
                );
                if (result != null) setSheet(() => picked = result.files);
              },
            ),

            if (picked.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ...picked.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(children: [
                  Icon(
                    ['mp4', 'mov'].contains(f.extension?.toLowerCase())
                        ? Icons.videocam_outlined : Icons.image_outlined,
                    size: 16,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(f.name,
                      style: Theme.of(ctx).textTheme.bodySmall,
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text('${(f.size / 1024).toStringAsFixed(0)} KB',
                      style: Theme.of(ctx).textTheme.labelSmall),
                ]),
              )),
            ],

            const SizedBox(height: AppSpacing.base),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Work notes (optional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              maxLines: 3,
              minLines: 2,
            ),
            const SizedBox(height: AppSpacing.xl),

            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: picked.isEmpty ? null : () async {
                    Navigator.pop(ctx);
                    await _uploadWorkproof(context, g.id, picked, notesCtrl.text.trim());
                    onRefresh();
                  },
                  child: const Text('Upload'),
                ),
              ),
            ]),
          ],
        ),
      ),
    ),
  );
}

Future<void> _uploadWorkproof(
    BuildContext context, int id, List<PlatformFile> files, String notes) async {
  try {
    for (final f in files) {
      await ApiService.postMultipart(
          '/grievances/$id/workproof',
          files: [f], fieldName: 'file', data: {'notes': notes});
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${files.length} file${files.length > 1 ? 's' : ''} uploaded'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.success,
      ));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Upload failed: $e'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.error,
      ));
    }
  }
}

Future<void> _doTransition(
    BuildContext context, Grievance g, String next, VoidCallback onRefresh) async {
  try {
    await ApiService.put('/grievances/${g.id}/status', {'status': next});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Status updated to ${AppStatus.labelFromStatus(next)}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppStatus.fromStatus(next),
      ));
    }
    onRefresh();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Update failed: $e'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.error,
      ));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label, required this.value,
    required this.selected, required this.onSelected,
  });
  final String label, value, selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final active = selected == value;
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => onSelected(value),
        selectedColor: primary.withOpacity(0.15),
        checkmarkColor: primary,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? primary : null,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.45);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: c),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 11, color: c)),
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined,
                size: 72, color: theme.colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: AppSpacing.base),
            Text('No Assignments', style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            )),
            const SizedBox(height: AppSpacing.sm),
            Text('Nothing assigned to you right now',
                style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: AppTheme.error),
            const SizedBox(height: AppSpacing.base),
            Text(error, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
