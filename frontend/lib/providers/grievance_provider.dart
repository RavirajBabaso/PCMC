import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/grievance_model.dart';
import '../models/paginated_result.dart';
import '../services/grievance_service.dart';

// ── Family provider: citizen grievance history by userId ─────────────────────
final citizenHistoryProvider =
    FutureProvider.family<List<Grievance>, int>((ref, userId) async {
  final response = await GrievanceService().getGrievancesByUserId(userId);
  return response.items;
});

// ── State ─────────────────────────────────────────────────────────────────────
class GrievanceState {
  final List<Grievance> grievances;
  final bool isLoading;
  final String? error;

  const GrievanceState({
    this.grievances = const [],
    this.isLoading = false,
    this.error,
  });

  GrievanceState copyWith({
    List<Grievance>? grievances,
    bool? isLoading,
    String? error,
  }) =>
      GrievanceState(
        grievances: grievances ?? this.grievances,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class GrievanceNotifier extends StateNotifier<GrievanceState> {
  final GrievanceService _service;

  GrievanceNotifier(this._service) : super(const GrievanceState());

  Future<void> _fetch(Future<PaginatedResult<Grievance>> Function() loader) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final page = await loader();
      state = state.copyWith(grievances: page.items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> fetchMyGrievances({int page = 1, int perPage = 20}) =>
      _fetch(() => _service.getMyGrievances(page: page, perPage: perPage));
  Future<void> fetchNewGrievances({int page = 1, int perPage = 20}) =>
      _fetch(() => _service.getNewGrievances(page: page, perPage: perPage));
  Future<void> fetchAssignedGrievances({int page = 1, int perPage = 20}) =>
      _fetch(() => _service.getAssignedGrievances(page: page, perPage: perPage));
}

final grievanceProvider =
    StateNotifierProvider<GrievanceNotifier, GrievanceState>(
        (ref) => GrievanceNotifier(ref.read(grievanceServiceProvider)));
