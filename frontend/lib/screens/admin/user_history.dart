import 'dart:async'; // For debouncing
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/grievance_provider.dart';
import '../../widgets/grievance_card.dart';
import '../../widgets/empty_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class UserHistoryScreen extends ConsumerStatefulWidget {
  final int? userId;
  const UserHistoryScreen({super.key, this.userId});

  @override
  _UserHistoryScreenState createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends ConsumerState<UserHistoryScreen> {
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.userId == null) {
      return Scaffold(
        backgroundColor: dsBackground,
        appBar: _buildAppBar(l10n.userHistory),
        body: EmptyState(
          icon: Icons.error_outline,
          title: l10n.userNotFound,
          message: l10n.userIdRequired,
        ),
      );
    }

    final history = ref.watch(citizenHistoryProvider(widget.userId!));

    return Scaffold(
      backgroundColor: dsBackground,
      appBar: _buildAppBar(l10n.userHistory),
      body: Column(
        children: [
          // Search Field
          _buildSearchField(l10n),
          Expanded(
            child: history.when(
              data: (grievances) {
                final filteredGrievances = grievances.where((grievance) {
                  final name = grievance.citizen?.name?.toLowerCase() ?? '';
                  final searchText = _searchText.toLowerCase();
                  return name.contains(searchText);
                }).toList();

                if (filteredGrievances.isEmpty) {
                  return _buildEmptyState(_searchText.isEmpty);
                }

                return RefreshIndicator(
                  color: dsAccent,
                  backgroundColor: dsSurface,
                  onRefresh: () async {
                    ref.refresh(citizenHistoryProvider(widget.userId!));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredGrievances.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GrievanceCard(grievance: filteredGrievances[index]),
                    ),
                  ),
                );
              },
              loading: () => _buildLoadingState(l10n),
              error: (err, stack) => _buildErrorState(l10n, err.toString()),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          hintText: l10n.searchByName,
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
                color: dsAccent.withValues(alpha:0.12),
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
              isSearchEmpty ? 'No grievances found' : 'No results found',
              style: const TextStyle(
                color: dsTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearchEmpty 
                ? 'No grievances have been submitted by this user yet.'
                : 'Try adjusting your search or clear the filter.',
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

  Widget _buildLoadingState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 3,
            color: dsAccent,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.loading,
            style: const TextStyle(
              color: dsTextSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n, String error) {
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
                color: _danger.withValues(alpha:0.12),
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
              l10n.error,
              style: const TextStyle(
                color: dsTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                color: dsTextSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                ref.refresh(citizenHistoryProvider(widget.userId!));
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
}

// Status colors matching theme

const Color _danger = Color(0xFFEF4444);
