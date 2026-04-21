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
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save settings: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context)!;
    final theme  = Theme.of(context);
    final locale = ref.watch(localeNotifierProvider);

    return AppShell(
      title: l10n.settings,
      currentRoute: '/settings',
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
                    _SectionHeader(title: 'Account Details', icon: Icons.person_outline_rounded),
                    _SettingsCard(children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: validateRequired,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: AppSpacing.base),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: AppSpacing.base),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'New Password (optional)',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                          hintText: 'Leave blank to keep current',
                        ),
                        obscureText: true,
                      ),
                    ]),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Notifications ────────────────────────────────────
                    _SectionHeader(title: l10n.notifications, icon: Icons.notifications_outlined),
                    _SettingsCard(children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.enableNotifications,
                            style: theme.textTheme.bodyLarge),
                        subtitle: Text('Receive push notifications for updates',
                            style: theme.textTheme.bodySmall),
                        value: _notificationsEnabled,
                        onChanged: (v) => setState(() => _notificationsEnabled = v),
                        activeColor: theme.colorScheme.primary,
                      ),
                    ]),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Language ─────────────────────────────────────────
                    _SectionHeader(title: l10n.language, icon: Icons.language_outlined),
                    _SettingsCard(children: [
                      DropdownButtonFormField<Locale>(
                        value: locale,
                        decoration: const InputDecoration(
                          labelText: 'App Language',
                          prefixIcon: Icon(Icons.translate_rounded),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                        items: const [
                          DropdownMenuItem(value: Locale('en'), child: Text('English')),
                          DropdownMenuItem(value: Locale('mr'), child: Text('मराठी (Marathi)')),
                          DropdownMenuItem(value: Locale('hi'), child: Text('हिन्दी (Hindi)')),
                        ],
                        onChanged: (v) {
                          if (v != null) ref.read(localeNotifierProvider.notifier).setLocale(v);
                        },
                      ),
                    ]),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Privacy & Security ────────────────────────────────
                    _SectionHeader(title: l10n.privacySecurity, icon: Icons.security_outlined),
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
                      foregroundColor: AppTheme.error,
                      icon: Icons.logout_rounded,
                    ),
                  ],
                ),
              ),
            ),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).dividerColor),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          final item   = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon, size: 20, color: Theme.of(context).colorScheme.primary),
                title: Text(item.title, style: Theme.of(context).textTheme.bodyLarge),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: item.onTap,
              ),
              if (!isLast) const Divider(height: 1, indent: 56),
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
