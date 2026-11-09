import 'package:ride_app/features/user_profile/domain/entites/user_entity.dart';

class UserProfileEntity {
  final UserEntity user;

  const UserProfileEntity({
    required this.user,
  });

  UserProfileEntity copyWith({
    UserEntity? user,
  }) {
    return UserProfileEntity(
      user: user ?? this.user,
    );
  }
}
