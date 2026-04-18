import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/navigation/nav_config.dart';
import 'package:main_ui/providers/auth_provider.dart';
import 'package:main_ui/providers/user_provider.dart';

const Color _bg = Color(0xFF050B18);
const Color _surfaceAlt = Color(0xFF0F2040);
const Color _cyan = Color(0xFF00E5FF);
const Color _amber = Color(0xFFFFB300);
const Color _green = Color(0xFF00E676);
const Color _red = Color(0xFFFF1744);
const Color _orange = Color(0xFFFF6D00);
const Color _purple = Color(0xFFD500F9);
const Color _gold = Color(0xFFFFD700);
const Color _text1 = Color(0xFFE8F4FD);
const Color _text2 = Color(0xFF8BA3BE);
const Color _border = Color(0xFF1A3050);

_RoleTheme _roleTheme(String? role) {
  switch (role?.toUpperCase()) {
    case 'SUPER_USER':
      return _RoleTheme(_gold, [const Color(0xFF1A1200), const Color(0xFF302000)], 'SUPER USER', Icons.shield_moon, '✦');
    case 'ADMIN':
      return _RoleTheme(_cyan, [const Color(0xFF001220), const Color(0xFF001830)], 'ADMINISTRATOR', Icons.admin_panel_settings, '⬡');
    case 'FIELD_STAFF':
      return _RoleTheme(_orange, [const Color(0xFF180800), const Color(0xFF200D00)], 'FIELD STAFF', Icons.engineering, '▲');
    case 'MEMBER_HEAD':
      return _RoleTheme(_purple, [const Color(0xFF0D0020), const Color(0xFF140030)], 'MEMBER HEAD', Icons.verified_user, '◆');
    default:
      return _RoleTheme(_green, [const Color(0xFF001810), const Color(0xFF002018)], 'CITIZEN', Icons.person, '●');
  }
}

class _RoleTheme {
  const _RoleTheme(this.accent, this.headerGradient, this.label, this.icon, this.badge);

  final Color accent;
  final List<Color> headerGradient;
  final String label;
  final IconData icon;
  final String badge;
}

class CustomNavigationDrawer extends ConsumerStatefulWidget {
  const CustomNavigationDrawer({super.key});

  @override
  ConsumerState<CustomNavigationDrawer> createState() => _CustomNavigationDrawerState();
}

class _CustomNavigationDrawerState extends ConsumerState<CustomNavigationDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = ref.watch(userNotifierProvider);
    final role = user?.role?.toUpperCase();
    final roleTheme = _roleTheme(role);
    final sections = buildNavigationSections(role: role, loc: loc);

    return Drawer(
      backgroundColor: _bg,
      child: Column(
        children: [
          _buildHeader(roleTheme, user?.name, user?.email),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (final section in sections) ...[
                    _sectionHeader(section.title, roleTheme.accent),
                    for (final item in section.items)
                      _item(
                        context,
                        icon: item.icon,
                        label: item.label(loc),
                        route: item.route,
                        color: item.highlighted ? roleTheme.accent : null,
                      ),
                    _divider(),
                  ],
                  _item(
                    context,
                    icon: Icons.logout,
                    label: loc.logout,
                    color: _red,
                    onTap: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: _border))),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _green,
                      boxShadow: [
                        BoxShadow(color: _green.withOpacity(0.3 + _pulse.value * 0.7), blurRadius: 6),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'PCMC GRIEVANCE SYSTEM',
                  style: TextStyle(color: _text2, fontSize: 9, letterSpacing: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(_RoleTheme roleTheme, String? name, String? email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: roleTheme.headerGradient),
        border: Border(bottom: BorderSide(color: roleTheme.accent.withOpacity(0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: roleTheme.accent.withOpacity(0.15),
                  border: Border.all(color: roleTheme.accent.withOpacity(0.5), width: 2),
                  boxShadow: [BoxShadow(color: roleTheme.accent.withOpacity(0.3), blurRadius: 12)],
                ),
                child: Center(child: Icon(roleTheme.icon, color: roleTheme.accent, size: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name ?? 'User', style: const TextStyle(color: _text1, fontSize: 15, fontWeight: FontWeight.w700)),
                    if (email != null)
                      Text(email, style: const TextStyle(color: _text2, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: roleTheme.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: roleTheme.accent.withOpacity(0.5)),
              boxShadow: [BoxShadow(color: roleTheme.accent.withOpacity(0.2), blurRadius: 8)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(roleTheme.badge, style: TextStyle(color: roleTheme.accent, fontSize: 10)),
                const SizedBox(width: 6),
                Text(
                  roleTheme.label,
                  style: TextStyle(color: roleTheme.accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: color.withOpacity(0.2))),
        ],
      ),
    );
  }

  Widget _divider() => Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), height: 1, color: _border);

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
    String? route,
    VoidCallback? onTap,
  }) {
    final itemColor = color ?? _text2;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {
          if (route == null) return;
          Navigator.pop(context);
          Navigator.pushNamed(context, route);
        },
        borderRadius: BorderRadius.circular(8),
        splashColor: itemColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            dense: true,
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: itemColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: itemColor.withOpacity(0.2)),
              ),
              child: Icon(icon, color: itemColor, size: 16),
            ),
            title: Text(
              label,
              style: TextStyle(
                color: color != null ? _text1 : _text2,
                fontSize: 13,
                fontWeight: color != null ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: itemColor.withOpacity(0.3), size: 16),
          ),
        ),
      ),
    );
  }
}
