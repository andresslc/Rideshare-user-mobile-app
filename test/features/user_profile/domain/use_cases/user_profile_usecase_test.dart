import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/user_profile/domain/entites/user_entity.dart';
import 'package:ride_app/features/user_profile/domain/entites/user_profile_entity.dart';
import 'package:ride_app/features/user_profile/domain/repositories/user_repositories.dart';
import 'package:ride_app/features/user_profile/domain/usecase/user_profile_usecase.dart';

class _MockUserProfileRepository extends Mock implements UserProfileRepository {}

void main() {
  late UserProfileRepository repository;
  late UserProfileUseCase useCase;

  final profile = UserProfileEntity(
    user: UserEntity(
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

  setUp(() {
    repository = _MockUserProfileRepository();
    useCase = UserProfileUseCase(repository);
  });

  test('returns profile from repository', () async {
    when(() => repository.getProfile()).thenAnswer((_) async => Right(profile));

    final result = await useCase.call();

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('expected success'), (value) {
      expect(value.user.firstName, 'Jane');
    });
  });

  test('returns failure from repository', () async {
    when(() => repository.getProfile()).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'network error')),
    );

    final result = await useCase.call();

    expect(result.isLeft(), isTrue);
  });
}
