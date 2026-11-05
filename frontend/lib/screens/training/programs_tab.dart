import 'package:flutter/material.dart';

import '../../data/training_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';

class ProgramsTab extends StatelessWidget {
  const ProgramsTab({
    super.key,
    required this.programs,
    required this.isMyLevel,
    required this.onOpenProgram,
    this.onOpenAi,
  });

  final List<TrainingProgram> programs;
  final bool Function(TrainingProgram program) isMyLevel;
  final ValueChanged<TrainingProgram> onOpenProgram;
  final VoidCallback? onOpenAi;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.xxxl,
      ),
      children: [
        if (onOpenAi != null) ...[
          ApexCard(
            tone: ApexCardTone.glow,
            accent: AppColors.volt,
            onTap: onOpenAi,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: AppColors.volt.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.volt),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Recommandation IA', style: text.titleMedium),
                  const SizedBox(height: 2),
                  Text('Plan, programmes et exercices selon ton objectif et ton niveau.', style: text.bodySmall),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.volt),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(
          'Les programmes de ton niveau sont en premier : charges et exercices adaptés.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final program in programs) ...[
          ApexCard(
            tone: ApexCardTone.glow,
            accent: AppColors.cyan,
            onTap: () => onOpenProgram(program),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.14),
                        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.pill)),
                      ),
                      child: Text(
                        levelLabel(program.level),
                        style: text.labelMedium?.copyWith(color: AppColors.cyan),
                      ),
                    ),
                    if (isMyLevel(program)) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.volt.withValues(alpha: 0.16),
                          borderRadius: const BorderRadius.all(Radius.circular(AppRadii.pill)),
                        ),
                        child: Text('Ton niveau', style: text.labelMedium?.copyWith(color: AppColors.volt)),
                      ),
                    ],
                    const Spacer(),
                    Icon(Icons.bolt_rounded, color: AppColors.cyan.withValues(alpha: 0.8)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(program.title, style: text.headlineSmall),
                const SizedBox(height: 4),
                Text(program.subtitle, style: text.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${program.weeks} sem.  ·  ${program.daysPerWeek} j / sem.  ·  ${program.sessionIds.length} séances type',
                  style: text.labelMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
