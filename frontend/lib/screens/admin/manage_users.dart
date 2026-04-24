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

  Color _roleColor(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':        return _danger;
      case 'SUPER_USER':   return _purple;
      case 'MEMBER_HEAD':  return _warning;
      case 'FIELD_STAFF':  return dsAccent;
      default:             return _success; // CITIZEN
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
          backgroundColor: dsSurface,
          title: Text(l10n.addUser, style: const TextStyle(color: dsTextPrimary)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogTextField(
                      labelText: 'Name',
                      prefixIcon: Icons.person_outline,
                      validator: validateRequired,
                      onChanged: (v) => name = v,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildDialogTextField(
                      labelText: 'Email',
                      prefixIcon: Icons.email_outlined,
                      validator: validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) => email = v,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildDialogTextField(
                      labelText: 'Phone',
                      prefixIcon: Icons.phone_outlined,
                      validator: validateRequired,
                      keyboardType: TextInputType.phone,
                      onChanged: (v) => phone = v,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildDialogTextField(
                      labelText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      validator: validateRequired,
                      obscureText: true,
                      onChanged: (v) => password = v,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      dropdownColor: dsSurface,
                      style: const TextStyle(color: dsTextPrimary),
                      decoration: InputDecoration(
                        labelText: 'Role',
                        labelStyle: const TextStyle(color: dsTextSecondary),
                        filled: true,
                        fillColor: dsSurfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dsBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: dsAccent, width: 2),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'CITIZEN',     child: Text('Citizen', style: TextStyle(color: dsTextPrimary))),
                        DropdownMenuItem(value: 'FIELD_STAFF', child: Text('Field Staff', style: TextStyle(color: dsTextPrimary))),
                        DropdownMenuItem(value: 'MEMBER_HEAD', child: Text('Member Head', style: TextStyle(color: dsTextPrimary))),
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
              style: TextButton.styleFrom(foregroundColor: dsTextSecondary),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: dsAccent,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.addUser),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTextField({
    required String labelText,
    required IconData prefixIcon,
    required String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      style: const TextStyle(color: dsTextPrimary),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: dsTextSecondary),
        prefixIcon: Icon(prefixIcon, color: dsAccent),
        filled: true,
        fillColor: dsSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dsBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dsAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _danger, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
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
          backgroundColor: dsSurface,
          title: Text(l10n.editUser, style: const TextStyle(color: dsTextPrimary)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogTextField(
                      labelText: 'Name',
                      prefixIcon: Icons.person_outline,
                      validator: validateRequired,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildDialogTextField(
                      labelText: 'Email',
                      prefixIcon: Icons.email_outlined,
                      validator: validateEmail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      dropdownColor: dsSurface,
                      style: const TextStyle(color: dsTextPrimary),
                      decoration: InputDecoration(
                        labelText: 'Role',
                        labelStyle: const TextStyle(color: dsTextSecondary),
                        filled: true,
                        fillColor: dsSurfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dsBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: dsAccent, width: 2),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'CITIZEN',     child: Text('Citizen', style: TextStyle(color: dsTextPrimary))),
                        DropdownMenuItem(value: 'FIELD_STAFF', child: Text('Field Staff', style: TextStyle(color: dsTextPrimary))),
                        DropdownMenuItem(value: 'MEMBER_HEAD', child: Text('Member Head', style: TextStyle(color: dsTextPrimary))),
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
              style: TextButton.styleFrom(foregroundColor: dsTextSecondary),
              child: Text(l10n.cancel),
            ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: dsAccent,
                foregroundColor: Colors.white,
              ),
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
        backgroundColor: dsSurface,
        title: Text(l10n.deleteUser, style: const TextStyle(color: dsTextPrimary)),
        content: Text(l10n.deleteUserConfirmation, style: const TextStyle(color: dsTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: dsTextSecondary),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
            ),
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
    final currentUser = ref.watch(userNotifierProvider);

    return AppShell(
      title: l10n.manageUsers,
      currentRoute: '/admin/users',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: dsAccent),
          onPressed: () => ref.read(usersProvider.notifier).fetchUsers(),
          tooltip: l10n.retry,
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        tooltip: l10n.addUser,
        backgroundColor: dsAccent,
        foregroundColor: Colors.white,
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
            child: _buildSearchField(l10n),
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
                : _buildList(users, currentUser, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(AppLocalizations l10n) {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: dsTextPrimary),
      decoration: InputDecoration(
        hintText: l10n.searchByNameOrEmail,
        hintStyle: const TextStyle(color: dsTextSecondary),
        prefixIcon: const Icon(Icons.search_rounded, color: dsAccent),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, color: dsTextSecondary),
                onPressed: () => setState(() => _searchController.clear()),
              )
            : null,
        filled: true,
        fillColor: dsSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dsBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dsAccent, width: 2),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildList(List<User> users, User? currentUser, AppLocalizations l10n) {
    final query = _searchController.text.toLowerCase();
    final filtered = users.where((u) {
      if (u.id == currentUser?.id) return false;
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
        roleColor: _roleColor(filtered[i].role),
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
    return Container(
      decoration: BoxDecoration(
        color: dsSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dsBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black..withValues(alpha:0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: roleColor..withValues(alpha:0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              (user.name?.isNotEmpty == true ? user.name![0] : '?').toUpperCase(),
              style: TextStyle(
                color: roleColor,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          user.name ?? '',
          style: const TextStyle(
            color: dsTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              user.email ?? l10n.noEmail,
              style: const TextStyle(color: dsTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: roleColor..withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                roleLabel,
                style: TextStyle(
                  color: roleColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: dsAccent, size: 20),
              onPressed: onEdit,
              tooltip: l10n.editUser,
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: isSelf ? dsTextSecondary.withValues(alpha:0.5) : _danger,
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

// Status colors matching theme
const Color _success = Color(0xFF10B981);
const Color _warning = Color(0xFFF59E0B);
const Color _danger = Color(0xFFEF4444);
const Color _purple = Color(0xFF8B5CF6);