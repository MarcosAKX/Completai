// Composition root da feature admin: um Provider por Repository.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/admin_repository_impl.dart';
import '../../data/services/admin_reports_service.dart';
import '../../data/services/admin_stations_service.dart';
import '../../domain/models/admin_reports_state.dart';
import '../../domain/models/admin_stations_state.dart';
import '../../domain/repositories/admin_repository.dart';
import '../viewmodels/admin_reports_viewmodel.dart';
import '../viewmodels/admin_stations_viewmodel.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepositoryImpl(
    AdminStationsService(FirebaseFirestore.instance),
    AdminReportsService(FirebaseFirestore.instance),
  ),
);

final adminStationsViewModelProvider =
    AsyncNotifierProvider<AdminStationsViewModel, AdminStationsState>(
      () => AdminStationsViewModel(adminRepositoryProvider),
    );

final adminReportsViewModelProvider =
    AsyncNotifierProvider<AdminReportsViewModel, AdminReportsState>(
      () => AdminReportsViewModel(adminRepositoryProvider),
    );
