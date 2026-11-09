import Flutter
import UIKit
import GoogleMaps
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Replace with your own Google Maps API key (see README.md).
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")

    Messaging.messaging().delegate = self

    UNUserNotificationCenter.current().delegate = self

    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    print("🔥🔥 APNS TOKEN RECEIVED 🔥🔥")

    Messaging.messaging().apnsToken = deviceToken

    print("🔥 APNS DEVICE TOKEN: \(deviceToken)")

    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌❌ APNS REGISTRATION FAILED ❌❌")
    print("❌ ERROR: \(error)")
  }

  func messaging(
    _ messaging: Messaging,
    didReceiveRegistrationToken fcmToken: String?
  ) {
    print("🔥🔥 FCM TOKEN: \(String(describing: fcmToken))")
  }
}

