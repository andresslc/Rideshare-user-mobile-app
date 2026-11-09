import 'package:ride_app/features/auth/domain/entities/auth_entity.dart';
import 'package:ride_app/features/user_profile/data/models/user_model.dart';

class AuthResponseModel extends AuthResponseEntity {
  AuthResponseModel({
    required super.token,
    required UserModel? super.user,
    required super.isOnboarded,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: json['token'],
      user: json['user'] != null
          ? UserModel.fromJson(json['user'])
          : null,
      isOnboarded: json['isOnboarded'] ?? false,
    );
  }

}
