// Formulário separado; mantém os dados digitados quando o salvamento falha.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/contact_input_formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/client_profile.dart';
import '../providers/client_profile_providers.dart';

class ClientProfileEditPage extends ConsumerStatefulWidget {
  const ClientProfileEditPage({required this.profile, super.key});
  final ClientProfile profile;
  @override
  ConsumerState<ClientProfileEditPage> createState() =>
      _ClientProfileEditPageState();
}

class _ClientProfileEditPageState extends ConsumerState<ClientProfileEditPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.name);
    _phone = TextEditingController(
      text: phoneMask(widget.profile.phone.replaceAll(RegExp(r'\D'), '')),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final ok = await ref
        .read(clientProfileViewModelProvider(widget.profile.uid).notifier)
        .save(name: _name.text, phone: _phone.text);
    if (!mounted) return;
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientProfileViewModelProvider(widget.profile.uid));
    return PopScope(
      canPop: !state.isLoading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Editar meus dados')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Nome completo',
                    controller: _name,
                    enabled: !state.isLoading,
                    textCapitalization: TextCapitalization.words,
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (value) =>
                        value == null ||
                            value.trim().isEmpty ||
                            value.trim().length > 100
                        ? 'Informe um nome com até 100 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Celular',
                    controller: _phone,
                    enabled: !state.isLoading,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [phoneInputFormatter],
                    prefixIcon: const Icon(Icons.phone_outlined),
                    validator: (value) {
                      final length = (value ?? '')
                          .replaceAll(RegExp(r'\D'), '')
                          .length;
                      return length < 10 || length > 11
                          ? 'Informe um celular com DDD.'
                          : null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (state.hasError) ...[
                    Text(
                      state.error.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  AppButton(
                    label: 'Salvar alterações',
                    isLoading: state.isLoading,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
