# Bootstrap CompletAI — entrega

Documento de entrega da fundação Flutter/MVVM. Os arquivos abaixo foram aplicados no projeto.

## Resultado

Dependências solicitadas instaladas, com firebase_core e riverpod adicionados explicitamente.
Riverpod puro mantém a ViewModel sem dependência de Flutter. A versão 2.6.1 foi a
compatível selecionada pelo resolvedor deste SDK; o lockfile registra as versões.
FirebaseOptions e a configuração FlutterFire foram preservados. firebase.json aponta
para firestore.rules; nenhuma regra foi publicada e o arquivo fornecido foi mantido.

Tema Material 3, paleta verde e Roboto são sugestões ajustáveis. A escala obrigatória
é xs=4, sm=8, md=16, lg=24, xl=32 e xxl=48. google_fonts está disponível como solicitado;
o tema usa Roboto nativa no Android para não depender de download de fontes.

AppButton e AppTextField usam os tokens. A raiz do app fica visualmente vazia de propósito.
Não há tela de login/cadastro, painel admin, Cloud Functions ou serviço dependente de Blaze.

## Contrato para as próximas telas

Consuma authViewModelProvider e renderize AsyncValue.when(data, loading, error).
Todas as operações assíncronas passam por AsyncValue.guard. Durante uma operação,
novos comandos são ignorados para evitar submissões concorrentes: desabilite controles.

- signIn(email, password): entra com e-mail/senha.
- signInWithGoogle(): entra com Google nas plataformas nativas compatíveis.
- createAccount(email, password): cria a conta Auth; não presume papel.
- completeClientRegistration(name): cria users/{uid}.
- completeStationRegistration(StationRegistration): geocodifica e grava o batch privado/público.
- sendPasswordResetEmail(email): envia recuperação de senha.
- refreshSession(): atualiza perfil e token/claim admin.
- signOut(): encerra sessão e limpa o cache.

AuthSession nula significa deslogado. needsProfile=true significa conta autenticada
com cadastro pendente. isAdmin vem exclusivamente do token Auth; não é papel Firestore.
Conta e perfil são etapas separadas: se a gravação do perfil falhar, o usuário pode
entrar novamente e completar o cadastro sem tentar criar uma segunda conta.

O cache vive no Repository e é isolado por UID. Login, logout, erros e atualização
explícita invalidam o cache; cadastro reconsulta o servidor, nunca usa cache para
validar papel. Não há listeners Firestore. Mudanças externas de perfil/claims exigem
refreshSession ou novo login. As futuras telas não devem chamar SDKs diretamente.

O cadastro de posto inicia os cinco preços e sete dias de horário como null, arrays
vazios e avaliações zeradas. São valores iniciais sugeridos que respeitam o schema.
CNPJ, endereço e nome são obrigatórios; validação fiscal completa não faz parte desta base.
Não foi exposta exclusão de conta: deve ser implementada junto da limpeza recursiva
exigida pelo schema e da revisão das permissões, antes de ser oferecida ao usuário.

## Pendências verificadas nos arquivos fornecidos

1. noConflictingRole usa OR com exists do estado anterior: quando só um papel existe,
   a criação do segundo ainda satisfaz a expressão. A checagem client melhora UX,
   mas não garante exclusividade contra cliente adulterado ou cadastros concorrentes.
   A correção das rules deve considerar também o estado final de batches.
2. station_reports/{stationUid}/{reporterUid} tem três segmentos; não é caminho de
   documento Firestore. Escolher um caminho válido exige alinhar schema e rules.
3. Reviews requerem atualizar agregados na mesma transação, mas as rules de
   public_stations só permitem escrita ao dono do posto. O fluxo de review por cliente
   precisa de regras específicas antes da implementação; não foi criado aqui.
4. O google-services.json existente possui oauth_client vazio. Habilitar Google no
   Firebase Authentication, cadastrar SHA do aplicativo Android e obter o JSON atualizado
   com OAuth (ou configurar serverClientId adequado) é necessário para login real.
   Habilitar também e-mail/senha no Console. Não foram alteradas contas/configurações remotas.
5. Apenas Android está configurado em firebase_options.dart. Outras plataformas
   continuam exigindo flutterfire configure específico.

Referências oficiais consultadas: [Google Sign-In](https://pub.dev/packages/google_sign_in),
[condições nas rules](https://firebase.google.com/docs/firestore/security/rules-conditions).

## Validação

- flutter analyze: sem problemas.
- flutter test: 16 testes passaram (ViewModel, cache, perfis e componentes).
- dart format lib test: concluído.
- flutter build apk --debug: concluído; APK em build/app/outputs/flutter-apk/app-debug.apk.
- Build exibiu avisos de compatibilidade futura Kotlin/Java nos plugins, sem falha.
- firestore.rules preservado: SHA256 ADDA5BC63AAAEFD3FAD4628AA6005DED3C928BA0B9FDF4D22D6F78DD95F7BBCA.
- Testes de perfil usam Firestore em memória; não validam regras de segurança reais.
- Login real, geocodificação no aparelho e regras no Emulator ainda precisam de teste integrado.

## Próximos passos

Corrigir e testar as inconsistências de rules/schema; concluir OAuth Android; gerar
as telas de login/cadastro usando a ViewModel; depois implementar as demais features.
A estrutura admin está reservada, sem implementar painel ou scripts do ADMIN.md.

## Árvore final dos arquivos da aplicação

```text
Listagem de caminhos de pasta
O n�mero de s�rie do volume � 000000F1 FC1A:9719
C:\USERS\MARCOS\DOWNLOADS\PROJETO\COMPLETAI\LIB
|   firebase_options.dart
|   main.dart
|   
+---app
|       app.dart
|       routes.dart
|       
+---core
|   +---constants
|   |       firestore_collections.dart
|   |       
|   +---errors
|   |       exceptions.dart
|   |       failures.dart
|   |       
|   +---theme
|   |       app_colors.dart
|   |       app_spacing.dart
|   |       app_text_styles.dart
|   |       app_theme.dart
|   |       
|   +---utils
|   |       .gitkeep
|   |       
|   \---widgets
|           app_button.dart
|           app_text_field.dart
|           
+---features
|   +---admin
|   |   +---data
|   |   |   +---repositories
|   |   |   |       .gitkeep
|   |   |   |       
|   |   |   \---services
|   |   |           .gitkeep
|   |   |           
|   |   +---domain
|   |   |   +---models
|   |   |   |       .gitkeep
|   |   |   |       
|   |   |   \---repositories
|   |   |           .gitkeep
|   |   |           
|   |   \---presentation
|   |       +---providers
|   |       |       .gitkeep
|   |       |       
|   |       +---viewmodels
|   |       |       .gitkeep
|   |       |       
|   |       +---views
|   |       |       .gitkeep
|   |       |       
|   |       \---widgets
|   |               .gitkeep
|   |               
|   \---auth
|       +---data
|       |   +---repositories
|       |   |       auth_failure_mapper.dart
|       |   |       auth_repository_impl.dart
|       |   |       
|       |   \---services
|       |           address_geocoding_service.dart
|       |           auth_profile_service.dart
|       |           firebase_auth_service.dart
|       |           
|       +---domain
|       |   +---models
|       |   |       auth_session.dart
|       |   |       station_registration.dart
|       |   |       
|       |   \---repositories
|       |           auth_repository.dart
|       |           
|       \---presentation
|           +---providers
|           |       auth_providers.dart
|           |       
|           +---viewmodels
|           |       auth_viewmodel.dart
|           |       
|           +---views
|           |       .gitkeep
|           |       
|           \---widgets
|                   .gitkeep
|                   
\---shared
    \---models
            .gitkeep
            
```

## Conteúdo completo dos arquivos


### lib/app/app.dart

```dart
// Raiz visual mínima sem telas de produto, pronta para receber navegação.
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'routes.dart';

class CompletAiApp extends StatelessWidget {
  const CompletAiApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CompletAI',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    routes: AppRoutes.routes,
    home: const SizedBox.shrink(),
  );
}

```

### lib/app/routes.dart

```dart
// Reserva a navegação; telas e rotas de autenticação virão na próxima etapa.
import 'package:flutter/widgets.dart';

abstract final class AppRoutes {
  static const Map<String, WidgetBuilder> routes = {};
}

```

### lib/core/constants/firestore_collections.dart

```dart
// Nomes de coleção definidos no SCHEMA-FIRESTORE.md.
abstract final class FirestoreCollections {
  static const users = 'users';
  static const gasStations = 'gas_stations';
  static const publicStations = 'public_stations';
  static const mvpCity = 'Bebedouro';
}

```

### lib/core/errors/exceptions.dart

```dart
// Exceções da camada de dados; o Repository traduz para Failure.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

class RoleConflictException extends AppException {
  const RoleConflictException() : super('Esta conta já possui outro papel.');
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class UnauthenticatedException extends AppException {
  const UnauthenticatedException() : super('Entre na conta para continuar.');
}

class InvalidProfileException extends AppException {
  const InvalidProfileException()
    : super('Perfil inconsistente. Entre em contato com o suporte.');
}

```

### lib/core/errors/failures.dart

```dart
// Falhas tipadas expostas pelo Repository para AsyncValue e futuras views.
sealed class Failure implements Exception {
  const Failure(this.message, {this.cause});
  final String message;
  final Object? cause;
  @override
  String toString() => message;
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.cause});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause});
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.cause});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.cause});
}

class RoleConflictFailure extends Failure {
  const RoleConflictFailure(super.message, {super.cause});
}

class CancelledFailure extends Failure {
  const CancelledFailure(super.message, {super.cause});
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.cause});
}

```

### lib/core/theme/app_colors.dart

```dart
// Paleta sugerida e ajustável: verde profundo e superfícies claras.
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF176B4B);
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFF486457);
  static const surface = Color(0xFFF8FAF8);
  static const onSurface = Color(0xFF18211D);
  static const outline = Color(0xFF707B74);
  static const error = Color(0xFFBA1A1A);
}

```

### lib/core/theme/app_spacing.dart

```dart
// Escala obrigatória; dimensões auxiliares são sugestões ajustáveis.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double controlMinHeight = xxl;
  static const double controlRadius = sm;
  static const double progressSize = lg;
  static const double progressStroke = 2;
}

```

### lib/core/theme/app_text_styles.dart

```dart
// Roboto sugerida: fonte nativa Android, sem download em runtime.
import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const title = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
  static const body = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16,
    height: 1.5,
  );
  static const label = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  static const caption = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 12,
    height: 1.4,
  );
  static const textTheme = TextTheme(
    titleLarge: title,
    bodyLarge: body,
    bodyMedium: body,
    labelLarge: label,
    bodySmall: caption,
  );
}

```

### lib/core/theme/app_theme.dart

```dart
// Centraliza Material 3 e tokens; identidade visual sugerida, passível de ajuste.
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colors = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      error: AppColors.error,
      outline: AppColors.outline,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      textTheme: AppTextStyles.textTheme,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppSpacing.controlMinHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          textStyle: AppTextStyles.label,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: border,
        enabledBorder: border.copyWith(
          borderSide: BorderSide(color: colors.outline),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        errorMaxLines: 3,
        labelStyle: AppTextStyles.body,
        errorStyle: AppTextStyles.caption,
      ),
    );
  }
}

```

### lib/core/utils/.gitkeep

```text
# Reserva de estrutura arquitetural; implementação futura.

```

### lib/core/widgets/app_button.dart

```dart
// Botão base acessível, com estado ocupado e tokens do tema.
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: isLoading,
    child: FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading) ...[
            SizedBox.square(
              dimension: AppSpacing.progressSize,
              child: CircularProgressIndicator(
                strokeWidth: AppSpacing.progressStroke,
                color: Theme.of(context).colorScheme.primary,
                semanticsLabel: 'Carregando',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    ),
  );
}

```

### lib/core/widgets/app_text_field.dart

```dart
// Campo base integrado a Form, com suporte a senha, teclado e acessibilidade.
import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.focusNode,
    this.obscureText = false,
    this.enabled = true,
    this.errorText,
  });
  final String label;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final bool obscureText;
  final bool enabled;
  final String? errorText;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    focusNode: focusNode,
    validator: validator,
    onChanged: onChanged,
    onFieldSubmitted: onFieldSubmitted,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    autofillHints: autofillHints,
    obscureText: obscureText,
    enabled: enabled,
    autocorrect: !obscureText,
    enableSuggestions: !obscureText,
    style: AppTextStyles.body,
    decoration: InputDecoration(labelText: label, errorText: errorText),
  );
}

```

### lib/features/admin/data/repositories/.gitkeep

```text
# Reserva de estrutura arquitetural; implementação futura.

```

### lib/features/admin/data/services/.gitkeep

```text
# Reserva de estrutura arquitetural; implementação futura.

```

### lib/features/admin/domain/models/.gitkeep

```text
# Reserva de estrutura arquitetural; implementação futura.

```

### lib/features/admin/domain/repositories/.gitkeep

```text
# Reserva de estrutura arquitetural; implementação futura.

```

### lib/features/admin/presentation/providers/.gitkeep

```text
# Reserva de estrutura arquitetural; implementação futura.

```

### lib/features/admin/presentation/viewmodels/.gitkeep

```text
# Reserva de estrutura arquitetural; implementação futura.

```

### lib/features/admin/presentation/views/.gitkeep

```text
# Reserva de estrutura arquitetural; implementação futura.

```

### lib/features/admin/presentation/widgets/.gitkeep

```text
# Reserva de estrutura arquitetural; implementação futura.

```

### lib/features/auth/data/repositories/auth_failure_mapper.dart

```dart
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

```

### lib/features/auth/data/repositories/auth_repository_impl.dart

```dart
// Orquestra serviços e mantém o único cache de perfil, restrito ao UID da sessão.
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/station_registration.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/auth_profile_service.dart';
import '../services/firebase_auth_service.dart';
import 'auth_failure_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._auth, this._profiles);
  final FirebaseAuthService _auth;
  final AuthProfileService _profiles;
  AuthSession? _cachedSession;

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error, stack) {
      _cachedSession = null;
      Error.throwWithStackTrace(mapAuthFailure(error), stack);
    }
  }

  Future<AuthSession> _session(User user, {bool forceRefresh = false}) async {
    final cached = _cachedSession;
    if (!forceRefresh && cached?.uid == user.uid) return cached!;
    _cachedSession = null;
    final role = await _profiles.readRole(user.uid);
    final admin = await _auth.isAdmin(forceRefresh: forceRefresh);
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

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) => _guard(() async {
    _cachedSession = null;
    return _session(await _auth.signIn(email: email, password: password));
  });

  @override
  Future<AuthSession> signInWithGoogle() => _guard(() async {
    _cachedSession = null;
    return _session(await _auth.signInWithGoogle());
  });

  @override
  Future<AuthSession> createAccount({
    required String email,
    required String password,
  }) => _guard(() async {
    _cachedSession = null;
    return _session(
      await _auth.createAccount(email: email, password: password),
    );
  });

  User _requireUser() =>
      _auth.currentUser ?? (throw const UnauthenticatedException());

  @override
  Future<AuthSession> completeClientRegistration({required String name}) =>
      _guard(() async {
        final user = _requireUser();
        await _profiles.createClient(
          uid: user.uid,
          email: user.email ?? '',
          name: name,
        );
        return _session(user, forceRefresh: true);
      });

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

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email));

  @override
  Future<void> signOut() => _guard(() async {
    _cachedSession = null;
    await _auth.signOut();
  });
}

```

### lib/features/auth/data/services/address_geocoding_service.dart

```dart
// Resolve o endereço uma vez durante o cadastro, sem persistir coordenadas nulas.
import 'package:geocoding/geocoding.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/errors/exceptions.dart';

class StationCoordinates {
  const StationCoordinates(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

class AddressGeocodingService {
  Future<StationCoordinates> resolve(String address) async {
    final locations = await Geocoding().locationFromAddress(
      '$address, ${FirestoreCollections.mvpCity}, SP, Brasil',
    );
    if (locations.isEmpty) {
      throw const ValidationException(
        'Endereço não encontrado. Confira o endereço do posto.',
      );
    }
    final location = locations.first;
    if (!location.latitude.isFinite ||
        !location.longitude.isFinite ||
        location.latitude.abs() > 90 ||
        location.longitude.abs() > 180) {
      throw const ValidationException(
        'O endereço retornou coordenadas inválidas.',
      );
    }
    return StationCoordinates(location.latitude, location.longitude);
  }
}

```

### lib/features/auth/data/services/auth_profile_service.dart

```dart
// Lê e grava perfis. Cadastro sempre consulta o servidor para validar exclusividade.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/station_registration.dart';
import 'address_geocoding_service.dart';

class AuthProfileService {
  AuthProfileService(this._firestore, this._geocoding);
  final FirebaseFirestore _firestore;
  final AddressGeocodingService _geocoding;

  DocumentReference<Map<String, dynamic>> _client(String uid) =>
      _firestore.collection(FirestoreCollections.users).doc(uid);
  DocumentReference<Map<String, dynamic>> _station(String uid) =>
      _firestore.collection(FirestoreCollections.gasStations).doc(uid);

  Future<AccountRole?> readRole(String uid) async {
    final documents = await Future.wait([
      _client(uid).get(const GetOptions(source: Source.server)),
      _station(uid).get(const GetOptions(source: Source.server)),
    ]);
    if (documents[0].exists && documents[1].exists) {
      throw const RoleConflictException();
    }
    for (var index = 0; index < documents.length; index++) {
      final data = documents[index].data();
      if (data == null) continue;
      final expected = index == 0 ? 'client' : 'gas_station';
      if (data['uid'] != uid || data['type'] != expected) {
        throw const InvalidProfileException();
      }
      return index == 0 ? AccountRole.client : AccountRole.gasStation;
    }
    return null;
  }

  Future<void> _ensureNewProfile(String uid, AccountRole requested) async {
    final existing = await readRole(uid);
    if (existing != null && existing != requested) {
      throw const RoleConflictException();
    }
    if (existing != null) {
      throw const ValidationException(
        'O cadastro desta conta já foi concluído.',
      );
    }
  }

  Future<void> createClient({
    required String uid,
    required String email,
    required String name,
  }) async {
    if (name.trim().isEmpty) {
      throw const ValidationException('Informe seu nome.');
    }
    await _ensureNewProfile(uid, AccountRole.client);
    await _client(uid).set({
      'uid': uid,
      'type': 'client',
      'name': name.trim(),
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createStation({
    required String uid,
    required String email,
    required StationRegistration registration,
  }) async {
    if (registration.cnpj.trim().isEmpty ||
        registration.brandName.trim().isEmpty ||
        registration.address.trim().isEmpty) {
      throw const ValidationException(
        'Preencha CNPJ, nome e endereço do posto.',
      );
    }
    await _ensureNewProfile(uid, AccountRole.gasStation);
    final coordinates = await _geocoding.resolve(registration.address.trim());
    // Revalida após o trabalho externo de geocodificação; rules são a garantia real.
    await _ensureNewProfile(uid, AccountRole.gasStation);
    final batch = _firestore.batch();
    batch.set(_station(uid), {
      'uid': uid,
      'type': 'gas_station',
      'cnpj': registration.cnpj.trim(),
      'email': email,
      'brandName': registration.brandName.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _firestore.collection(FirestoreCollections.publicStations).doc(uid),
      {
        'uid': uid,
        'brandName': registration.brandName.trim(),
        'address': registration.address.trim(),
        'city': FirestoreCollections.mvpCity,
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
        'prices': {
          'gasolineRegular': null,
          'gasolineAdditive': null,
          'ethanol': null,
          'dieselS10': null,
          'dieselS500': null,
        },
        'pricesUpdatedAt': FieldValue.serverTimestamp(),
        'openingHours': {
          'monday': null,
          'tuesday': null,
          'wednesday': null,
          'thursday': null,
          'friday': null,
          'saturday': null,
          'sunday': null,
        },
        'averageRating': 0.0,
        'reviewCount': 0,
        'services': <String>[],
        'tags': <String>[],
      },
    );
    await batch.commit();
  }
}

```

### lib/features/auth/data/services/firebase_auth_service.dart

```dart
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

```

### lib/features/auth/domain/models/auth_session.dart

```dart
// Representa a sessão sem expor tipos Firebase às camadas superiores.
enum AccountRole { client, gasStation }

class AuthSession {
  const AuthSession({
    required this.uid,
    required this.email,
    this.role,
    this.isAdmin = false,
  });

  final String uid;
  final String email;
  final AccountRole? role;
  final bool isAdmin;
  bool get needsProfile => role == null;
}

```

### lib/features/auth/domain/models/station_registration.dart

```dart
// Dados mínimos de cadastro; preços e horários começam sem informação.
class StationRegistration {
  const StationRegistration({
    required this.cnpj,
    required this.brandName,
    required this.address,
  });

  final String cnpj;
  final String brandName;
  final String address;
}

```

### lib/features/auth/domain/repositories/auth_repository.dart

```dart
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
  Future<AuthSession> completeClientRegistration({required String name});
  Future<AuthSession> completeStationRegistration(
    StationRegistration registration,
  );
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
}

```

### lib/features/auth/presentation/providers/auth_providers.dart

```dart
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

```

### lib/features/auth/presentation/viewmodels/auth_viewmodel.dart

```dart
// Coordena comandos em AsyncValue, dependendo apenas do contrato do Repository.
import 'package:riverpod/riverpod.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/station_registration.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthViewModel extends AsyncNotifier<AuthSession?> {
  AuthViewModel(this._repositoryProvider);
  final ProviderListenable<AuthRepository> _repositoryProvider;
  bool _busy = false;
  bool _disposed = false;

  AuthRepository get _repository => ref.read(_repositoryProvider);

  @override
  Future<AuthSession?> build() async {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    final result = await AsyncValue.guard(() => _repository.restoreSession());
    return result.requireValue;
  }

  Future<void> _run(Future<AuthSession?> Function() operation) async {
    if (_busy || state.isLoading) return;
    _busy = true;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(operation);
    if (!_disposed) state = result;
    _busy = false;
  }

  Future<void> signIn({required String email, required String password}) =>
      _run(() => _repository.signIn(email: email, password: password));
  Future<void> signInWithGoogle() => _run(_repository.signInWithGoogle);
  Future<void> createAccount({
    required String email,
    required String password,
  }) => _run(() => _repository.createAccount(email: email, password: password));
  Future<void> completeClientRegistration({required String name}) =>
      _run(() => _repository.completeClientRegistration(name: name));
  Future<void> completeStationRegistration(StationRegistration registration) =>
      _run(() => _repository.completeStationRegistration(registration));
  Future<void> refreshSession() =>
      _run(() => _repository.restoreSession(forceRefresh: true));
  Future<void> sendPasswordResetEmail(String email) => _run(() async {
    await _repository.sendPasswordResetEmail(email);
    return _repository.restoreSession();
  });
  Future<void> signOut() => _run(() async {
    await _repository.signOut();
    return null;
  });
}

```

### lib/features/auth/presentation/views/.gitkeep

```text
# Reserva de estrutura arquitetural; implementação futura.

```

### lib/features/auth/presentation/widgets/.gitkeep

```text
# Reserva de estrutura arquitetural; implementação futura.

```

### lib/main.dart

```dart
// Inicializa Firebase antes da aplicação e do container Riverpod.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: CompletAiApp()));
}

```

### lib/shared/models/.gitkeep

```text
# Reserva de estrutura arquitetural; implementação futura.

```

### test/auth_profile_service_test.dart

```dart
// Testa as escritas reais do serviço contra Firestore em memória (não valida rules).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:completai/core/errors/exceptions.dart';
import 'package:completai/features/auth/data/services/address_geocoding_service.dart';
import 'package:completai/features/auth/data/services/auth_profile_service.dart';
import 'package:completai/features/auth/domain/models/station_registration.dart';

class TestGeocoding extends AddressGeocodingService {
  bool fail = false;
  int calls = 0;
  @override
  Future<StationCoordinates> resolve(String address) async {
    calls++;
    if (fail) throw const ValidationException('Endereço não encontrado.');
    return const StationCoordinates(-20.949, -48.479);
  }
}

void main() {
  late FakeFirebaseFirestore firestore;
  late TestGeocoding geocoding;
  late AuthProfileService service;
  const station = StationRegistration(
    cnpj: '12345678000190',
    brandName: 'Posto Teste',
    address: 'Rua Teste, 100',
  );
  setUp(() {
    firestore = FakeFirebaseFirestore();
    geocoding = TestGeocoding();
    service = AuthProfileService(firestore, geocoding);
  });

  test(
    'cliente existente impede cadastro de posto antes da geocodificação',
    () async {
      await service.createClient(uid: 'u1', email: 'a@b.com', name: 'Ana');
      await expectLater(
        service.createStation(
          uid: 'u1',
          email: 'a@b.com',
          registration: station,
        ),
        throwsA(isA<RoleConflictException>()),
      );
      expect(
        (await firestore.collection('gas_stations').doc('u1').get()).exists,
        isFalse,
      );
      expect(
        (await firestore.collection('public_stations').doc('u1').get()).exists,
        isFalse,
      );
      expect(geocoding.calls, 0);
    },
  );

  test('posto existente impede cadastro de cliente', () async {
    await service.createStation(
      uid: 'u1',
      email: 'a@b.com',
      registration: station,
    );
    await expectLater(
      service.createClient(uid: 'u1', email: 'a@b.com', name: 'Ana'),
      throwsA(isA<RoleConflictException>()),
    );
    expect(
      (await firestore.collection('users').doc('u1').get()).exists,
      isFalse,
    );
  });

  test(
    'geocodificação com falha não salva nenhum documento de posto',
    () async {
      geocoding.fail = true;
      await expectLater(
        service.createStation(
          uid: 'u1',
          email: 'a@b.com',
          registration: station,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        (await firestore.collection('gas_stations').doc('u1').get()).exists,
        isFalse,
      );
      expect(
        (await firestore.collection('public_stations').doc('u1').get()).exists,
        isFalse,
      );
    },
  );

  test('cadastro grava schema público completo sem dados sensíveis', () async {
    await service.createStation(
      uid: 'u1',
      email: 'a@b.com',
      registration: station,
    );
    final private = (await firestore.collection('gas_stations').doc('u1').get())
        .data()!;
    final public =
        (await firestore.collection('public_stations').doc('u1').get()).data()!;
    expect(private.keys.toSet(), {
      'uid',
      'type',
      'cnpj',
      'email',
      'brandName',
      'createdAt',
      'updatedAt',
    });
    expect(public.keys.toSet(), {
      'uid',
      'brandName',
      'address',
      'city',
      'latitude',
      'longitude',
      'prices',
      'pricesUpdatedAt',
      'openingHours',
      'averageRating',
      'reviewCount',
      'services',
      'tags',
    });
    expect(public['city'], 'Bebedouro');
    expect(public['latitude'], -20.949);
    expect(public['longitude'], -48.479);
    expect(public['prices'], {
      'gasolineRegular': null,
      'gasolineAdditive': null,
      'ethanol': null,
      'dieselS10': null,
      'dieselS500': null,
    });
    expect(public['openingHours'], {
      'monday': null,
      'tuesday': null,
      'wednesday': null,
      'thursday': null,
      'friday': null,
      'saturday': null,
      'sunday': null,
    });
    expect(public['reviewCount'], 0);
    expect(private['createdAt'], isA<Timestamp>());
    expect(geocoding.calls, 1);
  });

  test('cadastro repetido não sobrescreve perfil existente', () async {
    await service.createClient(uid: 'u1', email: 'a@b.com', name: 'Ana');
    await expectLater(
      service.createClient(uid: 'u1', email: 'a@b.com', name: 'Outro'),
      throwsA(isA<ValidationException>()),
    );
    expect(
      (await firestore.collection('users').doc('u1').get()).data()!['name'],
      'Ana',
    );
  });

  test('leitura rejeita estado legado com dois papéis', () async {
    await firestore.collection('users').doc('u1').set({
      'uid': 'u1',
      'type': 'client',
    });
    await firestore.collection('gas_stations').doc('u1').set({
      'uid': 'u1',
      'type': 'gas_station',
    });
    await expectLater(
      service.readRole('u1'),
      throwsA(isA<RoleConflictException>()),
    );
  });
}

```

### test/auth_repository_test.dart

```dart
// Testa cache por UID, invalidação e tradução de erros do Repository concreto.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:completai/core/errors/exceptions.dart';
import 'package:completai/core/errors/failures.dart';
import 'package:completai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:completai/features/auth/data/services/firebase_auth_service.dart';
import 'package:completai/features/auth/data/services/auth_profile_service.dart';
import 'package:completai/features/auth/domain/models/auth_session.dart';

class TestUser implements User {
  TestUser(this.uid);
  @override
  final String uid;
  @override
  String get email => '$uid@example.com';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestAuthService implements FirebaseAuthService {
  @override
  User? currentUser = TestUser('a');
  bool admin = false;
  @override
  Future<bool> isAdmin({bool forceRefresh = false}) async => admin;
  @override
  Future<void> signOut() async {
    currentUser = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestProfiles implements AuthProfileService {
  int reads = 0;
  Object? failure;
  @override
  Future<AccountRole?> readRole(String uid) async {
    reads++;
    if (failure != null) throw failure!;
    return uid == 'a' ? AccountRole.client : AccountRole.gasStation;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('cache evita leituras repetidas e nunca atravessa UIDs', () async {
    final auth = TestAuthService();
    final profiles = TestProfiles();
    final repository = AuthRepositoryImpl(auth, profiles);
    await repository.restoreSession();
    await repository.restoreSession();
    expect(profiles.reads, 1);
    auth.currentUser = TestUser('b');
    final session = await repository.restoreSession();
    expect(session!.uid, 'b');
    expect(session.role, AccountRole.gasStation);
    expect(profiles.reads, 2);
  });
  test('refresh explícito atualiza claim e logout limpa cache', () async {
    final auth = TestAuthService();
    final profiles = TestProfiles();
    final repository = AuthRepositoryImpl(auth, profiles);
    await repository.restoreSession();
    auth.admin = true;
    expect(
      (await repository.restoreSession(forceRefresh: true))!.isAdmin,
      isTrue,
    );
    await repository.signOut();
    expect(await repository.restoreSession(), isNull);
    auth.currentUser = TestUser('a');
    await repository.restoreSession();
    expect(profiles.reads, 3);
  });
  test('conflito do serviço é traduzido para falha de domínio', () async {
    final profiles = TestProfiles()..failure = const RoleConflictException();
    final repository = AuthRepositoryImpl(TestAuthService(), profiles);
    await expectLater(
      repository.restoreSession(),
      throwsA(isA<RoleConflictFailure>()),
    );
  });
}

```

### test/auth_viewmodel_test.dart

```dart
// Verifica transições da ViewModel e propagação de falhas sem Firebase real.
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:completai/core/errors/failures.dart';
import 'package:completai/features/auth/domain/models/auth_session.dart';
import 'package:completai/features/auth/domain/repositories/auth_repository.dart';
import 'package:completai/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class TestAuthRepository implements AuthRepository {
  AuthSession? session;
  Completer<AuthSession>? pending;
  Object? failure;
  @override
  Future<AuthSession?> restoreSession({bool forceRefresh = false}) async {
    if (failure != null) throw failure!;
    return session;
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) => pending!.future;
  @override
  Future<void> signOut() async {
    session = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late TestAuthRepository repository;
  late ProviderContainer container;
  late AsyncNotifierProvider<AuthViewModel, AuthSession?> provider;

  setUp(() {
    repository = TestAuthRepository();
    final dependency = Provider<AuthRepository>((ref) => repository);
    provider = AsyncNotifierProvider<AuthViewModel, AuthSession?>(
      () => AuthViewModel(dependency),
    );
    container = ProviderContainer();
  });
  tearDown(() => container.dispose());

  test('restaura sessão ausente e sai de loading', () async {
    expect(await container.read(provider.future), isNull);
    expect(container.read(provider).isLoading, isFalse);
  });

  test('login publica loading e a sessão retornada', () async {
    await container.read(provider.future);
    repository.pending = Completer<AuthSession>();
    final operation = container
        .read(provider.notifier)
        .signIn(email: 'a@b.com', password: 'secret');
    expect(container.read(provider).isLoading, isTrue);
    repository.pending!.complete(
      const AuthSession(uid: 'u1', email: 'a@b.com', role: AccountRole.client),
    );
    await operation;
    expect(container.read(provider).requireValue!.uid, 'u1');
    expect(container.read(provider).requireValue!.role, AccountRole.client);
  });

  test('falha de login fica disponível no AsyncError', () async {
    await container.read(provider.future);
    repository.pending = Completer<AuthSession>();
    final operation = container
        .read(provider.notifier)
        .signIn(email: 'a@b.com', password: 'wrong');
    repository.pending!.completeError(
      const AuthFailure('Credenciais inválidas.'),
    );
    await operation;
    expect(container.read(provider).error, isA<AuthFailure>());
    expect(container.read(provider).isLoading, isFalse);
  });

  test('falha na restauração não é convertida em logout', () async {
    repository.failure = const RoleConflictFailure('Papéis conflitantes.');
    await expectLater(
      container.read(provider.future),
      throwsA(isA<RoleConflictFailure>()),
    );
    expect(container.read(provider).hasError, isTrue);
  });

  test('logout limpa sessão e claim admin', () async {
    repository.session = const AuthSession(
      uid: 'admin',
      email: 'a@b.com',
      isAdmin: true,
    );
    await container.read(provider.future);
    await container.read(provider.notifier).signOut();
    expect(container.read(provider).requireValue, isNull);
  });
}

```

### test/widget_test.dart

```dart
// Verifica controles ocupados e validação de formulário.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:completai/core/theme/app_theme.dart';
import 'package:completai/core/widgets/app_button.dart';
import 'package:completai/core/widgets/app_text_field.dart';

void main() {
  testWidgets('botão ocupado não aceita novo acionamento', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppButton(
            label: 'Entrar',
            isLoading: true,
            onPressed: () => calls++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Entrar'));
    expect(calls, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
  testWidgets('campo exibe falha de validação e protege senha', (tester) async {
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Form(
            key: form,
            child: AppTextField(
              label: 'Senha',
              obscureText: true,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Informe a senha' : null,
            ),
          ),
        ),
      ),
    );
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Informe a senha'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isTrue,
    );
  });
}

```

### pubspec.yaml

```yaml
name: completai
description: "A new Flutter project."
# The following line prevents the package from being accidentally published to
# pub.dev using `flutter pub publish`. This is preferred for private packages.
publish_to: 'none' # Remove this line if you wish to publish to pub.dev

# The following defines the version and build number for your application.
# A version number is three numbers separated by dots, like 1.2.43
# followed by an optional build number separated by a +.
# Both the version and the builder number may be overridden in flutter
# build by specifying --build-name and --build-number, respectively.
# In Android, build-name is used as versionName while build-number used as versionCode.
# Read more about Android versioning at https://developer.android.com/studio/publish/versioning
# In iOS, build-name is used as CFBundleShortVersionString while build-number is used as CFBundleVersion.
# Read more about iOS versioning at
# https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html
# In Windows, build-name is used as the major, minor, and patch parts
# of the product and file versions while build-number is used as the build suffix.
version: 1.0.0+1

environment:
  sdk: ^3.12.0

# Dependencies specify other packages that your package needs in order to work.
# To automatically upgrade your package dependencies to the latest versions
# consider running `flutter pub upgrade --major-versions`. Alternatively,
# dependencies can be manually updated by changing the version numbers below to
# the latest version available on pub.dev. To see which dependencies have newer
# versions available, run `flutter pub outdated`.
dependencies:
  flutter:
    sdk: flutter

  # The following adds the Cupertino Icons font to your application.
  # Use with the CupertinoIcons class for iOS style icons.
  cupertino_icons: ^1.0.8
  firebase_core: ^4.14.0
  flutter_riverpod: ^2.6.1
  riverpod: ^2.6.1
  cloud_firestore: ^6.9.0
  firebase_auth: ^6.6.1
  google_sign_in: ^7.2.0
  geocoding: ^5.0.0
  geolocator: ^14.0.3
  google_fonts: ^8.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter

  # The "flutter_lints" package below contains a set of recommended lints to
  # encourage good coding practices. The lint set provided by the package is
  # activated in the `analysis_options.yaml` file located at the root of your
  # package. See that file for information about deactivating specific lint
  # rules and activating additional ones.
  flutter_lints: ^6.0.0
  fake_cloud_firestore: ^4.2.0

# For information on the generic Dart part of this file, see the
# following page: https://dart.dev/tools/pub/pubspec

# The following section is specific to Flutter packages.
flutter:

  # The following line ensures that the Material Icons font is
  # included with your application, so that you can use the icons in
  # the material Icons class.
  uses-material-design: true

  # To add assets to your application, add an assets section, like this:
  # assets:
  #   - images/a_dot_burr.jpeg
  #   - images/a_dot_ham.jpeg

  # An image asset can refer to one or more resolution-specific "variants", see
  # https://flutter.dev/to/resolution-aware-images

  # For details regarding adding assets from package dependencies, see
  # https://flutter.dev/to/asset-from-package

  # To add custom fonts to your application, add a fonts section here,
  # in this "flutter" section. Each entry in this list should have a
  # "family" key with the font family name, and a "fonts" key with a
  # list giving the asset and other descriptors for the font. For
  # example:
  # fonts:
  #   - family: Schyler
  #     fonts:
  #       - asset: fonts/Schyler-Regular.ttf
  #       - asset: fonts/Schyler-Italic.ttf
  #         style: italic
  #   - family: Trajan Pro
  #     fonts:
  #       - asset: fonts/TrajanPro.ttf
  #       - asset: fonts/TrajanPro_Bold.ttf
  #         weight: 700
  #
  # For details regarding fonts from package dependencies,
  # see https://flutter.dev/to/font-from-package

```

### pubspec.lock

```yaml
# Generated by pub
# See https://dart.dev/tools/pub/glossary#lockfile
packages:
  _flutterfire_internals:
    dependency: transitive
    description:
      name: _flutterfire_internals
      sha256: f6966125633a34f82d9be2ee895b755cff3554087b1d00a9eb884e5947f4bca9
      url: "https://pub.dev"
    source: hosted
    version: "1.3.77"
  antlr4:
    dependency: transitive
    description:
      name: antlr4
      sha256: "752b4a6e4ad97953652a2b2bbf5377f46c94b579d3372b50080c7e5858234a05"
      url: "https://pub.dev"
    source: hosted
    version: "4.13.2"
  args:
    dependency: transitive
    description:
      name: args
      sha256: d0481093c50b1da8910eb0bb301626d4d8eb7284aa739614d2b394ee09e3ea04
      url: "https://pub.dev"
    source: hosted
    version: "2.7.0"
  async:
    dependency: transitive
    description:
      name: async
      sha256: e2eb0491ba5ddb6177742d2da23904574082139b07c1e33b8503b9f46f3e1a37
      url: "https://pub.dev"
    source: hosted
    version: "2.13.1"
  boolean_selector:
    dependency: transitive
    description:
      name: boolean_selector
      sha256: "8aab1771e1243a5063b8b0ff68042d67334e3feab9e95b9490f9a6ebf73b42ea"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.2"
  cel:
    dependency: transitive
    description:
      name: cel
      sha256: "51d77e16424d41b5fdb0a239be4c8a0550d4dd3f952801d35375ddd90cfb49da"
      url: "https://pub.dev"
    source: hosted
    version: "0.5.4+1"
  characters:
    dependency: transitive
    description:
      name: characters
      sha256: faf38497bda5ead2a8c7615f4f7939df04333478bf32e4173fcb06d428b5716b
      url: "https://pub.dev"
    source: hosted
    version: "1.4.1"
  clock:
    dependency: transitive
    description:
      name: clock
      sha256: fddb70d9b5277016c77a80201021d40a2247104d9f4aa7bab7157b7e3f05b84b
      url: "https://pub.dev"
    source: hosted
    version: "1.1.2"
  cloud_firestore:
    dependency: "direct main"
    description:
      name: cloud_firestore
      sha256: "098f59588473be708ac40e8418a3f7b343a8dba45b1c3fb820e39e94251db921"
      url: "https://pub.dev"
    source: hosted
    version: "6.9.0"
  cloud_firestore_platform_interface:
    dependency: transitive
    description:
      name: cloud_firestore_platform_interface
      sha256: ef985a8239846187de0eccce2092a940eaf281a1357c6325e1739ec0b6c230e2
      url: "https://pub.dev"
    source: hosted
    version: "8.0.7"
  cloud_firestore_web:
    dependency: transitive
    description:
      name: cloud_firestore_web
      sha256: b30b3b44937345d50b195f85ef328f1d71c2a79965cb1645a479d029d45f636a
      url: "https://pub.dev"
    source: hosted
    version: "5.7.3"
  code_assets:
    dependency: transitive
    description:
      name: code_assets
      sha256: bf394f466ba9205f1812a0433b392d6af280f155f56651eda7c18cc32ed493b8
      url: "https://pub.dev"
    source: hosted
    version: "1.2.1"
  collection:
    dependency: transitive
    description:
      name: collection
      sha256: "2f5709ae4d3d59dd8f7cd309b4e023046b57d8a6c82130785d2b0e5868084e76"
      url: "https://pub.dev"
    source: hosted
    version: "1.19.1"
  crypto:
    dependency: transitive
    description:
      name: crypto
      sha256: c8ea0233063ba03258fbcf2ca4d6dadfefe14f02fab57702265467a19f27fadf
      url: "https://pub.dev"
    source: hosted
    version: "3.0.7"
  cupertino_icons:
    dependency: "direct main"
    description:
      name: cupertino_icons
      sha256: "41e005c33bd814be4d3096aff55b1908d419fde52ca656c8c47719ec745873cd"
      url: "https://pub.dev"
    source: hosted
    version: "1.0.9"
  dbus:
    dependency: transitive
    description:
      name: dbus
      sha256: a48d5da28e89bd02196e80d81ed8d7954923d00a0f4a68cc20b575038f023383
      url: "https://pub.dev"
    source: hosted
    version: "0.7.15"
  equatable:
    dependency: transitive
    description:
      name: equatable
      sha256: "3bce007a596ff8b3119c45d68aaef631272537c03d30e5d4534dd24bf4c5eaa2"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.0"
  fake_async:
    dependency: transitive
    description:
      name: fake_async
      sha256: "5368f224a74523e8d2e7399ea1638b37aecfca824a3cc4dfdf77bf1fa905ac44"
      url: "https://pub.dev"
    source: hosted
    version: "1.3.3"
  fake_cloud_firestore:
    dependency: "direct dev"
    description:
      name: fake_cloud_firestore
      sha256: c2ce1f828e5840c2f212584d496dbae0cfc94848daa84112e51a0722358aa24a
      url: "https://pub.dev"
    source: hosted
    version: "4.2.0"
  fake_firebase_security_rules:
    dependency: transitive
    description:
      name: fake_firebase_security_rules
      sha256: "6af54bedfd6985451a9735f2cfac91ffe0128bfc92bf15e8544cd56c6941d6cc"
      url: "https://pub.dev"
    source: hosted
    version: "0.5.4"
  ffi:
    dependency: transitive
    description:
      name: ffi
      sha256: "6d7fd89431262d8f3125e81b50d3847a091d846eafcd4fdb88dd06f36d705a45"
      url: "https://pub.dev"
    source: hosted
    version: "2.2.0"
  ffi_leak_tracker:
    dependency: transitive
    description:
      name: ffi_leak_tracker
      sha256: "4093d4ef9ca06ffe2786e73bfb25e22aa92112b9bb4ec941f11e3e6b61489a97"
      url: "https://pub.dev"
    source: hosted
    version: "0.1.2"
  firebase_auth:
    dependency: "direct main"
    description:
      name: firebase_auth
      sha256: "89bf082422d09cb19d32450c6693c135ebadb2fef4852b2ad0daaa9820136893"
      url: "https://pub.dev"
    source: hosted
    version: "6.6.1"
  firebase_auth_platform_interface:
    dependency: transitive
    description:
      name: firebase_auth_platform_interface
      sha256: f693f59a1f11f2769cc9c2362e6032b5a95bc63d0b4a8a25ccd5190ea5899693
      url: "https://pub.dev"
    source: hosted
    version: "9.0.7"
  firebase_auth_web:
    dependency: transitive
    description:
      name: firebase_auth_web
      sha256: cfb98837959f3677696c997856cc8dedbb3e52367397ec80437b85b735ad6c17
      url: "https://pub.dev"
    source: hosted
    version: "6.2.7"
  firebase_core:
    dependency: "direct main"
    description:
      name: firebase_core
      sha256: "2343710d8a164e3157a5e2fbb00663503c669be4aa06185311df48626760fdf1"
      url: "https://pub.dev"
    source: hosted
    version: "4.14.0"
  firebase_core_platform_interface:
    dependency: transitive
    description:
      name: firebase_core_platform_interface
      sha256: "9bfbc85faca09346471ac56fbcee00757ebcfd85887c6f602764eff0001902d8"
      url: "https://pub.dev"
    source: hosted
    version: "8.1.1"
  firebase_core_web:
    dependency: transitive
    description:
      name: firebase_core_web
      sha256: de1e678209a0c974d8aa4cff39f17d61d2dc263aa64993168360f9be4efb8e91
      url: "https://pub.dev"
    source: hosted
    version: "3.11.0"
  fixnum:
    dependency: transitive
    description:
      name: fixnum
      sha256: b6dc7065e46c974bc7c5f143080a6764ec7a4be6da1285ececdc37be96de53be
      url: "https://pub.dev"
    source: hosted
    version: "1.1.1"
  flutter:
    dependency: "direct main"
    description: flutter
    source: sdk
    version: "0.0.0"
  flutter_lints:
    dependency: "direct dev"
    description:
      name: flutter_lints
      sha256: "3105dc8492f6183fb076ccf1f351ac3d60564bff92e20bfc4af9cc1651f4e7e1"
      url: "https://pub.dev"
    source: hosted
    version: "6.0.0"
  flutter_riverpod:
    dependency: "direct main"
    description:
      name: flutter_riverpod
      sha256: "9532ee6db4a943a1ed8383072a2e3eeda041db5657cdf6d2acecf3c21ecbe7e1"
      url: "https://pub.dev"
    source: hosted
    version: "2.6.1"
  flutter_test:
    dependency: "direct dev"
    description: flutter
    source: sdk
    version: "0.0.0"
  flutter_web_plugins:
    dependency: transitive
    description: flutter
    source: sdk
    version: "0.0.0"
  geoclue:
    dependency: transitive
    description:
      name: geoclue
      sha256: c2a998c77474fc57aa00c6baa2928e58f4b267649057a1c76738656e9dbd2a7f
      url: "https://pub.dev"
    source: hosted
    version: "0.1.1"
  geocoding:
    dependency: "direct main"
    description:
      name: geocoding
      sha256: "40f845e0a5505d4b47da991057f2ab25cd1c68bc4570255c7d4cfbb03a952063"
      url: "https://pub.dev"
    source: hosted
    version: "5.0.0"
  geocoding_android:
    dependency: transitive
    description:
      name: geocoding_android
      sha256: "17e88a69bb0e1ae44597d70df2d2fbdb2f503672cf665421a16ab56ab97e4ead"
      url: "https://pub.dev"
    source: hosted
    version: "5.1.0"
  geocoding_darwin:
    dependency: transitive
    description:
      name: geocoding_darwin
      sha256: "97552aa24f1453defc17e4d8e40b13ddf097e669c2edfa17ed86349cacdbc1ae"
      url: "https://pub.dev"
    source: hosted
    version: "1.0.3"
  geocoding_platform_interface:
    dependency: transitive
    description:
      name: geocoding_platform_interface
      sha256: "5164b8871705af7573698b3aa0746337faf818d72b488988741bcc7aeedd2f6e"
      url: "https://pub.dev"
    source: hosted
    version: "5.0.0"
  geolocator:
    dependency: "direct main"
    description:
      name: geolocator
      sha256: e146a6d63776582651e97a79cbe459f8e1211b100101fadcd84db83361fa599f
      url: "https://pub.dev"
    source: hosted
    version: "14.0.3"
  geolocator_android:
    dependency: transitive
    description:
      name: geolocator_android
      sha256: "86ea1654e4f61ff51466848e91c116b422d6010ea269fda0fbe1af7e9e742ce1"
      url: "https://pub.dev"
    source: hosted
    version: "5.0.3"
  geolocator_apple:
    dependency: transitive
    description:
      name: geolocator_apple
      sha256: "853803d6bb1713c094e935b4a5ae5f19c0308acf81da13fa9ff84fb4c70c0b73"
      url: "https://pub.dev"
    source: hosted
    version: "2.3.14"
  geolocator_linux:
    dependency: transitive
    description:
      name: geolocator_linux
      sha256: "3da7420f11c3496511a5bd3c18fd67b88e5659f12e46b7ce00a788f6996e850a"
      url: "https://pub.dev"
    source: hosted
    version: "0.2.6"
  geolocator_platform_interface:
    dependency: transitive
    description:
      name: geolocator_platform_interface
      sha256: "94db8255dc183d268765df682580440617ca35877fc82cacb5420ad03b86198d"
      url: "https://pub.dev"
    source: hosted
    version: "4.3.0"
  geolocator_web:
    dependency: transitive
    description:
      name: geolocator_web
      sha256: "19e485a0f8d6a88abcf9c53cba3a4105e14b7435ed8ac1c108c067b938fe8429"
      url: "https://pub.dev"
    source: hosted
    version: "4.1.4"
  geolocator_windows:
    dependency: transitive
    description:
      name: geolocator_windows
      sha256: "175435404d20278ffd220de83c2ca293b73db95eafbdc8131fe8609be1421eb6"
      url: "https://pub.dev"
    source: hosted
    version: "0.2.5"
  google_fonts:
    dependency: "direct main"
    description:
      name: google_fonts
      sha256: e3cb3ee6b47fd2472c23de6da5744796a4da195137759ddb3fbcc9467b7b3c7d
      url: "https://pub.dev"
    source: hosted
    version: "8.2.1"
  google_identity_services_web:
    dependency: transitive
    description:
      name: google_identity_services_web
      sha256: "5d187c46dc59e02646e10fe82665fc3884a9b71bc1c90c2b8b749316d33ee454"
      url: "https://pub.dev"
    source: hosted
    version: "0.3.3+1"
  google_sign_in:
    dependency: "direct main"
    description:
      name: google_sign_in
      sha256: "521031b65853b4409b8213c0387d57edaad7e2a949ce6dea0d8b2afc9cb29763"
      url: "https://pub.dev"
    source: hosted
    version: "7.2.0"
  google_sign_in_android:
    dependency: transitive
    description:
      name: google_sign_in_android
      sha256: c403315d87aba1f815a0a401093f97808cab6cb2bdd11ca431ff8587fd7f1c00
      url: "https://pub.dev"
    source: hosted
    version: "7.2.17"
  google_sign_in_ios:
    dependency: transitive
    description:
      name: google_sign_in_ios
      sha256: "50ab85d3a732227807bb871a5df0dfaa09005f24b00b6f775f500c7b62b12d7e"
      url: "https://pub.dev"
    source: hosted
    version: "6.3.3"
  google_sign_in_platform_interface:
    dependency: transitive
    description:
      name: google_sign_in_platform_interface
      sha256: "7f59208c42b415a3cca203571128d6f84f885fead2d5b53eb65a9e27f2965bb5"
      url: "https://pub.dev"
    source: hosted
    version: "3.1.0"
  google_sign_in_web:
    dependency: transitive
    description:
      name: google_sign_in_web
      sha256: d473003eeca892f96a01a64fc803378be765071cb0c265ee872c7f8683245d14
      url: "https://pub.dev"
    source: hosted
    version: "1.1.3"
  gsettings:
    dependency: transitive
    description:
      name: gsettings
      sha256: "1b0ce661f5436d2db1e51f3c4295a49849f03d304003a7ba177d01e3a858249c"
      url: "https://pub.dev"
    source: hosted
    version: "0.2.8"
  hooks:
    dependency: transitive
    description:
      name: hooks
      sha256: "9a62a50b50b769a737bc0a8ff381f333529df3ab746b2f6b02e83760231455ba"
      url: "https://pub.dev"
    source: hosted
    version: "2.0.2"
  http:
    dependency: transitive
    description:
      name: http
      sha256: "87721a4a50b19c7f1d49001e51409bddc46303966ce89a65af4f4e6004896412"
      url: "https://pub.dev"
    source: hosted
    version: "1.6.0"
  http_parser:
    dependency: transitive
    description:
      name: http_parser
      sha256: "178d74305e7866013777bab2c3d8726205dc5a4dd935297175b19a23a2e66571"
      url: "https://pub.dev"
    source: hosted
    version: "4.1.2"
  jni:
    dependency: transitive
    description:
      name: jni
      sha256: f038e58b4dc2c9037f50e233175086337e0b305e356d28211bf55f21c504cbd3
      url: "https://pub.dev"
    source: hosted
    version: "1.0.3"
  jni_flutter:
    dependency: transitive
    description:
      name: jni_flutter
      sha256: b2310cdd4c18c65c081ab141a41efa94aa26c65431803703ece51996f174f351
      url: "https://pub.dev"
    source: hosted
    version: "1.0.3"
  jni_util:
    dependency: transitive
    description:
      name: jni_util
      sha256: "1ba86da04a5f2bf18fde2edb235587e70c5b0fc5bd4ba955f46b00942c3fc35f"
      url: "https://pub.dev"
    source: hosted
    version: "1.0.0"
  leak_tracker:
    dependency: transitive
    description:
      name: leak_tracker
      sha256: "33e2e26bdd85a0112ec15400c8cbffea70d0f9c3407491f672a2fad47915e2de"
      url: "https://pub.dev"
    source: hosted
    version: "11.0.2"
  leak_tracker_flutter_testing:
    dependency: transitive
    description:
      name: leak_tracker_flutter_testing
      sha256: "1dbc140bb5a23c75ea9c4811222756104fbcd1a27173f0c34ca01e16bea473c1"
      url: "https://pub.dev"
    source: hosted
    version: "3.0.10"
  leak_tracker_testing:
    dependency: transitive
    description:
      name: leak_tracker_testing
      sha256: "8d5a2d49f4a66b49744b23b018848400d23e54caf9463f4eb20df3eb8acb2eb1"
      url: "https://pub.dev"
    source: hosted
    version: "3.0.2"
  lints:
    dependency: transitive
    description:
      name: lints
      sha256: "12f842a479589fea194fe5c5a3095abc7be0c1f2ddfa9a0e76aed1dbd26a87df"
      url: "https://pub.dev"
    source: hosted
    version: "6.1.0"
  logger:
    dependency: transitive
    description:
      name: logger
      sha256: "25aee487596a6257655a1e091ec2ae66bc30e7af663592cc3a27e6591e05035c"
      url: "https://pub.dev"
    source: hosted
    version: "2.7.0"
  logging:
    dependency: transitive
    description:
      name: logging
      sha256: c8245ada5f1717ed44271ed1c26b8ce85ca3228fd2ffdb75468ab01979309d61
      url: "https://pub.dev"
    source: hosted
    version: "1.3.0"
  matcher:
    dependency: transitive
    description:
      name: matcher
      sha256: dc0b7dc7651697ea4ff3e69ef44b0407ea32c487a39fff6a4004fa585e901861
      url: "https://pub.dev"
    source: hosted
    version: "0.12.19"
  material_color_utilities:
    dependency: transitive
    description:
      name: material_color_utilities
      sha256: "9c337007e82b1889149c82ed242ed1cb24a66044e30979c44912381e9be4c48b"
      url: "https://pub.dev"
    source: hosted
    version: "0.13.0"
  meta:
    dependency: transitive
    description:
      name: meta
      sha256: "1741988757a65eb6b36abe716829688cf01910bbf91c34354ff7ec1c3de2b349"
      url: "https://pub.dev"
    source: hosted
    version: "1.18.0"
  mock_exceptions:
    dependency: transitive
    description:
      name: mock_exceptions
      sha256: "6e3e623712d2c6106ffe9e14732912522b565ddaa82a8dcee6cd4441b5984056"
      url: "https://pub.dev"
    source: hosted
    version: "0.8.2"
  more:
    dependency: transitive
    description:
      name: more
      sha256: e252628d2183cc09539b686abfbd9d8302675959b89a2a8146f5f4baca6ac5ba
      url: "https://pub.dev"
    source: hosted
    version: "4.7.0"
  objective_c:
    dependency: transitive
    description:
      name: objective_c
      sha256: b7fb95a6d9a4f009edd63dc5ac69f07420b23a16161c6dd8660290b59c602e8e
      url: "https://pub.dev"
    source: hosted
    version: "9.5.0"
  package_config:
    dependency: transitive
    description:
      name: package_config
      sha256: ffcf4cf3d6c0b74ac43708d9f56625506e8a68aa935abe9d267a7330f320eb5d
      url: "https://pub.dev"
    source: hosted
    version: "3.0.0"
  package_info_plus:
    dependency: transitive
    description:
      name: package_info_plus
      sha256: "127e1751e37ffb2ff4658beeaca77bad0c27bf5f932bd3a501c2296926d4b481"
      url: "https://pub.dev"
    source: hosted
    version: "10.2.1"
  package_info_plus_platform_interface:
    dependency: transitive
    description:
      name: package_info_plus_platform_interface
      sha256: db762cb2f4f25ee60fb6359773861b0f199e00b90d237bd85a76a1e806b46ef4
      url: "https://pub.dev"
    source: hosted
    version: "4.1.0"
  path:
    dependency: transitive
    description:
      name: path
      sha256: "75cca69d1490965be98c73ceaea117e8a04dd21217b37b292c9ddbec0d955bc5"
      url: "https://pub.dev"
    source: hosted
    version: "1.9.1"
  path_provider:
    dependency: transitive
    description:
      name: path_provider
      sha256: a7f4874f987173da295a61c181b8ee71dab59b332a486b391babf26a1b884825
      url: "https://pub.dev"
    source: hosted
    version: "2.1.6"
  path_provider_android:
    dependency: transitive
    description:
      name: path_provider_android
      sha256: "69cbd515a62b94d32a7944f086b2f82b4ac40a1d45bebfc00813a430ab2dabcd"
      url: "https://pub.dev"
    source: hosted
    version: "2.3.1"
  path_provider_foundation:
    dependency: transitive
    description:
      name: path_provider_foundation
      sha256: "2a376b7d6392d80cd3705782d2caa734ca4727776db0b6ec36ef3f1855197699"
      url: "https://pub.dev"
    source: hosted
    version: "2.6.0"
  path_provider_linux:
    dependency: transitive
    description:
      name: path_provider_linux
      sha256: "58c2005f147315b11e9b4a7bc889cd5203e250cba8e3f012dae259b4972b5c16"
      url: "https://pub.dev"
    source: hosted
    version: "2.2.2"
  path_provider_platform_interface:
    dependency: transitive
    description:
      name: path_provider_platform_interface
      sha256: "484838772624c3a4b94f1e44a3e19897fee738f2d5c4ce448443b0417f7c9dda"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.3"
  path_provider_windows:
    dependency: transitive
    description:
      name: path_provider_windows
      sha256: bd6f00dbd873bfb70d0761682da2b3a2c2fccc2b9e84c495821639601d81afe7
      url: "https://pub.dev"
    source: hosted
    version: "2.3.0"
  petitparser:
    dependency: transitive
    description:
      name: petitparser
      sha256: "91bd59303e9f769f108f8df05e371341b15d59e995e6806aefab827b58336675"
      url: "https://pub.dev"
    source: hosted
    version: "7.0.2"
  platform:
    dependency: transitive
    description:
      name: platform
      sha256: "5d6b1b0036a5f331ebc77c850ebc8506cbc1e9416c27e59b439f917a902a4984"
      url: "https://pub.dev"
    source: hosted
    version: "3.1.6"
  plugin_platform_interface:
    dependency: transitive
    description:
      name: plugin_platform_interface
      sha256: "4820fbfdb9478b1ebae27888254d445073732dae3d6ea81f0b7e06d5dedc3f02"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.8"
  pub_semver:
    dependency: transitive
    description:
      name: pub_semver
      sha256: "261236774e8b1d69cfc6b9eabbc96c40f25e7a2d6b171f3385d4f65d5734fb24"
      url: "https://pub.dev"
    source: hosted
    version: "2.2.1"
  record_use:
    dependency: transitive
    description:
      name: record_use
      sha256: "2551bd8eecfe95d14ae75f6021ad0248be5c27f138c2ec12fcb52b500b3ba1ed"
      url: "https://pub.dev"
    source: hosted
    version: "0.6.0"
  riverpod:
    dependency: "direct main"
    description:
      name: riverpod
      sha256: "59062512288d3056b2321804332a13ffdd1bf16df70dcc8e506e411280a72959"
      url: "https://pub.dev"
    source: hosted
    version: "2.6.1"
  rx:
    dependency: transitive
    description:
      name: rx
      sha256: "3c819c80915138089c517e0d78f462792c5a2de05189466ab38bee7b6a8a330f"
      url: "https://pub.dev"
    source: hosted
    version: "0.5.0"
  rxdart:
    dependency: transitive
    description:
      name: rxdart
      sha256: "5c3004a4a8dbb94bd4bf5412a4def4acdaa12e12f269737a5751369e12d1a962"
      url: "https://pub.dev"
    source: hosted
    version: "0.28.0"
  sky_engine:
    dependency: transitive
    description: flutter
    source: sdk
    version: "0.0.0"
  source_span:
    dependency: transitive
    description:
      name: source_span
      sha256: "56a02f1f4cd1a2d96303c0144c93bd6d909eea6bee6bf5a0e0b685edbd4c47ab"
      url: "https://pub.dev"
    source: hosted
    version: "1.10.2"
  stack_trace:
    dependency: transitive
    description:
      name: stack_trace
      sha256: "8b27215b45d22309b5cddda1aa2b19bdfec9df0e765f2de506401c071d38d1b1"
      url: "https://pub.dev"
    source: hosted
    version: "1.12.1"
  state_notifier:
    dependency: transitive
    description:
      name: state_notifier
      sha256: b8677376aa54f2d7c58280d5a007f9e8774f1968d1fb1c096adcb4792fba29bb
      url: "https://pub.dev"
    source: hosted
    version: "1.0.0"
  stream_channel:
    dependency: transitive
    description:
      name: stream_channel
      sha256: "969e04c80b8bcdf826f8f16579c7b14d780458bd97f56d107d3950fdbeef059d"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.4"
  string_scanner:
    dependency: transitive
    description:
      name: string_scanner
      sha256: "921cd31725b72fe181906c6a94d987c78e3b98c2e205b397ea399d4054872b43"
      url: "https://pub.dev"
    source: hosted
    version: "1.4.1"
  term_glyph:
    dependency: transitive
    description:
      name: term_glyph
      sha256: "7f554798625ea768a7518313e58f83891c7f5024f88e46e7182a4558850a4b8e"
      url: "https://pub.dev"
    source: hosted
    version: "1.2.2"
  test_api:
    dependency: transitive
    description:
      name: test_api
      sha256: "949a932224383300f01be9221c39180316445ecb8e7547f70a41a35bf421fb9e"
      url: "https://pub.dev"
    source: hosted
    version: "0.7.11"
  typed_data:
    dependency: transitive
    description:
      name: typed_data
      sha256: f9049c039ebfeb4cf7a7104a675823cd72dba8297f264b6637062516699fa006
      url: "https://pub.dev"
    source: hosted
    version: "1.4.0"
  uuid:
    dependency: transitive
    description:
      name: uuid
      sha256: "9b129329f58692f6e6578329498a8fe9fbe98f090beb764ffbb8ee2eadd01dcd"
      url: "https://pub.dev"
    source: hosted
    version: "4.6.0"
  vector_math:
    dependency: transitive
    description:
      name: vector_math
      sha256: d530bd74fea330e6e364cda7a85019c434070188383e1cd8d9777ee586914c5b
      url: "https://pub.dev"
    source: hosted
    version: "2.2.0"
  vm_service:
    dependency: transitive
    description:
      name: vm_service
      sha256: "5f37239c4851efcef929cea7824e76df7f2f0970aef85d66bbc430afa40e72f0"
      url: "https://pub.dev"
    source: hosted
    version: "15.3.0"
  web:
    dependency: transitive
    description:
      name: web
      sha256: "868d88a33d8a87b18ffc05f9f030ba328ffefba92d6c127917a2ba740f9cfe4a"
      url: "https://pub.dev"
    source: hosted
    version: "1.1.1"
  win32:
    dependency: transitive
    description:
      name: win32
      sha256: a0b93865d5644f11cf6a8c3f6db909f1ec168958b5805f6cc684adea957cd63d
      url: "https://pub.dev"
    source: hosted
    version: "6.4.0"
  xdg_directories:
    dependency: transitive
    description:
      name: xdg_directories
      sha256: "7a3f37b05d989967cdddcbb571f1ea834867ae2faa29725fd085180e0883aa15"
      url: "https://pub.dev"
    source: hosted
    version: "1.1.0"
  xml:
    dependency: transitive
    description:
      name: xml
      sha256: "67f0aff7be013d107995e9b75bf4e7f2c3ef2dfdb2c8e68024bba0a7fd5756a4"
      url: "https://pub.dev"
    source: hosted
    version: "7.0.1"
  yaml:
    dependency: transitive
    description:
      name: yaml
      sha256: f67cdd8e07d3c6329146aaef1ba043542b3134c12489f553ca9a7435d1068aea
      url: "https://pub.dev"
    source: hosted
    version: "3.1.4"
sdks:
  dart: ">=3.12.0 <4.0.0"
  flutter: ">=3.44.0"

```

### firebase.json

```json
{
  "flutter": {
    "platforms": {
      "android": {
        "default": {
          "projectId": "tcc-completai",
          "appId": "1:194760798085:android:1cd28a6df6f78171af5eec",
          "fileOutput": "android/app/google-services.json"
        }
      },
      "dart": {
        "lib/firebase_options.dart": {
          "projectId": "tcc-completai",
          "configurations": {
            "android": "1:194760798085:android:1cd28a6df6f78171af5eec"
          }
        }
      }
    }
  },
  "firestore": {
    "rules": "firestore.rules"
  }
}

```

### firestore.rules

```text
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // ---------- Helpers ----------
    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(uid) {
      return isSignedIn() && request.auth.uid == uid;
    }

    // Mitigação do P0 do projeto anterior: um uid não pode assumir os dois
    // papéis (cliente e posto) ao mesmo tempo.
    function noConflictingRole(uid) {
      return !exists(/databases/$(database)/documents/gas_stations/$(uid)) ||
             !exists(/databases/$(database)/documents/users/$(uid));
    }

    // Verdadeiro somente se o token tiver a custom claim "admin: true",
    // atribuída manualmente via script Admin SDK local (ver ADMIN.md).
    // Não depende de Cloud Functions nem de documento gravável pelo cliente.
    function isAdmin() {
      return isSignedIn() && request.auth.token.admin == true;
    }

    // ---------- users (privado) ----------
    match /users/{uid} {
      allow read: if isOwner(uid);
      allow create: if isOwner(uid)
                    && request.resource.data.type == 'client'
                    && noConflictingRole(uid);
      allow update: if isOwner(uid) && request.resource.data.type == 'client';
      allow delete: if isOwner(uid);

      match /favorites/{stationId} {
        allow read, write: if isOwner(uid);
      }
    }

    // ---------- gas_stations (privado, dados sensíveis) ----------
    match /gas_stations/{uid} {
      allow read: if isOwner(uid);
      allow create: if isOwner(uid)
                    && request.resource.data.type == 'gas_station'
                    && noConflictingRole(uid);
      allow update: if isOwner(uid) && request.resource.data.type == 'gas_station';
      allow delete: if isOwner(uid);
    }

    // ---------- public_stations (leitura pública) ----------
    match /public_stations/{uid} {
      allow read: if true;
      allow create, update: if isOwner(uid)
                             && request.resource.data.city == 'Bebedouro'
                             && request.resource.data.services.size() <= 20
                             && request.resource.data.tags.size() <= 20;
      allow delete: if isOwner(uid);

      match /reviews/{clientUid} {
        allow read: if true;
        allow create: if isOwner(clientUid)
                      && request.resource.data.rating >= 1
                      && request.resource.data.rating <= 5;
        allow update: if isOwner(clientUid)
                      && request.resource.data.rating >= 1
                      && request.resource.data.rating <= 5;
        allow delete: if isOwner(clientUid);

        match /reports/{reporterUid} {
          allow read: if isAdmin();
          allow create: if isOwner(reporterUid);
          allow update: if isAdmin();
          allow delete: if isAdmin();
        }
      }
    }

    // ---------- station_reports (denúncia de posto) ----------
    match /station_reports/{stationUid}/{reporterUid} {
      allow read: if isAdmin();
      allow create: if isOwner(reporterUid);
      allow update: if isAdmin();
      allow delete: if isAdmin();
    }
  }
}

```

### android/app/src/main/AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Firebase e autenticação precisam de rede também em release. -->
    <uses-permission android:name="android.permission.INTERNET" />
    <application
        android:label="completai"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <!-- Specifies an Android theme to apply to this Activity as soon as
                 the Android process has started. This theme is visible to the user
                 while the Flutter UI initializes. After that, this theme continues
                 to determine the Window background behind the Flutter UI. -->
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    <!-- Required to query activities that can process text, see:
         https://developer.android.com/training/package-visibility and
         https://developer.android.com/reference/android/content/Intent#ACTION_PROCESS_TEXT.

         In particular, this is used by the Flutter engine in io.flutter.plugin.text.ProcessTextPlugin. -->
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>

```

### docs/bootstrap-plan.md

```text
# Plano do bootstrap CompletAI

Documento de execução baseado em ARCHITECTURE.md, SCHEMA-FIRESTORE.md e ADMIN.md.

- Instalar dependências preservando a configuração FlutterFire existente.
- Criar domínio de auth, contratos e testes de loading, falha, sessão e cache.
- Implementar serviços Firebase/Google, perfil com exclusividade e batch de posto.
- Implementar Repository com cache por UID e tradução de erros; AsyncNotifier sem Flutter.
- Criar tokens ajustáveis, AppButton e AppTextField; inicializar Firebase e ProviderScope.
- Manter diretórios vazios com .gitkeep, incluindo a estrutura futura de admin.
- Preservar firestore.rules literalmente; documentar incompatibilidades encontradas.
- Executar dart format, flutter analyze e flutter test; entregar árvore e fontes completas.

Decisões: conta Auth e conclusão do perfil são operações separadas para permitir
retomada após falha. Papel ausente significa cadastro pendente. Admin é uma claim,
independente do papel cliente/posto. Não há exclusão de conta neste bootstrap:
ela exige limpeza recursiva e revisão das permissões antes de ser disponibilizada.
Paleta verde, tipografia Roboto e nomes auxiliares são sugestões ajustáveis.

```

