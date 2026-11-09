import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/constants/api_endpoints.dart';
import 'package:ride_app/core/errors/network_error_handler.dart';
import 'package:ride_app/core/params/auth_params.dart';
import 'package:ride_app/core/services/api_service.dart';
import 'package:ride_app/features/auth/data/models/auth_model.dart';
import 'package:ride_app/features/user_profile/data/models/user_model.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

import '../../../../core/errors/failure.dart';

/// ===============================
/// ABSTRACT DATASOURCE
/// ===============================
abstract class AuthDatasource {
  /// Create new user profile (Signup)
  Future<Either<Failure, String>> sendOtp(SendOtpParams params);
  Future<Either<Failure, String>> logout();

  /// Login user with email & password
  Future<Either<Failure, AuthResponseModel>> createProfile(CreateProfileParams params);

  /// Verify OTP after signup/login
  Future<Either<Failure, AuthResponseModel>> verifyOtp(VerifyOtpParams params);

  /// Delete user account
  Future<Either<Failure, bool>> deleteAccount(String otp);
}

/// ===============================
/// IMPLEMENTATION
/// ===============================
class AuthDatasourceImpl implements AuthDatasource {
  final ApiService _apiService;

  const AuthDatasourceImpl(this._apiService);

  /// ---------------------------------
  /// CREATE PROFILE (SIGNUP)
  /// ---------------------------------
  @override
  Future<Either<Failure, AuthResponseModel>> createProfile(CreateProfileParams params) {
    return handleNetworkError(() async {
      _apiService.setDeviceIds();

      final response = await _apiService.post(
        ApiEndpoints.register,
        data: params.toFormData(),
      );

      final apiResponse = ApiResponse.fromMap(response.data);
      final data = apiResponse.data as Map<String, dynamic>;

      final authResponse = AuthResponseModel(
        token: data['token'] as String?,
        user: UserModel.fromJson(data['user']),
        isOnboarded: true,
      );
      _apiService.clearDeviceIds();

      return authResponse;
    });
  }

  /// ---------------------------------
  /// SEND OTP (LOGIN)
  /// ---------------------------------
  @override
  Future<Either<Failure, String>> sendOtp(SendOtpParams params) {
    return handleNetworkError(() async {
      final response = await _apiService.post(
        ApiEndpoints.sendOtp,
        data: params.toJson(),
      );

      final apiResponse = ApiResponse.fromMap(response.data);
      return apiResponse.message ?? 'Login successful';
    });
  }

  /// ---------------------------------
  ///  (LOGOUt)
  /// ---------------------------------
  @override
  Future<Either<Failure, String>> logout() {
    return handleNetworkError(() async {
      final response = await _apiService.post(ApiEndpoints.logout);

      final apiResponse = ApiResponse.fromMap(response.data);
      return apiResponse.message ?? '';
    });
  }

  /// ---------------------------------
  /// VERIFY OTP
  /// ---------------------------------
  @override
  Future<Either<Failure, AuthResponseModel>> verifyOtp(VerifyOtpParams params) {
    return handleNetworkError(() async {
      _apiService.setDeviceIds();

      final response = await _apiService.post(
        ApiEndpoints.verifyOtp,
        data: params.toJson(),
      );

      final apiResponse = ApiResponse.fromMap(response.data);
      _apiService.clearDeviceIds();

      return AuthResponseModel.fromJson(apiResponse.data);
    });
  }

  /// ---------------------------------
  /// DELETE ACCOUNT
  /// ---------------------------------
  @override
  Future<Either<Failure, bool>> deleteAccount(String otp) {
    return handleNetworkError(() async {
      final response = await _apiService.post(
        ApiEndpoints.deleteAccount,
        data: {'otp': otp},
      );

      final apiResponse = ApiResponse.fromMap(response.data);

      return apiResponse.success;
    });
  }
}
