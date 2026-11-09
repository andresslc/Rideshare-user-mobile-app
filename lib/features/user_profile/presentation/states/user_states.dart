import 'package:ride_app/features/user_profile/domain/entites/user_profile_entity.dart';

enum UserProfileStatus { initial, loading, success, error }

enum UserProfileAction {
  none,
  getProfile,
  updateProfile,
}

class UserProfileState {
  final UserProfileStatus status;
  final UserProfileAction action;
  final UserProfileEntity? profile;
  final String? message;

  const UserProfileState({
    this.status = UserProfileStatus.initial,
    this.action = UserProfileAction.none,
    this.profile,
    this.message,
  });

  UserProfileState copyWith({
    UserProfileStatus? status,
    UserProfileAction? action,
    UserProfileEntity? profile,
    String? message,
  }) {
    return UserProfileState(
      status: status ?? this.status,
      action: action ?? this.action,
      profile: profile ?? this.profile,
      message: message,
    );
  }
}
