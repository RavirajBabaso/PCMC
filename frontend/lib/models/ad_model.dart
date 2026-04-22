// lib/models/ad_model.dart

import 'package:main_ui/utils/constants.dart';

class Advertisement {
  final int id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? linkUrl;
  final bool isActive;
  final DateTime? createdAt;

  Advertisement({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.linkUrl,
    required this.isActive,
    this.createdAt,
  });

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is int) return value == 1;
      return false;
    }

    final rawImagePath = (json['image_url'] ?? json['image'] ?? json['image_path'] ?? json['file_path'])?.toString();
    final rawLink = json['link_url']?.toString();

    return Advertisement(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: Constants.resolveMediaUrl(rawImagePath),
      linkUrl: Constants.resolveMediaUrl(rawLink, assumeUploadPath: false) ?? rawLink,
      isActive: parseBool(json['is_active'] ?? false),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
      };
}
