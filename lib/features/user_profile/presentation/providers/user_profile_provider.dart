import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/params/auth_params.dart';
import 'package:ride_app/features/user_profile/data/models/user_model.dart';
import 'package:ride_app/features/user_profile/data/models/user_profile_model.dart';
import 'package:ride_app/features/user_profile/domain/usecase/update_profile_usecase.dart';
import 'package:ride_app/features/user_profile/domain/usecase/user_profile_usecase.dart';
import 'package:ride_app/features/user_profile/presentation/states/user_states.dart';

final getProfileUseCaseProvider = Provider<UserProfileUseCase>(
  (ref) => locator<UserProfileUseCase>(),
);

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>(
  (ref) => locator<UpdateProfileUseCase>(),
);

final userProfileProvider =
    NotifierProvider<UserProfileController, UserProfileState>(
      UserProfileController.new,
    );

class UserProfileController extends Notifier<UserProfileState> {
  @override
  UserProfileState build() {
    return const UserProfileState();
  }

  /// ===============================
  /// GET PROFILE
  /// ===============================
  Future<void> getProfile() async {
    final getProfile = ref.read(getProfileUseCaseProvider);

    state = state.copyWith(
      status: UserProfileStatus.loading,
      action: UserProfileAction.getProfile,
    );

    final result = await getProfile();

    result.fold(
      (failure) {
        state = state.copyWith(
          status: UserProfileStatus.error,
          message: failure.message,
        );
      },
      (profileData) {
        state = state.copyWith(
          status: UserProfileStatus.success,
          action: UserProfileAction.getProfile,
          profile: profileData,
          message: null,
        );
      },
    );
  }

  /// ===============================
  /// UPDATE PROFILE
  /// ===============================
  Future<void> updateProfile(UpdateProfileParams params) async {
    final updateProfile = ref.read(updateProfileUseCaseProvider);

    state = state.copyWith(
      status: UserProfileStatus.loading,
      action: UserProfileAction.updateProfile,
    );

    final result = await updateProfile(params);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: UserProfileStatus.error,
          message: failure.message,
        );
      },
      (updatedProfile) {
        state = state.copyWith(
          status: UserProfileStatus.success,
          action: UserProfileAction.updateProfile,
          profile: updatedProfile,
          message: null,
        );
      },
    );
  }

  /// ===============================
  /// UPDATE NOTIFICATION STATUS LOCALLY
  /// ===============================
  void updateNotificationStatus(bool isEnabled) {
    if (state.profile != null) {
      final updatedUser = state.profile!.user.copyWith(
        isNotificationEnabled: isEnabled,
      );
      final updatedProfile = state.profile!.copyWith(
        user: updatedUser as UserModel,
      );
      state = state.copyWith(profile: updatedProfile as UserProfileModel);
    }
  }
}
