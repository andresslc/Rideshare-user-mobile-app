/// Centralised route definitions.
///
/// Each enum value defines its [name] (used with `goNamed`)
/// and its URL [path].
enum Routes {
  root(name: 'root', path: '/'),
  login(name: 'login', path: '/login'),
  createProfile(name: 'create_profile', path: '/create-profile'),
  forgotPassword(name: 'forgot_password', path: '/forgot-password'),
  verification(name: 'verification', path: '/verification'),
  success(name: 'auth_success', path: '/auth-success'),
  home(name: 'home', path: '/home'),
  profile(name: 'profile', path: '/profile'),
  settings(name: 'settings', path: '/settings'),
  wallet(name: 'wallet', path: '/wallet'),
  editProfile(name: 'editProfile', path: '/editProfile'),
  //ride
  ridecomplete(name: 'ridecomplete', path: '/ridecomplete'),

  //cards
  cards(name: 'cards', path: '/cards'),
  addCard(name: 'addCard', path: '/addCard'),

  locationAccess(name: 'location_access', path: '/location-access'),
  themePreferences(name: 'theme_preferences', path: '/theme-preferences'),
  language(name: 'language', path: '/language'),
  savedLocations(name: 'saved_locations', path: '/saved-locations'),
  placePicker(name: 'place_picker', path: '/place-picker'),
  ridePlacePicker(name: 'ride_place_picker', path: '/ride-place-picker'),

  //ride history
  ridehistory(name: 'ride_history', path: '/ride-history'),
  ridehistorydetail(name: 'ride_history_detail', path: '/ride-history-detail'),
  ridedetailcarpool(name: 'ride_detail_carpool', path: '/ride-detail-carpool'),
  rideRoom(name: 'ride_room', path: '/ride-room'),
  //delete account
  deleteAccountOTP(name: 'delete_account_otp', path: '/delete-account-otp'),
  //reviews
  driverProfileScreen(name: 'driver_profile', path: '/driver-profile'),
  // feedback(name: 'reviews', path: '/feedback'),
  enterRoute(name: 'enter_route', path: '/enter-route'),
  availableCarpoolRides(
    name: 'available_carpool_rides',
    path: '/available-carpool-rides',
  ),
  requestedCarpool(name: 'requested_carpool', path: '/requested-carpool'),
  carpoolRideComplete(
    name: 'carpool_ride_complete',
    path: '/carpool-ride-complete',
  ),
  // availableCarpoolRides(
  //   name: 'available_carpool_rides',
  //   path: '/available-carpool-rides',
  // ),
  feedback(name: 'feedback', path: '/feedback'),
  chat(name: 'chat', path: '/chat'),
  // Notifications Screen
  notificationsScreen(name: 'notifications_screen', path: '/notifications_screen'),

  deleteAccountVerify(
    name: 'delete_account_verify',
    path: '/delete-account-verify',
  );

  const Routes({required this.name, required this.path});

  final String name;
  final String path;
}
