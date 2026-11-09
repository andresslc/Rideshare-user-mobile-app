import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @rideDetails.
  ///
  /// In en, this message translates to:
  /// **'Ride Details'**
  String get rideDetails;

  /// No description provided for @noSpecialRequest.
  ///
  /// In en, this message translates to:
  /// **'No special request'**
  String get noSpecialRequest;

  /// No description provided for @special_request_subtitle.
  ///
  /// In en, this message translates to:
  /// **'You can add a special request to your driver (e.g., extra luggage, preference for a quiet ride, etc.)'**
  String get special_request_subtitle;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @total_time.
  ///
  /// In en, this message translates to:
  /// **'Total Time'**
  String get total_time;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @total_amount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get total_amount;

  /// No description provided for @addReviewHere.
  ///
  /// In en, this message translates to:
  /// **'Add your review here...'**
  String get addReviewHere;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @we_couldnot_found.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any matching addresses'**
  String get we_couldnot_found;

  /// No description provided for @use_this_address.
  ///
  /// In en, this message translates to:
  /// **'Use this address'**
  String get use_this_address;

  /// No description provided for @cancellationReason.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Reason'**
  String get cancellationReason;

  /// No description provided for @enter_address.
  ///
  /// In en, this message translates to:
  /// **'Enter your address'**
  String get enter_address;

  /// No description provided for @noReasonProvided.
  ///
  /// In en, this message translates to:
  /// **'No reason provided'**
  String get noReasonProvided;

  /// No description provided for @please_reason.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reason'**
  String get please_reason;

  /// No description provided for @unable_to_submit.
  ///
  /// In en, this message translates to:
  /// **'Unable to submit feedback'**
  String get unable_to_submit;

  /// No description provided for @please_select_rating.
  ///
  /// In en, this message translates to:
  /// **'Please select a rating'**
  String get please_select_rating;

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'Ride App'**
  String get app_name;

  /// No description provided for @total_seats_booked.
  ///
  /// In en, this message translates to:
  /// **'Total Seats Booked'**
  String get total_seats_booked;

  /// No description provided for @seat_booked.
  ///
  /// In en, this message translates to:
  /// **'Seat Booked'**
  String get seat_booked;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @select_language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get select_language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @language_already_selected.
  ///
  /// In en, this message translates to:
  /// **'This language is already selected'**
  String get language_already_selected;

  /// No description provided for @view_profile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get view_profile;

  /// No description provided for @my_cards.
  ///
  /// In en, this message translates to:
  /// **'My Cards'**
  String get my_cards;

  /// No description provided for @carpool_ride.
  ///
  /// In en, this message translates to:
  /// **'Carpool'**
  String get carpool_ride;

  /// No description provided for @no_carpool.
  ///
  /// In en, this message translates to:
  /// **'No carpool rides found'**
  String get no_carpool;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @turn_on.
  ///
  /// In en, this message translates to:
  /// **'Turn On'**
  String get turn_on;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @special_request.
  ///
  /// In en, this message translates to:
  /// **'Special Request'**
  String get special_request;

  /// No description provided for @onboarding_title_1.
  ///
  /// In en, this message translates to:
  /// **'Book a Ride Easily'**
  String get onboarding_title_1;

  /// No description provided for @onboarding_subtitle_1.
  ///
  /// In en, this message translates to:
  /// **'Find and book rides near you in seconds.'**
  String get onboarding_subtitle_1;

  /// No description provided for @onboarding_title_2.
  ///
  /// In en, this message translates to:
  /// **'Track Your Driver'**
  String get onboarding_title_2;

  /// No description provided for @onboarding_subtitle_2.
  ///
  /// In en, this message translates to:
  /// **'Real-time tracking from pickup to drop-off.'**
  String get onboarding_subtitle_2;

  /// No description provided for @onboarding_title_3.
  ///
  /// In en, this message translates to:
  /// **'Safe & Secure'**
  String get onboarding_title_3;

  /// No description provided for @onboarding_subtitle_3.
  ///
  /// In en, this message translates to:
  /// **'Your safety is our top priority.'**
  String get onboarding_subtitle_3;

  /// No description provided for @get_started.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get get_started;

  /// No description provided for @welcome_back.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcome_back;

  /// No description provided for @login_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number to log in.'**
  String get login_subtitle;

  /// No description provided for @phone_number.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone_number;

  /// No description provided for @enter_phone_number.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enter_phone_number;

  /// No description provided for @add_phone_number.
  ///
  /// In en, this message translates to:
  /// **'Add phone number'**
  String get add_phone_number;

  /// No description provided for @continue_with_phone.
  ///
  /// In en, this message translates to:
  /// **'Continue With Phone Number'**
  String get continue_with_phone;

  /// No description provided for @no_account_prompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get no_account_prompt;

  /// No description provided for @phone_required.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phone_required;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get hour;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get min;

  /// No description provided for @mins.
  ///
  /// In en, this message translates to:
  /// **'mins'**
  String get mins;

  /// No description provided for @phone_invalid.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be valid'**
  String get phone_invalid;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// OTP subtitle with dynamic phone number
  ///
  /// In en, this message translates to:
  /// **'Enter the OTP code sent to {number}'**
  String otp_subtitle(Object number);

  /// No description provided for @enter_otp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enter_otp;

  /// No description provided for @otp_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter the OTP to proceed'**
  String get otp_required;

  /// No description provided for @invalid_otp.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP code. Please try again.'**
  String get invalid_otp;

  /// No description provided for @did_not_receive_code.
  ///
  /// In en, this message translates to:
  /// **'Didn’t receive the code?'**
  String get did_not_receive_code;

  /// No description provided for @resend_now.
  ///
  /// In en, this message translates to:
  /// **'Resend Now'**
  String get resend_now;

  /// No description provided for @number_verified.
  ///
  /// In en, this message translates to:
  /// **'Number Verified'**
  String get number_verified;

  /// No description provided for @number_verified_message.
  ///
  /// In en, this message translates to:
  /// **'Your phone number has been verified successfully!'**
  String get number_verified_message;

  /// No description provided for @account_deleted_title.
  ///
  /// In en, this message translates to:
  /// **'Account Deleted!'**
  String get account_deleted_title;

  /// No description provided for @account_deleted_message.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted successfully.'**
  String get account_deleted_message;

  /// No description provided for @funds_added_title.
  ///
  /// In en, this message translates to:
  /// **'Funds Added!'**
  String get funds_added_title;

  /// No description provided for @funds_added_message.
  ///
  /// In en, this message translates to:
  /// **'Funds have been added to your wallet.'**
  String get funds_added_message;

  /// No description provided for @language_updated_title.
  ///
  /// In en, this message translates to:
  /// **'Language Updated!'**
  String get language_updated_title;

  /// No description provided for @feedback_submitted_title.
  ///
  /// In en, this message translates to:
  /// **'We appreciate your Feedback!'**
  String get feedback_submitted_title;

  /// No description provided for @language_updated_message.
  ///
  /// In en, this message translates to:
  /// **'Tu idioma se ha actualizado correctamente.'**
  String get language_updated_message;

  /// No description provided for @feedback_submitted_message.
  ///
  /// In en, this message translates to:
  /// **'Your review has been submitted.'**
  String get feedback_submitted_message;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgot_password;

  /// No description provided for @forgot_password_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address to reset your password.'**
  String get forgot_password_subtitle;

  /// No description provided for @back_to_login.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get back_to_login;

  /// No description provided for @create_profile.
  ///
  /// In en, this message translates to:
  /// **'Create Profile'**
  String get create_profile;

  /// No description provided for @signup_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter your details to sign up.'**
  String get signup_subtitle;

  /// No description provided for @sign_up.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get sign_up;

  /// No description provided for @already_have_account.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get already_have_account;

  /// No description provided for @by_registering.
  ///
  /// In en, this message translates to:
  /// **'By registering, you accept our'**
  String get by_registering;

  /// No description provided for @full_name.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get full_name;

  /// No description provided for @accepting.
  ///
  /// In en, this message translates to:
  /// **'Accepting...'**
  String get accepting;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @enter_full_name.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enter_full_name;

  /// No description provided for @full_name_required.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get full_name_required;

  /// No description provided for @date_of_birth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get date_of_birth;

  /// No description provided for @select_date_of_birth.
  ///
  /// In en, this message translates to:
  /// **'Select your date of birth'**
  String get select_date_of_birth;

  /// No description provided for @date_of_birth_required.
  ///
  /// In en, this message translates to:
  /// **'Date of birth is required'**
  String get date_of_birth_required;

  /// No description provided for @field_required.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get field_required;

  /// Validation message shown when name is too short
  ///
  /// In en, this message translates to:
  /// **'Name must be at least {min} characters'**
  String name_min_length(int min);

  /// No description provided for @name_no_numbers.
  ///
  /// In en, this message translates to:
  /// **'Name cannot contain numbers'**
  String get name_no_numbers;

  /// No description provided for @name_invalid_characters.
  ///
  /// In en, this message translates to:
  /// **'Name contains invalid characters'**
  String get name_invalid_characters;

  /// No description provided for @email_address.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email_address;

  /// No description provided for @enter_email.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get enter_email;

  /// No description provided for @upload_profile_picture.
  ///
  /// In en, this message translates to:
  /// **'Upload Profile Picture'**
  String get upload_profile_picture;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'(Optional)'**
  String get optional;

  /// No description provided for @my_profile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get my_profile;

  /// No description provided for @edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get edit_profile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @where_to.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get where_to;

  /// No description provided for @location_access.
  ///
  /// In en, this message translates to:
  /// **'Location Access'**
  String get location_access;

  /// No description provided for @current_location.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get current_location;

  /// No description provided for @set_pickup_location.
  ///
  /// In en, this message translates to:
  /// **'Set Pickup Location'**
  String get set_pickup_location;

  /// No description provided for @pickup_location.
  ///
  /// In en, this message translates to:
  /// **'Pickup Location'**
  String get pickup_location;

  /// No description provided for @drop_location.
  ///
  /// In en, this message translates to:
  /// **'Drop Location'**
  String get drop_location;

  /// No description provided for @dropoff_location.
  ///
  /// In en, this message translates to:
  /// **'Drop-off Location'**
  String get dropoff_location;

  /// No description provided for @set_dropoff_location.
  ///
  /// In en, this message translates to:
  /// **'Set Drop-off Location'**
  String get set_dropoff_location;

  /// No description provided for @confirm_location.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirm_location;

  /// No description provided for @economy.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get economy;

  /// No description provided for @no_comp_found.
  ///
  /// In en, this message translates to:
  /// **'No completed rides found'**
  String get no_comp_found;

  /// No description provided for @cancel_carpool.
  ///
  /// In en, this message translates to:
  /// **'Cancel Carpool'**
  String get cancel_carpool;

  /// No description provided for @no_cancelled_found.
  ///
  /// In en, this message translates to:
  /// **'No cancelled rides found'**
  String get no_cancelled_found;

  /// No description provided for @avg_time.
  ///
  /// In en, this message translates to:
  /// **'Avg Time'**
  String get avg_time;

  /// No description provided for @carpool.
  ///
  /// In en, this message translates to:
  /// **'Carpool'**
  String get carpool;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @min_label.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get min_label;

  /// No description provided for @mins_label.
  ///
  /// In en, this message translates to:
  /// **'Mins'**
  String get mins_label;

  /// No description provided for @via_card.
  ///
  /// In en, this message translates to:
  /// **'Via Card'**
  String get via_card;

  /// No description provided for @via_wallet.
  ///
  /// In en, this message translates to:
  /// **'Via Wallet'**
  String get via_wallet;

  /// No description provided for @luxury.
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get luxury;

  /// No description provided for @select_ride.
  ///
  /// In en, this message translates to:
  /// **'Select Ride'**
  String get select_ride;

  /// No description provided for @estimated_time.
  ///
  /// In en, this message translates to:
  /// **'Estimated Time'**
  String get estimated_time;

  /// No description provided for @estimated_fare.
  ///
  /// In en, this message translates to:
  /// **'Estimated Fare'**
  String get estimated_fare;

  /// No description provided for @finding_driver.
  ///
  /// In en, this message translates to:
  /// **'Finding your driver...'**
  String get finding_driver;

  /// No description provided for @finding_ride_text.
  ///
  /// In en, this message translates to:
  /// **'Please wait, While a driver sends\n you an offer!'**
  String get finding_ride_text;

  /// No description provided for @your_complete_finished_trip.
  ///
  /// In en, this message translates to:
  /// **'Your finished trips will appear here'**
  String get your_complete_finished_trip;

  /// No description provided for @please_wait_for_calculation.
  ///
  /// In en, this message translates to:
  /// **'Please wait for the fare calculation'**
  String get please_wait_for_calculation;

  /// No description provided for @enter_last_name.
  ///
  /// In en, this message translates to:
  /// **'Enter last name'**
  String get enter_last_name;

  /// No description provided for @enter_first_name.
  ///
  /// In en, this message translates to:
  /// **'Enter first name'**
  String get enter_first_name;

  /// No description provided for @no_offers_available.
  ///
  /// In en, this message translates to:
  /// **'No offers available right now'**
  String get no_offers_available;

  /// No description provided for @your_have_not_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Your haven\'t cancelled any rides'**
  String get your_have_not_cancelled;

  /// No description provided for @no_rides_cancelled_by_driver.
  ///
  /// In en, this message translates to:
  /// **'No rides cancelled by driver'**
  String get no_rides_cancelled_by_driver;

  /// No description provided for @carpool_text.
  ///
  /// In en, this message translates to:
  /// **'No carpool rides yet'**
  String get carpool_text;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get transactions;

  /// No description provided for @type_amount.
  ///
  /// In en, this message translates to:
  /// **'Type amount'**
  String get type_amount;

  /// No description provided for @notification_center.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get notification_center;

  /// No description provided for @find_ride.
  ///
  /// In en, this message translates to:
  /// **'Find Ride'**
  String get find_ride;

  /// No description provided for @driver_on_the_way.
  ///
  /// In en, this message translates to:
  /// **'Driver is on the way'**
  String get driver_on_the_way;

  /// No description provided for @driver_arriving_in.
  ///
  /// In en, this message translates to:
  /// **'Reaching in around {time}'**
  String driver_arriving_in(String time);

  /// No description provided for @estimated_arrival.
  ///
  /// In en, this message translates to:
  /// **'Estimated arrival: {time}'**
  String estimated_arrival(String time);

  /// No description provided for @driver_arrived.
  ///
  /// In en, this message translates to:
  /// **'Driver has arrived'**
  String get driver_arrived;

  /// No description provided for @driver_arrived_at_pickup.
  ///
  /// In en, this message translates to:
  /// **'Driver arrived at Pickup Point!'**
  String get driver_arrived_at_pickup;

  /// No description provided for @driver_arrived_at_location.
  ///
  /// In en, this message translates to:
  /// **'Driver arrived at {location}'**
  String driver_arrived_at_location(String location);

  /// No description provided for @driver_arrived_sheet_warning.
  ///
  /// In en, this message translates to:
  /// **'To avoid ride cancellation, please be at the pickup location before the timer runs out.'**
  String get driver_arrived_sheet_warning;

  /// No description provided for @ride_started.
  ///
  /// In en, this message translates to:
  /// **'Ride Started'**
  String get ride_started;

  /// No description provided for @ride_in_progress.
  ///
  /// In en, this message translates to:
  /// **'Ride in Progress!'**
  String get ride_in_progress;

  /// No description provided for @reached_destination.
  ///
  /// In en, this message translates to:
  /// **'You have reached your destination'**
  String get reached_destination;

  /// No description provided for @ride_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed Rides'**
  String get ride_completed;

  /// No description provided for @ride_accepted_successfully.
  ///
  /// In en, this message translates to:
  /// **'Your ride has been accepted successfully!'**
  String get ride_accepted_successfully;

  /// No description provided for @cancel_ride.
  ///
  /// In en, this message translates to:
  /// **'Canceled Rides'**
  String get cancel_ride;

  /// No description provided for @cancel_rid.
  ///
  /// In en, this message translates to:
  /// **'Cancel Ride'**
  String get cancel_rid;

  /// No description provided for @cancel_rides.
  ///
  /// In en, this message translates to:
  /// **'Cancel Rides'**
  String get cancel_rides;

  /// No description provided for @sos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sos;

  /// No description provided for @ride_verification_code.
  ///
  /// In en, this message translates to:
  /// **'Ride Verification Code'**
  String get ride_verification_code;

  /// No description provided for @ride_verification_code_disclaimer.
  ///
  /// In en, this message translates to:
  /// **'The fare will be deducted from your account as soon as the driver enters your verification code to start the ride.'**
  String get ride_verification_code_disclaimer;

  /// No description provided for @ride_details.
  ///
  /// In en, this message translates to:
  /// **'View Ride Details'**
  String get ride_details;

  /// No description provided for @i_am_coming.
  ///
  /// In en, this message translates to:
  /// **'I am coming'**
  String get i_am_coming;

  /// No description provided for @cancel_ride_request.
  ///
  /// In en, this message translates to:
  /// **'Cancel Ride Request'**
  String get cancel_ride_request;

  /// No description provided for @cancel_ride_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this ride?'**
  String get cancel_ride_confirmation;

  /// No description provided for @cancel_ride_question.
  ///
  /// In en, this message translates to:
  /// **'Why are you cancelling this ride?'**
  String get cancel_ride_question;

  /// No description provided for @rider_cancel_reason_driver_not_responding.
  ///
  /// In en, this message translates to:
  /// **'Driver is not responding'**
  String get rider_cancel_reason_driver_not_responding;

  /// No description provided for @rider_cancel_reason_driver_asked_cancel.
  ///
  /// In en, this message translates to:
  /// **'Driver asked me to cancel'**
  String get rider_cancel_reason_driver_asked_cancel;

  /// No description provided for @rider_cancel_reason_pickup_too_long.
  ///
  /// In en, this message translates to:
  /// **'Driver is taking long'**
  String get rider_cancel_reason_pickup_too_long;

  /// No description provided for @rider_cancel_reason_changed_plans.
  ///
  /// In en, this message translates to:
  /// **'Changed my plans'**
  String get rider_cancel_reason_changed_plans;

  /// No description provided for @rider_cancel_reason_booked_mistake.
  ///
  /// In en, this message translates to:
  /// **'Booked by mistake'**
  String get rider_cancel_reason_booked_mistake;

  /// No description provided for @rider_cancel_reason_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get rider_cancel_reason_other;

  /// No description provided for @driver_profile.
  ///
  /// In en, this message translates to:
  /// **'Driver Profile'**
  String get driver_profile;

  /// No description provided for @call_driver.
  ///
  /// In en, this message translates to:
  /// **'Call Driver'**
  String get call_driver;

  /// No description provided for @number_of_passengers.
  ///
  /// In en, this message translates to:
  /// **'Number of Passengers'**
  String get number_of_passengers;

  /// No description provided for @passengers.
  ///
  /// In en, this message translates to:
  /// **'{count} Passengers'**
  String passengers(Object count);

  /// No description provided for @contact_driver.
  ///
  /// In en, this message translates to:
  /// **'Contact Driver'**
  String get contact_driver;

  /// No description provided for @payment_method.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get payment_method;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @add_payment_method.
  ///
  /// In en, this message translates to:
  /// **'Add Payment Method'**
  String get add_payment_method;

  /// No description provided for @add_card.
  ///
  /// In en, this message translates to:
  /// **'Add Card'**
  String get add_card;

  /// No description provided for @card_number.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get card_number;

  /// No description provided for @expiry_date.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiry_date;

  /// No description provided for @cvv.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get cvv;

  /// No description provided for @card_holder_name.
  ///
  /// In en, this message translates to:
  /// **'Card Holder Name'**
  String get card_holder_name;

  /// No description provided for @add_account.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get add_account;

  /// No description provided for @delete_account.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get delete_account;

  /// No description provided for @ride_history.
  ///
  /// In en, this message translates to:
  /// **'Ride History'**
  String get ride_history;

  /// No description provided for @no_rides_found.
  ///
  /// In en, this message translates to:
  /// **'No rides found'**
  String get no_rides_found;

  /// No description provided for @rate_your_ride.
  ///
  /// In en, this message translates to:
  /// **'Rate Your Ride'**
  String get rate_your_ride;

  /// No description provided for @leave_feedback.
  ///
  /// In en, this message translates to:
  /// **'Leave Feedback'**
  String get leave_feedback;

  /// No description provided for @add_tip.
  ///
  /// In en, this message translates to:
  /// **'Add Tip'**
  String get add_tip;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy_policy;

  /// No description provided for @terms_conditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get terms_conditions;

  /// No description provided for @continue_label.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_label;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @description_valid.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get description_valid;

  /// No description provided for @help_center.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get help_center;

  /// No description provided for @something_went_wrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get something_went_wrong;

  /// No description provided for @no_internet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get no_internet;

  /// No description provided for @request_timed_out.
  ///
  /// In en, this message translates to:
  /// **'Request Timed Out'**
  String get request_timed_out;

  /// No description provided for @connection_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect'**
  String get connection_error;

  /// No description provided for @auth_failed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get auth_failed;

  /// No description provided for @rate_limit.
  ///
  /// In en, this message translates to:
  /// **'Rate limit exceeded'**
  String get rate_limit;

  /// No description provided for @redirect_error.
  ///
  /// In en, this message translates to:
  /// **'Redirect error'**
  String get redirect_error;

  /// No description provided for @timeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out'**
  String get timeout;

  /// No description provided for @request_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Request was cancelled'**
  String get request_cancelled;

  /// No description provided for @unknown_error.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get unknown_error;

  /// No description provided for @invalid_status.
  ///
  /// In en, this message translates to:
  /// **'Received invalid status code'**
  String get invalid_status;

  /// No description provided for @unexpected_error.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error'**
  String get unexpected_error;

  /// No description provided for @try_again.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get try_again;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @account_name.
  ///
  /// In en, this message translates to:
  /// **'Account Info'**
  String get account_name;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @no_transactions_found.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get no_transactions_found;

  /// No description provided for @withdraw_funds.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Funds'**
  String get withdraw_funds;

  /// No description provided for @available_balance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get available_balance;

  /// No description provided for @total_balance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get total_balance;

  /// No description provided for @regular_balance.
  ///
  /// In en, this message translates to:
  /// **'Cash Balance'**
  String get regular_balance;

  /// No description provided for @rewarded_balance.
  ///
  /// In en, this message translates to:
  /// **'Rewarded Balance'**
  String get rewarded_balance;

  /// No description provided for @regular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get regular;

  /// No description provided for @rewarded.
  ///
  /// In en, this message translates to:
  /// **'Rewarded'**
  String get rewarded;

  /// No description provided for @enter_amount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enter_amount;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @saved_locations.
  ///
  /// In en, this message translates to:
  /// **'Saved Locations'**
  String get saved_locations;

  /// No description provided for @add_location.
  ///
  /// In en, this message translates to:
  /// **'Add Location'**
  String get add_location;

  /// No description provided for @office.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get office;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @gym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get gym;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @withdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get withdrawn;

  /// No description provided for @location_permission_title.
  ///
  /// In en, this message translates to:
  /// **'Location Permission'**
  String get location_permission_title;

  /// No description provided for @permission_denied_mesg.
  ///
  /// In en, this message translates to:
  /// **'Ride App needs your location to show nearby rides and provide accurate pickup/dropoff services. Please grant location permission to continue.'**
  String get permission_denied_mesg;

  /// No description provided for @location_permission_required_title.
  ///
  /// In en, this message translates to:
  /// **'Location Permission Required'**
  String get location_permission_required_title;

  /// No description provided for @permanently_denied_mesg.
  ///
  /// In en, this message translates to:
  /// **'Location permission has been permanently denied. Please enable it in your device settings to use location-based features.'**
  String get permanently_denied_mesg;

  /// No description provided for @location_services_disabled_title.
  ///
  /// In en, this message translates to:
  /// **'Location Services Disabled'**
  String get location_services_disabled_title;

  /// No description provided for @location_services_disabled_mesg.
  ///
  /// In en, this message translates to:
  /// **'Location services are currently disabled on your device. Please enable them in your device settings to continue.'**
  String get location_services_disabled_mesg;

  /// No description provided for @failed_to_request.
  ///
  /// In en, this message translates to:
  /// **'Failed to request location permission'**
  String get failed_to_request;

  /// No description provided for @error_occurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get error_occurred;

  /// No description provided for @image_file_too_large.
  ///
  /// In en, this message translates to:
  /// **'File size exceeds {maxSizeInMB}MB. Please select a smaller file.'**
  String image_file_too_large(int maxSizeInMB);

  /// No description provided for @image_invalid_type.
  ///
  /// In en, this message translates to:
  /// **'Invalid file type: .{extension}. Only JPG and PNG are allowed.'**
  String image_invalid_type(String extension);

  /// No description provided for @open_settings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get open_settings;

  /// No description provided for @add_funds.
  ///
  /// In en, this message translates to:
  /// **'Add Funds'**
  String get add_funds;

  /// No description provided for @themePreferences.
  ///
  /// In en, this message translates to:
  /// **'Theme Preferences'**
  String get themePreferences;

  /// No description provided for @themeAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic (Day & Night Mode)'**
  String get themeAutomatic;

  /// No description provided for @themeAutomaticSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Light theme during the day and dark theme at night.'**
  String get themeAutomaticSubtitle;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeDarkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Always use dark mode'**
  String get themeDarkSubtitle;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeLightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Always use light mode'**
  String get themeLightSubtitle;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @enter_city.
  ///
  /// In en, this message translates to:
  /// **'Enter city'**
  String get enter_city;

  /// No description provided for @enter_state.
  ///
  /// In en, this message translates to:
  /// **'Enter state'**
  String get enter_state;

  /// No description provided for @search_address.
  ///
  /// In en, this message translates to:
  /// **'Search Address'**
  String get search_address;

  /// No description provided for @select_location.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get select_location;

  /// No description provided for @unknown_address.
  ///
  /// In en, this message translates to:
  /// **'Unknown address'**
  String get unknown_address;

  /// No description provided for @error_fetching_address.
  ///
  /// In en, this message translates to:
  /// **'Error fetching address'**
  String get error_fetching_address;

  /// No description provided for @search_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Search for a place...'**
  String get search_placeholder;

  /// No description provided for @search_pickup.
  ///
  /// In en, this message translates to:
  /// **'Search for a Pickup...'**
  String get search_pickup;

  /// No description provided for @search_dropoff.
  ///
  /// In en, this message translates to:
  /// **'Search for a Drop-off...'**
  String get search_dropoff;

  /// No description provided for @selected_location_label.
  ///
  /// In en, this message translates to:
  /// **'Selected Location'**
  String get selected_location_label;

  /// No description provided for @save_location.
  ///
  /// In en, this message translates to:
  /// **'Save This Location'**
  String get save_location;

  /// No description provided for @location_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your Location has been updated successfully.'**
  String get location_subtitle;

  /// No description provided for @location_deleted_successfully.
  ///
  /// In en, this message translates to:
  /// **'Location deleted successfully'**
  String get location_deleted_successfully;

  /// No description provided for @no_saved_locations_found.
  ///
  /// In en, this message translates to:
  /// **'No saved locations found'**
  String get no_saved_locations_found;

  /// No description provided for @please_select_valid_location.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid location'**
  String get please_select_valid_location;

  /// No description provided for @please_choose_location_with_full_address.
  ///
  /// In en, this message translates to:
  /// **'Please choose a location with full address'**
  String get please_choose_location_with_full_address;

  /// No description provided for @enter_location_name.
  ///
  /// In en, this message translates to:
  /// **'Enter location name'**
  String get enter_location_name;

  /// No description provided for @name_this_location.
  ///
  /// In en, this message translates to:
  /// **'Name This Location'**
  String get name_this_location;

  /// No description provided for @type_here.
  ///
  /// In en, this message translates to:
  /// **'Type Here'**
  String get type_here;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @edit_location.
  ///
  /// In en, this message translates to:
  /// **'Edit This Location'**
  String get edit_location;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @customer_reviews.
  ///
  /// In en, this message translates to:
  /// **'Customer Reviews'**
  String get customer_reviews;

  /// No description provided for @total_reviews.
  ///
  /// In en, this message translates to:
  /// **'{count} Reviews'**
  String total_reviews(Object count);

  /// No description provided for @star_count.
  ///
  /// In en, this message translates to:
  /// **'{count} stars'**
  String star_count(Object count);

  /// No description provided for @days_ago.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String days_ago(Object count);

  /// No description provided for @weeks_ago.
  ///
  /// In en, this message translates to:
  /// **'{count} weeks ago'**
  String weeks_ago(Object count);

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get dashboard;

  /// No description provided for @update_profile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get update_profile;

  /// No description provided for @update_profile_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your profile information below'**
  String get update_profile_subtitle;

  /// No description provided for @valid_amount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get valid_amount;

  /// No description provided for @amount_must_be_greater_than_0.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0'**
  String get amount_must_be_greater_than_0;

  /// No description provided for @max_2_decimal_places_allowed.
  ///
  /// In en, this message translates to:
  /// **'Max 2 decimal places allowed'**
  String get max_2_decimal_places_allowed;

  /// No description provided for @please_select_a_card.
  ///
  /// In en, this message translates to:
  /// **'Please select a card'**
  String get please_select_a_card;

  /// No description provided for @attached_cards.
  ///
  /// In en, this message translates to:
  /// **'Attached Cards'**
  String get attached_cards;

  /// No description provided for @no_cards_available.
  ///
  /// In en, this message translates to:
  /// **'No cards available'**
  String get no_cards_available;

  /// No description provided for @logoutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get logoutDialogTitle;

  /// No description provided for @logoutDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout your account?'**
  String get logoutDialogSubtitle;

  /// No description provided for @noCardsFound.
  ///
  /// In en, this message translates to:
  /// **'No cards found'**
  String get noCardsFound;

  /// No description provided for @attachAnotherCard.
  ///
  /// In en, this message translates to:
  /// **'Attach Another Card'**
  String get attachAnotherCard;

  /// No description provided for @addCard.
  ///
  /// In en, this message translates to:
  /// **'Add Card'**
  String get addCard;

  /// No description provided for @cardDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Card deleted successfully'**
  String get cardDeletedSuccessfully;

  /// No description provided for @cardAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Card added successfully'**
  String get cardAddedSuccessfully;

  /// No description provided for @defaultCardUpdated.
  ///
  /// In en, this message translates to:
  /// **'Default card updated'**
  String get defaultCardUpdated;

  /// No description provided for @threeDSMissingClientSecret.
  ///
  /// In en, this message translates to:
  /// **'3D Secure verification is required, but client secret is missing.'**
  String get threeDSMissingClientSecret;

  /// No description provided for @threeDSMissingPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'3D Secure verification requires a valid payment method.'**
  String get threeDSMissingPaymentMethod;

  /// No description provided for @threeDSVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed during 3D Secure verification.'**
  String get threeDSVerificationFailed;

  /// No description provided for @card_label.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card_label;

  /// No description provided for @masked_card_number.
  ///
  /// In en, this message translates to:
  /// **'**** **** **** {last4}'**
  String masked_card_number(Object last4);

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @delete_account_otp_prefix.
  ///
  /// In en, this message translates to:
  /// **'We will send a 6-digit code to'**
  String get delete_account_otp_prefix;

  /// No description provided for @no_drivers_available.
  ///
  /// In en, this message translates to:
  /// **'No Drivers  Available'**
  String get no_drivers_available;

  /// No description provided for @we_could_not_find.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t find any available drivers near your pickup location right now. You can try again in a moment or explore other ride options.'**
  String get we_could_not_find;

  /// No description provided for @delete_account_data_warning.
  ///
  /// In en, this message translates to:
  /// **'Your data will be removed from our database permanently.'**
  String get delete_account_data_warning;

  /// No description provided for @delete_account_ride_ongoing.
  ///
  /// In en, this message translates to:
  /// **'You cannot delete your account while a ride is in progress. Please complete or cancel the ride first.'**
  String get delete_account_ride_ongoing;

  /// No description provided for @send_otp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get send_otp;

  /// No description provided for @please_enter_otp.
  ///
  /// In en, this message translates to:
  /// **'Please enter 6 digit OTP'**
  String get please_enter_otp;

  /// No description provided for @verify_delete_account.
  ///
  /// In en, this message translates to:
  /// **'Verify & Delete Account'**
  String get verify_delete_account;

  /// No description provided for @ride_type_economy.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get ride_type_economy;

  /// No description provided for @ride_type_luxury.
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get ride_type_luxury;

  /// No description provided for @ride_type_private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get ride_type_private;

  /// No description provided for @ride_type_standard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get ride_type_standard;

  /// No description provided for @ride_date_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get ride_date_today;

  /// No description provided for @ride_date_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get ride_date_yesterday;

  /// No description provided for @end_ride.
  ///
  /// In en, this message translates to:
  /// **'End Ride'**
  String get end_ride;

  /// No description provided for @upload_image.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get upload_image;

  /// No description provided for @take_photo.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get take_photo;

  /// No description provided for @remove_photo.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get remove_photo;

  /// No description provided for @switch_ride.
  ///
  /// In en, this message translates to:
  /// **'Switch Ride'**
  String get switch_ride;

  /// No description provided for @keep_waiting.
  ///
  /// In en, this message translates to:
  /// **'Keep waiting'**
  String get keep_waiting;

  /// No description provided for @profile_not_found.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profile_not_found;

  /// No description provided for @profile_data_not_loaded.
  ///
  /// In en, this message translates to:
  /// **'Profile data not loaded'**
  String get profile_data_not_loaded;

  /// No description provided for @no_changes_to_update.
  ///
  /// In en, this message translates to:
  /// **'No changes to update'**
  String get no_changes_to_update;

  /// No description provided for @profile_updated_success.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profile_updated_success;

  /// No description provided for @upload_profile_picture_required.
  ///
  /// In en, this message translates to:
  /// **'Please upload a profile picture'**
  String get upload_profile_picture_required;

  /// No description provided for @delete_card_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this card?'**
  String get delete_card_confirmation;

  /// No description provided for @feed_back.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feed_back;

  /// No description provided for @subtitle_description.
  ///
  /// In en, this message translates to:
  /// **'We value your feedback! Please rate your driver and share your experience to help us improve our service. Thank you.'**
  String get subtitle_description;

  /// No description provided for @report_submitted.
  ///
  /// In en, this message translates to:
  /// **'Report Submitted'**
  String get report_submitted;

  /// No description provided for @how_was_the_driver.
  ///
  /// In en, this message translates to:
  /// **'How was the driver?'**
  String get how_was_the_driver;

  /// No description provided for @your_rating.
  ///
  /// In en, this message translates to:
  /// **'Your Rating'**
  String get your_rating;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get rating;

  /// No description provided for @ride_complete.
  ///
  /// In en, this message translates to:
  /// **'Ride Completed'**
  String get ride_complete;

  /// No description provided for @location_updated.
  ///
  /// In en, this message translates to:
  /// **'Location Updated!'**
  String get location_updated;

  /// No description provided for @thank_you_for_riding_with_us.
  ///
  /// In en, this message translates to:
  /// **'Thank you for riding with Ride App'**
  String get thank_you_for_riding_with_us;

  /// No description provided for @thank_you_for_riding.
  ///
  /// In en, this message translates to:
  /// **'Thank you for riding with Ride App'**
  String get thank_you_for_riding;

  /// No description provided for @see_you_on_your_next_trip.
  ///
  /// In en, this message translates to:
  /// **'See you on your next trip!'**
  String get see_you_on_your_next_trip;

  /// No description provided for @total_distance.
  ///
  /// In en, this message translates to:
  /// **'Total Distance'**
  String get total_distance;

  /// No description provided for @subtitle_dialgue.
  ///
  /// In en, this message translates to:
  /// **'Your report has been submitted We\'ll investigate the issue!'**
  String get subtitle_dialgue;

  /// No description provided for @ride_time.
  ///
  /// In en, this message translates to:
  /// **'Ride Time'**
  String get ride_time;

  /// No description provided for @total_fare.
  ///
  /// In en, this message translates to:
  /// **'Total Fare'**
  String get total_fare;

  /// No description provided for @confirm_pickup.
  ///
  /// In en, this message translates to:
  /// **'Confirm Pickup'**
  String get confirm_pickup;

  /// No description provided for @confirm_dropoff.
  ///
  /// In en, this message translates to:
  /// **'Confirm Drop-off'**
  String get confirm_dropoff;

  /// No description provided for @report_driver.
  ///
  /// In en, this message translates to:
  /// **'Report Driver'**
  String get report_driver;

  /// No description provided for @leave_a_review.
  ///
  /// In en, this message translates to:
  /// **'Leave A Review'**
  String get leave_a_review;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @by_user.
  ///
  /// In en, this message translates to:
  /// **'By User'**
  String get by_user;

  /// No description provided for @by_driver.
  ///
  /// In en, this message translates to:
  /// **'By Driver'**
  String get by_driver;

  /// No description provided for @hint_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get hint_description;

  /// No description provided for @no_rides.
  ///
  /// In en, this message translates to:
  /// **'No rides available'**
  String get no_rides;

  /// No description provided for @dialogue.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get dialogue;

  /// No description provided for @we_appreciate_issue.
  ///
  /// In en, this message translates to:
  /// **'We appreciate your feedback. Please provide details & We\'ll investigate the issue.'**
  String get we_appreciate_issue;

  /// No description provided for @invalid_email.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalid_email;

  /// No description provided for @email_too_long.
  ///
  /// In en, this message translates to:
  /// **'Email address is too long'**
  String get email_too_long;

  /// No description provided for @email_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get email_hint;

  /// No description provided for @defaultt.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultt;

  /// No description provided for @delete_card.
  ///
  /// In en, this message translates to:
  /// **'Delete Card'**
  String get delete_card;

  /// No description provided for @delete_location.
  ///
  /// In en, this message translates to:
  /// **'Delete Location'**
  String get delete_location;

  /// No description provided for @delete_location_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this saved location?'**
  String get delete_location_confirmation;

  /// No description provided for @share_ride.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share_ride;

  /// No description provided for @tbd.
  ///
  /// In en, this message translates to:
  /// **'TBD'**
  String get tbd;

  /// No description provided for @miles.
  ///
  /// In en, this message translates to:
  /// **'miles'**
  String get miles;

  /// No description provided for @chat_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chat_today;

  /// No description provided for @chat_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chat_yesterday;

  /// No description provided for @chat_message_hint.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get chat_message_hint;

  /// No description provided for @chat_block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get chat_block;

  /// No description provided for @chat_report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get chat_report;

  /// No description provided for @report_user.
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get report_user;

  /// No description provided for @report_reason_unprofessional.
  ///
  /// In en, this message translates to:
  /// **'Unprofessional Behavior'**
  String get report_reason_unprofessional;

  /// No description provided for @report_reason_poor_communication.
  ///
  /// In en, this message translates to:
  /// **'Poor Communication'**
  String get report_reason_poor_communication;

  /// No description provided for @report_reason_fake_account.
  ///
  /// In en, this message translates to:
  /// **'Fake or Impersonating Account'**
  String get report_reason_fake_account;

  /// No description provided for @report_reason_harassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or Bullying'**
  String get report_reason_harassment;

  /// No description provided for @report_reason_abuse.
  ///
  /// In en, this message translates to:
  /// **'Abuse or Misconduct'**
  String get report_reason_abuse;

  /// No description provided for @report_reason_violation_policies.
  ///
  /// In en, this message translates to:
  /// **'Violation Policies'**
  String get report_reason_violation_policies;

  /// No description provided for @block_user.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get block_user;

  /// No description provided for @block_user_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to block this user?'**
  String get block_user_confirmation;

  /// No description provided for @don_t_block.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Block'**
  String get don_t_block;

  /// No description provided for @block_now.
  ///
  /// In en, this message translates to:
  /// **'Block Now'**
  String get block_now;

  /// No description provided for @requested_carpool.
  ///
  /// In en, this message translates to:
  /// **'Requested Carpool'**
  String get requested_carpool;

  /// No description provided for @no_requested_carpool.
  ///
  /// In en, this message translates to:
  /// **'No requested carpool found.'**
  String get no_requested_carpool;

  /// No description provided for @booking_id_with_id.
  ///
  /// In en, this message translates to:
  /// **'Booking ID: {id}'**
  String booking_id_with_id(String id);

  /// No description provided for @cancel_request.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancel_request;

  /// No description provided for @carpool_driver.
  ///
  /// In en, this message translates to:
  /// **'Carpool Driver'**
  String get carpool_driver;

  /// No description provided for @searching_carpool.
  ///
  /// In en, this message translates to:
  /// **'Searching for available\ncarpool rides...'**
  String get searching_carpool;

  /// No description provided for @ride_start_time.
  ///
  /// In en, this message translates to:
  /// **'Ride Start Time'**
  String get ride_start_time;

  /// No description provided for @available_seats_label.
  ///
  /// In en, this message translates to:
  /// **'Available Seats'**
  String get available_seats_label;

  /// No description provided for @seats_count.
  ///
  /// In en, this message translates to:
  /// **'{count} Seats'**
  String seats_count(int count);

  /// No description provided for @per_person.
  ///
  /// In en, this message translates to:
  /// **'/per person'**
  String get per_person;

  /// No description provided for @please_wait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get please_wait;

  /// No description provided for @request_sent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get request_sent;

  /// No description provided for @send_request.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get send_request;

  /// No description provided for @driver_label.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver_label;

  /// No description provided for @inappropriate_behavior.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate behavior'**
  String get inappropriate_behavior;

  /// No description provided for @map_load_error.
  ///
  /// In en, this message translates to:
  /// **'Map load error: {error}'**
  String map_load_error(String error);

  /// No description provided for @number_of_passengers_label.
  ///
  /// In en, this message translates to:
  /// **'Number of passenger'**
  String get number_of_passengers_label;

  /// No description provided for @persen.
  ///
  /// In en, this message translates to:
  /// **'/person'**
  String get persen;

  /// No description provided for @select_pickup_dropoff.
  ///
  /// In en, this message translates to:
  /// **'Please select pickup and dropoff locations.'**
  String get select_pickup_dropoff;

  /// No description provided for @select_ride_type_error.
  ///
  /// In en, this message translates to:
  /// **'Please select a ride type.'**
  String get select_ride_type_error;

  /// No description provided for @unable_calculate_distance.
  ///
  /// In en, this message translates to:
  /// **'Unable to calculate ride distance.'**
  String get unable_calculate_distance;

  /// No description provided for @fare_too_low.
  ///
  /// In en, this message translates to:
  /// **'Estimated fare is too low to proceed.'**
  String get fare_too_low;

  /// No description provided for @start_label.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start_label;

  /// No description provided for @end_label.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end_label;

  /// No description provided for @socket_error_502.
  ///
  /// In en, this message translates to:
  /// **'Live ride updates are temporarily unavailable. Please try again.'**
  String get socket_error_502;

  /// No description provided for @socket_error_auth.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please sign in again.'**
  String get socket_error_auth;

  /// No description provided for @socket_error_timeout.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to live ride updates right now. Please try again.'**
  String get socket_error_timeout;

  /// No description provided for @socket_error_network.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get socket_error_network;

  /// No description provided for @socket_error_generic.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to live ride updates right now.'**
  String get socket_error_generic;

  /// No description provided for @socket_disconnect_retry.
  ///
  /// In en, this message translates to:
  /// **'Connection to live ride updates was lost. Retrying...'**
  String get socket_disconnect_retry;

  /// No description provided for @socket_unstable_connection.
  ///
  /// In en, this message translates to:
  /// **'Unstable internet connection!'**
  String get socket_unstable_connection;

  /// No description provided for @ride_accepted_success.
  ///
  /// In en, this message translates to:
  /// **'Your ride has been accepted successfully!'**
  String get ride_accepted_success;

  /// No description provided for @driver_arrived_at_place.
  ///
  /// In en, this message translates to:
  /// **'Driver arrived at {place}'**
  String driver_arrived_at_place(String place);

  /// No description provided for @carpool_request_cancelled_fallback.
  ///
  /// In en, this message translates to:
  /// **'Carpool request was cancelled.'**
  String get carpool_request_cancelled_fallback;

  /// No description provided for @carpool_request_rejected_fallback.
  ///
  /// In en, this message translates to:
  /// **'Carpool request was rejected by the driver.'**
  String get carpool_request_rejected_fallback;

  /// No description provided for @carpool_request_accepted_fallback.
  ///
  /// In en, this message translates to:
  /// **'Carpool request accepted.'**
  String get carpool_request_accepted_fallback;

  /// No description provided for @carpool_ride_started_fallback.
  ///
  /// In en, this message translates to:
  /// **'Your carpool ride has started!'**
  String get carpool_ride_started_fallback;

  /// No description provided for @payment_verification_missing_client_secret.
  ///
  /// In en, this message translates to:
  /// **'Carpool payment verification is required, but client secret is missing.'**
  String get payment_verification_missing_client_secret;

  /// No description provided for @no_internet_title.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get no_internet_title;

  /// No description provided for @no_internet_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Please check your network settings and try again to continue using the app.'**
  String get no_internet_subtitle;

  /// No description provided for @slow_connection_title.
  ///
  /// In en, this message translates to:
  /// **'Connection Too Slow'**
  String get slow_connection_title;

  /// No description provided for @slow_connection_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your internet connection is too slow to use the app right now. Please check your network and try again.'**
  String get slow_connection_subtitle;

  /// No description provided for @slow_connection_banner.
  ///
  /// In en, this message translates to:
  /// **'Unstable connection. Some actions may be delayed.'**
  String get slow_connection_banner;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @enter_route.
  ///
  /// In en, this message translates to:
  /// **'Enter Route'**
  String get enter_route;

  /// No description provided for @search_results.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get search_results;

  /// No description provided for @recent_locations.
  ///
  /// In en, this message translates to:
  /// **'Recent Locations'**
  String get recent_locations;

  /// No description provided for @popular_nearby.
  ///
  /// In en, this message translates to:
  /// **'Popular Nearby'**
  String get popular_nearby;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @outside_service_region.
  ///
  /// In en, this message translates to:
  /// **'Outside Service Region'**
  String get outside_service_region;

  /// No description provided for @outside_service_region_message.
  ///
  /// In en, this message translates to:
  /// **'You are not in {regionName} right now. Please choose a location within {regionName} to continue.'**
  String outside_service_region_message(String regionName);

  /// No description provided for @chat_no_messages_yet.
  ///
  /// In en, this message translates to:
  /// **'There are no new messages yet'**
  String get chat_no_messages_yet;

  /// No description provided for @promo_code_applied.
  ///
  /// In en, this message translates to:
  /// **'Promo Code Applied'**
  String get promo_code_applied;

  /// No description provided for @hint_promo.
  ///
  /// In en, this message translates to:
  /// **'Apply Promo Code'**
  String get hint_promo;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @promo_code.
  ///
  /// In en, this message translates to:
  /// **'Promo Code'**
  String get promo_code;

  /// No description provided for @invalid_date_format.
  ///
  /// In en, this message translates to:
  /// **'Invalid date format'**
  String get invalid_date_format;

  /// No description provided for @min_age_15_required.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 15 years old'**
  String get min_age_15_required;

  /// No description provided for @enter_promo.
  ///
  /// In en, this message translates to:
  /// **'Enter Promo Code'**
  String get enter_promo;

  /// No description provided for @enter_promo_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Use a promo code to get instant ride discounts.'**
  String get enter_promo_subtitle;

  /// No description provided for @remove_promo.
  ///
  /// In en, this message translates to:
  /// **'Remove Promo Code'**
  String get remove_promo;

  /// No description provided for @remove_promo_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the applied promo code?'**
  String get remove_promo_message;

  /// No description provided for @promo_removal_warning.
  ///
  /// In en, this message translates to:
  /// **'Changing this will remove your applied promo code.'**
  String get promo_removal_warning;

  /// No description provided for @please_add_card_to_continue.
  ///
  /// In en, this message translates to:
  /// **'Please add a card to continue.'**
  String get please_add_card_to_continue;

  /// No description provided for @card_details_incomplete.
  ///
  /// In en, this message translates to:
  /// **'Card details incomplete'**
  String get card_details_incomplete;

  /// No description provided for @unable_cancel_ride_missing_id.
  ///
  /// In en, this message translates to:
  /// **'Unable to cancel ride. Missing ride ID.'**
  String get unable_cancel_ride_missing_id;

  /// No description provided for @unable_share_ride_missing_id.
  ///
  /// In en, this message translates to:
  /// **'Unable to share ride. Missing ride ID.'**
  String get unable_share_ride_missing_id;

  /// No description provided for @unable_share_ride_url.
  ///
  /// In en, this message translates to:
  /// **'Unable to share ride URL.'**
  String get unable_share_ride_url;

  /// No description provided for @unable_share_carpool_ride_missing_id.
  ///
  /// In en, this message translates to:
  /// **'Unable to share carpool ride. Missing ride ID.'**
  String get unable_share_carpool_ride_missing_id;

  /// No description provided for @unable_share_carpool_ride_url.
  ///
  /// In en, this message translates to:
  /// **'Unable to share carpool ride URL.'**
  String get unable_share_carpool_ride_url;

  /// No description provided for @first_name.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get first_name;

  /// No description provided for @last_name.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get last_name;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @dropoff.
  ///
  /// In en, this message translates to:
  /// **'Drop off'**
  String get dropoff;

  /// No description provided for @delete_all_notifications.
  ///
  /// In en, this message translates to:
  /// **'Delete all notifications'**
  String get delete_all_notifications;

  /// No description provided for @delete_all_notifications_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all notifications?'**
  String get delete_all_notifications_confirmation;

  /// No description provided for @minimum_5_characters_required.
  ///
  /// In en, this message translates to:
  /// **'Minimum 5 characters required'**
  String get minimum_5_characters_required;

  /// No description provided for @address_cannot_be_only_numbers.
  ///
  /// In en, this message translates to:
  /// **'Address cannot be only numbers'**
  String get address_cannot_be_only_numbers;

  /// No description provided for @address_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid address'**
  String get address_invalid;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @only_florida_addresses_supported.
  ///
  /// In en, this message translates to:
  /// **'Only Florida (FL) addresses are supported'**
  String get only_florida_addresses_supported;

  /// No description provided for @where_from.
  ///
  /// In en, this message translates to:
  /// **'Where From?'**
  String get where_from;

  /// No description provided for @locating.
  ///
  /// In en, this message translates to:
  /// **'Locating...'**
  String get locating;

  /// No description provided for @choose_on_map.
  ///
  /// In en, this message translates to:
  /// **'Choose on map'**
  String get choose_on_map;

  /// No description provided for @confirm_route.
  ///
  /// In en, this message translates to:
  /// **'Confirm Route'**
  String get confirm_route;

  /// No description provided for @set_location_on_map.
  ///
  /// In en, this message translates to:
  /// **'Set location on map'**
  String get set_location_on_map;

  /// No description provided for @searching_nearby_drivers.
  ///
  /// In en, this message translates to:
  /// **'Searching for nearby drivers...'**
  String get searching_nearby_drivers;

  /// No description provided for @searching_within_distance.
  ///
  /// In en, this message translates to:
  /// **'Searching within {distance}'**
  String searching_within_distance(String distance);

  /// No description provided for @search_step_of.
  ///
  /// In en, this message translates to:
  /// **'Step {ring} of {total}'**
  String search_step_of(int ring, int total);

  /// No description provided for @drivers_notified_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No drivers reached yet} =1{1 driver notified} other{{count} drivers notified}}'**
  String drivers_notified_count(int count);

  /// No description provided for @expanding_search_in_seconds.
  ///
  /// In en, this message translates to:
  /// **'Widening the search in {seconds}s'**
  String expanding_search_in_seconds(int seconds);

  /// No description provided for @widening_search_now.
  ///
  /// In en, this message translates to:
  /// **'Widening the search...'**
  String get widening_search_now;

  /// No description provided for @searched_up_to_distance.
  ///
  /// In en, this message translates to:
  /// **'We searched up to {distance} around your pickup.'**
  String searched_up_to_distance(String distance);

  /// No description provided for @request_another_ride.
  ///
  /// In en, this message translates to:
  /// **'Request another ride'**
  String get request_another_ride;

  /// No description provided for @back_to_home.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get back_to_home;

  /// No description provided for @free_ride.
  ///
  /// In en, this message translates to:
  /// **'Free ride'**
  String get free_ride;

  /// No description provided for @free_ride_no_payment_needed.
  ///
  /// In en, this message translates to:
  /// **'Your promo covers this ride in full. No payment method needed.'**
  String get free_ride_no_payment_needed;

  /// No description provided for @no_drivers_near_you.
  ///
  /// In en, this message translates to:
  /// **'No drivers near you'**
  String get no_drivers_near_you;

  /// No description provided for @search_stage_nearby.
  ///
  /// In en, this message translates to:
  /// **'Looking for drivers closest to you.'**
  String get search_stage_nearby;

  /// No description provided for @search_stage_widened.
  ///
  /// In en, this message translates to:
  /// **'Nobody nearby yet, so we widened the search to {distance}.'**
  String search_stage_widened(String distance);

  /// No description provided for @search_stage_last.
  ///
  /// In en, this message translates to:
  /// **'Last try: we are now searching up to {distance}.'**
  String search_stage_last(String distance);

  /// No description provided for @upgrade_offer_title.
  ///
  /// In en, this message translates to:
  /// **'No {category} drivers nearby'**
  String upgrade_offer_title(String category);

  /// No description provided for @upgrade_offer_fallback.
  ///
  /// In en, this message translates to:
  /// **'Want us to look for a {category} car for {fare}?'**
  String upgrade_offer_fallback(String category, String fare);

  /// No description provided for @upgrade_original_fare.
  ///
  /// In en, this message translates to:
  /// **'Original fare'**
  String get upgrade_original_fare;

  /// No description provided for @upgrade_new_fare.
  ///
  /// In en, this message translates to:
  /// **'New fare'**
  String get upgrade_new_fare;

  /// No description provided for @upgrade_seconds_left.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =0{Time is up} =1{1 second left to decide} other{{seconds} seconds left to decide}}'**
  String upgrade_seconds_left(int seconds);

  /// No description provided for @upgrade_promo_lost.
  ///
  /// In en, this message translates to:
  /// **'Your promo code doesn\'t apply to {category}. If you accept, you lose your {amount} discount.'**
  String upgrade_promo_lost(String category, String amount);

  /// No description provided for @upgrade_promo_lost_no_amount.
  ///
  /// In en, this message translates to:
  /// **'Your promo code doesn\'t apply to {category} and will be removed if you accept.'**
  String upgrade_promo_lost_no_amount(String category);

  /// No description provided for @upgrade_accept.
  ///
  /// In en, this message translates to:
  /// **'Search {category}'**
  String upgrade_accept(String category);

  /// No description provided for @upgrade_decline.
  ///
  /// In en, this message translates to:
  /// **'No thanks'**
  String get upgrade_decline;

  /// No description provided for @upgrade_new_search.
  ///
  /// In en, this message translates to:
  /// **'New search: {category}'**
  String upgrade_new_search(String category);

  /// No description provided for @upgrade_insufficient_wallet.
  ///
  /// In en, this message translates to:
  /// **'Your wallet balance doesn\'t cover the {category} fare. Top up your wallet or switch to a card.'**
  String upgrade_insufficient_wallet(String category);

  /// No description provided for @upgrade_no_active_card.
  ///
  /// In en, this message translates to:
  /// **'Add a card to switch to {category}.'**
  String upgrade_no_active_card(String category);

  /// No description provided for @upgrade_decision_failed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send your answer. Please try again.'**
  String get upgrade_decision_failed;

  /// No description provided for @search_ends_in_seconds.
  ///
  /// In en, this message translates to:
  /// **'Last try ends in {seconds}s'**
  String search_ends_in_seconds(int seconds);

  /// No description provided for @search_finishing_now.
  ///
  /// In en, this message translates to:
  /// **'Finishing the search...'**
  String get search_finishing_now;

  /// No description provided for @address_search_failed.
  ///
  /// In en, this message translates to:
  /// **'Unable to look up this address. You can try again or enter it manually.'**
  String get address_search_failed;

  /// No description provided for @address_search_outside_region.
  ///
  /// In en, this message translates to:
  /// **'Choose an address within the service area.'**
  String get address_search_outside_region;

  /// No description provided for @address_search_retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get address_search_retry;

  /// No description provided for @address_search_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Address search is unavailable. Enter the address manually.'**
  String get address_search_unavailable;

  /// No description provided for @address_search_incomplete.
  ///
  /// In en, this message translates to:
  /// **'This address could not be confirmed. Enter the address manually.'**
  String get address_search_incomplete;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
