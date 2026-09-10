// Composition root do perfil: dependências substituíveis para testes.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod/riverpod.dart';
import '../../data/repositories/client_profile_repository_impl.dart';
import '../../data/services/client_profile_service.dart';
import '../../domain/models/client_profile.dart';
import '../../domain/repositories/client_profile_repository.dart';
import '../viewmodels/client_profile_viewmodel.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final clientProfileRepositoryProvider = Provider<ClientProfileRepository>(
  (ref) => ClientProfileRepositoryImpl(
    ClientProfileService(FirebaseFirestore.instance),
  ),
);
final clientProfileViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<ClientProfileViewModel, ClientProfile, String>(
      () => ClientProfileViewModel(
        clientProfileRepositoryProvider,
        authRepositoryProvider,
        sessionViewModelProvider.notifier,
      ),
    );
