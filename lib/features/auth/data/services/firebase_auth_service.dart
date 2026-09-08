// Encapsula Firebase Auth e Google Sign-In, sem manter cache de perfil.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/errors/exceptions.dart';

class FirebaseAuthService {
  FirebaseAuthService(this._auth, this._google);
  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  Future<void>? _googleInitialization;

  User? get currentUser => _auth.currentUser;

  Future<User> signIn({required String email, required String password}) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return result.user!;
  }

  Future<User> createAccount({
    required String email,
    required String password,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return result.user!;
  }

  Future<User> signInWithGoogle() async {
    await (_googleInitialization ??= _google.initialize());
    if (!_google.supportsAuthenticate()) {
      throw const ValidationException(
        'Login Google disponível neste bootstrap apenas nas plataformas nativas compatíveis.',
      );
    }
    final account = await _google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) throw const UnauthenticatedException();
    final result = await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
    return result.user!;
  }

  Future<bool> isAdmin({bool forceRefresh = false}) async {
    final token = await _auth.currentUser?.getIdTokenResult(forceRefresh);
    return token?.claims?['admin'] == true;
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Apaga a conta logada. Usado para não deixar credencial órfã quando a
  /// gravação do perfil falha logo após a criação da conta.
  Future<void> deleteCurrentAccount() async {
    await _auth.currentUser?.delete();
  }

  Future<void> signOut() async {
    // Encerra Firebase mesmo se o provedor Google apresentar falha.
    try {
      if (_googleInitialization != null) {
        await _googleInitialization;
        await _google.signOut();
      }
    } finally {
      await _auth.signOut();
    }
  }
}
