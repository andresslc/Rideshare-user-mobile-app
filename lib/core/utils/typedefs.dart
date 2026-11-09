import 'package:fpdart/fpdart.dart';

import '../errors/failure.dart';

/// Shorthand for async Either operations used across app layers.
typedef FutureEither<T> = Future<Either<Failure, T>>;
typedef FutureVoid = FutureEither<void>;
