import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/layouts/app_shell.dart';
import 'package:main_ui/models/master_data_model.dart';
import 'package:main_ui/services/master_data_service.dart';
import 'package:main_ui/theme/app_theme.dart';
import 'package:main_ui/widgets/app/app_button.dart';
import 'package:main_ui/widgets/empty_state.dart';

class ManageSubjects extends ConsumerStatefulWidget {
  const ManageSubjects({super.key});

  @override
  ConsumerState<ManageSubjects> createState() => _ManageSubjectsState();
}

class _ManageSubjectsState extends ConsumerState<ManageSubjects> {
  // ── Dialog: add or edit ──────────────────────────────────────────────────
  void _showSubjectDialog({MasterSubject? subject}) {
    final nameCtrl = TextEditingController(text: subject?.name ?? '');
    final descCtrl = TextEditingController(text: subject?.description ?? '');
    final formKey  = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: dsSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: dsAccent.withValues(alpha: 0.3)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject == null ? 'Add Subject' : 'Edit Subject',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: dsTextPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameCtrl,
                  style: const TextStyle(color: dsTextPrimary),
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: descCtrl,
                  style: const TextStyle(color: dsTextPrimary),
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel', style: TextStyle(color: dsTextSecondary)),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    text: 'Save',
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final data = {
                        'name': nameCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                      };
                      try {
                        if (subject == null) {
                          await MasterDataService.addSubject(data);
                        } else {
                          await MasterDataService.updateSubject(subject.id, data);
                        }
                        ref.invalidate(subjectsProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Error: \$e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Delete confirm ───────────────────────────────────────────────────────
  Future<void> _confirmDelete(MasterSubject subject) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dsSurface,
        title: const Text('Delete Subject', style: TextStyle(color: dsTextPrimary)),
        content: Text(
          'Delete "\${subject.name}"? This will fail if grievances reference it.',
          style: const TextStyle(color: dsTextSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await MasterDataService.deleteSubject(subject.id);
      ref.invalidate(subjectsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: \$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return AppShell(
      title: 'Manage Subjects',
      currentRoute: '/admin/subjects',
      backgroundColor: dsBackground,
      appBarBackgroundColor: dsSurface,
      appBarForegroundColor: dsTextPrimary,
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: dsAccentSoft),
          onPressed: _showSubjectDialog,
          tooltip: 'Add Subject',
        ),
      ],
      child: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading Subjects',
            message: e.toString(),
            actionButton: AppButton(
              text: 'Retry',
              onPressed: () => ref.refresh(subjectsProvider),
              icon: Icons.refresh,
            ),
          ),
        ),
        data: (subjects) {
          if (subjects.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.category_outlined,
                title: 'No Subjects',
                message: 'Add a subject to get started.',
                actionButton: AppButton(
                  text: 'Add Subject',
                  onPressed: _showSubjectDialog,
                  icon: Icons.add,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final s = subjects[i];
              return Container(
                decoration: dsPanelDecoration(color: dsSurfaceAlt),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  title: Text(s.name,
                      style: const TextStyle(color: dsTextPrimary, fontWeight: FontWeight.w600)),
                  subtitle: s.description != null && s.description!.isNotEmpty
                      ? Text(s.description!,
                            style: const TextStyle(color: dsTextSecondary),
                            maxLines: 2, overflow: TextOverflow.ellipsis)
                      : null,
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: dsAccentSoft),
                      onPressed: () => _showSubjectDialog(subject: s),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _confirmDelete(s),
                      tooltip: 'Delete',
                    ),
                  ]),
                  onTap: () => _showSubjectDialog(subject: s),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
