sealed class Failure {
  const Failure(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType($message)';
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.cause});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause});
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.cause, this.statusCode});
  final int? statusCode;
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.cause});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fieldErrors = const {}});
  final Map<String, String> fieldErrors;
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.cause});
}

Failure failureFromException(Object error, [StackTrace? stack]) {
  if (error is Failure) return error;
  return UnknownFailure(error.toString(), cause: error);
}
