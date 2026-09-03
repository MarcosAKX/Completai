// Falhas tipadas expostas pelo Repository para AsyncValue e futuras views.
sealed class Failure implements Exception {
  const Failure(this.message, {this.cause});
  final String message;
  final Object? cause;
  @override
  String toString() => message;
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.cause});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause});
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.cause});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.cause});
}

class RoleConflictFailure extends Failure {
  const RoleConflictFailure(super.message, {super.cause});
}

class CancelledFailure extends Failure {
  const CancelledFailure(super.message, {super.cause});
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.cause});
}
