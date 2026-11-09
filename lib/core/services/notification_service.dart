// import 'dart:convert';
// import 'dart:io';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import '../di/service_locator.dart';
// import '../navigation/app_router.dart';
// import '../utils/app_log.dart';
// import 'notification_route_service.dart';
// import 'storage_service.dart';

// class NotificationService {
//   final FirebaseMessaging _messaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//   late NotificationSettings notificationSettings;

//   /// Call this once during app startup
//   Future<void> initialize() async {
//     // Request permission on iOS
//     try {
//       if (Platform.isIOS) {
//         notificationSettings = await _messaging.requestPermission(
//           alert: true,
//           badge: true,
//           sound: true,
//         );
//       } else if (Platform.isAndroid) {
//         notificationSettings = await _messaging.requestPermission(
//           alert: true,
//           badge: true,
//           sound: true,
//         );
//       }
//       debugPrint(
//         'notification settings ${notificationSettings.authorizationStatus}',
//       );
//     } catch (e, st) {
//       debugPrint('🔥 Notification permission request failed: $e\n$st');
//     }
//     // Initialize local notifications
//     const AndroidInitializationSettings androidInit =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
//       requestSoundPermission: true,
//       requestBadgePermission: true,
//       requestAlertPermission: true,
//     );

//     const InitializationSettings initSettings = InitializationSettings(
//       android: androidInit,
//       iOS: iosInit,
//     );

//     await _messaging.setForegroundNotificationPresentationOptions(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//     await _localNotificationsPlugin.initialize(
//       settings: initSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         try {
//           final payloadStr = response.payload ?? '{}';
//           final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
//           log(name: "FCM", "Notification clicked: $payload");
//           navigate(payload: payload);
//         } catch (e, st) {
//           debugPrint("🔥 Failed to handle notification click: $e\n$st");
//         }
//       },
//     );

//     // Save and log token
//     await getFcmToken().then((t) {
//       if (t != null) {
//         log(name: "FCM", "Token: $t");
//       }
//     });

//     // Foreground messages
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       log(name: "FCM", "Foreground: ${message.data}");
//       if (Platform.isAndroid) {
//         _showLocalNotification(message);
//       }
//     });

//     // setupInteractMessage();

//     // When app opened from terminated state via FCM
//     final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
//     if (initialMessage != null) {
//       log(name: "FCM", "Opened from terminated: ${initialMessage.data}");
//       navigate(payload: initialMessage.data);
//     }

//     // When app opened from background by tapping notification
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage event) {
//       log(name: "FCM", "Tapped (background): ${event.data}");
//       navigate(payload: event.data);
//     });
//   }

//   // Future<void> setupInteractMessage() async {
//   //   final RemoteMessage? initialMessage = await FirebaseMessaging.instance
//   //       .getInitialMessage();

//   //   FirebaseMessaging.onMessageOpenedApp.listen((event) {
//   //     if (initialMessage != null) {
//   //       Log.info(
//   //         title: "FCM",
//   //         message:
//   //             "Notification tapped (background): ${initialMessage.data.runtimeType} ",
//   //       );
//   //       // navigateToMusic(music: music);
//   //       navigateToVideoCall(payload: (initialMessage.data));
//   //     }
//   //   });
//   // }

//   /// Show local notification
//   Future<void> _showLocalNotification(RemoteMessage message) async {
//     const AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//           'default_channel',
//           'Default',
//           importance: Importance.max,
//           priority: Priority.high,
//           playSound: true,
//         );

//     const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//     );

//     const NotificationDetails details = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );

//     final id =
//         message.messageId?.hashCode ??
//         DateTime.now().millisecondsSinceEpoch ~/ 1000;
//     final data = message.data;
//     final notificationType = data['notificationType'] ?? data['screen'];
//     // TODO:
//     // if (notificationType == 'CALLNOTI') {
//     //   FlutterRingtonePlayer().playRingtone();
//     //   if (await Vibration.hasVibrator()) {
//     //     Vibration.vibrate(pattern: [0, 800, 700], repeat: 0);
//     //   }
//     // }

//     await _localNotificationsPlugin.show(
//       id: id,
//       title: message.notification?.title ?? 'Notification',
//       body: message.notification?.body ?? '',
//       notificationDetails: details,
//       payload: jsonEncode(message.data),
//     );
//   }

//   /// Get FCM token and retry if needed
//   Future<String?> getFcmToken({int retries = 3}) async {
//     for (int i = 0; i < retries; i++) {
//       try {
//         final token = await _messaging.getToken();
//         debugPrint('FCM ==> $token');
//         if (token != null) {
//           locator<StorageService>().setFCMToken(token);
//           return token;
//         }
//       } catch (e) {
//         debugPrint('🔥 getToken failed: $e (attempt ${i + 1})');
//         await Future.delayed(const Duration(seconds: 2));
//       }
//     }
//     return null;
//   }

//   /// Navigate based on notification payload
//   void navigate({Map<String, dynamic>? payload}) {
//     final BuildContext? context = rootNavigatorKey.currentContext;
//     if (context == null || payload == null) return;

//     if (kDebugMode) {
//      debugPrint('payload is $payload');
//     }

//     try {
//       // final NotificationEntity notification = NotificationModel.fromJson(payload);
//       locator<NotificationRouteService>().handleNotificationTap(
//         context,
//         payload,
//       );
//     } catch (e, st) {
//       debugPrint("🔥 Failed to navigate from payload: $e\n$st");
//     }
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../di/service_locator.dart';
import '../navigation/app_router.dart';
import '../utils/app_log.dart';
import 'notification_route_service.dart';
import 'storage_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling background message: ${message.messageId}");
}

class NotificationServices {
  final StorageService prefs = locator<StorageService>();
  late NotificationSettings notificationSettings;
  Map<String, dynamic>? pendingNotificationData;
  bool _launchNotificationProcessed = false;
  NotificationServices();
  Future<void> init() async {
    await requestNotificationPermission();
    await firebaseInit();
    await initLocalNotifications();
  }

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'Epic Ride_notification',
    'High Importance Channel Name',
    description: 'High IMportance',
    importance: Importance.max,
  );

  Future<void> requestNotificationPermission() async {
    if (Platform.isIOS) {
      notificationSettings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      notificationSettings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    // log("AUTHORIZED${settings.authorizationStatus}");
    if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.authorized) {
      debugPrint('Permission Granted');
    } else if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('Permission Approved');
    } else {
      debugPrint('Permission Denied');
    }
  }

  // Future<String?> getDeviceToken() async {
  //   try {
  //     final messaging = FirebaseMessaging.instance;

  //     // 1. Request notification permission
  //     final settings = await messaging.requestPermission(
  //       alert: true,
  //       badge: true,
  //       sound: true,
  //     );

  //     debugPrint('Notification permission: ${settings.authorizationStatus}');

  //     // 2. On iOS, wait for APNs token
  //     if (Platform.isIOS) {
  //       String? apnsToken;

  //       for (int i = 0; i < 10; i++) {
  //         apnsToken = await messaging.getAPNSToken();

  //         if (apnsToken != null) {
  //           debugPrint('APNS TOKEN: $apnsToken');
  //           break;
  //         }

  //         await Future.delayed(const Duration(milliseconds: 500));
  //       }

  //       if (apnsToken == null) {
  //         debugPrint('APNS TOKEN IS NULL');
  //         return null;
  //       }
  //     }

  //     // 3. Now get FCM token
  //     final String? fcmToken = await messaging.getToken();

  //     if (fcmToken != null) {
  //       debugPrint('FCM TOKEN: $fcmToken');

  //       await locator<StorageService>().setFCMToken(fcmToken);

  //       return fcmToken;
  //     }

  //     debugPrint('FCM TOKEN IS NULL');
  //     return null;
  //   } catch (e, stackTrace) {
  //     debugPrint('FCM TOKEN ERROR: $e');
  //     debugPrint('$stackTrace');
  //     return null;
  //   }
  // }
  Future<String?> getDeviceToken() async {
    // log("${await FirebaseMessaging.instance.getToken()}");
    try {
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint('FCM $token');
        await locator<StorageService>().setFCMToken(token);
        return token;
      } else {
        debugPrint('FCM TOKEN IS NULL!');
      }
      debugPrint('FCM TOKENNN $token');
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> firebaseInit() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    FirebaseMessaging.onMessage.listen((message) {
      debugNotification(message);
      log(" :::::::onMessage::::::::::::::::::: ${message.data}");
      locator<NotificationRouteService>().syncRideStateFromNotification(
        message.data,
      );

      if (message.notification != null) {
        if (Platform.isAndroid) {
          showNotification(message);
        }
      }
    });

    await setupInteractMessage();
  }

  Future<void> setupInteractMessage() async {
    final RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      _logNotificationTap(
        source: 'terminated',
        payload: initialMessage.data,
        messageId: initialMessage.messageId,
      );
      pendingNotificationData = initialMessage.data;
    }

    try {
      final localLaunchDetails =
          await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
      if (localLaunchDetails?.didNotificationLaunchApp == true &&
          localLaunchDetails?.notificationResponse?.payload != null) {
        final payloadStr =
            localLaunchDetails!.notificationResponse!.payload!;
        if (payloadStr.isNotEmpty) {
          final decoded = jsonDecode(payloadStr);
          if (decoded is Map<String, dynamic>) {
            _logNotificationTap(
              source: 'terminated_local',
              payload: decoded,
            );
            pendingNotificationData = decoded;
          }
        }
      }
    } catch (e) {
      debugPrint("🔥 Failed to check local notification launch details: $e");
    }
    _launchNotificationProcessed = true;

    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      debugNotification(event);
      debugPrint('NOTIF:: event data ${event.data}');
      _logNotificationTap(
        source: 'background',
        payload: event.data,
        messageId: event.messageId,
      );
      navigate(payload: event.data);
      // handleNavigation(event.data);
    });
  }

  Future<void> initLocalNotifications() async {
    const androidInitializationSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInit,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,

      onDidReceiveNotificationResponse: (response) {
        debugPrint("🔥 FOREGROUND TAP DETECTED");
        final payloadString = response.payload;
        debugPrint("📦 RAW PAYLOAD: $payloadString");

        if (payloadString == null || payloadString.isEmpty) {
          debugPrint("❌ Payload is empty");
          return;
        }

        try {
          final decoded = jsonDecode(payloadString);

          debugPrint("✅ DECODED PAYLOAD: $decoded");

          if (decoded is Map<String, dynamic>) {
            _logNotificationTap(
              source: 'foreground_local',
              payload: decoded,
              responseType: response.notificationResponseType.name,
            );
            navigate(payload: decoded);
          } else {
            debugPrint("❌ Payload is not a valid map");
          }
        } catch (e) {
          debugPrint("❌ JSON decode failed: $e");
        }
      },
    );
  }

  Future<void> showNotification(RemoteMessage message) async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          channel.id.toString(),
          channel.name.toString(),
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'harmonius',
          showProgress: true,
        );

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );
    Future.delayed(Duration.zero, () {
      _flutterLocalNotificationsPlugin.show(
        message.notification.hashCode,
        message.notification!.title.toString(),
        message.notification!.body,
        payload: jsonEncode(message.data),
        notificationDetails,
      );
      log(':::::::::::::::::::: ${message.data}');
    });
  }

  void setNotificationCallback(BuildContext context, VoidCallback callback) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // ======= commentout cuz notification appear twice : =======
      // showNotification(message);
      log(" :::::::onMessage111::::::::::::::::::: ${message.data}");

      if (context.mounted) {
        callback();
      }
    });
  }

  /// Navigate based on notification payload
  void navigate({Map<String, dynamic>? payload}) {
    //debugPrint('NOTIF:: payload ${payload.toString()}');
    final BuildContext? context = rootNavigatorKey.currentContext;
    if (payload == null) return;
    if (context == null) {
      log(
        'Notification tap received before navigator was ready. Saved to pendingNotificationData: $payload',
        name: 'FCM',
      );
      pendingNotificationData = payload;
      return;
    }

    if (kDebugMode) {
      debugPrint('payload is $payload');
    }

    try {
      // final NotificationEntity notification = NotificationModel.fromJson(payload);
      locator<NotificationRouteService>().handleNotificationTap(
        context,
        payload,
      );
      pendingNotificationData = null;
    } catch (e, st) {
      debugPrint("🔥 Failed to navigate from payload: $e\n$st");
    }
  }

  Future<void> processPendingNotification() async {
    if (pendingNotificationData == null || pendingNotificationData!.isEmpty) {
      try {
        final initialMsg = await FirebaseMessaging.instance.getInitialMessage();
        if (initialMsg != null && initialMsg.data.isNotEmpty) {
          log(
            'Retrieved initialMessage in processPendingNotification: ${initialMsg.data}',
            name: 'FCM',
          );
          pendingNotificationData = initialMsg.data;
        }
      } catch (e) {
        debugPrint(
          "🔥 Error checking getInitialMessage in processPendingNotification: $e",
        );
      }
    }

    if (pendingNotificationData == null || pendingNotificationData!.isEmpty) {
      // Only check local launch details once per app session.
      // getNotificationAppLaunchDetails() always returns the same stale
      // result within a session, so re-checking it would re-navigate
      // to e.g. the chat screen every time the home screen rebuilds.
      if (!_launchNotificationProcessed) {
        try {
          final localLaunchDetails =
              await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
          if (localLaunchDetails?.didNotificationLaunchApp == true &&
              localLaunchDetails?.notificationResponse?.payload != null) {
            final payloadStr =
                localLaunchDetails!.notificationResponse!.payload!;
            if (payloadStr.isNotEmpty) {
              final decoded = jsonDecode(payloadStr);
              if (decoded is Map<String, dynamic> && decoded.isNotEmpty) {
                log(
                  'Retrieved local launch details in processPendingNotification: $decoded',
                  name: 'FCM',
                );
                pendingNotificationData = decoded;
              }
            }
          }
        } catch (e) {
          debugPrint(
            "🔥 Error checking local launch details in processPendingNotification: $e",
          );
        }
        _launchNotificationProcessed = true;
      }
    }

    if (pendingNotificationData != null && pendingNotificationData!.isNotEmpty) {
      final data = pendingNotificationData;
      pendingNotificationData = null;
      navigate(payload: data);
    }
  }

  void debugNotification(RemoteMessage message) {
    debugPrint("========== FCM DEBUG START ==========");

    debugPrint("📩 messageId: ${message.messageId}");
    debugPrint("📦 data: ${message.data}");

    debugPrint("🔎 type: ${message.data['type']}");
    debugPrint("🔎 notificationType: ${message.data['notificationType']}");
    debugPrint("🔎 screen: ${message.data['screen']}");
    debugPrint("🔎 notification_type: ${message.data['notification_type']}");

    debugPrint("🔔 notification.title: ${message.notification?.title}");
    debugPrint("🔔 notification.body: ${message.notification?.body}");

    debugPrint("📱 android: ${message.notification?.android}");
    debugPrint("🍎 apple: ${message.notification?.apple}");

    debugPrint("========== FCM DEBUG END ==========");
  }

  void _logNotificationTap({
    required String source,
    required Map<String, dynamic> payload,
    String? messageId,
    String? responseType,
  }) {
    final List<String> details = <String>[
      'Notification tap detected',
      'source=$source',
      if (messageId != null && messageId.isNotEmpty) 'messageId=$messageId',
      if (responseType != null && responseType.isNotEmpty)
        'responseType=$responseType',
      'payload=$payload',
    ];
    log(details.join(' | '), name: 'FCM');
  }
}
