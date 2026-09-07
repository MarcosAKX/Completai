// Formulário compacto para uma avaliação por cliente e por posto.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';

class StationReviewDraft {
  const StationReviewDraft({required this.rating, required this.comment});

  final int rating;
  final String comment;
}

class StationReviewSheet extends StatefulWidget {
  const StationReviewSheet({super.key});

  @override
  State<StationReviewSheet> createState() => _StationReviewSheetState();
}

class _StationReviewSheetState extends State<StationReviewSheet> {
  final _comment = TextEditingController();
  var _rating = 0;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Avaliar posto',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Sua avaliação ajuda outros motoristas.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: 'Nota $_rating de 5',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var value = 1; value <= 5; value++)
                  IconButton(
                    tooltip: '$value estrelas',
                    onPressed: () => setState(() => _rating = value),
                    icon: Icon(
                      value <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppColors.accent,
                      size: 34,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _comment,
            maxLength: 500,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Comentário (opcional)',
              hintText: 'Conte como foi sua experiência',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Publicar avaliação',
            onPressed: _rating == 0
                ? null
                : () => Navigator.pop(
                    context,
                    StationReviewDraft(rating: _rating, comment: _comment.text),
                  ),
          ),
        ],
      ),
    ),
  );
}
