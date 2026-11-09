// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:ride_app/features/user_profile/domain/entites/user_entity.dart';

class AuthResponseEntity {
  final bool isOnboarded;
  final String? token;
  final UserEntity? user;

  AuthResponseEntity({
    required this.isOnboarded,
    this.token,
    this.user,
  });
}

