// Placeholder até a home real (cliente/posto) existir. Apagar quando a etapa 2 do roadmap chegar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/domain/models/auth_session.dart';
import '../features/auth/presentation/providers/auth_providers.dart';

class HomePlaceholder extends ConsumerWidget {
  const HomePlaceholder({required this.session, super.key});
  final AuthSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text('Olá, ${session.email}')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Papel: ${session.role}'),
          if (session.isAdmin) const Text('(admin)'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () =>
                ref.read(sessionViewModelProvider.notifier).signOut(),
            child: const Text('Sair'),
          ),
        ],
      ),
    ),
  );
}