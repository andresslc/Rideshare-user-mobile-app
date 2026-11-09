// models.dart

import '../domain/entities/notification_entity.dart';

class NotificationContentModel extends NotificationContentEntity {
  const NotificationContentModel({
    required super.id,
    super.title,
    super.description,
    super.metaData,
  });

  factory NotificationContentModel.fromJson(Map<String, dynamic> json) {
    return NotificationContentModel(
      id: json['_id'] ?? "",
      title: json['title'],
      description: json['description'],
      metaData: json['metaData'] != null
          ? Map<String, dynamic>.from(json['metaData'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "title": title,
      "description": description,
      "metaData": metaData,
    };
  }
}

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.notificationContent,
    required super.user,
    required super.userType,
    required super.isRead,
    required super.createdAt,
    super.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? "",
      notificationContent: NotificationContentModel.fromJson(
        json['notificationContent'] ?? {},
      ),
      user: json['user'] ?? "",
      userType: json['userType'] ?? "",
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "notificationContent": (notificationContent as NotificationContentModel).toJson(),
      "user": user,
      "userType": userType,
      "isRead": isRead,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt?.toIso8601String(),
    };
  }
}