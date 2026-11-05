import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../core/date_format.dart';
import '../../data/nutrition_models.dart' show fmtNum;
import '../../data/training_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/training_view_models.dart';
import '../../widgets/widgets.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exercise, required this.onStartExpress});

  final CatalogExercise exercise;
  final VoidCallback onStartExpress;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => ExerciseDetailViewModel(context.read<AppRepositories>().exercises, exercise)..load(),
        child: _ExerciseDetailView(onStartExpress: onStartExpress),
      );
}

class _ExerciseDetailView extends StatelessWidget {
  const _ExerciseDetailView({required this.onStartExpress});
  final VoidCallback onStartExpress;

  Future<void> _openVideo(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok) messenger.showSnackBar(const SnackBar(content: Text('Impossible d’ouvrir la vidéo.')));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<ExerciseDetailViewModel>();
    final ex = vm.exercise;
    final detail = vm.detail;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.xxxl),
          children: [
            Row(children: [
              ApexIconButton(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              Expanded(child: Text(ex.name, style: text.headlineMedium)),
            ]),
            const SizedBox(height: AppSpacing.md),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ApexChip(label: ex.category.label, selected: true, accent: ex.category.accent),
              ApexChip(label: ex.muscleGroupLabel, selected: true, accent: AppColors.cyan),
              ApexChip(label: levelLabel(ex.level), accent: AppColors.violet, selected: true),
              if (ex.atHome) const ApexChip(label: '🏠 Maison', accent: AppColors.mint, selected: true),
            ]),
            const SizedBox(height: AppSpacing.lg),
            ApexCard(
              tone: ApexCardTone.glow,
              accent: ex.category.accent,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('POINT CLÉ', style: text.labelSmall),
                const SizedBox(height: 8),
                Text(ex.cue, style: text.bodyLarge),
              ]),
            ),
            const SizedBox(height: AppSpacing.md),
            ApexButton(label: 'Voir la vidéo de technique', icon: Icons.play_circle_outline_rounded, variant: ApexButtonVariant.secondary, onPressed: () => _openVideo(context, vm.videoUrl)),
            if (ex.instructions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Exécution', style: text.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (var i = 0; i < ex.instructions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: ex.category.accent.withValues(alpha: 0.18),
                      child: Text('${i + 1}', style: text.labelSmall?.copyWith(color: ex.category.accent)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(ex.instructions[i], style: text.bodyMedium)),
                  ]),
                ),
            ],
            const SizedBox(height: AppSpacing.md),
            ApexCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Matériel', style: text.labelSmall),
                const SizedBox(height: 6),
                Text(ex.equipment, style: text.titleMedium),
                const SizedBox(height: AppSpacing.md),
                Text('Muscles', style: text.labelSmall),
                const SizedBox(height: 6),
                Text(ex.muscles, style: text.titleMedium),
              ]),
            ),
            const SizedBox(height: AppSpacing.md),
            ApexCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Mes performances', style: text.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                if (vm.loading)
                  const LinearProgressIndicator(minHeight: 2, color: AppColors.volt)
                else if (detail == null || detail.history.isEmpty)
                  Text('Pas encore réalisé. Lance une séance express pour enregistrer ta première perf !', style: text.bodySmall)
                else ...[
                  Row(children: [
                    if (detail.personalBestKg != null && detail.personalBestKg! > 0)
                      Expanded(child: ApexStat(value: fmtNum(detail.personalBestKg!), unit: 'kg', label: 'Record', accent: AppColors.volt)),
                    if (detail.personalBestKg != null && detail.personalBestKg! > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(child: ApexStat(value: '${detail.timesPerformed}', label: 'Séances', accent: AppColors.cyan)),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  for (final h in detail.history)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        SizedBox(width: 64, child: Text(h.date != null ? formatShortDate(h.date!) : '', style: text.labelSmall)),
                        Expanded(child: Text(h.summary, style: text.bodyMedium)),
                        if (h.volumeKg > 0) Text('${fmtNum(h.volumeKg.round())} kg vol.', style: text.labelSmall?.copyWith(color: AppColors.cyan)),
                      ]),
                    ),
                ],
              ]),
            ),
            const SizedBox(height: AppSpacing.xl),
            ApexButton(
              label: 'Séance express',
              icon: Icons.play_arrow_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                onStartExpress();
              },
            ),
          ],
        ),
      ),
    );
  }
}
