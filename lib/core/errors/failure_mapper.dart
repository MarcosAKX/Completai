// Tradução comum de erros de infraestrutura (Firestore, timeout, exceções da
// camada de dados) para `Failure` tipada. Cada Repository embrulha suas
// chamadas com isto — nunca deixa vazar erro cru nem engole com `catch (_)`.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'exceptions.dart';
import 'failures.dart';

/// Prazo máximo de uma operação de rede antes de virar [NetworkFailure] —
/// evita spinner infinito quando o Firestore não responde.
const Duration kInfraTimeout = Duration(seconds: 20);

Failure mapInfraFailure(Object error) {
  if (error is Failure) return error;
  if (error is TimeoutException) {
    return NetworkFailure(
      'A conexão demorou demais. Tente novamente.',
      cause: error,
    );
  }
  if (error is RoleConflictException) {
    return RoleConflictFailure(error.message, cause: error);
  }
  if (error is ValidationException) {
    return ValidationFailure(error.message, cause: error);
  }
  if (error is UnauthenticatedException) {
    return AuthFailure(error.message, cause: error);
  }
  if (error is AppException) {
    return UnexpectedFailure(error.message, cause: error);
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'network-request-failed' || 'unavailable' || 'deadline-exceeded' =>
        NetworkFailure('Confira sua conexão e tente novamente.', cause: error),
      'permission-denied' => PermissionFailure(
        'Esta operação não foi autorizada.',
        cause: error,
      ),
      'not-found' => ValidationFailure(
        'Registro não encontrado.',
        cause: error,
      ),
      _ => UnexpectedFailure(
        'Não foi possível concluir a operação. Tente novamente.',
        cause: error,
      ),
    };
  }
  return UnexpectedFailure(
    'Ocorreu um erro inesperado. Tente novamente.',
    cause: error,
  );
}

/// Executa [operation] com timeout e converte qualquer erro via
/// [mapInfraFailure], preservando a stack para o chamador.
Future<T> guardInfra<T>(Future<T> Function() operation) async {
  try {
    return await operation().timeout(kInfraTimeout);
  } catch (error, stack) {
    Error.throwWithStackTrace(mapInfraFailure(error), stack);
  }
}
