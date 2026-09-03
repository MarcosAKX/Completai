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
    onGenerateRoute: AppRoutes.onGenerateRoute,
    initialRoute: AppRoutes.login,
  );
}
