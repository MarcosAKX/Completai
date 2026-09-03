// Traduz erros externos para falhas estáveis, preservando causa e stack no chamador.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';

Failure mapAuthFailure(Object error) {
  if (error is Failure) return error;
  if (error is RoleConflictException) {
    return RoleConflictFailure(error.message, cause: error);
  }
  if (error is ValidationException) {
    return ValidationFailure(error.message, cause: error);
  }
  if (error is UnauthenticatedException) {
    return AuthFailure(error.message, cause: error);
  }
  if (error is InvalidProfileException) {
    return UnexpectedFailure(error.message, cause: error);
  }
  if (error is GoogleSignInException) {
    if (error.code == GoogleSignInExceptionCode.canceled) {
      return CancelledFailure('Login Google cancelado.', cause: error);
    }
    return AuthFailure(
      'Não foi possível entrar com Google. Tente novamente.',
      cause: error,
    );
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'network-request-failed' || 'unavailable' || 'deadline-exceeded' =>
        NetworkFailure('Confira sua conexão e tente novamente.', cause: error),
      'permission-denied' => PermissionFailure(
        'Esta operação não foi autorizada.',
        cause: error,
      ),
      'email-already-in-use' => AuthFailure(
        'Este e-mail já possui conta. Entre para continuar.',
        cause: error,
      ),
      'invalid-email' => ValidationFailure(
        'Informe um e-mail válido.',
        cause: error,
      ),
      'weak-password' => ValidationFailure(
        'Escolha uma senha mais forte.',
        cause: error,
      ),
      'invalid-credential' || 'wrong-password' || 'user-not-found' =>
        AuthFailure('E-mail ou senha inválidos.', cause: error),
      'too-many-requests' => AuthFailure(
        'Muitas tentativas. Aguarde e tente novamente.',
        cause: error,
      ),
      _ => AuthFailure(
        'Não foi possível concluir a operação. Tente novamente.',
        cause: error,
      ),
    };
  }
  if (error is PlatformException && error.code == 'IO_ERROR') {
    return ValidationFailure(
      'Não foi possível localizar o endereço. Confira os dados e sua conexão.',
      cause: error,
    );
  }
  return UnexpectedFailure(
    'Ocorreu um erro inesperado. Tente novamente.',
    cause: error,
  );
}
