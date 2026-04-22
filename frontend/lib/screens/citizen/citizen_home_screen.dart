import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:main_ui/layouts/app_shell.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/models/ad_model.dart';
import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/models/user_model.dart';
import 'package:main_ui/providers/ad_provider.dart';
import 'package:main_ui/providers/auth_provider.dart';
import 'package:main_ui/providers/grievance_provider.dart';
import 'package:main_ui/providers/user_provider.dart';
import 'package:main_ui/theme/app_theme.dart';
import 'package:main_ui/widgets/ad_card.dart';
import 'package:main_ui/widgets/app/app_button.dart';
import 'package:main_ui/widgets/app/app_card.dart';
import 'package:main_ui/widgets/app/status_badge.dart';



IconData _materialIcon(IconData icon) {
  return IconData(
    icon.codePoint,
    fontFamily: 'MaterialIcons',
    fontPackage: icon.fontPackage,
    matchTextDirection: icon.matchTextDirection,
  );
}
class CitizenHomeScreen extends ConsumerStatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  ConsumerState<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends ConsumerState<CitizenHomeScreen> {
  final PageController _adsPageController = PageController(viewportFraction: 0.92);
  Timer? _adsTicker;
  int _currentAdPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _primeCitizenHome();
      _startAdsTicker();
    });
  }

  @override
  void dispose() {
    _adsTicker?.cancel();
    _adsPageController.dispose();
    super.dispose();
  }

  void _primeCitizenHome() {
    ref.invalidate(adProvider);
    ref.read(userNotifierProvider.notifier).refreshUser();

    final currentUser = ref.read(authProvider) ?? ref.read(userNotifierProvider);
    final userId = currentUser?.id;
    if (userId != null) {
      ref.invalidate(citizenHistoryProvider(userId));
    }
  }

  void _startAdsTicker() {
    _adsTicker?.cancel();
    _adsTicker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_adsPageController.hasClients) {
        return;
      }

      final ads = ref.read(adProvider).valueOrNull ?? const <Advertisement>[];
      if (ads.length < 2) {
        return;
      }

      final currentPage = (_adsPageController.page ?? _currentAdPage.toDouble()).round();
      final nextPage = (currentPage + 1) % ads.length;
      _adsPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _refreshHome(User? currentUser) async {
    ref.invalidate(adProvider);
    await ref.read(userNotifierProvider.notifier).refreshUser();

    final userId = currentUser?.id;
    if (userId != null) {
      ref.invalidate(citizenHistoryProvider(userId));
      await ref.read(citizenHistoryProvider(userId).future);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(authProvider) ?? ref.watch(userNotifierProvider);
    final userId = currentUser?.id;
    final grievancesAsync = userId == null
        ? const AsyncData<List<Grievance>>(<Grievance>[])
        : ref.watch(citizenHistoryProvider(userId));
    final adsAsync = ref.watch(adProvider);

    if (currentUser == null || userId == null) {
      return AppShell(
        title: l10n.home,
        currentRoute: '/citizen/home',
        backgroundColor: theme.scaffoldBackgroundColor,
        child: Center(
          child: Padding(
            padding: AppSpacing.screen,
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _materialIcon(Icons.lock_outline_rounded),
                    size: 44,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    l10n.please_login,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Sign in to view your citizen dashboard, recent complaints, and local updates.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    text: l10n.login,
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    fullWidth: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final grievances = _sortGrievances(grievancesAsync.valueOrNull ?? const <Grievance>[]);
    final stats = _CitizenHomeStats.from(grievances);

    return AppShell(
      title: l10n.home,
      currentRoute: '/citizen/home',
      backgroundColor: theme.scaffoldBackgroundColor,
      actions: [
        IconButton(
          tooltip: l10n.notifications,
          icon: Icon(_materialIcon(Icons.notifications_none)),
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () => _refreshHome(currentUser),
        color: scheme.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            AppSpacing.base,
            AppSpacing.base,
            AppSpacing.xxxl,
          ),
          children: [
            _HeroPanel(
              user: currentUser,
              greeting: _greetingForHour(),
              subtitle:
                  'Everything important for a citizen is here: updates, quick actions, and the latest progress on your complaints.',
            ),
            const SizedBox(height: AppSpacing.xl),
            adsAsync.when(
              data: (ads) => ads.isEmpty
                  ? const SizedBox.shrink()
                  : _AdsSection(
                      ads: ads,
                      pageController: _adsPageController,
                      currentPage: _currentAdPage,
                      onPageChanged: (index) {
                        if (!mounted) {
                          return;
                        }
                        setState(() => _currentAdPage = index);
                      },
                    ),
              loading: () => const _AdsSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            if ((adsAsync.valueOrNull ?? const <Advertisement>[]).isNotEmpty)
              const SizedBox(height: AppSpacing.xl),
            _SectionHeader(
              title: 'Quick actions',
              subtitle: 'Jump straight to the things citizens use most.',
            ),
            const SizedBox(height: AppSpacing.base),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.base,
              mainAxisSpacing: AppSpacing.base,
              childAspectRatio: 1.1,
              children: [
                _QuickActionCard(
                  icon: _materialIcon(Icons.assignment),
                  title: l10n.submitGrievance,
                  subtitle: l10n.submitGrievanceSubtitle,
                  tint: scheme.primaryContainer,
                  accent: scheme.primary,
                  onTap: () => Navigator.pushNamed(context, '/citizen/submit').then((_) { ref.invalidate(citizenHistoryProvider(userId!)); }),
                ),
                _QuickActionCard(
                  icon: _materialIcon(Icons.track_changes),
                  title: l10n.track_grievances,
                  subtitle: 'Follow status updates and open details fast.',
                  tint: scheme.secondaryContainer,
                  accent: scheme.secondary,
                  onTap: () => Navigator.pushNamed(context, '/citizen/track'),
                ),
                _QuickActionCard(
                  icon: _materialIcon(Icons.location_on),
                  title: 'Nearby Help',
                  subtitle: 'Locate useful nearby civic places and services.',
                  tint: scheme.tertiaryContainer,
                  accent: scheme.tertiary,
                  onTap: () => Navigator.pushNamed(context, '/citizen/nearby'),
                ),
                _QuickActionCard(
                  icon: _materialIcon(Icons.campaign),
                  title: l10n.announcements,
                  subtitle: 'See local notices, campaigns, and civic updates.',
                  tint: scheme.surfaceContainerHighest,
                  accent: scheme.onSurfaceVariant,
                  onTap: () => Navigator.pushNamed(context, '/announcements'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionHeader(
              title: 'Your complaint pulse',
              subtitle: 'A quick read on how your complaints are moving.',
            ),
            const SizedBox(height: AppSpacing.base),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.base,
              mainAxisSpacing: AppSpacing.base,
              childAspectRatio: 1.45,
              children: [
                _MetricCard(
                  title: 'Total',
                  value: '${stats.total}',
                  icon: _materialIcon(Icons.folder),
                  accent: scheme.primary,
                  tone: scheme.primaryContainer,
                ),
                _MetricCard(
                  title: 'Active',
                  value: '${stats.active}',
                  icon: _materialIcon(Icons.pending_actions),
                  accent: scheme.secondary,
                  tone: scheme.secondaryContainer,
                ),
                _MetricCard(
                  title: 'Resolved',
                  value: '${stats.resolved}',
                  icon: _materialIcon(Icons.check_circle),
                  accent: AppTheme.success,
                  tone: AppTheme.success.withOpacity(0.12),
                ),
                _MetricCard(
                  title: 'High Priority',
                  value: '${stats.highPriority}',
                  icon: _materialIcon(Icons.priority_high),
                  accent: AppTheme.error,
                  tone: AppTheme.error.withOpacity(0.12),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionHeader(
              title: l10n.recentComplaints,
              subtitle: 'Your latest updates, sorted with the newest first.',
              actionLabel: grievances.isNotEmpty ? 'View all' : null,
              onAction: grievances.isNotEmpty
                  ? () => Navigator.pushNamed(context, '/citizen/track')
                  : null,
            ),
            const SizedBox(height: AppSpacing.base),
            grievancesAsync.when(
              data: (items) {
                final recentItems = _sortGrievances(items).take(3).toList();
                if (recentItems.isEmpty) {
                  return AppCard(
                    color: scheme.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.noGrievances,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.noGrievancesMessage,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.base),
                        AppButton(
                          text: l10n.submitGrievance,
                          onPressed: () => Navigator.pushNamed(context, '/citizen/submit'),
                          fullWidth: false,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    for (final grievance in recentItems) ...[
                      _RecentComplaintCard(grievance: grievance),
                      if (grievance != recentItems.last)
                        const SizedBox(height: AppSpacing.base),
                    ],
                  ],
                );
              },
              loading: () => Column(
                children: const [
                  _ComplaintSkeletonCard(),
                  SizedBox(height: AppSpacing.base),
                  _ComplaintSkeletonCard(),
                ],
              ),
              error: (error, _) => AppCard(
                color: scheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Could not load your recent complaints.',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '$error',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.base),
                    AppButton(
                      text: 'Retry',
                      onPressed: () => _refreshHome(currentUser),
                      fullWidth: false,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SupportPanel(
              supportLabel: l10n.contactSupport,
              supportMessage: l10n.supportTeamMessage,
            ),
          ],
        ),
      ),
    );
  }

  List<Grievance> _sortGrievances(List<Grievance> grievances) {
    final sorted = List<Grievance>.from(grievances);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  String _greetingForHour() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.user,
    required this.greeting,
    required this.subtitle,
  });

  final User user;
  final String greeting;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateLabel = DateFormat('EEEE, d MMMM').format(DateTime.now());
    final name = (user.name?.trim().isNotEmpty ?? false) ? user.name!.trim() : 'Citizen';
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, scheme.secondary, 0.55) ?? scheme.primary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.24),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withOpacity(0.18),
                  child: Text(
                    initials.isEmpty ? 'C' : initials,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.82),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    dateLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.92),
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Create Complaint',
                    icon: _materialIcon(Icons.add_circle),
                    onPressed: () => Navigator.pushNamed(context, '/citizen/submit'),
                    backgroundColor: Colors.white,
                    foregroundColor: scheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    text: 'My Updates',
                    icon: _materialIcon(Icons.track_changes),
                    onPressed: () => Navigator.pushNamed(context, '/citizen/track'),
                    variant: AppButtonVariant.outlined,
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdsSection extends StatelessWidget {
  const _AdsSection({
    required this.ads,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  final List<Advertisement> ads;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Latest from PCMC',
          subtitle: 'Promotions, announcements, and useful highlights from your local system.',
        ),
        const SizedBox(height: AppSpacing.base),
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: pageController,
            itemCount: ads.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index == ads.length - 1 ? 0 : AppSpacing.base,
                ),
                child: AdCard(ad: ads[index]),
              );
            },
          ),
        ),
        if (ads.length > 1) ...[
          const SizedBox(height: AppSpacing.base),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              ads.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == currentPage ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == currentPage
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AdsSkeleton extends StatelessWidget {
  const _AdsSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Latest from PCMC',
          subtitle: 'Loading local highlights...',
        ),
        const SizedBox(height: AppSpacing.base),
        AppCard(
          padding: EdgeInsets.zero,
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.surfaceContainerLow,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: accent),
          ),
          const Spacer(),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    required this.tone,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tone,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentComplaintCard extends ConsumerWidget {
  const _RecentComplaintCard({required this.grievance});

  final Grievance grievance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      color: scheme.surface,
      onTap: () {
        final userId = ref.read(authProvider)?.id ??
            ref.read(userNotifierProvider)?.id;
        Navigator.pushNamed(
          context,
          '/citizen/detail',
          arguments: grievance.id,
        ).then((_) {
          // Invalidate so deleted/updated grievances disappear on back-navigation
          if (userId != null) {
            ref.invalidate(citizenHistoryProvider(userId));
          }
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grievance.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      grievance.complaintId,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              StatusBadge(status: grievance.status ?? 'new'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            grievance.description,
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.base),
          Wrap(
            spacing: AppSpacing.base,
            runSpacing: AppSpacing.sm,
            children: [
              _MetaChip(
                icon: _materialIcon(Icons.schedule),
                label: DateFormat('dd MMM yyyy').format(grievance.createdAt),
              ),
              if (grievance.areaName != null && grievance.areaName!.isNotEmpty)
                _MetaChip(
                  icon: _materialIcon(Icons.place),
                  label: grievance.areaName!,
                ),
              if (grievance.priority != null && grievance.priority!.isNotEmpty)
                _MetaChip(
                  icon: _materialIcon(Icons.flag),
                  label: grievance.priority!.toUpperCase(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComplaintSkeletonCard extends StatelessWidget {
  const _ComplaintSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surfaceContainerHighest,
              theme.colorScheme.surfaceContainerLow,
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportPanel extends StatelessWidget {
  const _SupportPanel({
    required this.supportLabel,
    required this.supportMessage,
  });

  final String supportLabel;
  final String supportMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        color: scheme.surface,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    _materialIcon(Icons.support_agent),
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Text(
                    'Need a hand?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              supportMessage,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: supportLabel,
                    icon: _materialIcon(Icons.call),
                    onPressed: () => Navigator.pushNamed(context, '/contact-support'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    text: 'Profile',
                    icon: _materialIcon(Icons.person),
                    onPressed: () => Navigator.pushNamed(context, '/profile'),
                    variant: AppButtonVariant.outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _CitizenHomeStats {
  const _CitizenHomeStats({
    required this.total,
    required this.active,
    required this.resolved,
    required this.highPriority,
  });

  final int total;
  final int active;
  final int resolved;
  final int highPriority;

  factory _CitizenHomeStats.from(List<Grievance> grievances) {
    final resolvedStatuses = {'resolved', 'closed'};
    final ignoredStatuses = {'rejected'};

    final active = grievances.where((grievance) {
      final status = (grievance.status ?? '').toLowerCase();
      return !resolvedStatuses.contains(status) && !ignoredStatuses.contains(status);
    }).length;

    final resolved = grievances.where((grievance) {
      final status = (grievance.status ?? '').toLowerCase();
      return resolvedStatuses.contains(status);
    }).length;

    final highPriority = grievances.where((grievance) {
      return (grievance.priority ?? '').toLowerCase() == 'high';
    }).length;

    return _CitizenHomeStats(
      total: grievances.length,
      active: active,
      resolved: resolved,
      highPriority: highPriority,
    );
  }
}
