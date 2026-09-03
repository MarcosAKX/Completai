// Composition root da feature: um Provider por Repository e dependências substituíveis.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod/riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/address_geocoding_service.dart';
import '../../data/services/auth_profile_service.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../viewmodels/auth_viewmodel.dart';

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>(
  (ref) => FirebaseAuthService(FirebaseAuth.instance, GoogleSignIn.instance),
);
final addressGeocodingServiceProvider = Provider<AddressGeocodingService>(
  (ref) => AddressGeocodingService(),
);
final authProfileServiceProvider = Provider<AuthProfileService>(
  (ref) => AuthProfileService(
    FirebaseFirestore.instance,
    ref.watch(addressGeocodingServiceProvider),
  ),
);
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(firebaseAuthServiceProvider),
    ref.watch(authProfileServiceProvider),
  ),
);
final authViewModelProvider =
    AsyncNotifierProvider<AuthViewModel, AuthSession?>(
      () => AuthViewModel(authRepositoryProvider),
    );
