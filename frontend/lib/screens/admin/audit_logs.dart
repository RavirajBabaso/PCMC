// lib/screens/admin/audit_logs.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../widgets/app/app_button.dart';
import '../../widgets/empty_state.dart';
import '../../theme/app_theme.dart';

// Add these color definitions
const Color _success = Color(0xFF10B981);
const Color _warning = Color(0xFFF59E0B);
const Color _danger = Color(0xFFEF4444);
const Color _purple = Color(0xFF8B5CF6);

class AuditLogs extends ConsumerStatefulWidget {
  const AuditLogs({super.key});

  @override
  ConsumerState<AuditLogs> createState() => _AuditLogsState();
}

class _AuditLogsState extends ConsumerState<AuditLogs> {
  late Future<List<dynamic>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = _fetchLogs();
  }

  Future<List<dynamic>> _fetchLogs() async {
    final response = await ApiService.get('/admins/audit-logs');
    return response.data as List<dynamic>;
  }

  void _refreshLogs() {
    setState(() {
      _logsFuture = _fetchLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: dsBackground,
      appBar: AppBar(
        title: const Text(
          'Audit Logs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: dsAccent,
          ),
        ),
        centerTitle: true,
        backgroundColor: dsSurface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: dsBorder),
        ),
        iconTheme: const IconThemeData(color: dsAccent),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: dsAccent,
            tooltip: "Refresh Logs",
            onPressed: _refreshLogs,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: dsAccent,
                strokeWidth: 3,
              ),
            );
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Error Loading Logs',
              message: 'Failed to load audit logs. Please try again.',
              actionButton: AppButton(
                text: 'Retry',
                onPressed: _refreshLogs,
                backgroundColor: dsAccent,
              ),
            );
          }
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return EmptyState(
              icon: Icons.history_toggle_off,
              title: 'No Audit Logs',
              message: 'There are no audit logs to display at this time.',
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activities',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: dsAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: dsAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: dsAccent..withValues(alpha: 0.24),
                        ),
                      ),
                      child: Text(
                        '${logs.length} entries',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: dsAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _buildLogCard(log, theme);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log, ThemeData theme) {
    final action = log['action'] ?? 'Unknown Action';
    final actionIcon = _getActionIcon(action);
    final iconColor = _getIconColor(action);

    return Container(
      decoration: BoxDecoration(
        color: dsSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dsBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Handle log item tap if needed
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Icon(
                    actionIcon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: dsTextPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.person_outline_rounded,
                        'Performed by: ${log['performed_by'] ?? 'Unknown'}',
                        theme,
                      ),
                      const SizedBox(height: 4),
                      _buildInfoRow(
                        Icons.access_time_rounded,
                        'At: ${_formatTimestamp(log['timestamp'])}',
                        theme,
                      ),
                      if (log['details'] != null) ...[
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          Icons.description_outlined,
                          'Details: ${log['details']}',
                          theme,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: dsTextSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: dsTextSecondary,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  IconData _getActionIcon(String action) {
    final lowerAction = action.toLowerCase();
    if (lowerAction.contains('login')) return Icons.login_rounded;
    if (lowerAction.contains('create') || lowerAction.contains('add')) return Icons.add_circle_rounded;
    if (lowerAction.contains('update') || lowerAction.contains('edit')) return Icons.edit_rounded;
    if (lowerAction.contains('delete') || lowerAction.contains('remove')) return Icons.delete_rounded;
    if (lowerAction.contains('view') || lowerAction.contains('read')) return Icons.visibility_rounded;
    if (lowerAction.contains('export')) return Icons.download_rounded;
    if (lowerAction.contains('import')) return Icons.upload_rounded;
    return Icons.info_rounded;
  }

  Color _getIconColor(String action) {
    final lowerAction = action.toLowerCase();
    if (lowerAction.contains('login')) return dsAccent;
    if (lowerAction.contains('create') || lowerAction.contains('add')) return _success;
    if (lowerAction.contains('update') || lowerAction.contains('edit')) return _warning;
    if (lowerAction.contains('delete') || lowerAction.contains('remove')) return _danger;
    if (lowerAction.contains('view') || lowerAction.contains('read')) return _purple;
    if (lowerAction.contains('export')) return dsAccent;
    if (lowerAction.contains('import')) return dsAccent;
    return dsTextSecondary;
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      // Show relative time for recent logs
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Just now';
          }
          return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
        }
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${_formatTime(dateTime)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      }
      
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
    } catch (e) {
      return timestamp;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
    return '$displayHour:$minute $period';
  }
}