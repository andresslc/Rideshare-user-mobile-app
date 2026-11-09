import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/constants/api_endpoints.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/errors/network_error_handler.dart';
import 'package:ride_app/core/params/auth_params.dart';
import 'package:ride_app/core/services/api_service.dart';
import 'package:ride_app/core/services/storage_service.dart';
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
  Future<Either<Failure, UserModel>> createProfile(CreateProfileParams params);

  /// Verify OTP after signup/login
  Future<Either<Failure, AuthResponseModel>> verifyOtp(VerifyOtpParams params);

  /// Delete user account
  Future<Either<Failure, bool>> deleteAccount(String otp);
}

/// ===============================
/// IMPLEMENTATION
/// ===============================
class AuthDatasourceImpl implements AuthDatasource {
  final ApiService _apiService = locator<ApiService>();
  final StorageService _storageService = locator<StorageService>();

  /// ---------------------------------
  /// CREATE PROFILE (SIGNUP)
  /// ---------------------------------
  @override
  Future<Either<Failure, UserModel>> createProfile(CreateProfileParams params) {
    return handleNetworkError(() async {
      _apiService.setDeviceIds();

      final response = await _apiService.post(
        ApiEndpoints.register,
        data: params.toFormData(),
      );

      final apiResponse = ApiResponse.fromMap(response.data);

      if (apiResponse.success) {
        _saveTokenAndUser(apiResponse.data);
      }

      final user = UserModel.fromJson(apiResponse.data['user']);
      _apiService.clearDeviceIds();

      return user;
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

      if (apiResponse.success) {
        _saveTokenAndUser(apiResponse.data);
      }
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

      await _storageService.clearAuthSession();
      _apiService.clearAuthToken();
      

      return apiResponse.success;
    });
  }

  /// ---------------------------------
  /// PRIVATE HELPER: SAVE TOKEN AND USER
  /// ---------------------------------
  void _saveTokenAndUser(Map<String, dynamic> data) {
    final token = data['token'] as String?;
    final userJson = data['user'];

    if (token != null) {
      _apiService.setAuthToken(token);
      _storageService.setToken(token);

      if (userJson != null) {
        _storageService.setUser(userJson);
      }
    }
  }
}
