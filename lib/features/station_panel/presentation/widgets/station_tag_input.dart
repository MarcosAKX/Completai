// Campo de marcadores: digita, adiciona, e remove pelos chips.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';

class StationTagInput extends StatefulWidget {
  const StationTagInput({
    super.key,
    required this.tags,
    required this.onChanged,
    this.maxTags = 20,
  });

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final int maxTags;

  @override
  State<StationTagInput> createState() => _StationTagInputState();
}

class _StationTagInputState extends State<StationTagInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final value = _controller.text.trim().toLowerCase();
    if (value.isEmpty ||
        widget.tags.contains(value) ||
        widget.tags.length >= widget.maxTags) {
      return;
    }
    widget.onChanged([...widget.tags, value]);
    _controller.clear();
  }

  void _remove(String tag) =>
      widget.onChanged(widget.tags.where((t) => t != tag).toList());

  @override
  Widget build(BuildContext context) {
    final full = widget.tags.length >= widget.maxTags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                label: 'Novo marcador',
                controller: _controller,
                enabled: !full,
                hintText: full ? 'Limite atingido' : 'Ex.: 24 horas, rodovia',
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: IconButton.filledTonal(
                onPressed: full ? null : _add,
                icon: const Icon(Icons.add),
                tooltip: 'Adicionar',
              ),
            ),
          ],
        ),
        if (widget.tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final tag in widget.tags)
                Chip(
                  label: Text(tag),
                  onDeleted: () => _remove(tag),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
