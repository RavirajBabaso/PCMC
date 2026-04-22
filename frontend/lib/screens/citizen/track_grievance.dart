import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:main_ui/layouts/app_shell.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/models/ad_model.dart';
import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/providers/ad_provider.dart';
import 'package:main_ui/providers/auth_provider.dart';
import 'package:main_ui/providers/grievance_provider.dart';
import 'package:main_ui/theme/app_theme.dart';
import 'package:main_ui/widgets/ad_card.dart';

const Color _success = Color(0xFF10B981);
const Color _warning = Color(0xFFF59E0B);
const Color _danger = Color(0xFFEF4444);
const Color _purple = Color(0xFF8B5CF6);

final DateFormat _headlineDateFormat = DateFormat('dd MMM yyyy');
final DateFormat _metaDateFormat = DateFormat('dd MMM, hh:mm a');

final userIdProvider = Provider<int?>((ref) {
  final user = ref.watch(authProvider);
  return user?.id;
});

Color _statusColor(String status) => AppStatus.fromStatus(status);
IconData _statusIcon(String status) => AppStatus.iconFromStatus(status);
String _statusLabel(String status) => AppStatus.labelFromStatus(status);

Color _priorityColor(String? priority) {
  switch ((priority ?? '').toLowerCase()) {
    case 'high':
      return _danger;
    case 'medium':
      return _warning;
    case 'low':
      return _success;
    default:
      return dsTextSecondary;
  }
}

String _priorityLabel(String? priority) {
  final value = (priority ?? '').trim();
  if (value.isEmpty) return 'Not set';
  return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}

double _statusProgress(String status) {
  switch (status.toLowerCase()) {
    case 'new':
      return 0.2;
    case 'in_progress':
      return 0.55;
    case 'on_hold':
      return 0.6;
    case 'resolved':
      return 0.88;
    case 'closed':
      return 1;
    case 'rejected':
      return 0.35;
    default:
      return 0.15;
  }
}

bool _isActiveStatus(String? status) {
  switch ((status ?? '').toLowerCase()) {
    case 'new':
    case 'in_progress':
    case 'on_hold':
      return true;
    default:
      return false;
  }
}

bool _isCompletedStatus(String? status) {
  switch ((status ?? '').toLowerCase()) {
    case 'resolved':
    case 'closed':
      return true;
    default:
      return false;
  }
}

String _safeText(String? value, {String fallback = 'Not available'}) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
}

String _formatDate(DateTime date) => _headlineDateFormat.format(date.toLocal());
String _formatDateTime(DateTime date) => _metaDateFormat.format(date.toLocal());

BoxDecoration _sectionDecoration({
  Color accent = dsAccent,
  double radius = 20,
  bool elevated = true,
}) {
  return BoxDecoration(
    color: dsSurfaceAlt,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: accent.withOpacity(0.16)),
    boxShadow: elevated
        ? [
            BoxShadow(
              color: accent.withOpacity(0.08),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ]
        : null,
  );
}

class TrackGrievance extends ConsumerStatefulWidget {
  const TrackGrievance({super.key});

  @override
  ConsumerState<TrackGrievance> createState() => _TrackGrievanceState();
}

class _TrackGrievanceState extends ConsumerState<TrackGrievance> {
  static const Map<String?, String> _statusFilters = <String?, String>{
    null: 'All',
    'new': 'New',
    'in_progress': 'In Progress',
    'on_hold': 'On Hold',
    'resolved': 'Resolved',
    'closed': 'Closed',
    'rejected': 'Rejected',
  };

  late final PageController _promoController;
  late final PageController _adsPageController;
  late final TextEditingController _searchController;
  Timer? _promoTimer;
  Timer? _adsTimer;

  int _currentPromoPage = 0;
  int _currentAdPage = 0;
  String? _filterStatus;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _promoController = PageController(viewportFraction: 0.9);
    _adsPageController = PageController(viewportFraction: 0.92);
    _searchController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _primeData();
      _startPromoAutoScroll();
      _startAdsAutoScroll();
    });
  }

  void _primeData() {
    final userId = ref.read(userIdProvider);
    if (userId != null) {
      ref.invalidate(citizenHistoryProvider(userId));
    }
    ref.invalidate(adProvider);
  }

  void _startPromoAutoScroll() {
    _promoTimer?.cancel();
    _promoTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_promoController.hasClients) return;
      const promoCount = 3;
      final nextPage = (_currentPromoPage + 1) % promoCount;
      _promoController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
  }

  void _startAdsAutoScroll() {
    _adsTimer?.cancel();
    _adsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_adsPageController.hasClients) return;
      final ads = ref.read(adProvider).value ?? const <Advertisement>[];
      if (ads.length <= 1) return;
      final nextPage = (_currentAdPage + 1) % ads.length;
      _adsPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _adsTimer?.cancel();
    _promoController.dispose();
    _adsPageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    ref.invalidate(adProvider);
    try {
      await ref.read(adProvider.future);
    } catch (_) {
      // Ads are non-blocking for the screen.
    }

    final userId = ref.read(userIdProvider);
    if (userId != null) {
      ref.invalidate(citizenHistoryProvider(userId));
      try {
        await ref.read(citizenHistoryProvider(userId).future);
      } catch (_) {
        // Error state is handled by the UI.
      }
    }
  }

  List<Grievance> _applyFilters(List<Grievance> grievances) {
    var filtered = grievances;

    if (_filterStatus != null) {
      filtered = filtered
          .where((g) => (g.status ?? '').toLowerCase() == _filterStatus)
          .toList();
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((g) {
        return g.title.toLowerCase().contains(query) ||
            g.complaintId.toLowerCase().contains(query) ||
            g.description.toLowerCase().contains(query) ||
            (g.area?.name.toLowerCase().contains(query) ?? false) ||
            (g.subject?.name.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  Future<void> _navigateToSubmit() async {
    final result = await Navigator.pushNamed(context, '/citizen/submit');
    if (result == true && mounted) {
      await _refreshData();
    }
  }

  Future<void> _navigateToDetail(int grievanceId) async {
    final result = await Navigator.pushNamed(
      context,
      '/citizen/detail',
      arguments: grievanceId,
    );
    if (result == true && mounted) {
      await _refreshData();
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _filterStatus = null;
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final userId = ref.watch(userIdProvider);

    if (userId == null) {
      return _buildLoginRequired(localizations);
    }

    final grievancesAsync = ref.watch(citizenHistoryProvider(userId));
    final adsAsync = ref.watch(adProvider);

    return AppShell(
      title: localizations.track_grievances,
      currentRoute: '/citizen/track',
      backgroundColor: dsBackground,
      appBarBackgroundColor: dsSurface,
      appBarForegroundColor: dsAccent,
      appBarElevation: 0,
      actions: [
        IconButton(
          tooltip: localizations.refresh,
          onPressed: _refreshData,
          icon: const Icon(Icons.refresh_rounded, color: dsAccent),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToSubmit,
        backgroundColor: dsAccent,
        foregroundColor: dsSurface,
        icon: const Icon(Icons.add_rounded),
        label: Text(localizations.submitGrievance),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      child: RefreshIndicator(
        color: dsAccent,
        backgroundColor: dsSurface,
        onRefresh: _refreshData,
        child: grievancesAsync.when(
          loading: _buildLoadingState,
          error: (error, _) => _buildErrorState(localizations, '$error'),
          data: (grievances) =>
              _buildLoadedState(localizations, grievances, adsAsync),
        ),
      ),
    );
  }

  Widget _buildLoginRequired(AppLocalizations localizations) {
    return Scaffold(
      backgroundColor: dsBackground,
      appBar: AppBar(
        backgroundColor: dsSurface,
        foregroundColor: dsAccent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: dsAccent.withOpacity(0.16)),
        ),
        title: Text(localizations.track_grievances),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(24),
            decoration: _sectionDecoration(accent: dsAccent),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: dsAccent.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    color: dsAccent,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  localizations.please_login,
                  style: const TextStyle(
                    color: dsTextPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Sign in to review your submitted complaints, see live status updates, and open full case details.',
                  style: TextStyle(
                    color: dsTextSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  icon: const Icon(Icons.login_rounded),
                  label: Text(localizations.login),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: _sectionDecoration(accent: dsAccent),
            child: Column(
              children: const [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: dsAccent,
                    backgroundColor: dsBorder,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading your grievance dashboard...',
                  style: TextStyle(
                    color: dsTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations localizations, String message) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: _sectionDecoration(accent: _danger),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: _danger, size: 48),
            const SizedBox(height: 14),
            Text(
              localizations.error,
              style: const TextStyle(
                color: dsTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: dsTextSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(localizations.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: _danger.withOpacity(0.16),
                foregroundColor: _danger,
                side: BorderSide(color: _danger.withOpacity(0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedState(
    AppLocalizations localizations,
    List<Grievance> grievances,
    AsyncValue<List<Advertisement>> adsAsync,
  ) {
    final sorted = [...grievances]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latestGrievance = sorted.isEmpty ? null : sorted.first;
    final filtered = _applyFilters(grievances);

    final totalCount = grievances.length;
    final activeCount = grievances.where((g) => _isActiveStatus(g.status)).length;
    final inProgressCount = grievances
        .where((g) => (g.status ?? '').toLowerCase() == 'in_progress')
        .length;
    final completedCount =
        grievances.where((g) => _isCompletedStatus(g.status)).length;
    final rejectedCount =
        grievances.where((g) => (g.status ?? '').toLowerCase() == 'rejected').length;
    final showAdsSection = adsAsync.maybeWhen(
      data: (ads) => ads.isNotEmpty,
      orElse: () => true,
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(
            localizations: localizations,
            latestGrievance: latestGrievance,
            totalCount: totalCount,
            activeCount: activeCount,
          ),
          const SizedBox(height: 16),
          _buildStatsGrid(
            totalCount: totalCount,
            activeCount: activeCount,
            completedCount: completedCount,
            rejectedCount: rejectedCount,
          ),
          const SizedBox(height: 16),
          _buildPromoDeck(localizations, latestGrievance, inProgressCount),
          if (showAdsSection) ...[
            const SizedBox(height: 16),
            _buildAdsSection(adsAsync),
          ],
          const SizedBox(height: 16),
          _buildFilterPanel(grievances.length, filtered.length),
          const SizedBox(height: 16),
          _buildResultsSection(localizations, grievances, filtered),
        ],
      ),
    );
  }

  Widget _buildHeroSection({
    required AppLocalizations localizations,
    required Grievance? latestGrievance,
    required int totalCount,
    required int activeCount,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dsAccent.withOpacity(0.18)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            dsSurface,
            dsSurfaceAlt,
            dsAccent.withOpacity(0.14),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: dsAccent.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 920;

          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: dsAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: dsAccent.withOpacity(0.28)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.radar_rounded, color: dsAccent, size: 14),
                    SizedBox(width: 8),
                    Text(
                      'Citizen Tracking Center',
                      style: TextStyle(
                        color: dsAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                localizations.track_grievances,
                style: const TextStyle(
                  color: dsTextPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                localizations.trackGrievancesSubtitle,
                style: const TextStyle(
                  color: dsTextSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildHeroMetric(
                    icon: Icons.folder_copy_rounded,
                    label: 'Total Cases',
                    value: '$totalCount',
                    color: dsAccent,
                  ),
                  _buildHeroMetric(
                    icon: Icons.sync_rounded,
                    label: 'Active Now',
                    value: '$activeCount',
                    color: _warning,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: _navigateToSubmit,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: Text(localizations.submitGrievance),
                  ),
                  OutlinedButton.icon(
                    onPressed: _refreshData,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(localizations.refresh),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: dsTextPrimary,
                      side: BorderSide(color: dsAccent.withOpacity(0.35)),
                    ),
                  ),
                ],
              ),
            ],
          );

          final spotlight = _buildLatestSpotlight(latestGrievance);

          return Padding(
            padding: const EdgeInsets.all(22),
            child: stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      summary,
                      const SizedBox(height: 18),
                      spotlight,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: summary),
                      const SizedBox(width: 18),
                      Expanded(flex: 2, child: spotlight),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildLatestSpotlight(Grievance? grievance) {
    if (grievance == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: dsSurface.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dsBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Latest Activity',
              style: TextStyle(
                color: dsTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Submit your first grievance to start tracking service updates and progress here.',
              style: TextStyle(
                color: dsTextSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final status = grievance.status ?? 'new';
    final color = _statusColor(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToDetail(grievance.id),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: dsSurface.withOpacity(0.94),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(status), color: color, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          _statusLabel(status),
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    grievance.complaintId,
                    style: const TextStyle(
                      color: dsTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Latest Complaint',
                style: const TextStyle(
                  color: dsTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                grievance.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: dsTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _safeText(grievance.description),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: dsTextSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      color: dsTextSecondary.withOpacity(0.8), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(grievance.createdAt),
                    style: const TextStyle(
                      color: dsTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_rounded,
                      color: dsAccent, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid({
    required int totalCount,
    required int activeCount,
    required int completedCount,
    required int rejectedCount,
  }) {
    final metrics = [
      _MetricTileData(
        icon: Icons.inventory_2_rounded,
        label: 'Total',
        value: '$totalCount',
        color: dsAccent,
      ),
      _MetricTileData(
        icon: Icons.hourglass_top_rounded,
        label: 'Active',
        value: '$activeCount',
        color: _warning,
      ),
      _MetricTileData(
        icon: Icons.check_circle_rounded,
        label: 'Completed',
        value: '$completedCount',
        color: _success,
      ),
      _MetricTileData(
        icon: Icons.block_rounded,
        label: 'Rejected',
        value: '$rejectedCount',
        color: _danger,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 1120 ? 4 : constraints.maxWidth >= 620 ? 2 : 1;
        const spacing = 12.0;
        final tileWidth =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: tileWidth,
                  child: _buildMetricTile(metric),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildMetricTile(_MetricTileData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _sectionDecoration(accent: data.color, radius: 18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: const TextStyle(
                    color: dsTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  style: const TextStyle(
                    color: dsTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoDeck(
    AppLocalizations localizations,
    Grievance? latestGrievance,
    int inProgressCount,
  ) {
    final cards = [
      _PromoCardData(
        title: localizations.submitGrievance,
        subtitle: localizations.submitGrievanceSubtitle,
        accent: dsAccent,
        icon: Icons.add_task_rounded,
        buttonLabel: 'Start now',
        onTap: _navigateToSubmit,
      ),
      _PromoCardData(
        title: latestGrievance != null ? latestGrievance.complaintId : 'No Case Yet',
        subtitle: latestGrievance != null
            ? latestGrievance.title
            : 'Your latest complaint will appear here for one-tap access.',
        accent: _purple,
        icon: Icons.folder_open_rounded,
        buttonLabel: latestGrievance != null ? 'Open case' : 'Submit first',
        onTap: latestGrievance != null
            ? () => _navigateToDetail(latestGrievance.id)
            : _navigateToSubmit,
      ),
      _PromoCardData(
        title: localizations.quickResolutionsTitle,
        subtitle: inProgressCount > 0
            ? '$inProgressCount complaint${inProgressCount == 1 ? '' : 's'} currently in progress.'
            : localizations.quickResolutionsSubtitle,
        accent: _success,
        icon: Icons.verified_user_rounded,
        buttonLabel: 'View in progress',
        onTap: () {
          setState(() {
            _filterStatus = 'in_progress';
          });
        },
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _sectionDecoration(accent: dsAccent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: dsTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Swipe through useful shortcuts and case shortcuts.',
            style: TextStyle(
              color: dsTextSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final cardHeight = width < 340 ? 228.0 : 194.0;
              return SizedBox(
                height: cardHeight,
                child: PageView.builder(
                  controller: _promoController,
                  itemCount: cards.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPromoPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildPromoCard(card),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildPageIndicator(cards.length, _currentPromoPage),
        ],
      ),
    );
  }

  Widget _buildPromoCard(_PromoCardData card) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            card.accent.withOpacity(0.28),
            card.accent.withOpacity(0.1),
            dsSurface,
          ],
        ),
        border: Border.all(color: card.accent.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: card.accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(card.icon, color: card.accent),
          ),
          const SizedBox(height: 14),
          Text(
            card.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: dsTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              card.subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: dsTextSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: card.onTap,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                card.buttonLabel,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: card.accent,
                side: BorderSide(color: card.accent.withOpacity(0.35)),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdsSection(AsyncValue<List<Advertisement>> adsAsync) {
    return adsAsync.when(
      data: (ads) {
        if (ads.isEmpty) {
          return const SizedBox.shrink();
        }

        final indicatorIndex = _currentAdPage % ads.length;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: _sectionDecoration(accent: _purple),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Public Updates',
                style: TextStyle(
                  color: dsTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Announcements and public information relevant to city services.',
                style: TextStyle(
                  color: dsTextSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: PageView.builder(
                  controller: _adsPageController,
                  itemCount: ads.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentAdPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AdCard(ad: ads[index]),
                    );
                  },
                ),
              ),
              if (ads.length > 1) ...[
                const SizedBox(height: 12),
                _buildPageIndicator(ads.length, indicatorIndex),
              ],
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(18),
        decoration: _sectionDecoration(accent: _purple),
        child: const SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _purple,
            ),
          ),
        ),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(18),
        decoration: _sectionDecoration(accent: _purple),
        child: const Text(
          'Public updates are unavailable right now.',
          style: TextStyle(
            color: dsTextSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPanel(int totalCount, int filteredCount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _sectionDecoration(accent: dsAccent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Find Your Complaint',
                style: TextStyle(
                  color: dsTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$filteredCount of $totalCount',
                style: const TextStyle(
                  color: dsTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Search by title, complaint ID, area, or subject, then narrow by status.',
            style: TextStyle(
              color: dsTextSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: const TextStyle(color: dsTextPrimary),
            decoration: InputDecoration(
              hintText: 'Search grievances',
              hintStyle: const TextStyle(color: dsTextSecondary),
              prefixIcon: const Icon(Icons.search_rounded, color: dsAccent),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: dsSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: dsBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: dsAccent.withOpacity(0.4)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statusFilters.entries.map((entry) {
              final selected = _filterStatus == entry.key;
              final label = entry.value;
              final color =
                  entry.key == null ? dsAccent : _statusColor(entry.key!);

              return FilterChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _filterStatus = entry.key;
                  });
                },
                selectedColor: color.withOpacity(0.18),
                backgroundColor: dsSurface,
                checkmarkColor: color,
                side: BorderSide(
                  color: selected ? color : dsBorder,
                ),
                labelStyle: TextStyle(
                  color: selected ? color : dsTextSecondary,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            }).toList(),
          ),
          if (_filterStatus != null || _searchQuery.isNotEmpty) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: const Text('Clear filters'),
              style: TextButton.styleFrom(foregroundColor: dsAccentSoft),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsSection(
    AppLocalizations localizations,
    List<Grievance> allGrievances,
    List<Grievance> filteredGrievances,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _sectionDecoration(accent: dsAccent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                localizations.grievanceDetails,
                style: const TextStyle(
                  color: dsTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${filteredGrievances.length} result${filteredGrievances.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: dsTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            allGrievances.isEmpty
                ? localizations.noGrievancesMessage
                : 'Tap any complaint to see full details, comments, feedback, and work proofs.',
            style: const TextStyle(
              color: dsTextSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          if (allGrievances.isEmpty)
            _buildNoGrievancesState(localizations)
          else if (filteredGrievances.isEmpty)
            _buildNoResultsState()
          else
            Column(
              children: filteredGrievances
                  .map(
                    (grievance) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildGrievanceCard(grievance),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildNoGrievancesState(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: dsSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dsBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: dsAccent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_rounded, color: dsAccent, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            localizations.noGrievances,
            style: const TextStyle(
              color: dsTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.noGrievancesMessage,
            style: const TextStyle(
              color: dsTextSecondary,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _navigateToSubmit,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: Text(localizations.submitGrievance),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: dsSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dsBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _warning.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.search_off_rounded, color: _warning, size: 30),
          ),
          const SizedBox(height: 14),
          const Text(
            'No matches found',
            style: TextStyle(
              color: dsTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try a different search term or clear the current filters to see more complaints.',
            style: TextStyle(
              color: dsTextSecondary,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.filter_alt_off_rounded),
            label: const Text('Clear filters'),
            style: TextButton.styleFrom(foregroundColor: dsAccentSoft),
          ),
        ],
      ),
    );
  }

  Widget _buildGrievanceCard(Grievance grievance) {
    final status = grievance.status ?? 'new';
    final statusColor = _statusColor(status);
    final priorityColor = _priorityColor(grievance.priority);
    final progress = _statusProgress(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToDetail(grievance.id),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dsSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.16)),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
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
                          grievance.complaintId,
                          style: const TextStyle(
                            color: dsTextSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          grievance.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: dsTextPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusPill(status),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: priorityColor.withOpacity(0.24),
                          ),
                        ),
                        child: Text(
                          _priorityLabel(grievance.priority),
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _safeText(grievance.description),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: dsTextSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMetaChip(
                    icon: Icons.calendar_today_rounded,
                    label: _formatDateTime(grievance.createdAt),
                    color: dsTextSecondary,
                  ),
                  if (grievance.area != null)
                    _buildMetaChip(
                      icon: Icons.location_on_rounded,
                      label: grievance.area!.name,
                      color: dsAccentSoft,
                    ),
                  if (grievance.subject != null)
                    _buildMetaChip(
                      icon: Icons.category_rounded,
                      label: grievance.subject!.name,
                      color: _purple,
                    ),
                  if (grievance.assignee != null)
                    _buildMetaChip(
                      icon: Icons.engineering_rounded,
                      label: grievance.assignee!.name ?? 'Assigned',
                      color: _warning,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: dsSurfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withOpacity(0.14)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_statusIcon(status), color: statusColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Progress: ${_statusLabel(status)}',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            color: dsTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        color: statusColor,
                        backgroundColor: dsBorder,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildMiniMetric(
                          icon: Icons.attach_file_rounded,
                          value: '${grievance.attachments?.length ?? 0}',
                        ),
                        _buildMiniMetric(
                          icon: Icons.comment_rounded,
                          value: '${grievance.comments?.length ?? 0}',
                        ),
                        _buildMiniMetric(
                          icon: Icons.verified_rounded,
                          value: '${grievance.workproofs?.length ?? 0}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: dsAccent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View details',
                          style: TextStyle(
                            color: dsAccentSoft,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: dsAccentSoft,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            _statusLabel(status),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric({
    required IconData icon,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: dsTextSecondary, size: 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: dsTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dsSurface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: dsTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: dsTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int count, int currentIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: currentIndex == index ? 18 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: currentIndex == index
                ? dsAccent
                : dsTextSecondary.withOpacity(0.35),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _MetricTileData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTileData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _PromoCardData {
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback onTap;

  const _PromoCardData({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.buttonLabel,
    required this.onTap,
  });
}
