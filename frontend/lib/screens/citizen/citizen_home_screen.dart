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
import 'package:flutter_svg/flutter_svg.dart';

// Status colors matching TrackGrievance
const Color _success = Color(0xFF10B981);
const Color _warning = Color(0xFFF59E0B);
const Color _danger = Color(0xFFEF4444);
const Color _purple = Color(0xFF8B5CF6);

class CitizenHomeScreen extends ConsumerStatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  ConsumerState<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends ConsumerState<CitizenHomeScreen> {
  final PageController _adsPageController = PageController(
    viewportFraction: 0.92,
  );
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

    final currentUser =
        ref.read(authProvider) ?? ref.read(userNotifierProvider);
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

      final currentPage = (_adsPageController.page ?? _currentAdPage.toDouble())
          .round();
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
    final l10n = AppLocalizations.of(context)!;
    final currentUser =
        ref.watch(authProvider) ?? ref.watch(userNotifierProvider);
    final userId = currentUser?.id;
    final grievancesAsync = userId == null
        ? const AsyncData<List<Grievance>>(<Grievance>[])
        : ref.watch(citizenHistoryProvider(userId));
    final adsAsync = ref.watch(adProvider);

    if (currentUser == null || userId == null) {
      return AppShell(
        title: l10n.home,
        currentRoute: '/citizen/home',
        child: Center(
          child: Padding(
            padding: AppSpacing.screen,
            child: _buildCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: dsAccent.withValues(alpha:0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_person_rounded,
                      color: dsAccent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    l10n.please_login,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: dsTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Sign in to view your citizen dashboard, recent complaints, and local updates.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: dsTextSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    text: l10n.login,
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    fullWidth: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final grievances = _sortGrievances(
      grievancesAsync.valueOrNull ?? const <Grievance>[],
    );
    final stats = _CitizenHomeStats.from(grievances);

    return AppShell(
      title: l10n.home,
      currentRoute: '/citizen/home',
      actions: [
        IconButton(
          tooltip: l10n.notifications,
          icon: const Icon(Icons.notifications_outlined, color: dsAccent),
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () => _refreshHome(currentUser),
        color: dsAccent,
        backgroundColor: dsSurface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
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
              onComplaintCreated: () =>
                  Navigator.pushNamed(context, '/citizen/submit').then((_) {
                    if (userId != null) {
                      ref.invalidate(citizenHistoryProvider(userId));
                    }
                  }),
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
            const _SectionHeader(
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
                  icon: Icons.add_circle_outline_rounded,
                  title: l10n.submitGrievance,
                  subtitle: l10n.submitGrievanceSubtitle,
                  accent: dsAccent,
                ),
                _QuickActionCard(
                  icon: Icons.track_changes_rounded,
                  title: l10n.track_grievances,
                  subtitle: 'Follow status updates and open details fast.',
                  accent: _warning,
                ),
                _QuickActionCard(
                  icon: Icons.location_on_rounded,
                  title: 'Nearby Help',
                  subtitle: 'Locate useful nearby civic places and services.',
                  accent: _purple,
                ),
                _QuickActionCard(
                  icon: Icons.campaign_rounded,
                  title: l10n.announcements,
                  subtitle: 'See local notices, campaigns, and civic updates.',
                  accent: dsTextSecondary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionHeader(
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
                  icon: Icons.folder_copy_rounded,
                  accent: dsAccent,
                ),
                _MetricCard(
                  title: 'Active',
                  value: '${stats.active}',
                  icon: Icons.hourglass_top_rounded,
                  accent: _warning,
                ),
                _MetricCard(
                  title: 'Resolved',
                  value: '${stats.resolved}',
                  icon: Icons.check_circle_rounded,
                  accent: _success,
                ),
                _MetricCard(
                  title: 'High Priority',
                  value: '${stats.highPriority}',
                  icon: Icons.warning_rounded,
                  accent: _danger,
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
                  return _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.noGrievances,
                          style: const TextStyle(
                            color: dsTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.noGrievancesMessage,
                          style: const TextStyle(
                            color: dsTextSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.base),
                        AppButton(
                          text: l10n.submitGrievance,
                          onPressed: () =>
                              Navigator.pushNamed(
                                context,
                                '/citizen/submit',
                              ).then((_) {
                                if (userId != null) {
                                  ref.invalidate(
                                    citizenHistoryProvider(userId),
                                  );
                                }
                              }),
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
              error: (error, _) => _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Could not load your recent complaints.',
                      style: const TextStyle(
                        color: dsTextPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '$error',
                      style: const TextStyle(color: dsTextSecondary),
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
              onCreateComplaint: () =>
                  Navigator.pushNamed(context, '/citizen/submit').then((_) {
                    if (userId != null) {
                      ref.invalidate(citizenHistoryProvider(userId));
                    }
                  }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: dsSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dsBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: child,
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
    this.onComplaintCreated,
  });

  final User user;
  final String greeting;
  final String subtitle;
  final VoidCallback? onComplaintCreated;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, d MMMM').format(DateTime.now());
    final name = (user.name?.trim().isNotEmpty ?? false)
        ? user.name!.trim()
        : 'Citizen';
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [dsAccent, Color(0xFF1D4ED8)],
        ),
        boxShadow: [
          BoxShadow(
            color: dsAccent.withValues(alpha:0.24),
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
                  backgroundColor: Colors.white.withValues(alpha:0.18),
                  child: Text(
                    initials.isEmpty ? 'C' : initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
                        style: TextStyle(
                          color: Colors.white.withValues(alpha:0.82),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
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
                color: Colors.white.withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha:0.92),
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Create Complaint',
                    icon: Icons.add_circle,
                    onPressed: onComplaintCreated,
                    backgroundColor: Colors.white,
                    foregroundColor: dsAccent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    text: 'My Updates',
                    icon: Icons.bar_chart,
                    onPressed: () =>
                        Navigator.pushNamed(context, '/citizen/track'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Latest from PCMC',
          subtitle:
              'Promotions, announcements, and useful highlights from your local system.',
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
                  color: index == currentPage ? dsAccent : dsBorder,
                  borderRadius: BorderRadius.circular(999),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Latest from PCMC',
          subtitle: 'Loading local highlights...',
        ),
        const SizedBox(height: AppSpacing.base),
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            color: dsSurfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: dsBorder),
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
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: dsSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dsBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: dsTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: const TextStyle(color: dsTextSecondary, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: dsSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dsBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: dsTextPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: dsTextSecondary,
                      fontSize: 12,
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

class _RecentComplaintCard extends ConsumerWidget {
  const _RecentComplaintCard({required this.grievance});

  final Grievance grievance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        final userId =
            ref.read(authProvider)?.id ?? ref.read(userNotifierProvider)?.id;
        Navigator.pushNamed(
          context,
          '/citizen/detail',
          arguments: grievance.id,
        ).then((_) {
          if (userId != null) {
            ref.invalidate(citizenHistoryProvider(userId));
          }
        });
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: dsSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dsBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
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
                          style: const TextStyle(
                            color: dsTextPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          grievance.complaintId,
                          style: const TextStyle(
                            color: dsAccent,
                            fontSize: 11,
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
                style: const TextStyle(
                  color: dsTextSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.base),
              Wrap(
                spacing: AppSpacing.base,
                runSpacing: AppSpacing.sm,
                children: [
                  _MetaChip(
                    icon: Icons.calendar_today_rounded,
                    label: DateFormat(
                      'dd MMM yyyy',
                    ).format(grievance.createdAt),
                  ),
                  if (grievance.areaName != null &&
                      grievance.areaName!.isNotEmpty)
                    _MetaChip(
                      icon: Icons.location_on_rounded,
                      label: grievance.areaName!,
                    ),
                  if (grievance.priority != null &&
                      grievance.priority!.isNotEmpty)
                    _MetaChip(
                      icon: Icons.flag_rounded,
                      label: grievance.priority!.toUpperCase(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComplaintSkeletonCard extends StatelessWidget {
  const _ComplaintSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: dsSurfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dsBorder),
      ),
    );
  }
}

class _SupportPanel extends StatelessWidget {
  const _SupportPanel({
    required this.supportLabel,
    required this.supportMessage,
    this.onCreateComplaint,
  });

  final String supportLabel;
  final String supportMessage;
  final VoidCallback? onCreateComplaint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: dsSurface,
        border: Border.all(color: dsBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: dsAccent.withValues(alpha:0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: dsAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Text(
                    'Need a hand?',
                    style: const TextStyle(
                      color: dsTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              supportMessage,
              style: const TextStyle(color: dsTextSecondary, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Create Complaint',
                    icon: Icons.add_circle,
                    onPressed: onCreateComplaint,
                    backgroundColor: Colors.white,
                    foregroundColor: dsAccent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    text: 'Profile',
                    icon: Icons.person,
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
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: dsSurfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: dsTextSecondary, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: dsTextSecondary, fontSize: 11),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: dsTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: dsTextSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: dsAccent),
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
      return !resolvedStatuses.contains(status) &&
          !ignoredStatuses.contains(status);
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
