import 'package:ride_app/features/notification/domain/entities/notification_entity.dart';

enum NotificationStatus { initial, loading, success, error }

class NotificationState {
  static const Object _keepMessage = Object();

  final NotificationStatus toggleNotifStatus;
  final NotificationStatus getNotifStatus;
  final String? message;
  final bool isNotificationEnabled;
  final List<NotificationEntity> notifications;
  final bool isDeleting;

  // Pagination
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  const NotificationState({
    this.toggleNotifStatus = NotificationStatus.initial,
    this.getNotifStatus = NotificationStatus.initial,
    this.message,
    this.isNotificationEnabled = true,
    this.notifications = const [],
    this.isDeleting = false,
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  NotificationState copyWith({
    NotificationStatus? toggleNotifStatus,
    NotificationStatus? getNotifStatus,
    Object? message = _keepMessage,
    bool? isNotificationEnabled,
    List<NotificationEntity>? notifications,
    bool? isDeleting,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return NotificationState(
      toggleNotifStatus: toggleNotifStatus ?? this.toggleNotifStatus,
      getNotifStatus: getNotifStatus ?? this.getNotifStatus,
      message: message == _keepMessage ? this.message : message as String?,
      isNotificationEnabled: isNotificationEnabled ?? this.isNotificationEnabled,
      notifications: notifications ?? this.notifications,
      isDeleting: isDeleting ?? this.isDeleting,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
