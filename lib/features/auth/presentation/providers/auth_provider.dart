import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/features/auth/domain/use_cases/create_profile_usecase.dart.dart';
import 'package:ride_app/features/auth/domain/use_cases/delete_account_usecase.dart';
import 'package:ride_app/features/auth/domain/use_cases/logout_usecase.dart';
import 'package:ride_app/features/auth/domain/use_cases/send_otp_usecase.dart';
import 'package:ride_app/features/auth/domain/use_cases/verify_otp_usecase.dart';
import 'package:ride_app/features/auth/presentation/states/auth_state.dart';
import 'package:ride_app/features/card/presentation/providers/card_provider.dart';
import 'package:ride_app/features/notification/presentation/providers/notification_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/carpool_map_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/map_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_room_provider.dart';
import 'package:ride_app/features/settings/presentation/providers/saved_locations_provider.dart';
import 'package:ride_app/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:ride_app/features/wallet/presentation/providers/wallet_provider.dart';

import '../../../../core/params/auth_params.dart';

final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  late StorageService storageService;
  late ApiService apiService;
  @override
  AuthState build() {
    storageService = locator<StorageService>();
    apiService = locator<ApiService>();
    return const AuthInitial();
  }

  /// ------------------------------
  /// CREATE PROFILE
  /// ------------------------------
  Future<void> createProfile(CreateProfileParams params) async {
    state = const AuthLoading();

    final result = await locator<CreateProfileUseCase>().call(params);

    await result.fold(
      (failure) async {
        state = AuthError(failure.message);
      },
      (user) async {
        await _connectSocketForAuthenticatedUser();
        state = ProfileCreated(user);
      },
    );
  }

  /// ------------------------------
  /// SEND OTP
  /// ------------------------------
  Future<void> sendOtp(SendOtpParams params) async {
    state = const AuthLoading();

    final result = await locator<SendOtpUseCase>().call(params);

    state = result.fold(
      (failure) => AuthError(failure.message),
      (result) => OtpSent(result),
    );
  }

  Future<void> resendOtp(SendOtpParams params) async {
    state = const AuthLoading();

    final result = await locator<SendOtpUseCase>().call(params);

    state = result.fold(
      (failure) => AuthError(failure.message),
      (result) => OtpResent(result),
    );
  }

  /// ------------------------------
  /// VERIFY OTP
  /// ------------------------------
  Future<void> verifyOtp(VerifyOtpParams params) async {
    state = const AuthLoading();

    final result = await locator<VerifyOtpUseCase>().call(params);

    await result.fold(
      (failure) async {
        state = AuthError(failure.message);
      },
      (response) async {
        await _connectSocketForAuthenticatedUser();
        state = OtpVerified(response);
      },
    );
  }

  void reset() {
    state = const AuthInitial();
  }

  /// ------------------------------
  /// LOGOUT
  /// ------------------------------
  Future<void> logout() async {
    state = const AuthLoading();

    try {
      // Best-effort server logout while Dio still has the Bearer token.
      await locator<LogoutUseCase>().call();
    } finally {
      await storageService.clearAuthSession();
      apiService.clearAuthToken();
      try {
        await ref.read(rideRoomProvider.notifier).disconnectRideSocket();
      } catch (_) {
        // Still clear session locally even if socket teardown fails.
      }
      _clearUserScopedProviders();
      state = LoggedOut();
    }
  }

  /// ------------------------------
  /// DELETE ACCOUNT
  /// ------------------------------
  Future<void> deleteAccount(String otp) async {
    state = const AuthLoading();

    final result = await locator<DeleteAccountUseCase>().call(otp);

    await result.fold(
      (failure) async {
        state = AuthError(failure.message);
      },
      (success) async {
        await ref.read(rideRoomProvider.notifier).disconnectRideSocket();
        state = AccountDeleted();
      },
    );
  }

  Future<void> _connectSocketForAuthenticatedUser() async {
    final String? token = storageService.getToken;
    if (token == null || token.isEmpty) return;
    await ref.read(rideRoomProvider.notifier).connectRideSocket();
  }

  void _clearUserScopedProviders() {
    ref.invalidate(mapProvider);
    ref.invalidate(carpoolMapProvider);
    ref.invalidate(rideRoomProvider);
    ref.invalidate(userProfileProvider);
    ref.invalidate(notificationProvider);
    ref.invalidate(paymentProvider);
    ref.invalidate(walletProvider);
    ref.invalidate(savedLocationsProvider);
  }
}
