import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/layouts/app_shell.dart';
import 'package:main_ui/providers/admin_provider.dart';
import 'package:main_ui/theme/app_theme.dart';
import 'package:main_ui/widgets/app/app_button.dart';
import 'package:main_ui/widgets/empty_state.dart';

class ManageConfigs extends ConsumerStatefulWidget {
  const ManageConfigs({super.key});
  @override
  ConsumerState<ManageConfigs> createState() => _ManageConfigsState();
}

class _ManageConfigsState extends ConsumerState<ManageConfigs> {
  final _keyCtrl   = TextEditingController();
  final _valueCtrl = TextEditingController();

  @override
  void dispose() { _keyCtrl.dispose(); _valueCtrl.dispose(); super.dispose(); }

  void _showAddConfigDialog() {
    _keyCtrl.clear(); _valueCtrl.clear();
    _openDialog(title: 'Add Configuration', keyEditable: true,
        onSave: (k, v) => ref.read(adminProvider.notifier).addConfig(k, v));
  }

  void _showEditConfigDialog(Config config) {
    _keyCtrl.text = config.key; _valueCtrl.text = config.value;
    _openDialog(title: 'Edit Configuration', keyEditable: false,
        onSave: (k, v) => ref.read(adminProvider.notifier).addConfig(k, v));
  }

  void _openDialog({
    required String title,
    required bool keyEditable,
    required Future<void> Function(String, String) onSave,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: dsSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: dsAccent.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: dsTextPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: _keyCtrl, enabled: keyEditable,
                style: const TextStyle(color: dsTextPrimary),
                decoration: const InputDecoration(labelText: 'Key')),
            const SizedBox(height: 14),
            TextField(controller: _valueCtrl,
                style: const TextStyle(color: dsTextPrimary),
                decoration: const InputDecoration(labelText: 'Value')),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: dsTextSecondary))),
              const SizedBox(width: 12),
              AppButton(text: 'Save', onPressed: () async {
                final k = _keyCtrl.text.trim(); final v = _valueCtrl.text.trim();
                if (k.isEmpty || v.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Both fields required')));
                  return;
                }
                try {
                  await onSave(k, v);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved'), backgroundColor: Colors.green));
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              }),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state   = ref.watch(adminProvider);
    final configs = state.configs;

    return AppShell(
      title: 'Manage Configurations',
      currentRoute: '/admin/configs',
      backgroundColor: dsBackground,
      appBarBackgroundColor: dsSurface,
      appBarForegroundColor: dsTextPrimary,
      actions: [
        IconButton(icon: const Icon(Icons.add, color: dsAccentSoft),
            onPressed: _showAddConfigDialog, tooltip: 'Add Config'),
      ],
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: EmptyState(icon: Icons.error_outline, title: 'Error',
                  message: state.error!,
                  actionButton: AppButton(text: 'Retry',
                      onPressed: () => ref.read(adminProvider.notifier).getConfigs(),
                      icon: Icons.refresh)))
              : configs.isEmpty
                  ? Center(child: EmptyState(icon: Icons.settings_outlined,
                      title: 'No Configurations', message: 'Add key-value configs to start.',
                      actionButton: AppButton(text: 'Add Config',
                          onPressed: _showAddConfigDialog, icon: Icons.add)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: configs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final c = configs[i];
                        return Container(
                          decoration: dsPanelDecoration(color: dsSurfaceAlt),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(c.key, style: const TextStyle(
                                color: dsAccentSoft, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                            subtitle: Text(c.value, style: const TextStyle(color: dsTextPrimary)),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_outlined, color: dsAccentSoft),
                              onPressed: () => _showEditConfigDialog(c),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
