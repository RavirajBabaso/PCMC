import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/navigation/nav_config.dart';
import 'package:main_ui/services/auth_service.dart';
import 'package:main_ui/providers/user_provider.dart';
import 'package:main_ui/widgets/navigation_drawer.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
    this.actions,
    this.backgroundColor,
    this.floatingActionButton,
  });

  final String title;
  final String currentRoute;
  final Widget child;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final role = ref.watch(userNotifierProvider)?.role;
    final sections = buildNavigationSections(role: role, loc: loc);
    final bottomItems = mobilePrimaryItems(sections);
    final allItems = sections.expand((section) => section.items).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 600) {
          return Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(title: Text(title), actions: actions),
            drawer: const CustomNavigationDrawer(),
            body: child,
            floatingActionButton: floatingActionButton,
            bottomNavigationBar: _BottomNavPresenter(
              items: bottomItems,
              currentRoute: currentRoute,
            ),
          );
        }

        if (width <= 1200) {
          return Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(title: Text(title), actions: actions),
            floatingActionButton: floatingActionButton,
            body: Row(
              children: [
                _RailPresenter(
                  items: allItems,
                  currentRoute: currentRoute,
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: child),
                      Expanded(
                        child: _QuickLinksPanel(
                          items: allItems,
                          title: 'Quick Links',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(title: Text(title), actions: actions),
          floatingActionButton: floatingActionButton,
          body: Row(
            children: [
              SizedBox(
                width: 280,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: const CustomNavigationDrawer(),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Row(
                  children: [
                    Expanded(flex: 5, child: child),
                    Expanded(
                      flex: 2,
                      child: _QuickLinksPanel(
                        items: allItems,
                        title: 'Navigation',
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _ProfilePanel(role: role),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BottomNavPresenter extends StatelessWidget {
  const _BottomNavPresenter({required this.items, required this.currentRoute});

  final List<NavItem> items;
  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final index = items.indexWhere((item) => item.route == currentRoute);

    return BottomNavigationBar(
      currentIndex: index < 0 ? 0 : index,
      type: BottomNavigationBarType.fixed,
      items: items
          .map(
            (item) => BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label(AppLocalizations.of(context)!),
            ),
          )
          .toList(),
      onTap: (newIndex) {
        final route = items[newIndex].route;
        if (route != currentRoute) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}

class _RailPresenter extends StatelessWidget {
  const _RailPresenter({required this.items, required this.currentRoute});

  final List<NavItem> items;
  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final index = items.indexWhere((item) => item.route == currentRoute);

    return NavigationRail(
      selectedIndex: index < 0 ? 0 : index,
      labelType: NavigationRailLabelType.all,
      destinations: items
          .map(
            (item) => NavigationRailDestination(
              icon: Icon(item.icon),
              label: Text(item.label(AppLocalizations.of(context)!)),
            ),
          )
          .toList(),
      onDestinationSelected: (newIndex) {
        final route = items[newIndex].route;
        if (route != currentRoute) {
          Navigator.pushNamed(context, route);
        }
      },
      trailing: IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () async {
          await AuthService.logout();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
          }
        },
      ),
    );
  }
}

class _QuickLinksPanel extends StatelessWidget {
  const _QuickLinksPanel({required this.items, required this.title});

  final List<NavItem> items;
  final String title;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: items
                  .take(8)
                  .map(
                    (item) => ListTile(
                      dense: true,
                      leading: Icon(item.icon, size: 18),
                      title: Text(item.label(loc), maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.pushNamed(context, item.route),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePanel extends ConsumerWidget {
  const _ProfilePanel({required this.role});

  final String? role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userNotifierProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Session', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          CircleAvatar(child: Text((user?.name ?? 'U').substring(0, 1).toUpperCase())),
          const SizedBox(height: 12),
          Text(user?.name ?? 'User', style: Theme.of(context).textTheme.titleSmall),
          Text(user?.email ?? '', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Chip(label: Text((role ?? 'citizen').toUpperCase())),
        ],
      ),
    );
  }
}
