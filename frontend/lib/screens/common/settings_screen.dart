import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/providers/locale_provider.dart';
import 'package:main_ui/providers/user_provider.dart';
import 'package:main_ui/services/auth_service.dart';
import 'package:main_ui/services/api_service.dart';
import 'package:main_ui/utils/validators.dart';
import 'package:main_ui/widgets/app/app_button.dart';
import 'package:main_ui/widgets/loading_indicator.dart';
import 'package:main_ui/layouts/app_shell.dart';
import 'package:main_ui/theme/app_theme.dart';

// Status colors matching TrackGrievance
const Color _success = Color(0xFF10B981);
const Color _warning = Color(0xFFF59E0B);
const Color _danger = Color(0xFFEF4444);
const Color _purple = Color(0xFF8B5CF6);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isLoading = false;
  bool _isSaving  = false;
  final _formKey         = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _nameController     = TextEditingController();
    _emailController    = TextEditingController();
    _passwordController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/settings/');
      setState(() {
        _notificationsEnabled = response.data['notifications_enabled'] ?? true;
        final user = ref.read(userNotifierProvider);
        _nameController.text  = user?.name ?? '';
        _emailController.text = user?.email ?? '';
      });
    } catch (_) {
      // Settings failed to load — show what we have from provider
      final user = ref.read(userNotifierProvider);
      _nameController.text  = user?.name ?? '';
      _emailController.text = user?.email ?? '';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ApiService.post('/settings/', {
        'notifications_enabled': _notificationsEnabled,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
      });
      await ref.read(userNotifierProvider.notifier).updateUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Settings saved successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save settings: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context)!;
    final locale = ref.watch(localeNotifierProvider);

    return AppShell(
      title: l10n.settings,
      currentRoute: '/settings',
      bottomNavCurrentRoute: '/profile',
      appBarBackgroundColor: dsSurface,
      appBarForegroundColor: dsAccent,
      child: _isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base, AppSpacing.base,
                AppSpacing.base, AppSpacing.xxxl,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // ── Account details ─────────────────────────────────
                    const _SectionHeader(title: 'Account Details', icon: Icons.person_outline_rounded),
                    _SettingsCard(children: [
                      _buildFormField(
                        controller: _nameController,
                        labelText: 'Name',
                        prefixIcon: Icons.badge_outlined,
                        validator: validateRequired,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: AppSpacing.base),
                      _buildFormField(
                        controller: _emailController,
                        labelText: 'Email',
                        prefixIcon: Icons.email_outlined,
                        validator: validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: AppSpacing.base),
                      _buildFormField(
                        controller: _passwordController,
                        labelText: 'New Password (optional)',
                        prefixIcon: Icons.lock_outline_rounded,
                        hintText: 'Leave blank to keep current',
                        obscureText: true,
                      ),
                    ]),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Notifications ────────────────────────────────────
                    _SectionHeader(title: l10n.notifications, icon: Icons.notifications_outlined),
                    _SettingsCard(children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enable Notifications',
                            style: TextStyle(color: dsTextPrimary, fontSize: 14)),
                        subtitle: const Text('Receive push notifications for updates',
                            style: TextStyle(color: dsTextSecondary, fontSize: 12)),
                        value: _notificationsEnabled,
                        onChanged: (v) => setState(() => _notificationsEnabled = v),
                        activeColor: dsAccent,
                        activeTrackColor: dsAccent.withOpacity(0.4),
                        inactiveThumbColor: dsTextSecondary,
                        inactiveTrackColor: dsBorder,
                      ),
                    ]),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Language ─────────────────────────────────────────
                    _SectionHeader(title: l10n.language, icon: Icons.language_outlined),
                    _SettingsCard(children: [
                     Container(
  decoration: BoxDecoration(
    color: dsSurfaceAlt,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: dsBorder),
  ),
  child: DropdownButtonHideUnderline(
    child: DropdownButtonFormField<Locale>(
      value: locale,
      decoration: const InputDecoration(
        labelText: 'App Language',
        labelStyle: TextStyle(color: dsTextSecondary),
        prefixIcon: Icon(Icons.translate_rounded, color: dsAccent),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dropdownColor: dsSurface,
      style: const TextStyle(color: dsTextPrimary), // This sets the selected item text color
      iconEnabledColor: dsAccent,
      isExpanded: true,
      items: const [
        DropdownMenuItem(value: Locale('en'), child: Text('English', style: TextStyle(color: dsTextPrimary))),
        DropdownMenuItem(value: Locale('mr'), child: Text('मराठी (Marathi)', style: TextStyle(color: dsTextPrimary))),
        DropdownMenuItem(value: Locale('hi'), child: Text('हिन्दी (Hindi)', style: TextStyle(color: dsTextPrimary))),
      ],
      onChanged: (v) {
        if (v != null) ref.read(localeNotifierProvider.notifier).setLocale(v);
      },
    ),
  ),
),
                    ]),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Privacy & Security ────────────────────────────────
                    const _SectionHeader(title: 'Privacy & Security', icon: Icons.security_outlined),
                    _NavCard(items: [
                      _NavItem(
                        icon: Icons.privacy_tip_outlined,
                        title: l10n.viewPrivacyPolicy,
                        onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
                      ),
                    ]),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Help & Support ────────────────────────────────────
                    _SectionHeader(title: l10n.helpSupport, icon: Icons.help_outline_rounded),
                    _NavCard(items: [
                      _NavItem(
                        icon: Icons.quiz_outlined,
                        title: l10n.faqs,
                        onTap: () => Navigator.pushNamed(context, '/faqs'),
                      ),
                      _NavItem(
                        icon: Icons.support_agent_outlined,
                        title: l10n.contactSupport,
                        onTap: () => Navigator.pushNamed(context, '/contact-support'),
                      ),
                    ]),

                    const SizedBox(height: AppSpacing.xl),

                    // ── About ─────────────────────────────────────────────
                    _SectionHeader(title: l10n.about, icon: Icons.info_outline_rounded),
                    _NavCard(items: [
                      _NavItem(
                        icon: Icons.new_releases_outlined,
                        title: l10n.appVersion,
                        onTap: () => Navigator.pushNamed(context, '/app-version'),
                      ),
                    ]),

                    const SizedBox(height: AppSpacing.xxl),

                    // ── Actions ───────────────────────────────────────────
                    AppButton(
                      text: l10n.save,
                      onPressed: _saveSettings,
                      isLoading: _isSaving,
                      fullWidth: true,
                      icon: Icons.save_outlined,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      text: l10n.logout,
                      onPressed: () async {
                        await AuthService.logout();
                        ref.read(userNotifierProvider.notifier).setUser(null);
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      fullWidth: true,
                      variant: AppButtonVariant.outlined,
                      foregroundColor: _danger,
                      icon: Icons.logout_rounded,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? hintText,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: dsTextPrimary),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: dsTextSecondary),
        hintText: hintText,
        hintStyle: const TextStyle(color: dsTextSecondary),
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
        errorStyle: const TextStyle(color: _danger, fontSize: 12),
      ),
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      validator: validator,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable settings widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: dsAccent),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: const TextStyle(
              color: dsAccent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: dsSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dsBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({required this.items});
  final List<_NavItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: dsSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dsBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          final item   = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon, size: 20, color: dsAccent),
                title: Text(item.title, style: const TextStyle(color: dsTextPrimary, fontSize: 14)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: dsTextSecondary),
                onTap: item.onTap,
                tileColor: Colors.transparent,
              ),
              if (!isLast) const Divider(height: 1, indent: 56, color: dsBorder),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
}