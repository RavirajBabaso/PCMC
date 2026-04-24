import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../models/comment_model.dart';
import '../../models/grievance_model.dart';
import '../../models/user_model.dart';
import '../../models/workproof_model.dart';
import '../../providers/user_provider.dart';
import '../../services/grievance_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

const Color _success = Color(0xFF10B981);
const Color _warning = Color(0xFFF59E0B);
const Color _danger = Color(0xFFEF4444);
const Color _purple = Color(0xFF8B5CF6);
const Color _slateBorder = Color(0xFF223750);

final DateFormat _detailDateFormat = DateFormat('dd MMM yyyy, hh:mm a');
final DateFormat _shortDateFormat = DateFormat('dd MMM yyyy');

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

bool _isImageFile(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.bmp') ||
      lower.endsWith('.webp');
}

BoxDecoration _cardDecoration({
  Color accent = dsAccent,
  double radius = 20,
  bool elevated = true,
}) {
  return BoxDecoration(
    color: dsSurfaceAlt,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: accent.withValues(alpha: 0.16)),
    boxShadow: elevated
        ? [
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ]
        : null,
  );
}

final grievanceProvider = FutureProvider.family<Grievance, int>((ref, id) async {
  return GrievanceService().getGrievanceDetails(id);
});

class GrievanceDetail extends ConsumerStatefulWidget {
  final int id;

  const GrievanceDetail({super.key, required this.id});

  @override
  ConsumerState<GrievanceDetail> createState() => _GrievanceDetailState();
}

class _GrievanceDetailState extends ConsumerState<GrievanceDetail> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  List<PlatformFile> _selectedFiles = <PlatformFile>[];
  int? _rating;
  bool _isPostingComment = false;
  bool _isSubmittingFeedback = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(grievanceProvider(widget.id));
    });
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _refreshGrievance() async {
    ref.invalidate(grievanceProvider(widget.id));
    try {
      await ref.read(grievanceProvider(widget.id).future);
    } catch (_) {
      // Error UI is already handled by the provider.
    }
  }

  void _showToast(String message, {Color color = dsAccent}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: dsSurfaceAlt,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color.withValues(alpha: 0.35)),
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
                  color: dsTextPrimary,
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

  Future<void> _launchURL(String path) async {
    final l10n = AppLocalizations.of(context)!;
    final resolvedUrl = Constants.resolveMediaUrl(path);
    if (resolvedUrl == null) {
      _showToast(l10n.couldNotLaunchUrl(path), color: _danger);
      return;
    }
    final Uri uri = Uri.parse(resolvedUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showToast(l10n.couldNotLaunchUrl(resolvedUrl), color: _danger);
    }
  }

  Future<void> _copyComplaintId(String complaintId) async {
    await Clipboard.setData(ClipboardData(text: complaintId));
    _showToast('Complaint ID copied', color: dsAccent);
  }

  Future<void> _pickCommentAttachments() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty || !mounted) return;
    setState(() {
      _selectedFiles = [..._selectedFiles, ...result.files];
    });
  }

  Future<void> _addComment() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      _showToast(l10n.commentCannotBeEmpty, color: _warning);
      return;
    }
    if (_isPostingComment) return;

    setState(() {
      _isPostingComment = true;
    });

    try {
      await GrievanceService().addComment(
        widget.id,
        text,
        attachments: _selectedFiles,
      );
      _commentController.clear();
      if (mounted) {
        setState(() {
          _selectedFiles = <PlatformFile>[];
        });
      }
      _showToast(l10n.commentAddedSuccess, color: _success);
      await _refreshGrievance();
    } catch (e) {
      _showToast('${l10n.failedToAddComment}: $e', color: _danger);
    } finally {
      if (mounted) {
        setState(() {
          _isPostingComment = false;
        });
      }
    }
  }

  Future<void> _submitFeedback() async {
    final l10n = AppLocalizations.of(context)!;
    if (_rating == null) {
      _showToast(l10n.pleaseProvideRating, color: _warning);
      return;
    }
    if (_isSubmittingFeedback) return;

    setState(() {
      _isSubmittingFeedback = true;
    });

    try {
      await GrievanceService().submitFeedback(
        widget.id,
        _rating!,
        _feedbackController.text.trim(),
      );
      _feedbackController.clear();
      if (mounted) {
        setState(() {
          _rating = null;
        });
      }
      _showToast(l10n.feedbackSubmitted, color: _success);
      await _refreshGrievance();
    } catch (e) {
      _showToast('${l10n.error}: $e', color: _danger);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingFeedback = false;
        });
      }
    }
  }

  Future<void> _deleteGrievance() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await GrievanceService().deleteGrievance(widget.id);
      if (!mounted) return;
      _showToast(l10n.grievanceDeletedSuccessfully, color: _success);
      Navigator.of(context).pop(true);
    } catch (e) {
      _showToast('${l10n.failedToDeleteGrievance}: $e', color: _danger);
    }
  }

  void _onMenuSelected(String value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == 'edit') {
      Navigator.pushNamed(context, '/citizen/edit', arguments: widget.id).then((_) {
        _refreshGrievance();
      });
      return;
    }

    if (value == 'delete') {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: dsSurfaceAlt,
          title: Text(
            l10n.confirmDelete,
            style: const TextStyle(color: dsTextPrimary),
          ),
          content: Text(
            l10n.areYouSureDeleteGrievance,
            style: const TextStyle(color: dsTextSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteGrievance();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _danger.withValues(alpha: 0.18),
                foregroundColor: _danger,
                side: BorderSide(color: _danger.withValues(alpha: 0.4)),
              ),
              child: Text(l10n.delete),
            ),
          ],
        ),
      );
    }
  }

  bool _canManageGrievance(User? currentUser, Grievance? grievance) {
    if (currentUser == null || grievance == null) return false;
    final role = currentUser.role?.toLowerCase();
    return grievance.citizenId == currentUser.id || role == 'admin';
  }

  bool _canSubmitFeedback(User? currentUser, Grievance grievance) {
    return (grievance.status ?? '').toLowerCase() == 'resolved' &&
        grievance.feedbackRating == null &&
        currentUser?.role?.toLowerCase() == 'citizen' &&
        grievance.citizenId == currentUser?.id;
  }

  bool _canViewFeedback(User? currentUser, Grievance grievance) {
    if ((grievance.feedbackRating ?? 0) <= 0) return false;
    final role = currentUser?.role?.toLowerCase();
    return role == 'admin' ||
        role == 'member_head' ||
        (role == 'citizen' && grievance.citizenId == currentUser?.id);
  }

  @override
  Widget build(BuildContext context) {
    final grievanceAsync = ref.watch(grievanceProvider(widget.id));
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(userNotifierProvider);

    return Scaffold(
      backgroundColor: dsBackground,
      appBar: _buildAppBar(l10n, currentUser, grievanceAsync.value),
      body: grievanceAsync.when(
        loading: _buildLoadingState,
        error: (error, _) => _buildErrorState(l10n, error),
        data: (grievance) => Column(
          children: [
            Expanded(
              child: _buildBody(
                grievance: grievance,
                currentUser: currentUser,
                l10n: l10n,
              ),
            ),
            _buildCommentComposer(l10n),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    AppLocalizations l10n,
    User? currentUser,
    Grievance? grievance,
  ) {
    return AppBar(
      backgroundColor: dsSurface,
      foregroundColor: dsAccent,
      elevation: 0,
      titleSpacing: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: dsAccent.withValues(alpha: 0.2)),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.grievanceDetails,
            style: const TextStyle(
              color: dsTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Live citizen case view',
            style: TextStyle(
              color: dsTextSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: l10n.refresh,
          onPressed: _refreshGrievance,
          icon: const Icon(Icons.refresh_rounded, color: dsAccent),
        ),
        if (_canManageGrievance(currentUser, grievance))
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            color: dsSurfaceAlt,
            icon: const Icon(Icons.more_vert_rounded, color: dsTextPrimary),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Text(
                  l10n.edit,
                  style: const TextStyle(color: dsTextPrimary),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  l10n.delete,
                  style: const TextStyle(color: _danger),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: _cardDecoration(accent: dsAccent),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: dsAccent,
                backgroundColor: _slateBorder,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading your grievance details...',
              style: TextStyle(
                color: dsTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(24),
          decoration: _cardDecoration(accent: _danger),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: _danger, size: 48),
              const SizedBox(height: 14),
              Text(
                l10n.failedToLoadGrievance,
                style: const TextStyle(
                  color: dsTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                '$error',
                style: const TextStyle(
                  color: dsTextSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _refreshGrievance,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.refresh),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _danger.withValues(alpha: 0.18),
                  foregroundColor: _danger,
                  side: BorderSide(color: _danger.withValues(alpha: 0.4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required Grievance grievance,
    required User? currentUser,
    required AppLocalizations l10n,
  }) {
    return RefreshIndicator(
      onRefresh: _refreshGrievance,
      color: dsAccent,
      backgroundColor: dsSurface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1040;

                final mainColumn = Column(
                  children: [
                    _buildDescriptionCard(grievance, l10n),
                    const SizedBox(height: 16),
                    _buildAttachmentsSection(grievance, l10n),
                    const SizedBox(height: 16),
                    _buildWorkproofSection(grievance),
                    if (_canSubmitFeedback(currentUser, grievance) ||
                        _canViewFeedback(currentUser, grievance)) ...[
                      const SizedBox(height: 16),
                      _buildFeedbackSection(grievance, currentUser, l10n),
                    ],
                    const SizedBox(height: 16),
                    _buildCommentsSection(grievance, currentUser?.id, l10n),
                  ],
                );

                final sideColumn = Column(
                  children: [
                    _buildStatusCard(grievance),
                    const SizedBox(height: 16),
                    _buildPeopleCard(grievance, l10n),
                    const SizedBox(height: 16),
                    _buildCaseDetailsCard(grievance, l10n),
                    const SizedBox(height: 16),
                    _buildTimelineCard(grievance, l10n),
                    if (grievance.address != null ||
                        grievance.latitude != null ||
                        grievance.longitude != null) ...[
                      const SizedBox(height: 16),
                      _buildLocationCard(grievance, l10n),
                    ],
                  ],
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroSection(grievance),
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

  Widget _buildHeroSection(Grievance grievance) {
    final status = grievance.status ?? 'new';
    final statusColor = _statusColor(status);
    final priorityColor = _priorityColor(grievance.priority);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            dsSurface,
            dsSurfaceAlt,
            dsAccent.withValues(alpha: 0.12),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: dsAccent.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -30,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dsAccent.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -36,
            bottom: -52,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withValues(alpha: 0.08),
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
                            color: dsAccent,
                          ),
                          _buildTopChip(
                            icon: _statusIcon(status),
                            label: _statusLabel(status),
                            color: statusColor,
                          ),
                          _buildTopChip(
                            icon: Icons.flag_rounded,
                            label: _priorityLabel(grievance.priority),
                            color: priorityColor,
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
                    color: dsTextPrimary,
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
                    color: dsTextSecondary,
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
                      icon: Icons.schedule_rounded,
                      title: 'Created',
                      value: _formatDate(grievance.createdAt),
                      color: dsAccent,
                    ),
                    _buildHeroMetric(
                      icon: Icons.engineering_rounded,
                      title: 'Assigned To',
                      value: grievance.assignee?.name ?? 'Awaiting assignment',
                      color: _purple,
                    ),
                    _buildHeroMetric(
                      icon: Icons.trending_up_rounded,
                      title: 'Escalation',
                      value: 'Level ${grievance.escalationLevel}',
                      color: _warning,
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
    final stats = <_MetricItem>[
      _MetricItem(
        icon: Icons.comment_rounded,
        label: 'Comments',
        value: '${grievance.comments?.length ?? 0}',
        color: _purple,
      ),
      _MetricItem(
        icon: Icons.attach_file_rounded,
        label: 'Attachments',
        value: '${grievance.attachments?.length ?? 0}',
        color: dsAccent,
      ),
      _MetricItem(
        icon: Icons.verified_rounded,
        label: 'Work Proofs',
        value: '${grievance.workproofs?.length ?? 0}',
        color: _success,
      ),
      _MetricItem(
        icon: Icons.star_rounded,
        label: 'Feedback',
        value: grievance.feedbackRating != null
            ? '${grievance.feedbackRating}/5'
            : 'Pending',
        color: _warning,
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

  Widget _buildStatusCard(Grievance grievance) {
    final status = grievance.status ?? 'new';
    final statusColor = _statusColor(status);

    return _buildSectionShell(
      icon: Icons.track_changes_rounded,
      title: 'Case Status',
      subtitle: 'Current tracking state and what it means for the complaint.',
      accent: statusColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.15),
                  ),
                  child: Icon(_statusIcon(status), color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Status',
                        style: TextStyle(
                          color: dsTextSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _statusLabel(status),
                        style: const TextStyle(
                          color: dsTextPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: dsSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _slateBorder),
            ),
            child: Text(
              'You can use this page to follow updates, review field proofs, and add comments to the thread as your complaint progresses.',
              style: const TextStyle(
                color: dsTextSecondary,
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleCard(Grievance grievance, AppLocalizations l10n) {
    return _buildSectionShell(
      icon: Icons.people_alt_rounded,
      title: 'People',
      subtitle: 'Owner and assigned staff linked to this grievance.',
      accent: _purple,
      child: Column(
        children: [
          _buildPersonPanel(
            title: l10n.citizenName,
            subtitle: 'Complaint owner',
            user: grievance.citizen,
            accent: dsAccent,
            emptyMessage: 'Citizen details are not available for this grievance.',
          ),
          const SizedBox(height: 12),
          _buildPersonPanel(
            title: l10n.assignedToLabel,
            subtitle: 'Current handling staff',
            user: grievance.assignee,
            accent: _purple,
            emptyMessage: 'Your grievance has not been assigned yet.',
          ),
        ],
      ),
    );
  }

  Widget _buildCaseDetailsCard(Grievance grievance, AppLocalizations l10n) {
    final tiles = [
      _buildDetailTile(
        icon: Icons.category_rounded,
        label: l10n.filterBySubject,
        value: grievance.subject?.name ?? 'Not mapped',
        accent: _purple,
      ),
      _buildDetailTile(
        icon: Icons.map_rounded,
        label: l10n.filterByArea,
        value: grievance.area?.name ?? 'Not mapped',
        accent: dsAccent,
      ),
      _buildDetailTile(
        icon: Icons.grid_view_rounded,
        label: 'Ward',
        value: grievance.wardNumber ?? 'Not specified',
        accent: _warning,
      ),
      _buildDetailTile(
        icon: Icons.flag_rounded,
        label: l10n.filterByPriority,
        value: _priorityLabel(grievance.priority),
        accent: _priorityColor(grievance.priority),
      ),
      _buildDetailTile(
        icon: Icons.badge_rounded,
        label: l10n.citizenId,
        value: grievance.citizenId?.toString() ?? 'Unknown',
        accent: _success,
      ),
      _buildDetailTile(
        icon: Icons.confirmation_number_rounded,
        label: 'Record ID',
        value: grievance.id.toString(),
        accent: dsTextSecondary,
      ),
    ];

    return _buildSectionShell(
      icon: Icons.dashboard_customize_rounded,
      title: l10n.description,
      subtitle: 'Reference fields and routing information for the complaint.',
      accent: dsAccent,
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

  Widget _buildTimelineCard(Grievance grievance, AppLocalizations l10n) {
    final items = <_TimelineItem>[
      _TimelineItem(
        icon: Icons.add_circle_outline_rounded,
        label: l10n.created,
        value: _formatDateTime(grievance.createdAt),
        color: dsAccent,
      ),
      _TimelineItem(
        icon: Icons.update_rounded,
        label: l10n.lastUpdated,
        value: _formatDateTime(grievance.updatedAt),
        color: _purple,
      ),
      if (grievance.resolvedAt != null)
        _TimelineItem(
          icon: Icons.task_alt_rounded,
          label: 'Resolved',
          value: _formatDateTime(grievance.resolvedAt),
          color: _success,
        ),
    ];

    return _buildSectionShell(
      icon: Icons.timeline_rounded,
      title: 'Timeline',
      subtitle: 'Key milestones recorded as this complaint moves forward.',
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
                color: _slateBorder,
              ),
          ],
          if ((grievance.rejectionReason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _danger.withValues(alpha: 0.22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rejection Reason',
                    style: TextStyle(
                      color: _danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    grievance.rejectionReason!,
                    style: const TextStyle(
                      color: dsTextPrimary,
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

  Widget _buildLocationCard(Grievance grievance, AppLocalizations l10n) {
    return _buildSectionShell(
      icon: Icons.place_rounded,
      title: l10n.locationDetails,
      subtitle: 'Address and coordinates submitted with the complaint.',
      accent: _success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((grievance.address ?? '').trim().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: dsSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _success.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.home_work_rounded, color: _success, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      grievance.address!,
                      style: const TextStyle(
                        color: dsTextPrimary,
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

  Widget _buildDescriptionCard(Grievance grievance, AppLocalizations l10n) {
    return _buildSectionShell(
      icon: Icons.notes_rounded,
      title: l10n.details,
      subtitle: 'The full complaint description and important notes.',
      accent: dsAccent,
      child: Text(
        grievance.description.isEmpty
            ? 'No description was entered for this grievance.'
            : grievance.description,
        style: const TextStyle(
          color: dsTextPrimary,
          fontSize: 14,
          height: 1.7,
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection(
    Grievance grievance,
    AppLocalizations l10n,
  ) {
    final List<GrievanceAttachment> attachments =
        grievance.attachments ?? const <GrievanceAttachment>[];

    return _buildSectionShell(
      icon: Icons.attach_file_rounded,
      title: l10n.attachments,
      subtitle: 'Files and visual evidence shared with your complaint.',
      accent: dsAccent,
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
                        accent: dsAccent,
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
      subtitle: 'Completion proof and updates uploaded by field staff.',
      accent: _success,
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

  Widget _buildFeedbackSection(
    Grievance grievance,
    User? currentUser,
    AppLocalizations l10n,
  ) {
    final canSubmit = _canSubmitFeedback(currentUser, grievance);
    final canView = _canViewFeedback(currentUser, grievance);

    return _buildSectionShell(
      icon: Icons.star_rounded,
      title: canSubmit ? l10n.submitFeedback : l10n.submittedFeedback,
      subtitle: canSubmit
          ? 'Share your satisfaction after the grievance is resolved.'
          : 'Your submitted rating and feedback for this complaint.',
      accent: _warning,
      child: canSubmit
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.selectRating,
                  style: const TextStyle(
                    color: dsTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(5, (index) {
                    final rating = index + 1;
                    final selected = _rating == rating;
                    return ChoiceChip(
                      label: Text('$rating'),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          _rating = value ? rating : null;
                        });
                      },
                      labelStyle: TextStyle(
                        color: selected ? dsSurface : dsTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      selectedColor: _warning,
                      backgroundColor: dsSurface,
                      side: BorderSide(
                        color: selected
                            ? _warning
                            : _warning.withValues(alpha: 0.24),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _feedbackController,
                  minLines: 3,
                  maxLines: 4,
                  style: const TextStyle(color: dsTextPrimary),
                  decoration: dsFormFieldDecoration(label: l10n.feedback),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isSubmittingFeedback ? null : _submitFeedback,
                  icon: _isSubmittingFeedback
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: dsTextPrimary,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _isSubmittingFeedback ? 'Submitting...' : l10n.submit,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _warning..withValues(alpha: 0.18),
                    foregroundColor: dsTextPrimary,
                    side: BorderSide(color: _warning.withValues(alpha: 0.45)),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            )
          : canView
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              index < (grievance.feedbackRating ?? 0)
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: _warning,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${grievance.feedbackRating}/5',
                          style: const TextStyle(
                            color: dsTextPrimary,
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
                          color: dsSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _warning.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          grievance.feedbackText!,
                          style: const TextStyle(
                            color: dsTextPrimary,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                )
              : const SizedBox.shrink(),
    );
  }

  Widget _buildCommentsSection(
    Grievance grievance,
    int? currentUserId,
    AppLocalizations l10n,
  ) {
    final List<Comment> comments = grievance.comments ?? const <Comment>[];

    return _buildSectionShell(
      icon: Icons.forum_rounded,
      title: l10n.comments,
      subtitle: 'Conversation history and updates related to this grievance.',
      accent: _purple,
      child: comments.isEmpty
          ? _buildEmptyMessage(
              icon: Icons.chat_bubble_outline_rounded,
              message: l10n.noCommentsMessage,
            )
          : Column(
              children: comments
                  .map(
                    (comment) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCommentCard(comment, currentUserId),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildCommentComposer(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: dsSurface,
        border: Border(top: BorderSide(color: dsAccent.withValues(alpha: 0.16))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedFiles.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: dsSurfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dsAccent.withValues(alpha: 0.14)),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedFiles
                      .map(
                        (file) => InputChip(
                          label: Text(
                            file.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: dsTextPrimary),
                          ),
                          backgroundColor: dsSurface,
                          side: BorderSide(color: dsAccent.withValues(alpha: 0.2)),
                          onDeleted: () {
                            setState(() {
                              _selectedFiles.remove(file);
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(color: dsTextPrimary),
                    decoration: dsFormFieldDecoration(label: l10n.addComment),
                  ),
                ),
                const SizedBox(width: 10),
                _buildComposerAction(
                  icon: Icons.attach_file_rounded,
                  tooltip: l10n.attachments,
                  onTap: _pickCommentAttachments,
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isPostingComment ? null : _addComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dsAccent.withValues(alpha: 0.18),
                    foregroundColor: dsTextPrimary,
                    side: BorderSide(color: dsAccent.withValues(alpha: 0.45)),
                    minimumSize: const Size(54, 54),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: _isPostingComment
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: dsTextPrimary,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposerAction({
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
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: dsSurfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: dsAccent.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, color: dsAccent),
          ),
        ),
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
              color: dsSurface,
              shape: BoxShape.circle,
              border: Border.all(color: _slateBorder),
            ),
            child: Icon(icon, color: dsTextPrimary, size: 18),
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
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dsSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
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

  Widget _buildStatCard(_MetricItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(accent: item.color, radius: 18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
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
                    color: dsTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
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

  Widget _buildSectionShell({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(accent: accent),
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
                    color: accent.withValues(alpha: 0.12),
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
                          color: dsTextPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: dsTextSecondary,
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
          color: dsSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _slateBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.person_off_rounded, color: accent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                emptyMessage,
                style: const TextStyle(
                  color: dsTextSecondary,
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
        color: dsSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: accent.withValues(alpha: 0.16),
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
                        color: dsTextSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _safeText(user.name),
                      style: const TextStyle(
                        color: dsTextPrimary,
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
                  color: dsAccent,
                ),
              if ((user.phoneNumber ?? '').trim().isNotEmpty)
                _buildInlineInfoChip(
                  icon: Icons.phone_rounded,
                  text: user.phoneNumber!,
                  color: _success,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: dsTextSecondary,
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
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
        color: dsSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
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
                    color: dsTextSecondary,
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
              color: dsTextPrimary,
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
            color: item.color.withValues(alpha: 0.12),
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
                  color: dsTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                style: const TextStyle(
                  color: dsTextPrimary,
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
        color: dsSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _success.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: dsTextPrimary,
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
        color: dsSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _slateBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: dsTextSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: dsTextSecondary,
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
    final resolvedImageUrl = Constants.resolveMediaUrl(path);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchURL(path),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: dsSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 62,
                  height: 62,
                  color: dsBackground,
                  child: (isImage && resolvedImageUrl != null)
                      ? Image.network(
                          resolvedImageUrl,
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
                        color: dsTextPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: dsTextSecondary,
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
        color: dsSurfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _success.withValues(alpha: 0.16)),
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
              accent: _success,
            ),
            if ((workproof.notes ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: dsSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _slateBorder),
                ),
                child: Text(
                  workproof.notes!,
                  style: const TextStyle(
                    color: dsTextPrimary,
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
    final accent = isCurrentUser ? dsAccent : _purple;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrentUser ? dsSurface : dsSurfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accent.withValues(alpha: 0.16),
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
                              color: dsTextPrimary,
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
                              color: dsAccent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                color: dsAccent,
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
                        color: dsTextSecondary,
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
              color: dsTextPrimary,
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

class _MetricItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricItem({
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
