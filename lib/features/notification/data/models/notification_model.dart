import 'package:ride_app/features/notification/domain/entities/notification_entity.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

class NotificationContentModel {
  final String id;
  final String? title;
  final String? description;
  final Map<String, dynamic>? metaData;

  const NotificationContentModel({
    required this.id,
    this.title,
    this.description,
    this.metaData,
  });

  factory NotificationContentModel.fromJson(Map<String, dynamic> json) {
    return NotificationContentModel(
      id: (json['_id'] ?? '').toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      metaData: json['metaData'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['metaData'] as Map)
          : null,
    );
  }

  NotificationContentEntity toEntity() {
    return NotificationContentEntity(
      id: id,
      title: title,
      description: description,
      metaData: metaData,
    );
  }
}

class NotificationModel {
  final String id;
  final NotificationContentModel notificationContent;
  final String user;
  final String userType;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const NotificationModel({
    required this.id,
    required this.notificationContent,
    required this.user,
    required this.userType,
    required this.isRead,
    required this.createdAt,
    this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['_id'] ?? '').toString(),
      notificationContent: NotificationContentModel.fromJson(
        json['notificationContent'] is Map<String, dynamic>
            ? json['notificationContent'] as Map<String, dynamic>
            : const {},
      ),
      user: (json['user'] ?? '').toString(),
      userType: (json['userType'] ?? '').toString(),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  /// GET `/api/notification` — list items live in `data` as an array.
  static List<NotificationModel> listFromResponse(Map<String, dynamic> body) {
    final envelope = _requireSuccess(body, 'Failed to fetch notifications');
    final data = envelope.data;
    if (data is! List<dynamic>) {
      return const [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
  }

  static ApiResponse successEnvelopeFromResponse(
    Map<String, dynamic> body, {
    required String fallbackMessage,
  }) {
    return _requireSuccess(body, fallbackMessage);
  }

  NotificationEntity toEntity() {
    return NotificationEntity(
      id: id,
      notificationContent: notificationContent.toEntity(),
      user: user,
      userType: userType,
      isRead: isRead,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static ApiResponse _requireSuccess(
    Map<String, dynamic> body,
    String fallbackMessage,
  ) {
    final envelope = ApiResponse.fromMap(body);
    if (!envelope.success) {
      throw Exception(envelope.message ?? fallbackMessage);
    }
    return envelope;
  }

  static DateTime? _parseDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
