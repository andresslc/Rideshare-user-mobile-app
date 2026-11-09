import 'package:ride_app/core/core.dart';

/// Centralised API endpoint constants.
/// Base URL is driven by [Env.current] (dev / staging / prod).
class ApiEndpoints {
  ApiEndpoints._();

  // static String get baseUrl => remoteConfigModel.baseUrl;
  // static String get socketUrl => remoteConfigModel.socketUrl;
  static String get termsUrl => remoteConfigModel.termsURL;
  static String get privacyPolicyUrl => remoteConfigModel.privacyURL;
  static String get mapApiKey => remoteConfigModel.mapApiKey;
  static String get stripePublishableKey =>
      remoteConfigModel.stripePublishableKey;
  static bool get useOsrmInDebug => remoteConfigModel.useOsrmInDebug;

  // Env.current.baseUrl;

  // ── Auth ────────────────────────────────────────────────────────────────
  static const String sendOtp = '/api/auth/send-otp';
  static const String register = '/api/auth/onboard/user';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String logout = '/api/auth/logout';
  static const String promocode = '/api/promo-code/apply';

  // ── User ────────────────────────────────────────────────────────────────
  static const String profile = '/api/user/me';
  static const String updateProfile = '/api/user/edit/me';
  static const String toggleNotification = '/api/notification/user/toggle';

  // ── Card ────────────────────────────────────────────────────────────────
  static const String addCard = '/api/user/attach-card';
  static const String deleteCard = '/api/user/card/';
  static const String cardsList = '/api/user/cards-list';
  static const String setDefaultCard = '/api/user/card/';

  // Saved locations
  static const String myLocations = '/api/user/locations';
  static const String saveLocation = '/api/user/locations/save';
  static const String reorderLocations = '/api/user/locations/re-order';
  static String locationById(String id) => '/api/user/locations/$id';
  static const String fareCalculator = '/api/rides/fare-calculator';

  /// Dispatch ladder, timings, distance unit and copy, all editable from the
  /// admin panel. Public, so the search screen reads right before login.
  static const String rideConfig = '/api/config/ride';
  static String rideById(String id) => '/api/rides/$id';
  static String riderComing(String id) => '/api/rides/$id/coming';
  static String shareRideUrl(String id) => '/api/rides/share/$id';
  // ── Account Deletion ────────────────────────────────────────────────────
  static const String deleteAccount = '/api/user/delete';
  // ── Wallet ────────────────────────────────────────────────────
  static const String topUpWallet = '/api/user/topup-wallet';
  static const String transactionHistory = '/api/user/transaction-history';

  //review
  static String driverProfile(String id) => '/api/driver/$id/stats';

  static const String review = '/api/review';
  static const String report = '/api/report';

  // ── Change Location ────────────────────────────────────────────────────
  static const String changeLanguage = '/api/user/change-locale';

  //ridehistory

  static const String ridehistory = "/api/rides/history";
  static const String ridedetail = "/api/rides/";

  // Carpool
  static const String findCarpoolRides = '/api/carpool/user/matches';
  static String shareCarpoolRideUrl(String id) => '/api/carpool/share/$id';

  static String carpoolById(String id) => '/api/carpool/$id';
  // static const String carpooldetail = "/api/carpool/";
  static String carpooldetail(String id) => "/api/carpool/$id/details";

  static const String carpoolhistory = "/api/carpool/history";
  // ── Chat ────────────────────────────────────────────────────────────────
  static String chatHistory(String rideId) => '/api/chat/$rideId/history';
  static const String chatSend = '/api/chat/send';
  // Notifications
  static const String getNotifications = "/api/notification";
  static const String deleteAllNotifications = '/api/notification';
  static String notificationById(String id) => '/api/notification/$id';
}
