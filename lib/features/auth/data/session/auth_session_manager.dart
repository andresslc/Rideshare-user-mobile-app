import 'package:ride_app/core/observability/observability_service.dart';
import 'package:ride_app/core/services/api_service.dart';
import 'package:ride_app/core/services/storage_service.dart';
import 'package:ride_app/features/auth/domain/entities/auth_entity.dart';
import 'package:ride_app/features/user_profile/domain/entites/user_entity.dart';

class AuthSessionManager {
  final StorageService storageService;
  final ApiService apiService;
  final ObservabilityService observabilityService;

  const AuthSessionManager({
    required this.storageService,
    required this.apiService,
    required this.observabilityService,
  });

  Future<void> persistAuthResponse(AuthResponseEntity response) async {
    final token = response.token;
    if (token == null || token.isEmpty) {
      return;
    }
    apiService.setAuthToken(token);
    await storageService.setToken(token);
    if (response.user != null) {
      await observabilityService.setUserId(response.user!.id);
      await storageService.setUID(response.user!.id);
      await storageService.setUser(_userToJson(response.user!));
    }
  }

  Future<void> persistProfile(UserEntity user) async {
    await observabilityService.setUserId(user.id);
    await storageService.setUID(user.id);
    await storageService.setUser(_userToJson(user));
  }

  Future<void> clear() async {
    await storageService.clearAuthSession();
    apiService.clearAuthToken();
    await observabilityService.clearUser();
  }

  Map<String, dynamic> _userToJson(UserEntity user) {
    return {
      '_id': user.id,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'email': user.email,
      'profilePicture': user.profilePicture,
      'phone': user.phone,
      'stripeCustomerId': user.stripeCustomerId,
      'balance': user.balance,
      'locale': user.locale,
      'isNotificationEnabled': user.isNotificationEnabled,
      'rating': user.rating,
      'reviewsGiven': user.reviewsGiven,
      'reviewsReceived': user.reviewsReceived,
      'completedRides': user.completedRides,
      'cancelledRides': user.cancelledRides,
      'createdAt': user.createdAt.toIso8601String(),
      'updatedAt': user.updatedAt.toIso8601String(),
      '__v': user.v,
      if (user.dob != null) 'dob': user.dob!.toUtc().millisecondsSinceEpoch,
    };
  }
}
