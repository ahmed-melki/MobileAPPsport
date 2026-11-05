import 'package:flutter/material.dart';

import '../../data/training_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';

class ProgramDetailScreen extends StatelessWidget {
  const ProgramDetailScreen({
    super.key,
    required this.catalog,
    required this.program,
    required this.onStartSession,
  });

  final TrainingCatalog catalog;
  final TrainingProgram program;
  final ValueChanged<WorkoutSession> onStartSession;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.md,
            AppSpacing.screenH,
            AppSpacing.xxxl,
          ),
          children: [
            Row(
              children: [
                ApexIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(program.title, style: text.headlineMedium)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            ApexCard(
              tone: ApexCardTone.glow,
              accent: AppColors.cyan,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(levelLabel(program.level).toUpperCase(), style: text.labelSmall),
                  const SizedBox(height: 8),
                  Text(program.subtitle, style: text.bodyLarge),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${program.weeks} semaines · ${program.daysPerWeek} séances / semaine',
                    style: text.titleSmall?.copyWith(color: AppColors.cyan),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const ApexSectionHeader(title: 'Séances'),
            const SizedBox(height: AppSpacing.sm),
            for (final id in program.sessionIds) ...[
              _SessionRow(
                session: catalog.sessionById(id),
                catalog: catalog,
                onStart: () => onStartSession(catalog.sessionById(id)),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.session,
    required this.catalog,
    required this.onStart,
  });

  final WorkoutSession session;
  final TrainingCatalog catalog;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final names = session.exercises.map((e) => catalog.exerciseById(e.exerciseId).name).join(' · ');
    final adapted = session.exercises.where((e) => e.adaptedFrom != null).length;

    return ApexCard(
      tone: ApexCardTone.elevated,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(session.title, style: text.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${session.durationMin} min  ·  ${session.focus}',
            style: text.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            names,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: AppColors.textPrimary),
          ),
          if (adapted > 0) ...[
            const SizedBox(height: 6),
            Text(
              '$adapted exercice(s) remplacé(s) par une variante adaptée à ton niveau',
              style: text.labelSmall?.copyWith(color: AppColors.amber),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          ApexButton(
            label: 'Démarrer la séance',
            icon: Icons.play_arrow_rounded,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}
