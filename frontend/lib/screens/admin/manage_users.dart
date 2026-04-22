import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/models/user_model.dart';
import 'package:main_ui/utils/validators.dart';
import 'package:main_ui/widgets/app/app_button.dart';
import 'package:main_ui/widgets/empty_state.dart';
import 'package:main_ui/widgets/loading_indicator.dart';
import 'package:main_ui/providers/user_provider.dart';
import 'package:main_ui/layouts/app_shell.dart';
import 'package:main_ui/theme/app_theme.dart';

class ManageUsers extends ConsumerStatefulWidget {
  const ManageUsers({super.key});

  @override
  ConsumerState<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends ConsumerState<ManageUsers> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─────────── Role UI helpers ─────────────────────────────────────────────

  Color _roleColor(ColorScheme s, String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':        return AppTheme.error;
      case 'SUPER_USER':   return const Color(0xFF7C3AED);
      case 'MEMBER_HEAD':  return AppTheme.warning;
      case 'FIELD_STAFF':  return s.secondary;
      default:             return s.primary; // CITIZEN
    }
  }

  String _roleLabel(String? role, AppLocalizations l10n) {
    if (role == null) return '';
    switch (role.toLowerCase()) {
      case 'member_head': return l10n.roleSupervisor;
      default:            return role.toUpperCase();
    }
  }

  // ─────────── Add user dialog ──────────────────────────────────────────────

  Future<void> _showAddUserDialog() async {
    final l10n   = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    String name = '', email = '', phone = '', password = '';
    String role = 'CITIZEN';
    String? departmentId;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(l10n.addUser),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline)),
                      validator: validateRequired,
                      onChanged: (v) => name = v,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                      validator: validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) => email = v,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
                      validator: validateRequired,
                      keyboardType: TextInputType.phone,
                      onChanged: (v) => phone = v,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                      validator: validateRequired,
                      obscureText: true,
                      onChanged: (v) => password = v,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(value: 'CITIZEN',     child: Text('Citizen')),
                        DropdownMenuItem(value: 'FIELD_STAFF', child: Text('Field Staff')),
                        DropdownMenuItem(value: 'MEMBER_HEAD', child: Text('Member Head')),
                        // ADMIN intentionally excluded — admins are created via backend only
                      ],
                      onChanged: (v) => setDlg(() => role = v ?? 'CITIZEN'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                await ref.read(usersProvider.notifier).addUser({
                  'name': name.trim(),
                  'email': email.trim(),
                  'phone_number': phone.trim(),
                  'password': password,
                  'role': role,
                  'department_id': departmentId,
                });
              },
              child: Text(l10n.addUser),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditUserDialog(User user) async {
    final l10n    = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final nameCtrl  = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    String role     = user.role ?? 'CITIZEN';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(l10n.editUser),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline)),
                      validator: validateRequired,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                      validator: validateEmail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(value: 'CITIZEN',     child: Text('Citizen')),
                        DropdownMenuItem(value: 'FIELD_STAFF', child: Text('Field Staff')),
                        DropdownMenuItem(value: 'MEMBER_HEAD', child: Text('Member Head')),
                        // ADMIN intentionally excluded — admins are created via backend only
                      ],
                      onChanged: (v) => setDlg(() => role = v ?? 'CITIZEN'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                await ref.read(usersProvider.notifier).updateUser(
                  user.id,
                  {
                    'id': user.id,
                    'name': nameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'role': role,
                  },
                );
              },
              child: Text(l10n.update),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(int? userId) async {
    if (userId == null) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteUser),
        content: Text(l10n.deleteUserConfirmation),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(usersProvider.notifier).deleteUser(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n        = AppLocalizations.of(context)!;
    final users       = ref.watch(usersProvider);
    final theme       = Theme.of(context);
    final currentUser = ref.watch(userNotifierProvider);

    return AppShell(
      title: l10n.manageUsers,
      currentRoute: '/admin/users',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => ref.read(usersProvider.notifier).fetchUsers(),
          tooltip: l10n.retry,
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        tooltip: l10n.addUser,
        child: const Icon(Icons.person_add_outlined),
      ),
      child: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, AppSpacing.base,
              AppSpacing.base, AppSpacing.xs,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchByNameOrEmail,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _searchController.clear()),
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // ── List ──────────────────────────────────────────────────────
          Expanded(
            child: users.isEmpty
                ? EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: l10n.noUsers,
                    message: l10n.noUsersMessage,
                    actionButton: AppButton(
                      text: l10n.addUser,
                      onPressed: _showAddUserDialog,
                    ),
                  )
                : _buildList(users, currentUser, theme, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<User> users, User? currentUser, ThemeData theme, AppLocalizations l10n) {
    final query   = _searchController.text.toLowerCase();
    // Exclude the currently logged-in admin from the list
    final filtered = users.where((u) {
      if (u.id == currentUser?.id) return false;  // hide self
      if (query.isEmpty) return true;
      return (u.name?.toLowerCase().contains(query) ?? false) ||
             (u.email?.toLowerCase().contains(query) ?? false);
    }).toList();

    if (filtered.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: l10n.noResultsFound,
        message: l10n.noMatchingUsers,
        actionButton: AppButton(
          text: 'Clear search',
          onPressed: () => setState(() => _searchController.clear()),
          variant: AppButtonVariant.outlined,
          size: AppButtonSize.small,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base, AppSpacing.xs,
        AppSpacing.base, AppSpacing.xxxl,
      ),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _UserCard(
        user: filtered[i],
        isSelf: currentUser?.id == filtered[i].id,
        roleColor: _roleColor(theme.colorScheme, filtered[i].role),
        roleLabel: _roleLabel(filtered[i].role, l10n),
        onEdit: () => _showEditUserDialog(filtered[i]),
        onDelete: () => _confirmDelete(filtered[i].id),
        l10n: l10n,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.isSelf,
    required this.roleColor,
    required this.roleLabel,
    required this.onEdit,
    required this.onDelete,
    required this.l10n,
  });

  final User user;
  final bool isSelf;
  final Color roleColor;
  final String roleLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
        leading: CircleAvatar(
          backgroundColor: primary.withOpacity(0.12),
          child: Text(
            (user.name?.isNotEmpty == true ? user.name![0] : '?').toUpperCase(),
            style: TextStyle(color: primary, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(user.name ?? '', style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(user.email ?? l10n.noEmail, style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                roleLabel,
                style: TextStyle(
                  color: roleColor, fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: primary, size: 20),
              onPressed: onEdit,
              tooltip: l10n.editUser,
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: isSelf ? theme.disabledColor : AppTheme.error,
                size: 20,
              ),
              onPressed: isSelf ? null : onDelete,
              tooltip: l10n.deleteUser,
            ),
          ],
        ),
      ),
    );
  }
}
