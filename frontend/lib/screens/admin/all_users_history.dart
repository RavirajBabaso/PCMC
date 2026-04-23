import 'dart:async';
import 'package:flutter/material.dart';
import 'package:main_ui/services/api_service.dart';
import 'package:main_ui/models/user_model.dart';
import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/theme/app_theme.dart';
import '../../widgets/empty_state.dart';

class AllUsersHistoryScreen extends StatefulWidget {
  const AllUsersHistoryScreen({super.key});

  @override
  State<AllUsersHistoryScreen> createState() => _AllUsersHistoryScreenState();
}

class _AllUsersHistoryScreenState extends State<AllUsersHistoryScreen> {
  List<dynamic> usersHistory = [];
  bool isLoading = true;
  String? error;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    fetchAllHistories();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  Future<void> fetchAllHistories() async {
    try {
      final response = await ApiService.dio.get('/admins/users/history');
      setState(() {
        usersHistory = response.data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load histories: $e';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return _success;
      case 'in_progress':
        return _warning;
      case 'pending':
      case 'new':
        return _warning;
      case 'rejected':
        return _danger;
      case 'closed':
        return dsTextSecondary;
      default:
        return dsTextSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Icons.check_circle_rounded;
      case 'in_progress':
        return Icons.sync_rounded;
      case 'pending':
      case 'new':
        return Icons.access_time_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'closed':
        return Icons.lock_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final filteredUsersHistory = usersHistory.where((userData) {
      final user = User.fromJson(userData['user']);
      final name = user.name?.toLowerCase() ?? '';
      final email = user.email?.toLowerCase() ?? '';
      final searchText = _searchText.toLowerCase();
      return name.contains(searchText) || email.contains(searchText);
    }).toList();

    return Scaffold(
      backgroundColor: dsBackground,
      appBar: _buildAppBar(l10n.allUsersHistory),
      body: Column(
        children: [
          _buildSearchField(l10n),
          Expanded(
            child: isLoading
                ? _buildLoadingState()
                : error != null
                    ? _buildErrorState()
                    : filteredUsersHistory.isEmpty
                        ? _buildEmptyState(_searchText.isEmpty)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: filteredUsersHistory.length,
                            itemBuilder: (context, index) {
                              final userData = filteredUsersHistory[index];
                              final user = User.fromJson(userData['user']);
                              final grievances = (userData['grievances'] as List)
                                  .map((g) => Grievance.fromJson(g))
                                  .toList();

                              return _buildUserCard(user, grievances);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String title) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: dsTextPrimary,
        ),
      ),
      backgroundColor: dsSurface,
      foregroundColor: dsAccent,
      elevation: 0,
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: dsBorder),
      ),
    );
  }

  Widget _buildSearchField(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dsSurface,
        border: Border(
          bottom: BorderSide(color: dsBorder, width: 1),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: dsTextPrimary),
        decoration: InputDecoration(
          hintText: l10n.searchByName ?? 'Search by name or email',
          hintStyle: const TextStyle(color: dsTextSecondary),
          prefixIcon: const Icon(Icons.search, color: dsAccent),
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: dsTextSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchText = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: dsSurfaceAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: dsBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: dsAccent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildUserCard(User user, List<Grievance> grievances) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: dsSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dsBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          backgroundColor: dsSurface,
          collapsedBackgroundColor: dsSurface,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          expandedAlignment: Alignment.centerLeft,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: dsAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: dsAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? 'Unknown',
                      style: const TextStyle(
                        color: dsTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email ?? 'No email',
                      style: const TextStyle(
                        color: dsTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: dsAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${grievances.length}',
                  style: const TextStyle(
                    color: dsAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          children: [
            const SizedBox(height: 8),
            const Text(
              'Grievance History',
              style: TextStyle(
                color: dsTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...grievances.map((g) => _buildGrievanceItem(g)),
            if (grievances.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No grievances submitted',
                    style: TextStyle(
                      color: dsTextSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrievanceItem(Grievance grievance) {
    final status = grievance.status ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final createdAt = grievance.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dsSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dsBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grievance.title,
                  style: const TextStyle(
                    color: dsTextPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  grievance.description ?? 'No description',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: dsTextSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (createdAt != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: dsTextSecondary,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                            style: const TextStyle(
                              color: dsTextSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
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

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: dsAccent),
          SizedBox(height: 16),
          Text(
            'Loading user histories...',
            style: TextStyle(color: dsTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _danger.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: _danger,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: dsTextSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  error = null;
                });
                fetchAllHistories();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: dsAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSearchEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: dsAccent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearchEmpty ? Icons.history_toggle_off : Icons.search_off,
                color: dsAccent,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearchEmpty ? 'No Histories Found' : 'No Results Found',
              style: const TextStyle(
                color: dsTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearchEmpty
                  ? 'No user histories available'
                  : 'No matching users found',
              style: const TextStyle(
                color: dsTextSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Status colors matching theme
const Color _success = Color(0xFF10B981);
const Color _warning = Color(0xFFF59E0B);
const Color _danger = Color(0xFFEF4444);
const Color _purple = Color(0xFF8B5CF6);