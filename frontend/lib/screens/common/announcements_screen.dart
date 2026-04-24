import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:main_ui/layouts/app_shell.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/models/announcement_model.dart';
import 'package:main_ui/providers/user_provider.dart';
import 'package:main_ui/services/api_service.dart';
import 'package:main_ui/theme/app_theme.dart';

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final response = await ApiService.get('/admins/announcements');
  return (response.data as List)
      .map((json) => Announcement.fromJson(json))
      .toList();
});

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _type = 'general';
  DateTime? _expiresAt;
  String? _targetRole;

  void _showAddAnnouncementDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final localizations = AppLocalizations.of(context)!;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: dsPanelDecoration(color: dsSurface, radius: 20),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.addAnnouncement,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: dsTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Share timely updates with the right audience using the same civic design language as the rest of the app.',
                      style: TextStyle(
                        fontSize: 14,
                        color: dsTextSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: dsTextPrimary),
                      cursorColor: dsAccent,
                      decoration: dsFormFieldDecoration(label: localizations.title),
                      validator: (value) => value!.isEmpty ? localizations.error : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _messageController,
                      style: const TextStyle(color: dsTextPrimary),
                      cursorColor: dsAccent,
                      decoration: dsFormFieldDecoration(label: localizations.message),
                      validator: (value) => value!.isEmpty ? localizations.error : null,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _type,
                      dropdownColor: dsSurface,
                      style: const TextStyle(fontSize: 14, color: dsTextPrimary),
                      iconEnabledColor: dsAccentSoft,
                      items: ['general', 'emergency']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                type.capitalize(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: dsTextPrimary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _type = value!),
                      decoration: dsFormFieldDecoration(label: localizations.type),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: dsPanelDecoration(color: dsSurfaceAlt, radius: 12),
                      child: ListTile(
                        title: Text(
                          _expiresAt == null
                              ? localizations.selectExpiration
                              : DateFormat('yyyy-MM-dd').format(_expiresAt!),
                          style: const TextStyle(fontSize: 14, color: dsTextPrimary),
                        ),
                        trailing: const Icon(
                          Icons.calendar_today_rounded,
                          size: 20,
                          color: dsAccentSoft,
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.dark().copyWith(
                                   dialogTheme: DialogThemeData(
    backgroundColor: dsSurface,
  ),
                                  colorScheme: const ColorScheme.dark(
                                    primary: dsAccent,
                                    secondary: dsAccentSoft,
                                    surface: dsSurface,
                                    onPrimary: dsBackground,
                                    onSurface: dsTextPrimary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() => _expiresAt = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _targetRole,
                      dropdownColor: dsSurface,
                      style: const TextStyle(fontSize: 14, color: dsTextPrimary),
                      iconEnabledColor: dsAccentSoft,
                      items: const [
                        {'label': 'CITIZEN', 'value': 'citizen'},
                        {'label': 'SUPERVISOR', 'value': 'member_head'},
                        {'label': 'FIELD_STAFF', 'value': 'field_staff'},
                        {'label': 'ADMIN', 'value': 'admin'},
                      ]
                          .map(
                            (role) => DropdownMenuItem(
                              value: role['value'],
                              child: Text(
                                role['label']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: dsTextPrimary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _targetRole = value),
                      decoration: dsFormFieldDecoration(label: localizations.targetRole),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(foregroundColor: dsTextSecondary),
                          child: Text(localizations.cancel),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final data = {
                                'title': _titleController.text,
                                'message': _messageController.text,
                                'type': _type,
                                'expires_at': _expiresAt?.toIso8601String(),
                                'target_role': _targetRole,
                                'is_active': true,
                              };

                              try {
                                await ApiService.post('/admins/announcements', data);
                                ref.refresh(announcementsProvider);
                                if (!mounted) return;
                                Navigator.pop(context);
                                _titleController.clear();
                                _messageController.clear();
                                _type = 'general';
                                _expiresAt = null;
                                _targetRole = null;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(localizations.announcementAdded),
                                    backgroundColor: AppTheme.success,
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: AppTheme.error,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dsAccent,
                            foregroundColor: dsTextPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.campaign_rounded, size: 18),
                          label: Text(localizations.submit),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteAnnouncement(int id) async {
    final localizations = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dsSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          localizations.confirmDelete,
          style: const TextStyle(
            color: dsTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this announcement?',
          style: TextStyle(
            color: dsTextSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: dsTextSecondary),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: dsTextPrimary,
            ),
            child: Text(localizations.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.delete('/admins/announcements/$id');
        ref.refresh(announcementsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Announcement deleted successfully'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final user = ref.watch(userNotifierProvider);
    final isAdmin = user?.role?.toUpperCase() == 'ADMIN';
    final announcementsAsync = ref.watch(announcementsProvider);

    return AppShell(
      title: localizations.announcements,
      currentRoute: '/announcements',
      bottomNavCurrentRoute: '/profile',
      backgroundColor: dsBackground,
      appBarBackgroundColor: dsSurface,
      appBarForegroundColor: dsTextPrimary,
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _showAddAnnouncementDialog,
              backgroundColor: dsAccent,
              foregroundColor: dsTextPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.add),
            )
          : null,
      child: announcementsAsync.when(
        data: (announcements) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(localizations, announcements.length, isAdmin),
            const SizedBox(height: 20),
            if (announcements.isEmpty)
              _buildStateCard(
                icon: Icons.announcement_outlined,
                title: localizations.noAnnouncements,
                subtitle: 'New civic updates and department notices will appear here.',
              )
            else
              ...announcements.map(
                (announcement) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildAnnouncementCard(announcement, isAdmin),
                ),
              ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: dsAccent),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildStateCard(
              icon: Icons.error_outline_rounded,
              title: localizations.error,
              subtitle: '$err',
              accent: AppTheme.error,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations localizations, int count, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: dsPanelDecoration(color: dsSurface, radius: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: dsAccent.withValues(alpha:0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: dsAccent.withValues(alpha:0.35)),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: dsAccentSoft,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.announcements,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: dsTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAdmin
                      ? 'Publish civic notices, emergency alerts, and role-based updates from one consistent admin surface.'
                      : 'Stay up to date with official notices, service alerts, and department updates.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: dsTextSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: dsSurfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: dsBorder),
            ),
            child: Column(
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: dsTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 12,
                    color: dsTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement, bool isAdmin) {
    final accent = announcement.type == 'emergency' ? AppTheme.error : dsAccentSoft;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: dsPanelDecoration(color: dsSurfaceAlt, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha:0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha:0.28)),
                ),
                child: Icon(
                  announcement.type == 'emergency'
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline_rounded,
                  color: accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: dsTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      announcement.message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: dsTextSecondary,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAdmin)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.error,
                    size: 22,
                  ),
                  onPressed: () => _deleteAnnouncement(announcement.id),
                  tooltip: 'Delete Announcement',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetaChip(
                icon: announcement.type == 'emergency'
                    ? Icons.priority_high_rounded
                    : Icons.push_pin_outlined,
                label: announcement.type.capitalize(),
                color: accent,
              ),
              _buildMetaChip(
                icon: Icons.calendar_today_rounded,
                label: 'Posted ${DateFormat('dd MMM yyyy').format(announcement.createdAt)}',
              ),
              if (announcement.expiresAt != null)
                _buildMetaChip(
                  icon: Icons.timer_outlined,
                  label: 'Expires ${DateFormat('dd MMM yyyy').format(announcement.expiresAt!)}',
                  color: const Color(0xFFF59E0B),
                ),
              if (announcement.targetRole != null && announcement.targetRole!.isNotEmpty)
                _buildMetaChip(
                  icon: Icons.groups_rounded,
                  label: _formatRole(announcement.targetRole!),
                ),
              _buildMetaChip(
                icon: announcement.isActive
                    ? Icons.check_circle_outline_rounded
                    : Icons.block_outlined,
                label: announcement.isActive ? 'Active' : 'Inactive',
                color: announcement.isActive ? AppTheme.success : AppTheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    Color color = dsTextSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: dsSurface.withValues(alpha:0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: dsBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Color accent = dsAccentSoft,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: dsPanelDecoration(color: dsSurface, radius: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accent.withValues(alpha:0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 32, color: accent),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: dsTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: dsTextSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatRole(String role) {
    return role
        .split('_')
        .where((segment) => segment.isNotEmpty)
        .map((segment) => segment.capitalize())
        .join(' ');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
