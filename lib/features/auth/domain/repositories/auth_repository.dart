// Contrato de autenticação e conclusão de perfil, independente de SDKs.
import '../models/auth_session.dart';
import '../models/station_registration.dart';

abstract interface class AuthRepository {
  Future<AuthSession?> restoreSession({bool forceRefresh = false});
  Future<AuthSession> signIn({required String email, required String password});
  Future<AuthSession> signInWithGoogle();
  Future<AuthSession> createAccount({
    required String email,
    required String password,
  });
  Future<AuthSession> completeClientRegistration({
    required String name,
    required String phone,
  });
  Future<AuthSession> completeStationRegistration(
    StationRegistration registration,
  );
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
}
