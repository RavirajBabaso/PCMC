import 'package:dio/dio.dart';

import '../models/grievance_model.dart';
import '../models/paginated_result.dart';
import 'api_service.dart';

class AdminService {
  final Dio _dio = ApiService.dio;

  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _dio.get('/admins/dashboard');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load dashboard data: $e');
    }
  }

  Future<List<dynamic>> getAuditLogs() async {
    try {
      final response = await _dio.get('/admins/audit-logs');
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to load audit logs: $e');
    }
  }

  PaginatedResult<Grievance> _parseGrievancePage(Response response) {
    final payload = response.data as Map<String, dynamic>;
    final raw = payload['grievances'] as List<dynamic>;
    final grievances = raw
        .map((item) => Grievance.fromJson(item as Map<String, dynamic>))
        .toList();
    return PaginatedResult<Grievance>(
      items: grievances,
      total: payload['total'] as int? ?? grievances.length,
      page: payload['page'] as int? ?? 1,
      perPage: payload['per_page'] as int? ?? grievances.length,
    );
  }

  Future<PaginatedResult<Grievance>> getAllGrievances({
    String? status,
    String? priority,
    int? areaId,
    int? subjectId,
    int page = 1,
    int perPage = 20,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      final response = await _dio.get(
        '/admins/grievances/all',
        queryParameters: {
          if (status != null) 'status': status,
          if (priority != null) 'priority': priority,
          if (areaId != null) 'area_id': areaId,
          if (subjectId != null) 'subject_id': subjectId,
          'page': page,
          'per_page': perPage,
          'sort_by': sortBy,
          'sort_order': sortOrder,
        },
      );
      return _parseGrievancePage(response);
    } on DioException catch (e) {
      throw Exception('Failed to fetch grievances: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch grievances: $e');
    }
  }
}
