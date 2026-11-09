import 'package:ride_app/features/user_profile/data/models/user_model.dart';
import 'package:ride_app/features/user_profile/domain/entites/user_entity.dart';
import 'package:ride_app/features/user_profile/domain/entites/user_profile_entity.dart';

class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({required super.user});

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(user: UserModel.fromJson(json['data']['user']));
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(user: UserModel.fromJson(map['user']));
  }

  @override
  UserProfileModel copyWith({UserEntity? user}) {
    return UserProfileModel(user: (user ?? this.user) as UserModel);
  }
}
