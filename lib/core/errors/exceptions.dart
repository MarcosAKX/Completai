// Exceções da camada de dados; o Repository traduz para Failure.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

class RoleConflictException extends AppException {
  const RoleConflictException() : super('Esta conta já possui outro papel.');
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class UnauthenticatedException extends AppException {
  const UnauthenticatedException() : super('Entre na conta para continuar.');
}

class InvalidProfileException extends AppException {
  const InvalidProfileException()
    : super('Perfil inconsistente. Entre em contato com o suporte.');
}

class LocationPermissionException extends AppException {
  const LocationPermissionException()
    : super('Permita o acesso à localização ou escolha uma cidade.');
}

class LocationUnavailableException extends AppException {
  const LocationUnavailableException()
    : super('Não foi possível obter sua localização atual.');
}
