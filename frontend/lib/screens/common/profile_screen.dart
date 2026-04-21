import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/services/api_service.dart';
import 'package:main_ui/services/auth_service.dart';
import 'package:main_ui/widgets/app/app_button.dart';
import 'package:main_ui/widgets/loading_indicator.dart';
import 'package:main_ui/widgets/file_upload_widget.dart';
import 'package:main_ui/models/user_model.dart';
import 'package:main_ui/providers/user_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:main_ui/utils/constants.dart';
import 'package:main_ui/layouts/app_shell.dart';
import 'package:main_ui/theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  PlatformFile? _profilePic;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userNotifierProvider);
    _nameController    = TextEditingController(text: user?.name);
    _emailController   = TextEditingController(text: user?.email);
    _addressController = TextEditingController(text: user?.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final updatedUser = await ApiService.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: null,
        address: _addressController.text.trim(),
        profilePic: _profilePic,
      );
      ref.read(userNotifierProvider.notifier).setUser(updatedUser);
      setState(() { _isEditing = false; _profilePic = null; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.userUpdatedSuccess),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update profile: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final user  = ref.watch(userNotifierProvider);

    return AppShell(
      title: l10n.profile,
      currentRoute: '/profile',
      actions: [
        if (user != null)
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: l10n.logout,
            onPressed: _isLoading ? null : () async {
              setState(() => _isLoading = true);
              try {
                await AuthService.logout();
                ref.read(userNotifierProvider.notifier).setUser(null);
                if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n.logoutFailed),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
          ),
      ],
      child: _isLoading
          ? const LoadingIndicator()
          : user == null
              ? _NotLoggedIn(l10n: l10n)
              : _ProfileBody(
                  user: user,
                  l10n: l10n,
                  formKey: _formKey,
                  nameController: _nameController,
                  emailController: _emailController,
                  addressController: _addressController,
                  profilePic: _profilePic,
                  isEditing: _isEditing,
                  onEditToggle: () => setState(() => _isEditing = true),
                  onCancelEdit: () => setState(() {
                    _isEditing = false;
                    _nameController.text    = user.name ?? '';
                    _emailController.text   = user.email ?? '';
                    _addressController.text = user.address ?? '';
                    _profilePic = null;
                  }),
                  onSave: _updateProfile,
                  onPickPhoto: () => showModalBottomSheet(
                    context: context,
                    builder: (_) => FileUploadWidget(
                      onFilesSelected: (files) {
                        if (files.isNotEmpty) {
                          setState(() => _profilePic = files.first);
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.user,
    required this.l10n,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.addressController,
    required this.profilePic,
    required this.isEditing,
    required this.onEditToggle,
    required this.onCancelEdit,
    required this.onSave,
    required this.onPickPhoto,
  });

  final User user;
  final AppLocalizations l10n;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final PlatformFile? profilePic;
  final bool isEditing;
  final VoidCallback onEditToggle;
  final VoidCallback onCancelEdit;
  final VoidCallback onSave;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base, AppSpacing.xl,
        AppSpacing.base, AppSpacing.xxxl,
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Avatar header ─────────────────────────────────────────────
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: primary.withOpacity(0.12),
                    backgroundImage: user.profilePicture != null
                        ? NetworkImage('${Constants.baseUrl}/uploads/${user.profilePicture}')
                        : null,
                    child: user.profilePicture == null
                        ? Text(
                            (user.name?.isNotEmpty == true
                                ? user.name![0]
                                : '?').toUpperCase(),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          )
                        : null,
                  ),
                  if (isEditing)
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: onPickPhoto,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.base),

            Text(
              user.name ?? l10n.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  (user.role ?? 'CITIZEN').toUpperCase(),
                  style: TextStyle(
                    color: primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ── Info card ─────────────────────────────────────────────────
            _InfoCard(
              children: [
                _Field(
                  icon: Icons.email_outlined,
                  label: l10n.email,
                  value: user.email,
                  controller: emailController,
                  isEditing: isEditing,
                  validator: (v) => v == null || !v.contains('@') ? l10n.invalidEmail : null,
                  keyboardType: TextInputType.emailAddress,
                ),
                const Divider(height: 1),
                _Field(
                  icon: Icons.person_outline_rounded,
                  label: l10n.name,
                  value: user.name,
                  controller: nameController,
                  isEditing: isEditing,
                  validator: (v) => v == null || v.isEmpty ? l10n.nameRequired : null,
                  textCapitalization: TextCapitalization.words,
                ),
                const Divider(height: 1),
                _Field(
                  icon: Icons.location_on_outlined,
                  label: l10n.address,
                  value: user.address,
                  controller: addressController,
                  isEditing: isEditing,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.access_time_rounded, color: primary, size: 20),
                  title: Text(l10n.lastLogin, style: theme.textTheme.bodyMedium),
                  subtitle: Text(
                    user.lastLogin != null
                        ? DateFormat('dd MMM yyyy  HH:mm').format(user.lastLogin!)
                        : l10n.notApplicable,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.verified_user_outlined, color: primary, size: 20),
                  title: Text(l10n.accountStatus, style: theme.textTheme.bodyMedium),
                  subtitle: Text(
                    user.isActive ? l10n.statusActive : l10n.statusInactive,
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (user.isActive ? AppTheme.success : AppTheme.error).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      user.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: user.isActive ? AppTheme.success : AppTheme.error,
                        fontSize: 11, fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (user.departmentId != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.location_city_outlined, color: primary, size: 20),
                    title: Text(l10n.department, style: theme.textTheme.bodyMedium),
                    subtitle: FutureBuilder(
                      future: ApiService.getMasterArea(user.departmentId!),
                      builder: (_, snap) => Text(
                        snap.connectionState == ConnectionState.waiting
                            ? 'Loading…'
                            : snap.data?['name'] ?? l10n.statusUnknown,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ── Action buttons ────────────────────────────────────────────
            if (isEditing)
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: l10n.cancel,
                      onPressed: onCancelEdit,
                      variant: AppButtonVariant.outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      text: l10n.update,
                      icon: Icons.save_outlined,
                      onPressed: onSave,
                    ),
                  ),
                ],
              )
            else
              AppButton(
                text: l10n.editProfile,
                icon: Icons.edit_outlined,
                onPressed: onEditToggle,
                fullWidth: true,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile field — shows read value or editable TextFormField
// ─────────────────────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  const _Field({
    required this.icon,
    required this.label,
    required this.value,
    required this.controller,
    required this.isEditing,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final IconData icon;
  final String label;
  final String? value;
  final TextEditingController controller;
  final bool isEditing;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (!isEditing) {
      return ListTile(
        leading: Icon(icon, color: primary, size: 20),
        title: Text(label, style: theme.textTheme.bodySmall),
        subtitle: Text(
          value ?? AppLocalizations.of(context)!.notApplicable,
          style: theme.textTheme.bodyMedium,
        ),
        visualDensity: VisualDensity.compact,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        validator: validator,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(children: children),
    );
  }
}

class _NotLoggedIn extends StatelessWidget {
  const _NotLoggedIn({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_circle_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: AppSpacing.base),
            Text(l10n.please_login,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: l10n.login,
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
