import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/auth_params.dart';
import 'package:ride_app/features/auth/domain/repositories/auth_repositories.dart';
import 'package:ride_app/features/auth/domain/use_cases/send_otp_usecase.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthRepository repository;
  late SendOtpUseCase useCase;

  setUp(() {
    repository = _MockAuthRepository();
    useCase = SendOtpUseCase(repository);
  });

  test('returns success message from repository', () async {
    final params = SendOtpParams(phone: '1234567890', countryCode: '1');
    when(
      () => repository.login(params: params),
    ).thenAnswer((_) async => const Right('OTP sent'));

    final result = await useCase.call(params);

    expect(result.isRight(), isTrue);
  });

  test('returns failure from repository', () async {
    final params = SendOtpParams(phone: '1234567890', countryCode: '1');
    when(() => repository.login(params: params)).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'network error')),
    );

    final result = await useCase.call(params);

    expect(result.isLeft(), isTrue);
  });
}
