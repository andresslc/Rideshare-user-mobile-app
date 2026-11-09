// entities.dart

class NotificationContentEntity {
  final String id;
  final String? title;
  final String? description;
  final Map<String, dynamic>? metaData;

  const NotificationContentEntity({
    required this.id,
    this.title,
    this.description,
    this.metaData,
  });
}

class NotificationEntity {
  final String id;
  final NotificationContentEntity notificationContent;
  final String user;
  final String userType;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const NotificationEntity({
    required this.id,
    required this.notificationContent,
    required this.user,
    required this.userType,
    required this.isRead,
    required this.createdAt,
    this.updatedAt,
  });
}