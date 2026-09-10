// Composition root; providers descartáveis não retêm histórico entre contas.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod/riverpod.dart';
import '../../data/repositories/my_reviews_repository_impl.dart';
import '../../data/services/my_reviews_service.dart';
import '../../domain/repositories/my_reviews_repository.dart';
import '../../domain/models/my_reviews_state.dart';
import '../viewmodels/my_reviews_viewmodel.dart';
import '../../../station_details/data/services/station_details_service.dart';

final myReviewsRepositoryProvider = Provider.autoDispose<MyReviewsRepository>(
  (ref) => MyReviewsRepositoryImpl(
    MyReviewsService(
      FirebaseFirestore.instance,
      StationDetailsService(FirebaseFirestore.instance),
    ),
  ),
);
final myReviewsViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<MyReviewsViewModel, MyReviewsState, String>(
      () => MyReviewsViewModel(myReviewsRepositoryProvider),
    );
