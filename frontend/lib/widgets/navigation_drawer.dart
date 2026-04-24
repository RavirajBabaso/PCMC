import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/navigation/nav_config.dart';
import 'package:main_ui/providers/auth_provider.dart';
import 'package:main_ui/providers/user_provider.dart';
import 'package:main_ui/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Role accent theming — one definition, no duplicate constants
// ─────────────────────────────────────────────────────────────────────────────

class _RoleTheme {
  const _RoleTheme({
    required this.accent,
    required this.label,
    required this.icon,
  });
  final Color accent;
  final String label;
  final IconData icon;
}

_RoleTheme _roleTheme(String? role) {
  switch (role?.toUpperCase()) {
    case 'SUPER_USER':  return const _RoleTheme(accent: Color(0xFFFFD700), label: 'SUPER USER',    icon: Icons.shield_rounded);
    case 'ADMIN':       return const _RoleTheme(accent: Color(0xFF60A5FA), label: 'ADMINISTRATOR', icon: Icons.admin_panel_settings_rounded);
    case 'FIELD_STAFF': return const _RoleTheme(accent: Color(0xFFFB923C), label: 'FIELD STAFF',   icon: Icons.engineering_rounded);
    case 'MEMBER_HEAD': return const _RoleTheme(accent: Color(0xFFA78BFA), label: 'MEMBER HEAD',   icon: Icons.verified_user_rounded);
    default:            return const _RoleTheme(accent: Color(0xFF34D399), label: 'CITIZEN',       icon: Icons.person_rounded);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drawer widget
// ─────────────────────────────────────────────────────────────────────────────

class CustomNavigationDrawer extends ConsumerWidget {
  const CustomNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc      = AppLocalizations.of(context)!;
    final user     = ref.watch(userNotifierProvider);
    final role     = user?.role?.toUpperCase();
    final rt       = _roleTheme(role);
    final sections = buildNavigationSections(role: role, loc: loc);

    return Drawer(
      backgroundColor: dsBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────
            _DrawerHeader(user: user, roleTheme: rt),

            // ── Nav items ──────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  children: [
                    for (final section in sections) ...[
                      _SectionLabel(title: section.title, color: rt.accent),
                      for (final item in section.items)
                        _NavItem(
                          icon: item.icon,
                          label: item.label(loc),
                          route: item.route,
                          accentColor: item.highlighted ? rt.accent : null,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, item.route);
                          },
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.base, vertical: AppSpacing.xs),
                        child: Divider(color: dsBorder, height: 1),
                      ),
                    ],

                    // Logout
                    _NavItem(
                      icon: Icons.logout_rounded,
                      label: loc.logout,
                      accentColor: AppTheme.error,
                      onTap: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/login', (_) => false);
                        }
                      },
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // ── Footer ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: dsBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppTheme.success.withValues(alpha:0.5), blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'PCMC GRIEVANCE SYSTEM',
                    style: TextStyle(
                      color: dsTextSecondary,
                      fontSize: 9,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.user, required this.roleTheme});

  final dynamic user;
  final _RoleTheme roleTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base, AppSpacing.xl,
        AppSpacing.base, AppSpacing.base,
      ),
      decoration: BoxDecoration(
        color: dsSurface,
        border: Border(bottom: BorderSide(color: dsBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: roleTheme.accent.withValues(alpha:0.12),
              border: Border.all(color: roleTheme.accent.withValues(alpha:0.4), width: 2),
            ),
            child: Icon(roleTheme.icon, color: roleTheme.accent, size: 26),
          ),
          const SizedBox(height: AppSpacing.md),

          // Name
          Text(
            user?.name ?? 'User',
            style: TextStyle(
              color: dsTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          if (user?.email != null) ...[
            const SizedBox(height: 2),
            Text(
              user!.email!,
              style: TextStyle(color: dsTextSecondary, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: AppSpacing.sm),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
            decoration: BoxDecoration(
              color: roleTheme.accent.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: roleTheme.accent.withValues(alpha:0.4)),
            ),
            child: Text(
              roleTheme.label,
              style: TextStyle(
                color: roleTheme.accent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.color});
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.md, AppSpacing.base, AppSpacing.xs),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: color.withValues(alpha:0.7),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Divider(color: color.withValues(alpha:0.2), height: 1)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.route,
    this.accentColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? route;
  final Color? accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? dsTextSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            leading: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            title: Text(
              label,
              style: TextStyle(
                color: accentColor != null ? dsTextPrimary : dsTextSecondary,
                fontSize: 13,
                fontWeight: accentColor != null ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            trailing: Icon(Icons.chevron_right_rounded,
                color: color.withValues(alpha:0.3), size: 16),
            minVerticalPadding: AppSpacing.xs,
          ),
        ),
      ),
    );
  }
}
