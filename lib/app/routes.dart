// Reserva a navegação; telas e rotas de autenticação virão na próxima etapa.
import 'package:completai/app/auth_gate.dart';
import 'package:flutter/material.dart';
import '../features/auth/domain/models/station_registration.dart';
import '../features/auth/presentation/views/client_registration_page.dart';
import '../features/auth/presentation/views/forgot_password_page.dart';
import '../features/auth/presentation/views/role_selection_page.dart';
import '../features/auth/presentation/views/station_registration_step1_page.dart';
import '../features/auth/presentation/views/station_registration_step2_page.dart';

abstract final class AppRoutes {
  static const login = '/';
  static const forgotPassword = '/forgot-password';
  static const roleSelection = '/register';
  static const clientRegistration = '/register/client';
  static const stationRegistrationStep1 = '/register/station/step-1';
  static const stationRegistrationStep2 = '/register/station/step-2';
  static const stationDetails = '/station-details';
  static final routes = <String, WidgetBuilder>{
    login: (_) => const AuthGate(),
    forgotPassword: (_) => const ForgotPasswordPage(),
    roleSelection: (_) => const RoleSelectionPage(),
    clientRegistration: (_) => const ClientRegistrationPage(),
    stationRegistrationStep1: (_) => const StationRegistrationStep1Page(),
  };
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == stationRegistrationStep2 &&
        settings.arguments is StationRegistrationDraft) {
      return MaterialPageRoute<void>(
        builder: (_) => StationRegistrationStep2Page(
          draft: settings.arguments! as StationRegistrationDraft,
        ),
        settings: settings,
      );
    }
    return null;
  }
}
