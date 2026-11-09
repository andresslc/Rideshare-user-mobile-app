import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/constants/socket_event.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/features/ride_room/data/datasources/ride_socket_listener.dart';

class NotificationRouteService {
  static const Set<String> _rideResumeNotificationTypes = <String>{
    'RIDE_CANCELLED',
    'RIDE_COMPLETED',
    'RIDE_STARTED',
    'RIDE_ARRIVED',
    'RIDE_ACCEPTED',
    'DRIVER_ARRIVED',
    'CARPOOL_ACCEPTED',
    'CARPOOL_STARTED',
    'CARPOOL_ARRIVED',
  };

  Map<String, dynamic> normalizePayload(Map<String, dynamic> rawPayload) {
    final Map<String, dynamic> result = Map<String, dynamic>.from(rawPayload);
    final nestedKeys = [
      'metaData',
      'metadata',
      'data',
      'payload',
      'body',
      'notification',
    ];

    for (final key in nestedKeys) {
      final val = rawPayload[key];
      if (val is Map<String, dynamic>) {
        val.forEach((k, v) {
          result.putIfAbsent(k, () => v);
        });
      } else if (val is Map) {
        val.forEach((k, v) {
          result.putIfAbsent(k.toString(), () => v);
        });
      } else if (val is String && val.trim().startsWith('{')) {
        try {
          final decoded = jsonDecode(val);
          if (decoded is Map<String, dynamic>) {
            decoded.forEach((k, v) {
              result.putIfAbsent(k, () => v);
            });
          } else if (decoded is Map) {
            decoded.forEach((k, v) {
              result.putIfAbsent(k.toString(), () => v);
            });
          }
        } catch (_) {}
      }
    }
    return result;
  }

  void handleNotificationTap(
    BuildContext context,
    Map<String, dynamic> rawMeta,
  ) {
    final meta = normalizePayload(rawMeta);
    final String type = notificationTypeOf(meta);
    syncRideStateFromNotification(meta);

    final router = AppRouter.router;
    final String currentLocation = router.location();

    void navigateIfNeeded(String targetLocation, VoidCallback navigate) {
      debugPrint('Current Location: $currentLocation');
      debugPrint('Target Location: $targetLocation');
      if (currentLocation == targetLocation) return;
      navigate();
    }

    switch (type) {
      case 'REVIEW_RECEIVED':
        // Do not navigate to any screen when a review is received
        break;

      case 'REVIEW_SUBMITTED':
      case 'REVIEW_GIVEN':
      //     case 'PENDING_REVIEW':
      case 'RIDE_REVIEWED':
      case 'REVIEW':
        navigateIfNeeded(
          router.namedLocation(Routes.ridehistory.name),
          () => router.pushNamed(Routes.ridehistory.name),
        );

        break;
      case 'PENDING_REVIEW':
        navigateIfNeeded(
          router.namedLocation(
            Routes.ridehistory.name,
            queryParameters: {'status': 'carpool'},
          ),
          () => router.pushNamed(
            Routes.ridehistory.name,
            extra: {'status': 'carpool'},
          ),
        );
        break;
      case 'PAYMENT':
      case 'ADMIN_REWARD':
      case 'REWARD':
      case 'WALLET':
      case 'TRANSACTION':
        navigateIfNeeded(
          router.namedLocation(Routes.wallet.name),
          () => router.pushNamed(Routes.wallet.name),
        );
        break;

      case 'NOTIFICATION':
      case 'NOTIFICATIONS':
      case 'NOTIFICATION_LIST':
      case 'ANNOUNCEMENT':
      case 'GENERAL':
      case 'SYSTEM':
      case 'PROMO':
      case 'PROMOTION':
        navigateIfNeeded(
          router.namedLocation(Routes.notificationsScreen.name),
          () => router.pushNamed(Routes.notificationsScreen.name),
        );
        break;

      case 'RIDE_CANCELLED':
      case 'RIDE_CANCEL':
        navigateIfNeeded(
          router.namedLocation(
            Routes.ridehistory.name,
            queryParameters: {'status': 'cancelled'},
          ),
          () => router.pushNamed(
            Routes.ridehistory.name,
            extra: {'status': 'cancelled'},
          ),
        );
        break;

      case 'RIDE_COMPLETED':
      case 'RIDE_COMPLETE':
      case 'RIDE_FINISHED':
      case 'RIDE_ENDED':
        navigateIfNeeded(
          router.namedLocation(
            Routes.ridehistory.name,
            queryParameters: {'status': 'completed'},
          ),
          () => router.pushNamed(
            Routes.ridehistory.name,
            extra: {'status': 'completed'},
          ),
        );
        break;

      case 'CARPOOL_CANCELLED':
      case 'CARPOOL_ENDED':
      case 'CARPOOL_CANCEL':
        navigateIfNeeded(
          router.namedLocation(
            Routes.ridehistory.name,
            queryParameters: {'status': 'carpool'},
          ),
          () => router.pushNamed(
            Routes.ridehistory.name,
            extra: {'status': 'carpool'},
          ),
        );
        break;

      case 'RIDE_DETAIL':
      case 'RIDE_DETAILS':
      case 'TRIP_DETAIL':
      case 'TRIP_DETAILS':
      case 'RIDE_HISTORY_DETAIL':
        final rideId = _extractString(meta, [
          'rideId',
          'ride_id',
          'id',
          'bookingId',
          'booking_id',
        ]);
        final driverId = _extractString(meta, [
          'driverId',
          'driver_id',
          'riderId',
          'rider_id',
        ]);
        if (rideId.isNotEmpty) {
          navigateIfNeeded(
            router.namedLocation(Routes.ridehistorydetail.name),
            () => router.pushNamed(
              Routes.ridehistorydetail.name,
              extra: {'rideId': rideId, 'driverId': driverId},
            ),
          );
        } else {
          navigateIfNeeded(
            router.namedLocation(Routes.ridehistory.name),
            () => router.pushNamed(Routes.ridehistory.name),
          );
        }
        break;

      case 'CHAT':
      case 'MESSAGE':
      case 'NEW_MESSAGE':
      case 'CHAT_MESSAGE':
      case 'RIDE_CHAT':
      case 'DRIVER_MESSAGE':
      case 'RIDER_MESSAGE':
      case 'PASSENGER_MESSAGE':
      case 'INBOX':
        _navigateToChat(context, router, meta);
        break;

      case 'RIDE_ACCEPTED':
      case 'RIDE_STARTED':
      case 'RIDE_ARRIVED':
      case 'DRIVER_ARRIVED':
      case 'CARPOOL_ACCEPTED':
      case 'CARPOOL_STARTED':
      case 'CARPOOL_ARRIVED':
        navigateIfNeeded(
          router.namedLocation(Routes.home.name),
          () => router.goNamed(Routes.home.name),
        );
        break;

      default:
        final uppercaseType = type.toUpperCase();
        if (uppercaseType.contains('CHAT') ||
            uppercaseType.contains('MESSAGE') ||
            uppercaseType.contains('MSG')) {
          _navigateToChat(context, router, meta);
        } else if (uppercaseType.contains('WALLET') ||
            uppercaseType.contains('PAYMENT') ||
            uppercaseType.contains('REWARD')) {
          navigateIfNeeded(
            router.namedLocation(Routes.wallet.name),
            () => router.pushNamed(Routes.wallet.name),
          );
        } else if (uppercaseType.contains('NOTIF') ||
            uppercaseType.contains('GENERAL') ||
            uppercaseType.contains('PROMO')) {
          navigateIfNeeded(
            router.namedLocation(Routes.notificationsScreen.name),
            () => router.pushNamed(Routes.notificationsScreen.name),
          );
        } else if (uppercaseType.contains('CANCEL') ||
            uppercaseType.contains('COMPLETE') ||
            uppercaseType.contains('HISTORY')) {
          navigateIfNeeded(
            router.namedLocation(Routes.ridehistory.name),
            () => router.pushNamed(Routes.ridehistory.name),
          );
        } else {
          navigateIfNeeded(
            router.namedLocation(Routes.notificationsScreen.name),
            () => router.pushNamed(Routes.notificationsScreen.name),
          );
        }
        break;
    }
  }

  void _navigateToChat(
    BuildContext context,
    GoRouter router,
    Map<String, dynamic> rawMeta,
  ) {
    final meta = normalizePayload(rawMeta);
    String rideId = _extractString(meta, [
      'rideId',
      'ride_id',
      'bookingId',
      'booking_id',
      'ride_Id',
      'id',
      'carpoolId',
      'carpool_id',
    ]);
    String driverId = _extractString(meta, [
      'driverId',
      'driver_id',
      'riderId',
      'rider_id',
      'senderId',
      'sender_id',
      'userId',
      'user_id',
      'driver_Id',
      'rider_Id',
      'partnerId',
      'partner_id',
    ]);
    String driverName = _extractString(meta, [
      'driverName',
      'driver_name',
      'riderName',
      'rider_name',
      'senderName',
      'sender_name',
      'name',
      'driver_Name',
      'rider_Name',
    ]);
    String driverProfileImage = _extractString(meta, [
      'driverProfileImage',
      'driver_profile_image',
      'riderProfileImage',
      'rider_profile_image',
      'profileImage',
      'profile_image',
      'avatar',
      'image',
    ]);
    String isCarpool = _extractString(meta, [
      'isCarpool',
      'is_carpool',
      'carpool',
    ]);

    // Fallback to cached active ride in RideSocketListener if rideId / driverId missing
    final activeRideResume = locator<RideSocketListener>().lastRideResume;
    final cachedRide = activeRideResume?.ride;
    final cachedDriver = cachedRide?.driver;
    if (rideId.isEmpty && cachedRide != null && cachedRide.id.isNotEmpty) {
      rideId = cachedRide.id;
    }
    if (driverId.isEmpty &&
        cachedDriver != null &&
        cachedDriver.id.isNotEmpty) {
      driverId = cachedDriver.id;
    }
    if (driverName.isEmpty &&
        cachedDriver != null &&
        cachedDriver.fullName.isNotEmpty) {
      driverName = cachedDriver.fullName;
    }
    if (driverProfileImage.isEmpty &&
        cachedDriver != null &&
        cachedDriver.profilePicture.isNotEmpty) {
      driverProfileImage = cachedDriver.profilePicture;
    }

    if (driverId.isEmpty && rideId.isNotEmpty) {
      driverId = 'driver';
    }

    if (rideId.isEmpty || driverId.isEmpty) {
      log(
        'Cannot navigate to chat: missing rideId or driverId in payload=$meta and active ride cache',
        name: 'FCM',
      );
      return;
    }

    final queryParameters = <String, String>{
      'rideId': rideId,
      'driverId': driverId,
      if (driverName.isNotEmpty) 'driverName': driverName,
      if (driverProfileImage.isNotEmpty)
        'driverProfileImage': driverProfileImage,
      if (isCarpool.isNotEmpty) 'isCarpool': isCarpool,
    };

    final String currentLocation = router.location();
    if (currentLocation.startsWith(Routes.chat.path)) {
      log('Already on chat screen location=$currentLocation', name: 'FCM');
      return;
    }

    router.pushNamed(Routes.chat.name, queryParameters: queryParameters);
  }

  String _extractString(Map<String, dynamic> meta, List<String> keys) {
    for (final key in keys) {
      final val = meta[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
    return '';
  }

  void syncRideStateFromNotification(Map<String, dynamic> rawMeta) {
    final meta = normalizePayload(rawMeta);
    final String type = notificationTypeOf(meta);
    if (_rideResumeNotificationTypes.contains(type)) {
      unawaited(_requestRideResume(type: type));
    }
  }

  String notificationTypeOf(Map<String, dynamic> rawMeta) {
    final meta = normalizePayload(rawMeta);
    for (final key in [
      'type',
      'notification_type',
      'notificationType',
      'notification_Type',
      'eventType',
      'event_type',
      'screen',
      'screen_name',
      'action',
      'route',
      'click_action',
    ]) {
      final val = meta[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim().toUpperCase();
      }
    }

    // Infer type from payload key presence if explicit type string is missing
    final rideId = _extractString(meta, [
      'rideId',
      'ride_id',
      'bookingId',
      'booking_id',
    ]);
    final driverId = _extractString(meta, [
      'driverId',
      'driver_id',
      'riderId',
      'rider_id',
      'senderId',
      'sender_id',
    ]);
    if (rideId.isNotEmpty && driverId.isNotEmpty) {
      return 'CHAT';
    } else if (rideId.isNotEmpty) {
      return 'RIDE_DETAIL';
    }

    return '';
  }

  Future<void> _requestRideResume({required String type}) async {
    if (type == 'RIDE_COMPLETED') {
      final bool published = locator<RideSocketListener>()
          .publishLastRideResumeAsCompleted();
      log(
        published
            ? 'Republished cached ride resume as completed for notification type=$type'
            : 'No cached ride resume available for notification type=$type',
        name: 'FCM',
      );
      return;
    }

    try {
      final SocketAckResponse response = await locator<SocketService>()
          .emitWithAckResponse(SocketEvent.rideResume, {});
      if (response.data != null) {
        locator<RideSocketListener>().publishRideResumeFromPayload(
          response.data,
        );
      }
      log(
        'Triggered ${SocketEvent.rideResume} after notification type=$type success=${response.success}',
        name: 'FCM',
      );
    } on TimeoutException {
      await locator<SocketService>().emit(SocketEvent.rideResume);
      log(
        'Ack timed out for ${SocketEvent.rideResume} after notification type=$type. Fallback emit sent.',
        name: 'FCM',
      );
    } catch (e, st) {
      log(
        'Failed to trigger ${SocketEvent.rideResume} for notification type=$type: $e\n$st',
        name: 'FCM',
      );
    }
  }
}

extension GoRouterExtension on GoRouter {
  String location() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    final String location = matchList.uri.toString();
    return location;
  }
}
