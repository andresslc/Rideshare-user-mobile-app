/// Base class for all failures in the app.
/// Use [Either<Failure, T>] to return results from repositories/usecases.
abstract class Failure {
  final String message;
  final dynamic error;

  const Failure({required this.message, this.error});

  @override
  String toString() => '$runtimeType: $message';
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({required super.message, super.error, this.statusCode});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.error});
}

class TokenFailure extends Failure {
  const TokenFailure({required super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}
