import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/comment_model.dart';
import '../../models/grievance_model.dart';
import '../../models/user_model.dart';
import '../../models/workproof_model.dart';
import '../../providers/user_provider.dart';
import '../../services/grievance_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

const Color _bg = Color(0xFF050B18);
const Color _surface = Color(0xFF0D1829);
const Color _surfaceAlt = Color(0xFF10213C);
const Color _surfaceSoft = Color(0xFF14294A);
const Color _cyan = Color(0xFF00E5FF);
const Color _amber = Color(0xFFFFB300);
const Color _green = Color(0xFF00E676);
const Color _red = Color(0xFFFF5252);
const Color _orange = Color(0xFFFF8A00);
const Color _purple = Color(0xFF9C6BFF);
const Color _text1 = Color(0xFFE8F4FD);
const Color _text2 = Color(0xFF8BA3BE);
const Color _border = Color(0xFF1A3050);

final DateFormat _detailDateFormat = DateFormat('dd MMM yyyy, hh:mm a');
final DateFormat _shortDateFormat = DateFormat('dd MMM yyyy');

List<String> _allowedTransitions(String current) {
  switch (current.toLowerCase()) {
    case 'new':
      return ['in_progress', 'rejected'];
    case 'in_progress':
      return ['on_hold', 'resolved', 'rejected'];
    case 'on_hold':
      return ['in_progress', 'rejected'];
    case 'resolved':
      return ['closed'];
    case 'closed':
      return [];
    case 'rejected':
      return [];
    default:
      return ['in_progress'];
  }
}

Color _statusColor(String status) => AppStatus.fromStatus(status);
IconData _statusIcon(String status) => AppStatus.iconFromStatus(status);
String _statusLabel(String status) => AppStatus.labelFromStatus(status);

Color _priorityColor(String? priority) {
  switch ((priority ?? '').toLowerCase()) {
    case 'high':
      return _red;
    case 'medium':
      return _amber;
    case 'low':
      return _green;
    default:
      return _text2;
  }
}

String _priorityLabel(String? priority) {
  final value = (priority ?? '').trim();
  if (value.isEmpty) return 'Not set';
  return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}

String _safeText(String? value, {String fallback = 'Not available'}) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
}

String _formatDateTime(DateTime? value) {
  if (value == null) return 'Not available';
  return _detailDateFormat.format(value.toLocal());
}

String _formatDate(DateTime? value) {
  if (value == null) return 'Not available';
  return _shortDateFormat.format(value.toLocal());
}

String _roleLabel(String? role) {
  final value = (role ?? '').trim();
  if (value.isEmpty) return 'User';
  return value
      .split('_')
      .map((part) => part.isEmpty
          ? part
          : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}

String _initials(String? name) {
  final value = (name ?? '').trim();
  if (value.isEmpty) return 'U';
  final parts = value.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

bool _isImageFile(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.bmp') ||
      lower.endsWith('.webp');
}

BoxDecoration _panelDecoration({
  Color glow = _cyan,
  double radius = 20,
  bool elevated = true,
}) {
  return BoxDecoration(
    color: _surfaceAlt,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: glow.withOpacity(0.18)),
    boxShadow: elevated
        ? [
            BoxShadow(
              color: glow.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ]
        : null,
  );
}

final grievanceProvider = FutureProvider.family<Grievance, int>((ref, id) async {
  return GrievanceService().getGrievanceDetails(id);
});

class AdminGrievanceDetail extends ConsumerStatefulWidget {
  final int id;

  const AdminGrievanceDetail({super.key, required this.id});

  @override
  ConsumerState<AdminGrievanceDetail> createState() =>
      _AdminGrievanceDetailState();
}

class _AdminGrievanceDetailState extends ConsumerState<AdminGrievanceDetail> {
  final TextEditingController _commentController = TextEditingController();
  bool _isUpdatingStatus = false;
  bool _isPostingComment = false;
  String? _selectedStatus;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _refreshGrievance() async {
    ref.invalidate(grievanceProvider(widget.id));
    try {
      await ref.read(grievanceProvider(widget.id).future);
    } catch (_) {
      // The error state is already surfaced by the provider.
    }
  }

  void _showToast(String message, {Color color = _cyan}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _surfaceAlt,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.4)),
        ),
        content: Row(
          children: [
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: _text1,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyComplaintId(String complaintId) async {
    await Clipboard.setData(ClipboardData(text: complaintId));
    _showToast('Complaint ID copied', color: _cyan);
  }

  Future<void> _openUpload(String path) async {
    final uri = Uri.parse('${Constants.baseUrl}/uploads/$path');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      _showToast('Could not open file', color: _red);
    }
  }

  Future<void> _updateStatus(
    int grievanceId,
    String currentStatus,
    String nextStatus,
  ) async {
    if (_isUpdatingStatus || nextStatus == currentStatus) return;
    setState(() {
      _isUpdatingStatus = true;
      _selectedStatus = nextStatus;
    });

    try {
      await GrievanceService().updateGrievanceStatus(grievanceId, nextStatus);
      _showToast(
        'Status updated to ${_statusLabel(nextStatus)}',
        color: _statusColor(nextStatus),
      );
      await _refreshGrievance();
    } catch (e) {
      _showToast('Failed to update status: $e', color: _red);
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
          _selectedStatus = null;
        });
      }
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isPostingComment) return;

    setState(() {
      _isPostingComment = true;
    });

    try {
      await GrievanceService().addComment(widget.id, text);
      _commentController.clear();
      _showToast('Comment added', color: _green);
      await _refreshGrievance();
    } catch (e) {
      _showToast('Failed to add comment: $e', color: _red);
    } finally {
      if (mounted) {
        setState(() {
          _isPostingComment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final grievanceAsync = ref.watch(grievanceProvider(widget.id));
    final currentUser = ref.watch(userNotifierProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: grievanceAsync.when(
        loading: _buildLoadingState,
        error: (error, _) => _buildErrorState(error),
        data: (grievance) => _buildBody(grievance, currentUser?.id),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      iconTheme: const IconThemeData(color: _cyan),
      titleSpacing: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _cyan.withOpacity(0.2)),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'ADMIN GRIEVANCE',
            style: TextStyle(
              color: _text1,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Case command center',
            style: TextStyle(
              color: _text2,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _refreshGrievance,
          icon: const Icon(Icons.refresh_rounded, color: _cyan),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: _panelDecoration(glow: _cyan),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: _cyan,
                backgroundColor: _border,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading complaint intelligence...',
              style: TextStyle(
                color: _text1,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(24),
          decoration: _panelDecoration(glow: _red),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: _red, size: 48),
              const SizedBox(height: 14),
              const Text(
                'Failed to load grievance details',
                style: TextStyle(
                  color: _text1,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                '$error',
                style: const TextStyle(
                  color: _text2,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _refreshGrievance,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red.withOpacity(0.16),
                  foregroundColor: _red,
                  side: BorderSide(color: _red.withOpacity(0.45)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(Grievance grievance, int? currentUserId) {
    final liveStatus = grievance.status ?? 'new';
    final displayStatus =
        _isUpdatingStatus ? (_selectedStatus ?? liveStatus) : liveStatus;

    return RefreshIndicator(
      onRefresh: _refreshGrievance,
      color: _cyan,
      backgroundColor: _surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1040;

                final mainColumn = Column(
                  children: [
                    _buildDescriptionCard(grievance),
                    const SizedBox(height: 16),
                    _buildAttachmentsSection(grievance),
                    const SizedBox(height: 16),
                    _buildWorkproofSection(grievance),
                    if (grievance.feedbackRating != null &&
                        grievance.feedbackRating! > 0) ...[
                      const SizedBox(height: 16),
                      _buildFeedbackSection(grievance),
                    ],
                    const SizedBox(height: 16),
                    _buildCommentsSection(grievance, currentUserId),
                  ],
                );

                final sideColumn = Column(
                  children: [
                    _buildWorkflowCard(grievance, displayStatus),
                    const SizedBox(height: 16),
                    _buildPeopleCard(grievance),
                    const SizedBox(height: 16),
                    _buildCaseDetailsCard(grievance),
                    const SizedBox(height: 16),
                    _buildTimelineCard(grievance),
                    if (grievance.address != null ||
                        grievance.latitude != null ||
                        grievance.longitude != null) ...[
                      const SizedBox(height: 16),
                      _buildLocationCard(grievance),
                    ],
                  ],
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroSection(grievance, displayStatus),
                    const SizedBox(height: 16),
                    _buildStatsGrid(grievance),
                    const SizedBox(height: 16),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: mainColumn),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: sideColumn),
                        ],
                      )
                    else ...[
                      sideColumn,
                      const SizedBox(height: 16),
                      mainColumn,
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(Grievance grievance, String status) {
    final statusColor = _statusColor(status);
    final priorityColor = _priorityColor(grievance.priority);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.28)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _surface,
            _surfaceAlt,
            statusColor.withOpacity(0.15),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -36,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -56,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _cyan.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildTopChip(
                            icon: Icons.confirmation_number_rounded,
                            label: grievance.complaintId,
                            color: _cyan,
                          ),
                          _buildTopChip(
                            icon: Icons.priority_high_rounded,
                            label: _priorityLabel(grievance.priority),
                            color: priorityColor,
                          ),
                          if (grievance.area != null)
                            _buildTopChip(
                              icon: Icons.location_on_rounded,
                              label: _safeText(grievance.area?.name),
                              color: _purple,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildCircleAction(
                      icon: Icons.copy_rounded,
                      tooltip: 'Copy complaint ID',
                      onTap: () => _copyComplaintId(grievance.complaintId),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  grievance.title,
                  style: const TextStyle(
                    color: _text1,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  grievance.description.isEmpty
                      ? 'No description was provided for this grievance.'
                      : grievance.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text2,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildHeroMetric(
                      icon: _statusIcon(status),
                      title: 'Current Status',
                      value: _statusLabel(status),
                      color: statusColor,
                    ),
                    _buildHeroMetric(
                      icon: Icons.schedule_rounded,
                      title: 'Created',
                      value: _formatDate(grievance.createdAt),
                      color: _cyan,
                    ),
                    _buildHeroMetric(
                      icon: Icons.engineering_rounded,
                      title: 'Assigned To',
                      value: grievance.assignee?.name ?? 'Unassigned',
                      color: _orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Grievance grievance) {
    final stats = [
      _StatItem(
        icon: Icons.comment_rounded,
        label: 'Comments',
        value: '${grievance.comments?.length ?? 0}',
        color: _purple,
      ),
      _StatItem(
        icon: Icons.attach_file_rounded,
        label: 'Attachments',
        value: '${grievance.attachments?.length ?? 0}',
        color: _cyan,
      ),
      _StatItem(
        icon: Icons.verified_rounded,
        label: 'Work Proofs',
        value: '${grievance.workproofs?.length ?? 0}',
        color: _green,
      ),
      _StatItem(
        icon: Icons.trending_up_rounded,
        label: 'Escalation',
        value: 'L${grievance.escalationLevel}',
        color: _amber,
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
          children: stats
              .map(
                (item) => SizedBox(
                  width: tileWidth,
                  child: _buildStatCard(item),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildWorkflowCard(Grievance grievance, String displayStatus) {
    final currentStatus = grievance.status ?? 'new';
    final allowed = _allowedTransitions(currentStatus);
    final currentColor = _statusColor(displayStatus);

    return _buildSectionShell(
      icon: Icons.alt_route_rounded,
      title: 'Workflow Control',
      subtitle: 'Advance the grievance through approved state transitions.',
      accent: currentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: currentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: currentColor.withOpacity(0.28)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentColor.withOpacity(0.16),
                  ),
                  child: Icon(_statusIcon(displayStatus), color: currentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Status',
                        style: TextStyle(
                          color: _text2,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _statusLabel(displayStatus),
                        style: const TextStyle(
                          color: _text1,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isUpdatingStatus)
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: currentColor,
                      backgroundColor: _border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (allowed.isEmpty)
            _buildEmptyMessage(
              icon: Icons.lock_outline_rounded,
              message:
                  'This complaint is in a terminal state, so no further transitions are available.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allowed
                  .map(
                    (nextStatus) => _buildTransitionButton(
                      grievance.id,
                      currentStatus,
                      nextStatus,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPeopleCard(Grievance grievance) {
    return _buildSectionShell(
      icon: Icons.people_alt_rounded,
      title: 'People & Ownership',
      subtitle: 'Citizen and assignee context for this case.',
      accent: _orange,
      child: Column(
        children: [
          _buildPersonPanel(
            title: 'Citizen',
            subtitle: 'Complaint owner',
            user: grievance.citizen,
            accent: _cyan,
            emptyMessage: 'Citizen details are not available for this grievance.',
          ),
          const SizedBox(height: 12),
          _buildPersonPanel(
            title: 'Assigned Staff',
            subtitle: 'Current operator',
            user: grievance.assignee,
            accent: _orange,
            emptyMessage: 'No staff member has been assigned yet.',
          ),
        ],
      ),
    );
  }

  Widget _buildCaseDetailsCard(Grievance grievance) {
    final tiles = [
      _buildDetailTile(
        icon: Icons.category_rounded,
        label: 'Subject',
        value: grievance.subject?.name ?? 'Not mapped',
        accent: _purple,
      ),
      _buildDetailTile(
        icon: Icons.map_rounded,
        label: 'Area',
        value: grievance.area?.name ?? 'Not mapped',
        accent: _cyan,
      ),
      _buildDetailTile(
        icon: Icons.grid_view_rounded,
        label: 'Ward',
        value: grievance.wardNumber ?? 'Not specified',
        accent: _amber,
      ),
      _buildDetailTile(
        icon: Icons.flag_rounded,
        label: 'Priority',
        value: _priorityLabel(grievance.priority),
        accent: _priorityColor(grievance.priority),
      ),
      _buildDetailTile(
        icon: Icons.badge_rounded,
        label: 'Citizen ID',
        value: grievance.citizenId?.toString() ?? 'Unknown',
        accent: _green,
      ),
      _buildDetailTile(
        icon: Icons.confirmation_number_rounded,
        label: 'Record ID',
        value: grievance.id.toString(),
        accent: _text2,
      ),
    ];

    return _buildSectionShell(
      icon: Icons.dashboard_customize_rounded,
      title: 'Case Details',
      subtitle: 'Core grievance metadata and routing information.',
      accent: _cyan,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 420 ? 2 : 1;
          const spacing = 10.0;
          final tileWidth =
              (constraints.maxWidth - (columns - 1) * spacing) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: tiles
                .map((tile) => SizedBox(width: tileWidth, child: tile))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildTimelineCard(Grievance grievance) {
    final items = <_TimelineItem>[
      _TimelineItem(
        icon: Icons.add_circle_outline_rounded,
        label: 'Created',
        value: _formatDateTime(grievance.createdAt),
        color: _cyan,
      ),
      _TimelineItem(
        icon: Icons.update_rounded,
        label: 'Last Updated',
        value: _formatDateTime(grievance.updatedAt),
        color: _purple,
      ),
      if (grievance.resolvedAt != null)
        _TimelineItem(
          icon: Icons.task_alt_rounded,
          label: 'Resolved',
          value: _formatDateTime(grievance.resolvedAt),
          color: _green,
        ),
    ];

    return _buildSectionShell(
      icon: Icons.timeline_rounded,
      title: 'Timeline',
      subtitle: 'Operational milestones recorded on this grievance.',
      accent: _purple,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _buildTimelineRow(items[i]),
            if (i != items.length - 1)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: double.infinity,
                height: 1,
                color: _border,
              ),
          ],
          if ((grievance.rejectionReason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _red.withOpacity(0.24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rejection Reason',
                    style: TextStyle(
                      color: _red,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    grievance.rejectionReason!,
                    style: const TextStyle(
                      color: _text1,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationCard(Grievance grievance) {
    return _buildSectionShell(
      icon: Icons.place_rounded,
      title: 'Location',
      subtitle: 'Reported address and coordinates.',
      accent: _green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((grievance.address ?? '').trim().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surfaceSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _green.withOpacity(0.18)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.home_work_rounded, color: _green, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      grievance.address!,
                      style: const TextStyle(
                        color: _text1,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (grievance.latitude != null || grievance.longitude != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (grievance.latitude != null)
                  _buildCoordinateChip(
                    label: 'Lat',
                    value: grievance.latitude!.toStringAsFixed(6),
                  ),
                if (grievance.longitude != null)
                  _buildCoordinateChip(
                    label: 'Lng',
                    value: grievance.longitude!.toStringAsFixed(6),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(Grievance grievance) {
    return _buildSectionShell(
      icon: Icons.notes_rounded,
      title: 'Description',
      subtitle: 'Complaint summary and operational notes.',
      accent: _cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            grievance.description.isEmpty
                ? 'No description was entered for this grievance.'
                : grievance.description,
            style: const TextStyle(
              color: _text1,
              fontSize: 14,
              height: 1.7,
            ),
          ),
          if ((grievance.rejectionReason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _red.withOpacity(0.24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Escalation Note',
                    style: TextStyle(
                      color: _red,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    grievance.rejectionReason!,
                    style: const TextStyle(
                      color: _text1,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection(Grievance grievance) {
    final List<GrievanceAttachment> attachments =
        grievance.attachments ?? const <GrievanceAttachment>[];

    return _buildSectionShell(
      icon: Icons.attach_file_rounded,
      title: 'Citizen Attachments',
      subtitle: 'Uploaded documents and visual evidence from the complaint.',
      accent: _cyan,
      child: attachments.isEmpty
          ? _buildEmptyMessage(
              icon: Icons.attach_file_rounded,
              message: 'No attachments were uploaded with this grievance.',
            )
          : Column(
              children: attachments
                  .map(
                    (attachment) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildFileCard(
                        path: attachment.filePath,
                        title: attachment.filePath.split('/').last,
                        subtitle:
                            'Type: ${_safeText(attachment.fileType, fallback: 'Unknown')}',
                        accent: _cyan,
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildWorkproofSection(Grievance grievance) {
    final List<Workproof> workproofs =
        grievance.workproofs ?? const <Workproof>[];

    return _buildSectionShell(
      icon: Icons.verified_rounded,
      title: 'Work Proofs',
      subtitle: 'Field evidence and closure materials uploaded by staff.',
      accent: _green,
      child: workproofs.isEmpty
          ? _buildEmptyMessage(
              icon: Icons.verified_outlined,
              message: 'No work proofs have been uploaded yet.',
            )
          : Column(
              children: workproofs
                  .map(
                    (workproof) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildWorkproofCard(workproof),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildFeedbackSection(Grievance grievance) {
    final rating = grievance.feedbackRating ?? 0;

    return _buildSectionShell(
      icon: Icons.star_rounded,
      title: 'Citizen Feedback',
      subtitle: 'Submitted satisfaction score and optional remarks.',
      accent: _amber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    index < rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: _amber,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$rating / 5',
                style: const TextStyle(
                  color: _text1,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if ((grievance.feedbackText ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surfaceSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _amber.withOpacity(0.2)),
              ),
              child: Text(
                grievance.feedbackText!,
                style: const TextStyle(
                  color: _text1,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentsSection(Grievance grievance, int? currentUserId) {
    final List<Comment> comments = grievance.comments ?? const <Comment>[];

    return _buildSectionShell(
      icon: Icons.forum_rounded,
      title: 'Discussion',
      subtitle: 'Internal updates and coordination notes for the case thread.',
      accent: _purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (comments.isEmpty)
            _buildEmptyMessage(
              icon: Icons.chat_bubble_outline_rounded,
              message:
                  'No comments yet. Add the first operational note below.',
            )
          else
            ...comments.map(
              (comment) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCommentCard(comment, currentUserId),
              ),
            ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _purple.withOpacity(0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _commentController,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(color: _text1, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Add an operational update or staff note...',
                    hintStyle: const TextStyle(color: _text2, fontSize: 13),
                    filled: true,
                    fillColor: _surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: _purple.withOpacity(0.55)),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Comments are visible in the grievance discussion thread.',
                        style: TextStyle(
                          color: _text2,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isPostingComment ? null : _addComment,
                      icon: _isPostingComment
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _text1,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(_isPostingComment ? 'Posting...' : 'Post'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple.withOpacity(0.2),
                        foregroundColor: _text1,
                        side: BorderSide(color: _purple.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _surfaceSoft,
              shape: BoxShape.circle,
              border: Border.all(color: _border),
            ),
            child: Icon(icon, color: _text1, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroMetric({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      constraints: const BoxConstraints(minWidth: 180),
      decoration: BoxDecoration(
        color: _surfaceSoft.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _text2,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: _text1,
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

  Widget _buildStatCard(_StatItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(glow: item.color, radius: 18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    color: _text2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: const TextStyle(
                    color: _text1,
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

  Widget _buildSectionShell({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: _panelDecoration(glow: accent),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _text1,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _text2,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTransitionButton(
    int grievanceId,
    String currentStatus,
    String nextStatus,
  ) {
    final color = _statusColor(nextStatus);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isUpdatingStatus
            ? null
            : () => _updateStatus(grievanceId, currentStatus, nextStatus),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.38)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_statusIcon(nextStatus), color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                _statusLabel(nextStatus),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonPanel({
    required String title,
    required String subtitle,
    required User? user,
    required Color accent,
    required String emptyMessage,
  }) {
    if (user == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surfaceSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(Icons.person_off_rounded, color: accent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                emptyMessage,
                style: const TextStyle(
                  color: _text2,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: accent.withOpacity(0.18),
                child: Text(
                  _initials(user.name),
                  style: TextStyle(
                    color: accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _text2,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _safeText(user.name),
                      style: const TextStyle(
                        color: _text1,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInlineInfoChip(
                icon: Icons.shield_outlined,
                text: _roleLabel(user.role),
                color: accent,
              ),
              if ((user.email ?? '').trim().isNotEmpty)
                _buildInlineInfoChip(
                  icon: Icons.mail_outline_rounded,
                  text: user.email!,
                  color: _cyan,
                ),
              if ((user.phoneNumber ?? '').trim().isNotEmpty)
                _buildInlineInfoChip(
                  icon: Icons.phone_rounded,
                  text: user.phoneNumber!,
                  color: _green,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: _text2,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
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

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _text2,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: _text1,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(_TimelineItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, color: item.color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: const TextStyle(
                  color: _text2,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                style: const TextStyle(
                  color: _text1,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoordinateChip({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _green.withOpacity(0.2)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: _text1,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyMessage({
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _text2, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _text2,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard({
    required String path,
    required String title,
    required String subtitle,
    required Color accent,
  }) {
    final isImage = _isImageFile(path);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openUpload(path),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _surfaceSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 62,
                  height: 62,
                  color: _surface,
                  child: isImage
                      ? Image.network(
                          '${Constants.baseUrl}/uploads/$path',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.broken_image_outlined,
                            color: accent,
                          ),
                        )
                      : Icon(
                          Icons.insert_drive_file_rounded,
                          color: accent,
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _text1,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _text2,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded, color: accent, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkproofCard(Workproof workproof) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withOpacity(0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildFileCard(
              path: workproof.filePath,
              title: workproof.filePath.split('/').last,
              subtitle:
                  'Uploaded by ${_safeText(workproof.uploader?.name, fallback: 'Unknown staff')} on ${_formatDate(workproof.uploadedAt)}',
              accent: _green,
            ),
            if ((workproof.notes ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  workproof.notes!,
                  style: const TextStyle(
                    color: _text1,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCard(Comment comment, int? currentUserId) {
    final isCurrentUser = currentUserId != null && currentUserId == comment.userId;
    final accent = isCurrentUser ? _cyan : _purple;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrentUser ? _surfaceSoft : _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accent.withOpacity(0.18),
                child: Text(
                  _initials(comment.userName),
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _safeText(
                              comment.userName,
                              fallback: 'User ${comment.userId}',
                            ),
                            style: const TextStyle(
                              color: _text1,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isCurrentUser)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _cyan.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                color: _cyan,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(comment.createdAt),
                      style: const TextStyle(
                        color: _text2,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _safeText(comment.commentText, fallback: 'No comment text'),
            style: const TextStyle(
              color: _text1,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          if (comment.attachments != null && comment.attachments!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...comment.attachments!.map(
              (attachment) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildFileCard(
                  path: attachment.filePath,
                  title: attachment.filePath.split('/').last,
                  subtitle:
                      'Attachment: ${_safeText(attachment.fileType, fallback: 'Unknown')}',
                  accent: accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _TimelineItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TimelineItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
