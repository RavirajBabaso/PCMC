import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/navigation/nav_config.dart';
import 'package:main_ui/providers/user_provider.dart';
import 'package:main_ui/widgets/navigation_drawer.dart';
import 'package:main_ui/theme/app_theme.dart';

/// Mobile-first scaffold shell.
/// Mobile (< 600 px): AppBar + Drawer + BottomNav.
class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
    this.actions,
    this.backgroundColor,
    this.bottomNavCurrentRoute,
    this.appBarBackgroundColor,
    this.appBarForegroundColor,
    this.appBarElevation,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  final String title;
  final String currentRoute;
  final Widget child;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final String? bottomNavCurrentRoute;
  final Color? appBarBackgroundColor;
  final Color? appBarForegroundColor;
  final double? appBarElevation;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final role = ref.watch(userNotifierProvider)?.role;
    final sections = buildNavigationSections(role: role, loc: loc);
    final bottomItems = mobilePrimaryItems(sections);
    final selectedBottomRoute = bottomNavCurrentRoute ?? currentRoute;

    return Scaffold(
      backgroundColor: backgroundColor ?? dsBackground,
      appBar: AppBar(
        backgroundColor: appBarBackgroundColor ?? dsSurface,
        foregroundColor: appBarForegroundColor ?? dsAccent,
        elevation: appBarElevation ?? 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        actions: actions,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: dsBorder,
          ),
        ),
      ),
      drawer: const CustomNavigationDrawer(),
      body: SafeArea(
        bottom: false,
        child: child,
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation:
          floatingActionButtonLocation ?? FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: bottomItems.isNotEmpty
          ? _BottomNav(
              items: bottomItems,
              currentRoute: currentRoute,
              selectedRoute: selectedBottomRoute,
            )
          : null,
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.items,
    required this.currentRoute,
    required this.selectedRoute,
  });

  final List<NavItem> items;
  final String currentRoute;
  final String selectedRoute;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final index = items.indexWhere((item) => item.route == selectedRoute);
    final selectedIndex = index < 0 ? 0 : index;

    return Container(
      decoration: BoxDecoration(
        color: dsSurface,
        border: Border(
          top: BorderSide(
            color: dsBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        iconSize: 22,
        selectedItemColor: dsAccent,
        unselectedItemColor: dsTextSecondary,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
        items: items
            .map(
              (item) => BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Icon(item.icon),
                ),
                activeIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Icon(item.icon),
                ),
                label: item.label(loc),
              ),
            )
            .toList(),
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