import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/navigation/nav_config.dart';
import 'package:main_ui/providers/user_provider.dart';
import 'package:main_ui/services/auth_service.dart';
import 'package:main_ui/widgets/navigation_drawer.dart';
import 'package:main_ui/theme/app_theme.dart';

/// Mobile-first scaffold shell.
/// Mobile (< 600 px): AppBar + Drawer + BottomNav.
/// Tablet / desktop is supported minimally (rail) but primary focus is mobile.
class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
    this.actions,
    this.backgroundColor,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  final String title;
  final String currentRoute;
  final Widget child;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc   = AppLocalizations.of(context)!;
    final role  = ref.watch(userNotifierProvider)?.role;
    final sections = buildNavigationSections(role: role, loc: loc);
    final bottomItems = mobilePrimaryItems(sections);

    // ── Mobile layout ────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        // Back button auto-added by Navigator when applicable
      ),
      drawer: const CustomNavigationDrawer(),
      body: SafeArea(
        // Bottom safe area handled by BottomNavBar; top already in AppBar
        bottom: false,
        child: child,
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation:
          floatingActionButtonLocation ?? FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: bottomItems.isNotEmpty
          ? _BottomNav(items: bottomItems, currentRoute: currentRoute)
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Navigation
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.items, required this.currentRoute});

  final List<NavItem> items;
  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc   = AppLocalizations.of(context)!;
    final index = items.indexWhere((item) => item.route == currentRoute);
    final selectedIndex = index < 0 ? 0 : index;

    return Container(
      // Top border instead of elevation noise
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        iconSize: 22,
        items: items.map((item) => BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Icon(item.icon),
          ),
          activeIcon: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Icon(item.icon),
          ),
          label: item.label(loc),
        )).toList(),
        onTap: (newIndex) {
          final route = items[newIndex].route;
          if (route != currentRoute) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }
}
