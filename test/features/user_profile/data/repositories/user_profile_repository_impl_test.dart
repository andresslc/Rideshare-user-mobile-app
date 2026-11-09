import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/auth_params.dart';
import 'package:ride_app/features/auth/data/session/auth_session_manager.dart';
import 'package:ride_app/features/user_profile/data/datasources/user_profile_datasource.dart';
import 'package:ride_app/features/user_profile/data/models/user_model.dart';
import 'package:ride_app/features/user_profile/data/models/user_profile_model.dart';
import 'package:ride_app/features/user_profile/data/repositories/user_profile_repository_impl.dart';
import 'package:ride_app/features/user_profile/domain/entites/user_entity.dart';

class _MockDatasource extends Mock implements UserProfileDatasource {}

class _MockSessionManager extends Mock implements AuthSessionManager {}

void main() {
  late UserProfileDatasource datasource;
  late AuthSessionManager sessionManager;
  late UserProfileRepositoryImpl repository;

  final model = UserProfileModel(
    user: UserModel(
      id: '1',
      firstName: 'Jane',
      lastName: 'Rider',
      email: 'jane@example.com',
      phone: '+15551234567',
      address: '',
      balance: 0,
      locale: 'en',
      isNotificationEnabled: true,
      rating: 5,
      reviewsGiven: 0,
      reviewsReceived: 0,
      completedRides: 1,
      cancelledRides: 0,
      createdAt: DateTime.parse('2024-01-01'),
      updatedAt: DateTime.parse('2024-01-02'),
      v: 0,
    ),
  );

  setUpAll(() {
    registerFallbackValue(
      UserEntity(
        id: '',
        firstName: '',
        lastName: '',
        email: '',
        phone: '',
        balance: 0,
        locale: 'en',
        isNotificationEnabled: false,
        rating: 0,
        reviewsGiven: 0,
        reviewsReceived: 0,
        completedRides: 0,
        cancelledRides: 0,
        createdAt: DateTime.parse('2024-01-01'),
        updatedAt: DateTime.parse('2024-01-01'),
        v: 0,
      ),
    );
  });

  setUp(() {
    datasource = _MockDatasource();
    sessionManager = _MockSessionManager();
    repository = UserProfileRepositoryImpl(datasource, sessionManager);
  });

  test('maps model to entity and persists user on getProfile', () async {
    when(() => datasource.getProfile()).thenAnswer((_) async => Right(model));
    when(
      () => sessionManager.persistProfile(any()),
    ).thenAnswer((_) async {});

    final result = await repository.getProfile();

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('expected success'), (entity) {
      expect(entity.user.firstName, 'Jane');
      expect(entity.user.fullName, 'Jane Rider');
    });
    verify(() => sessionManager.persistProfile(any())).called(1);
  });

  test('maps model to entity and persists user on updateProfile', () async {
    final params = UpdateProfileParams(
      firstName: 'Jane',
      lastName: 'Updated',
      email: 'jane@example.com',
    );
    when(
      () => datasource.updateProfile(params),
    ).thenAnswer((_) async => Right(model));
    when(
      () => sessionManager.persistProfile(any()),
    ).thenAnswer((_) async {});

    final result = await repository.updateProfile(params: params);

    expect(result.isRight(), isTrue);
    verify(() => sessionManager.persistProfile(any())).called(1);
  });

  test('returns failure when datasource fails', () async {
    when(() => datasource.getProfile()).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'network error')),
    );

    final result = await repository.getProfile();

    expect(result.isLeft(), isTrue);
    verifyNever(() => sessionManager.persistProfile(any()));
  });
}
