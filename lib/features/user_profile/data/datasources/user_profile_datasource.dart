import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/constants/api_endpoints.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/params/auth_params.dart';
import 'package:ride_app/core/services/api_service.dart';
import 'package:ride_app/core/services/storage_service.dart';
import 'package:ride_app/features/user_profile/data/models/user_profile_model.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/network_error_handler.dart';

abstract class UserProfileDatasource {
  Future<Either<Failure, UserProfileModel>> getProfile();
  Future<Either<Failure, UserProfileModel>> updateProfile(
    UpdateProfileParams params,
  );
}

class UserProfileDatasourceImpl implements UserProfileDatasource {
  final ApiService apiService = locator<ApiService>();
  final StorageService _storageService = locator<StorageService>();

  @override
  Future<Either<Failure, UserProfileModel>> getProfile() {
    return handleNetworkError(() async {
      final res = await apiService.get(ApiEndpoints.profile);
      final apiRes = ApiResponse.fromMap(res.data);

      if (apiRes.success && apiRes.data['user'] != null) {
        await _storageService.setUser(apiRes.data['user']);
      }
      return UserProfileModel.fromJson(res.data);
    });
  }

  @override
  Future<Either<Failure, UserProfileModel>> updateProfile(
    UpdateProfileParams params,
  ) async {
    return handleNetworkError(() async {
      final formData = params.toFormData();
      final res = await apiService.patch(
        ApiEndpoints.updateProfile,
        data: formData,
      );
      final apiRes = ApiResponse.fromMap(res.data);

      if (apiRes.success && apiRes.data['user'] != null) {
        await _storageService.setUser(apiRes.data['user']);
      }
      return UserProfileModel.fromJson(res.data);
    });
  }
}

