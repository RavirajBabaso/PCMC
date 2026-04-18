import 'package:flutter/material.dart';
import 'package:main_ui/l10n/app_localizations.dart';

typedef NavLabelBuilder = String Function(AppLocalizations loc);

class NavItem {
  const NavItem({
    required this.icon,
    required this.route,
    required this.label,
    this.highlighted = false,
    this.mobilePrimary = false,
  });

  final IconData icon;
  final String route;
  final NavLabelBuilder label;
  final bool highlighted;
  final bool mobilePrimary;
}

class NavSection {
  const NavSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<NavItem> items;
}

String? homeRouteForRole(String? role) {
  switch (role?.toUpperCase()) {
    case 'SUPER_USER':
    case 'ADMIN':
      return '/admin/home';
    case 'CITIZEN':
      return '/citizen/home';
    case 'MEMBER_HEAD':
      return '/member_head/home';
    case 'FIELD_STAFF':
      return '/field_staff/home';
    default:
      return null;
  }
}

List<NavSection> buildNavigationSections({
  required String? role,
  required AppLocalizations loc,
}) {
  final normalizedRole = role?.toUpperCase();
  final sections = <NavSection>[
    NavSection(
      title: 'HOME',
      items: [
        NavItem(
          icon: Icons.home,
          route: homeRouteForRole(normalizedRole) ?? '/citizen/home',
          label: (l) => l.home ?? 'Home',
          highlighted: true,
          mobilePrimary: true,
        ),
      ],
    ),
  ];

  if (normalizedRole == 'SUPER_USER') {
    sections.add(
      NavSection(
        title: 'SUPER CONTROLS',
        items: [
          NavItem(icon: Icons.shield, route: '/admin/home', label: (_) => 'System Overview', highlighted: true, mobilePrimary: true),
          NavItem(icon: Icons.report, route: '/admin/complaints', label: (l) => l.complaintManagement, highlighted: true, mobilePrimary: true),
          NavItem(icon: Icons.people, route: '/admin/users', label: (l) => l.manageUsers, mobilePrimary: true),
          NavItem(icon: Icons.bar_chart, route: '/admin/analytics', label: (_) => 'Full Analytics'),
          NavItem(icon: Icons.manage_accounts, route: '/admin/users', label: (_) => 'Manage Admins'),
          NavItem(icon: Icons.subject, route: '/admin/subjects', label: (l) => l.manageSubjects),
          NavItem(icon: Icons.location_on, route: '/admin/areas', label: (l) => l.manageAreas),
          NavItem(icon: Icons.settings_applications, route: '/admin/configs', label: (l) => l.manageConfigs),
          NavItem(icon: Icons.campaign, route: '/admin/ads', label: (_) => 'Advertisements'),
          NavItem(icon: Icons.map, route: '/admin/nearby', label: (_) => 'Nearby Places'),
          NavItem(icon: Icons.history, route: '/admin/all_users_history', label: (_) => 'User History'),
          NavItem(icon: Icons.security, route: '/admin/audit', label: (_) => 'Audit Logs'),
        ],
      ),
    );
  }

  if (normalizedRole == 'ADMIN') {
    sections.add(
      NavSection(
        title: 'ADMINISTRATION',
        items: [
          NavItem(icon: Icons.report, route: '/admin/complaints', label: (l) => l.complaintManagement, highlighted: true, mobilePrimary: true),
          NavItem(icon: Icons.people, route: '/admin/users', label: (l) => l.manageUsers, mobilePrimary: true),
          NavItem(icon: Icons.subject, route: '/admin/subjects', label: (l) => l.manageSubjects),
          NavItem(icon: Icons.location_on, route: '/admin/areas', label: (l) => l.manageAreas),
          NavItem(icon: Icons.settings_applications, route: '/admin/configs', label: (l) => l.manageConfigs),
          NavItem(icon: Icons.campaign, route: '/admin/ads', label: (_) => 'Advertisements'),
          NavItem(icon: Icons.map, route: '/admin/nearby', label: (_) => 'Nearby Places'),
          NavItem(icon: Icons.history, route: '/admin/all_users_history', label: (_) => 'User History'),
          NavItem(icon: Icons.security, route: '/admin/audit', label: (_) => 'Audit Logs'),
        ],
      ),
    );
  }

  if (normalizedRole == 'MEMBER_HEAD') {
    sections.add(
      NavSection(
        title: 'OVERSIGHT',
        items: [
          NavItem(icon: Icons.list_alt, route: '/member_head/grievances', label: (_) => 'View Grievances', highlighted: true, mobilePrimary: true),
        ],
      ),
    );
  }

  if (normalizedRole == 'CITIZEN' || normalizedRole == null) {
    sections.add(
      NavSection(
        title: 'MY COMPLAINTS',
        items: [
          NavItem(icon: Icons.add_circle, route: '/citizen/submit', label: (_) => 'Submit Complaint', highlighted: true, mobilePrimary: true),
          NavItem(icon: Icons.track_changes, route: '/citizen/track', label: (_) => 'Track Complaint', mobilePrimary: true),
          NavItem(icon: Icons.location_on, route: '/citizen/nearby', label: (_) => 'Nearby Me'),
        ],
      ),
    );
  }

  sections.add(
    NavSection(
      title: 'COMMON',
      items: [
        NavItem(icon: Icons.person, route: '/profile', label: (l) => l.profile, mobilePrimary: true),
        NavItem(icon: Icons.settings, route: '/settings', label: (l) => l.settings),
        NavItem(icon: Icons.announcement, route: '/announcements', label: (l) => l.announcements),
        NavItem(icon: Icons.privacy_tip, route: '/privacy-policy', label: (l) => l.privacyPolicy),
        NavItem(icon: Icons.help, route: '/faqs', label: (l) => l.faqs),
        NavItem(icon: Icons.support_agent, route: '/contact-support', label: (l) => l.contactSupport),
        NavItem(icon: Icons.info_outline, route: '/app-version', label: (l) => l.appVersion),
      ],
    ),
  );

  return sections;
}

List<NavItem> mobilePrimaryItems(List<NavSection> sections) {
  final items = sections.expand((s) => s.items).where((item) => item.mobilePrimary).toList();
  if (items.length <= 4) {
    return items;
  }
  return items.take(4).toList();
}
