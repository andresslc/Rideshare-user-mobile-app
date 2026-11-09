import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/params/notification_params.dart';
import 'package:ride_app/features/notification/domain/usecase/delete_all_notifications_usecase.dart';
import 'package:ride_app/features/notification/domain/usecase/delete_notification_usecase.dart';
import 'package:ride_app/features/notification/domain/usecase/get_notification_use_case.dart';
import 'package:ride_app/features/notification/domain/usecase/toggle_notification_usecase.dart';
import 'package:ride_app/features/notification/presentation/states/notification_state.dart';
import 'package:ride_app/features/user_profile/presentation/providers/user_profile_provider.dart';

final notificationProvider =
    NotifierProvider<NotificationController, NotificationState>(
      NotificationController.new,
    );

class NotificationController extends Notifier<NotificationState> {
  late ToggleNotificationUsecase _toggleNotification;
  late DeleteNotificationUsecase _deleteNotification;
  late DeleteAllNotificationsUsecase _deleteAllNotifications;

  GetNotificationUseCase get getNotificationUseCase =>
      locator<GetNotificationUseCase>();

  @override
  NotificationState build() {
    _toggleNotification = locator<ToggleNotificationUsecase>();
    _deleteNotification = locator<DeleteNotificationUsecase>();
    _deleteAllNotifications = locator<DeleteAllNotificationsUsecase>();
    final profile = ref.read(userProfileProvider).profile;
    return NotificationState(
      isNotificationEnabled: profile?.user.isNotificationEnabled ?? true,
    );
  }

  void setInitialValue(bool value) {
    state = state.copyWith(isNotificationEnabled: value);
  }

  Future<void> toggleNotification(bool value, String? fcm) async {
    state = state.copyWith(
      toggleNotifStatus: NotificationStatus.loading,
      isNotificationEnabled: value,
    );

    final result = await _toggleNotification(isEnabled: value, fcm: fcm);

    result.fold(
      (failure) {
        state = state.copyWith(
          toggleNotifStatus: NotificationStatus.error,
          message: failure.message,
          isNotificationEnabled: !value,
        );
      },
      (response) {
        state = state.copyWith(
          toggleNotifStatus: NotificationStatus.success,
          isNotificationEnabled: value,
        );
        ref.read(userProfileProvider.notifier).updateNotificationStatus(value);
      },
    );
  }

  Future<({bool success, String? errorMessage})> deleteNotification(
    String notificationId,
  ) async {
    if (state.isDeleting || notificationId.trim().isEmpty) {
      return (success: false, errorMessage: null);
    }

    state = state.copyWith(isDeleting: true, message: null);

    final result = await _deleteNotification(notificationId);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isDeleting: false,
          message: failure.message,
        );
        return (success: false, errorMessage: failure.message);
      },
      (_) {
        final updatedNotifications = state.notifications
            .where((notification) => notification.id != notificationId)
            .toList();

        state = state.copyWith(
          isDeleting: false,
          notifications: updatedNotifications,
          message: null,
        );
        return (success: true, errorMessage: null);
      },
    );
  }

  Future<({bool success, String? errorMessage})> deleteAllNotifications() async {
    if (state.isDeleting || state.notifications.isEmpty) {
      return (success: false, errorMessage: null);
    }

    state = state.copyWith(isDeleting: true, message: null);

    final result = await _deleteAllNotifications();

    return result.fold(
      (failure) {
        state = state.copyWith(
          isDeleting: false,
          message: failure.message,
        );
        return (success: false, errorMessage: failure.message);
      },
      (_) {
        state = state.copyWith(
          isDeleting: false,
          notifications: const [],
          page: 1,
          hasMore: false,
          message: null,
        );
        return (success: true, errorMessage: null);
      },
    );
  }

  Future<void> getNotifications({required NotificationParams params}) async {
    final isFirstPage = params.page == 1;

    if (isFirstPage) {
      state = state.copyWith(
        getNotifStatus: NotificationStatus.loading,
        page: 1,
        hasMore: true,
      );
    } else {
      if (state.isLoadingMore || !state.hasMore) return;
      state = state.copyWith(isLoadingMore: true);
    }

    final result = await getNotificationUseCase.call(params: params);

    result.fold(
          (failure) {
        state = state.copyWith(
          message: failure.message,
          getNotifStatus: NotificationStatus.error,
          isLoadingMore: false,
        );
      },
          (newNotifications) {
        final isLastPage = newNotifications.isEmpty;

        state = state.copyWith(
          getNotifStatus: NotificationStatus.success,
          notifications: isFirstPage
              ? newNotifications
              : [...state.notifications, ...newNotifications],
          page: params.page,
          hasMore: !isLastPage,
          isLoadingMore: false,
        );
      },
    );
  }}
