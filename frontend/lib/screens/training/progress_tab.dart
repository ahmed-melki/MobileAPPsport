import 'package:flutter/material.dart';

import '../../core/date_format.dart';
import '../../data/training_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';

class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key, required this.catalog});

  final TrainingCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hasHistory = catalog.logs.isNotEmpty;
    final hasProgress = catalog.lifts.any((lift) => lift.points.isNotEmpty);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.xxxl,
      ),
      children: [
        Text(
          'Ta charge max par séance et ton historique réel.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!hasProgress) const ApexCard(tone: ApexCardTone.muted, child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: Text('Aucune progression pour le moment')))),
        for (final lift in catalog.lifts.where((lift) => lift.points.isNotEmpty)) ...[
          ApexCard(
            tone: ApexCardTone.elevated,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(lift.name, style: text.titleMedium)),
                    Text(
                      '${lift.points.last} ${lift.unit}',
                      style: text.titleMedium?.copyWith(color: AppColors.cyan),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ApexSparkline(values: lift.points, color: AppColors.cyan, height: 72),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.lg),
        const ApexSectionHeader(title: 'Historique'),
        const SizedBox(height: AppSpacing.sm),
        if (!hasHistory) const ApexCard(tone: ApexCardTone.muted, child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: Text('Aucune séance enregistrée')))),
        for (final log in catalog.logs) ...[
          ApexCard(
            tone: ApexCardTone.muted,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(formatShortDate(log.date), style: text.labelMedium),
                    const Spacer(),
                    Text('${log.durationMin} min', style: text.bodySmall),
                  ],
                ),
                const SizedBox(height: 6),
                Text(log.sessionTitle, style: text.titleMedium),
                Text(log.programTitle, style: text.bodySmall),
                const SizedBox(height: 6),
                Text(
                  log.volumeKg > 0
                      ? '${log.highlight}  ·  ${log.volumeKg} kg volume'
                      : log.highlight,
                  style: text.labelMedium?.copyWith(color: AppColors.volt),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
