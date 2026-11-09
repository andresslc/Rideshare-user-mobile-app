import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/auth_params.dart';
import 'package:ride_app/features/auth/domain/entities/auth_entity.dart';
import 'package:ride_app/features/auth/domain/repositories/auth_repositories.dart';
import 'package:ride_app/features/auth/domain/use_cases/verify_otp_usecase.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthRepository repository;
  late VerifyOtpUseCase useCase;

  setUp(() {
    repository = _MockAuthRepository();
    useCase = VerifyOtpUseCase(repository);
  });

  test('returns auth response from repository', () async {
    final params = VerifyOtpParams(
      phone: '1234567890',
      otp: '123456',
      countryCode: '1',
    );
    final response = AuthResponseEntity(isOnboarded: false, token: 'abc');
    when(
      () => repository.verifyOtp(params: params),
    ).thenAnswer((_) async => Right(response));

    final result = await useCase.call(params);

    expect(result.isRight(), isTrue);
  });

  test('returns failure from repository', () async {
    final params = VerifyOtpParams(
      phone: '1234567890',
      otp: '123456',
      countryCode: '1',
    );
    when(() => repository.verifyOtp(params: params)).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'invalid otp')),
    );

    final result = await useCase.call(params);

    expect(result.isLeft(), isTrue);
  });
}
