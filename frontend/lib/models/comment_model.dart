// lib/models/comment_model.dart
class CommentAttachment {
  final int id;
  final String filePath;
  final String fileType;

  CommentAttachment({
    required this.id,
    required this.filePath,
    required this.fileType,
  });

  factory CommentAttachment.fromJson(Map<String, dynamic> json) {
    return CommentAttachment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      filePath: (json['file_path'] ?? json['path'] ?? json['url'])?.toString() ?? '',
      fileType: (json['file_type'] ?? json['type'])?.toString() ?? '',
    );
  }
}

class Comment {
  final int id;
  final int grievanceId;
  final int userId;
  final String? userName;
  final String? commentText;
  final DateTime createdAt;
  final List<CommentAttachment>? attachments;

  Comment({
    required this.id,
    required this.grievanceId,
    required this.userId,
    this.userName,
    this.commentText,
    required this.createdAt,
    this.attachments,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      grievanceId: (json['grievance_id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      userName: json['user']?['name']?.toString(),
      commentText: json['comment_text']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      attachments: json['attachments'] is List
          ? (json['attachments'] as List)
              .map((item) => CommentAttachment.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grievance_id': grievanceId,
      'user_id': userId,
      'comment_text': commentText,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
