import 'package:fpdart/fpdart.dart';
import 'package:ride_app/features/auth/domain/entities/auth_entity.dart';
import 'package:ride_app/features/user_profile/data/models/user_model.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/params/auth_params.dart';

/// =======================================
/// AUTH REPOSITORY CONTRACT
/// =======================================
abstract class AuthRepository {
  /// Login with phone number (OTP)
  Future<Either<Failure, UserModel>> createProfile({
    required CreateProfileParams params,
  });

  /// Create new user profile (Signup)
  Future<Either<Failure, String>> login({required SendOtpParams params});

  /// Verify OTP after signup/login
  Future<Either<Failure, AuthResponseEntity>> verifyOtp({
    required VerifyOtpParams params,
  });

  Future<Either<Failure, String>> logout();

  Future<Either<Failure, bool>> deleteAccount(String otp);
}
