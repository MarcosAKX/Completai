// "Editar exibição": bandeira e foto que o cliente vê.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/cover_edit.dart';
import '../../../../shared/models/station_brand.dart';
import '../providers/station_panel_providers.dart';
import '../widgets/station_client_preview_card.dart';

class StationDisplayEditPage extends ConsumerStatefulWidget {
  const StationDisplayEditPage({super.key, this.imagePicker});

  /// Injeção para teste; em produção usa o `ImagePicker` padrão.
  final ImagePicker? imagePicker;

  @override
  ConsumerState<StationDisplayEditPage> createState() =>
      _StationDisplayEditPageState();
}

class _StationDisplayEditPageState
    extends ConsumerState<StationDisplayEditPage> {
  late StationBrand _brand;
  Uint8List? _pickedBytes;
  var _coverRemoved = false;
  var _saving = false;
  var _pickingImage = false;
  String? _error;

  ImagePicker get _picker => widget.imagePicker ?? ImagePicker();

  @override
  void initState() {
    super.initState();
    _brand =
        ref.read(stationPanelViewModelProvider).valueOrNull?.brand ??
        StationBrand.branca;
  }

  Future<void> _pickImage() async {
    setState(() {
      _pickingImage = true;
      _error = null;
    });
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
      );
      final bytes = await file?.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickingImage = false;
        if (bytes != null && bytes.isNotEmpty) {
          _pickedBytes = bytes;
          _coverRemoved = false;
        }
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _pickingImage = false;
        _error = 'Não foi possível abrir a galeria: $error';
      });
    }
  }

  Future<void> _save() async {
    final CoverEditKind edit;
    if (_pickedBytes != null) {
      edit = CoverEditKind.replace;
    } else if (_coverRemoved) {
      edit = CoverEditKind.remove;
    } else {
      edit = CoverEditKind.keep;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await ref
        .read(stationPanelViewModelProvider.notifier)
        .saveDisplay(
          brand: _brand,
          coverEdit: edit,
          coverBytes: _pickedBytes,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = false;
      _error =
          ref.read(stationPanelViewModelProvider).error?.toString() ??
          'Não foi possível salvar a exibição.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(stationPanelViewModelProvider).valueOrNull;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text('Editar exibição'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Editar exibição', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Escolha como o posto será apresentado para quem procura onde abastecer.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Bandeira', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<StationBrand>(
            initialValue: _brand,
            decoration: const InputDecoration(filled: true),
            items: [
              for (final brand in StationBrand.values)
                DropdownMenuItem(value: brand, child: Text(brand.label)),
            ],
            onChanged: (brand) =>
                setState(() => _brand = brand ?? _brand),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Foto do posto', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          StationClientPreviewCard(
            profile: profile.copyWith(brand: _brand),
            pendingCoverBytes: _pickedBytes,
            pendingCoverRemoved: _coverRemoved,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Substituir foto',
                  outlined: true,
                  isLoading: _pickingImage,
                  onPressed: _saving ? null : _pickImage,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Remover foto',
                  outlined: true,
                  onPressed: (_saving || (_pickedBytes == null && _coverRemoved))
                      ? null
                      : () => setState(() {
                          _pickedBytes = null;
                          _coverRemoved = true;
                        }),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
              ),
              child: Text(
                _error!,
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Salvar exibição',
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
