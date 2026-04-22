import 'package:main_ui/models/comment_model.dart';
import 'package:main_ui/models/master_data_model.dart';
import 'package:main_ui/models/user_model.dart';
import 'package:main_ui/models/workproof_model.dart';

class Assignee {
  final String? name;

  Assignee({this.name});

  factory Assignee.fromJson(Map<String, dynamic> json) {
    return Assignee(
      name: json['name'] as String?,
    );
  }
}

class Grievance {
  final int id;
  final String complaintId;
  final int? citizenId;
  final int? subjectId;
  final int? areaId;
  final String title;
  final String description;
  final String? wardNumber;
  final String? status;
  final String? priority;
  final int? assignedTo;
  final int? assignedBy;
  final String? rejectionReason;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? latitude;
  final double? longitude;
  final String? address;
  final int escalationLevel;
  final int? feedbackRating;
  final String? feedbackText;
  final User? citizen;
  final User? assignee;
  final MasterSubject? subject;
  final MasterArea? area;
  String? get areaName => area?.name;
  final List<GrievanceAttachment>? attachments;
  final List<Comment>? comments;
  final List<Workproof>? workproofs;

  Grievance({
    required this.id,
    required this.complaintId,
    this.citizenId,
    this.subjectId,
    this.areaId,
    required this.title,
    required this.description,
    this.wardNumber,
    this.status,
    this.priority,
    this.assignedTo,
    this.assignedBy,
    this.rejectionReason,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.address,
    required this.escalationLevel,
    this.feedbackRating,
    this.feedbackText,
    this.citizen,
    this.assignee,
    this.subject,
    this.area,
    this.attachments,
    this.comments,
    this.workproofs,
  });

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static DateTime _parseDateTime(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed ?? DateTime.now();
  }

  factory Grievance.fromJson(Map<String, dynamic> json) {
    return Grievance(
      id: _parseInt(json['id']),
      complaintId: json['complaint_id']?.toString() ?? '',
      citizenId: json['citizen'] != null ? _parseInt(json['citizen']['id']) : null,
      subjectId: json['subject'] != null ? _parseInt(json['subject']['id']) : null,
      areaId: json['area'] != null ? _parseInt(json['area']['id']) : null,
      title: json['title']?.toString() ?? 'Untitled',
      description: json['description']?.toString() ?? '',
      wardNumber: json['ward_number']?.toString(),
      status: json['status']?.toString(),
      priority: json['priority']?.toString(),
      assignedTo: json['assignee'] != null ? _parseInt(json['assignee']['id']) : null,
      assignedBy: json['assigner'] != null ? _parseInt(json['assigner']['id']) : null,
      rejectionReason: json['rejection_reason']?.toString(),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'].toString())
          : null,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      address: json['address']?.toString(),
      escalationLevel: _parseInt(json['escalation_level']),
      feedbackRating: json['feedback_rating'] is num
          ? (json['feedback_rating'] as num).toInt()
          : int.tryParse(json['feedback_rating']?.toString() ?? ''),
      feedbackText: json['feedback_text']?.toString(),
      citizen: json['citizen'] != null
          ? User.fromJson(json['citizen'] as Map<String, dynamic>)
          : null,
      assignee: json['assignee'] != null
          ? User.fromJson(json['assignee'] as Map<String, dynamic>)
          : null,
      subject: json['subject'] != null
          ? MasterSubject.fromJson(json['subject'] as Map<String, dynamic>)
          : null,
      area: json['area'] != null
          ? MasterArea.fromJson(json['area'] as Map<String, dynamic>)
          : null,
      attachments: json['attachments'] is List
          ? (json['attachments'] as List)
              .map((a) => GrievanceAttachment.fromJson(a as Map<String, dynamic>))
              .toList()
          : null,
      comments: json['comments'] is List
          ? (json['comments'] as List)
              .map((c) => Comment.fromJson(c as Map<String, dynamic>))
              .toList()
          : null,
      workproofs: json['workproofs'] is List
          ? (json['workproofs'] as List)
              .map((wp) => Workproof.fromJson(wp as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'complaint_id': complaintId,
      'citizen_id': citizenId,
      'subject_id': subjectId,
      'area_id': areaId,
      'title': title,
      'description': description,
      'ward_number': wardNumber,
      'status': status,
      'priority': priority,
      'assigned_to': assignedTo,
      'assigned_by': assignedBy,
      'rejection_reason': rejectionReason,
      'resolved_at': resolvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'escalation_level': escalationLevel,
      'feedback_rating': feedbackRating,
      'feedback_text': feedbackText,
      'citizen': citizen?.toJson(),
      'assignee': assignee?.toJson(),
      'subject': subject?.toJson(),
      'area': area?.toJson(),
      'attachments': attachments?.map((a) => a.toJson()).toList(),
      'comments': comments?.map((c) => c.toJson()).toList(),
      'workproofs': workproofs?.map((wp) => wp.toJson()).toList(),
    };
  }
}

class GrievanceAttachment {
  final int id;
  final int grievanceId;
  final String filePath;
  final String fileType;
  final DateTime uploadedAt;

  GrievanceAttachment({
    required this.id,
    required this.grievanceId,
    required this.filePath,
    required this.fileType,
    required this.uploadedAt,
  });

  factory GrievanceAttachment.fromJson(Map<String, dynamic> json) {
    final rawPath = (json['file_path'] ?? json['path'] ?? json['url'] ?? json['attachment_url'])?.toString() ?? '';
    return GrievanceAttachment(
      id: Grievance._parseInt(json['id']),
      grievanceId: Grievance._parseInt(json['grievance_id']),
      filePath: rawPath,
      fileType: json['file_type']?.toString() ?? json['type']?.toString() ?? '',
      uploadedAt: DateTime.tryParse(json['uploaded_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grievance_id': grievanceId,
      'file_path': filePath,
      'file_type': fileType,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}
