import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';

import 'dio_exception_handler.dart';
import 'failure.dart';

Future<Either<Failure, T>> handleNetworkError<T>(
  Future<T> Function() apiCall,
) async {
  try {
    final response = await apiCall();
    return Right(response);
  } catch (e) {
    // log(
    //     name: 'api error data handling error',
    //     '${e.toString()}, StackTrace: $stackTrace',
    //     category: LogCategory.apiError);
    if (e is DioException) {
      final customError = CustomDioException.fromDioError(e);
      return Left(NetworkFailure(message: customError.customMessage));
    } else if (e is FirebaseException) {
      return Left(NetworkFailure(message: e.message.toString()));
    } else {
      return Left(NetworkFailure(message: e.toString()));
    }
  }
}

