// Orquestra serviços e mantém o único cache de perfil, restrito ao UID da sessão.
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/station_registration.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/auth_profile_service.dart';
import '../services/firebase_auth_service.dart';
import 'auth_failure_mapper.dart';

// Implementação real do AuthRepository (interface definida em domain/).
// É a única classe que fala diretamente com FirebaseAuthService e
// AuthProfileService — ViewModel nunca acessa esses serviços direto.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._auth, this._profiles);
  final FirebaseAuthService _auth;
  final AuthProfileService _profiles;

  // Cache em memória da sessão atual, evita reler o Firestore toda hora.
  AuthSession? _cachedSession;

  // Executa uma operação e traduz qualquer erro em uma Failure tipada
  // (via mapAuthFailure), além de invalidar o cache em caso de falha.
  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error, stack) {
      _cachedSession = null;
      Error.throwWithStackTrace(mapAuthFailure(error), stack);
    }
  }

  // Monta (ou reaproveita do cache) a sessão completa de um usuário:
  // papel (cliente/posto) + se é admin.
  Future<AuthSession> _session(User user, {bool forceRefresh = false}) async {
    // Se já tem sessão em cache do mesmo uid e não foi pedido refresh
    // forçado, devolve o cache sem consultar nada.
    final cached = _cachedSession;
    if (!forceRefresh && cached?.uid == user.uid) return cached!;
    _cachedSession = null;

    // readRole (Firestore) e isAdmin (token de Auth) não dependem uma da
    // outra, então rodam em paralelo em vez de uma esperar a outra —
    // reduz o tempo total de carregamento da sessão.
    final results = await Future.wait([
      _profiles.readRole(user.uid),
      _auth.isAdmin(forceRefresh: forceRefresh),
    ]);
    final role = results[0] as AccountRole?;
    final admin = results[1] as bool;

    // Proteção contra condição de corrida: se o usuário deslogou durante
    // as consultas acima, não monta sessão para um uid que não é mais o
    // atual.
    if (_auth.currentUser?.uid != user.uid) {
      throw const UnauthenticatedException();
    }

    return _cachedSession = AuthSession(
      uid: user.uid,
      email: user.email ?? '',
      role: role,
      isAdmin: admin,
    );
  }

  // Chamado ao abrir o app: verifica se já existe um usuário logado e,
  // se sim, monta a sessão dele. Usado pela splash/AuthGate.
  @override
  Future<AuthSession?> restoreSession({bool forceRefresh = false}) =>
      _guard(() async {
        final user = _auth.currentUser;
        if (user == null) {
          _cachedSession = null;
          return null;
        }
        return _session(user, forceRefresh: forceRefresh);
      });

  // Login com e-mail e senha.
  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) => _guard(() async {
    _cachedSession = null;
    return _session(await _auth.signIn(email: email, password: password));
  });

  // Login com conta Google.
  @override
  Future<AuthSession> signInWithGoogle() => _guard(() async {
    _cachedSession = null;
    return _session(await _auth.signInWithGoogle());
  });

  // Cria uma conta nova no Firebase Auth (ainda sem perfil/papel definido).
  @override
  Future<AuthSession> createAccount({
    required String email,
    required String password,
  }) => _guard(() async {
    _cachedSession = null;
    final existing = _auth.currentUser;
    // Se já existe uma conta logada com o MESMO e-mail, reaproveita (cobre
    // o caso de o cadastro de perfil ter falhado antes e o usuário tentar
    // de novo, sem precisar recriar a conta Auth).
    if (existing != null &&
        existing.email?.trim().toLowerCase() == email.trim().toLowerCase()) {
      return _session(existing, forceRefresh: true);
    }
    // Se está logado com OUTRO e-mail, não deixa criar conta nova sem
    // sair antes.
    if (existing != null) {
      throw const ValidationException(
        'Saia da conta atual antes de cadastrar outro e-mail.',
      );
    }
    return _session(
      await _auth.createAccount(email: email, password: password),
    );
  });

  // Retorna o usuário atual ou lança erro se ninguém estiver logado.
  User _requireUser() =>
      _auth.currentUser ?? (throw const UnauthenticatedException());

  // Segunda etapa do cadastro: grava o perfil de cliente no Firestore
  // (a conta Auth já existe, criada por createAccount).
  @override
  Future<AuthSession> completeClientRegistration({
    required String name,
    required String phone,
  }) => _guard(() async {
    final user = _requireUser();
    await _profiles.createClient(
      uid: user.uid,
      email: user.email ?? '',
      name: name,
      phone: phone,
    );
    return _session(user, forceRefresh: true);
  });

  // Segunda etapa do cadastro: grava o perfil de posto (privado + público)
  // no Firestore.
  @override
  Future<AuthSession> completeStationRegistration(
    StationRegistration registration,
  ) => _guard(() async {
    final user = _requireUser();
    await _profiles.createStation(
      uid: user.uid,
      email: user.email ?? '',
      registration: registration,
    );
    return _session(user, forceRefresh: true);
  });

  // Envia e-mail de recuperação de senha.
  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email));

  // Encerra a sessão e limpa o cache local.
  @override
  Future<void> signOut() => _guard(() async {
    _cachedSession = null;
    await _auth.signOut();
  });
}