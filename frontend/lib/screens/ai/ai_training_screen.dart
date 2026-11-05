import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../data/ai_recommendation_models.dart';
import '../../data/training_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/ai_recommendation_view_models.dart';
import '../../widgets/widgets.dart';
import 'ai_widgets.dart';

/// AI training recommendation (View). Returns the id of a program when the user taps "Voir le programme".
class AiTrainingScreen extends StatelessWidget {
  const AiTrainingScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => AiTrainingViewModel(context.read<AppRepositories>().coach)..load(),
        child: const _AiTrainingView(),
      );
}

class _AiTrainingView extends StatelessWidget {
  const _AiTrainingView();

  static const _accent = AppColors.cyan;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AiTrainingViewModel>();
    final advice = vm.advice;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(children: [
          AiHeader(overline: 'Coach IA · entraînement', title: 'Ton plan sur mesure', accent: _accent, onRefresh: vm.load),
          Expanded(
            child: advice == null
                ? AiStateView(loading: vm.loading, error: vm.error, onRetry: vm.load, accent: _accent)
                : RefreshIndicator(color: _accent, onRefresh: vm.load, child: _content(context, advice)),
          ),
        ]),
      ),
    );
  }

  Widget _content(BuildContext context, AiTrainingAdvice a) {
    final text = Theme.of(context).textTheme;
    final p = a.plan;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.xxxl),
      children: [
        AiSummaryCard(
          title: 'Analyse de ton profil',
          summary: a.summary,
          fromAi: a.fromAi,
          accent: _accent,
          chips: [a.goalLabel, a.levelLabel, '${p.daysPerWeek} séances / sem.'],
        ),
        const AiSectionTitle('Ton plan type'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 2.1,
          children: [
            _PlanTile(icon: Icons.layers_rounded, label: 'Séries', value: p.sets),
            _PlanTile(icon: Icons.repeat_rounded, label: 'Répétitions', value: p.reps),
            _PlanTile(icon: Icons.timer_outlined, label: 'Repos', value: p.rest),
            _PlanTile(icon: Icons.schedule_rounded, label: 'Durée', value: p.duration),
            _PlanTile(icon: Icons.fitness_center_rounded, label: 'Exercices / séance', value: '${p.exercisesPerSession}'),
            _PlanTile(icon: Icons.event_available_rounded, label: 'Fait cette semaine', value: '${a.sessionsLast7Days} / ${p.daysPerWeek}'),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _InfoRow(icon: Icons.speed_rounded, title: 'Intensité', body: p.intensity),
        const SizedBox(height: AppSpacing.sm),
        _InfoRow(icon: Icons.directions_run_rounded, title: 'Cardio', body: p.cardio),
        const AiSectionTitle('Programmes recommandés'),
        for (final program in a.programs) ...[
          ApexCard(
            tone: ApexCardTone.elevated,
            accent: _accent,
            onTap: () => Navigator.of(context).pop(program.id),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(program.title, style: text.titleMedium)),
                _Pill(label: levelLabel(program.level), color: _accent),
              ]),
              const SizedBox(height: 4),
              Text('${program.weeks} semaines · ${program.daysPerWeek} séances / semaine', style: text.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              for (final reason in program.reasons.take(3))
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.mint),
                    const SizedBox(width: 6),
                    Expanded(child: Text(reason, style: text.bodySmall)),
                  ]),
                ),
              const SizedBox(height: AppSpacing.sm),
              Text('Voir le programme →', style: text.labelMedium?.copyWith(color: _accent)),
            ]),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const AiSectionTitle('Exercices clés pour toi'),
        for (final e in a.exercises) ...[
          ApexCard(
            tone: ApexCardTone.standard,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.all(Radius.circular(AppRadii.md)),
                ),
                child: Icon(e.atHome ? Icons.home_rounded : Icons.fitness_center_rounded, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.name, style: text.titleSmall),
                  const SizedBox(height: 2),
                  Text(e.why, style: text.bodySmall),
                ]),
              ),
              Text(e.atHome ? 'Maison' : 'Salle', style: text.labelSmall?.copyWith(color: AppColors.textTertiary)),
            ]),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
        AiTipsCard(tips: a.tips, accent: _accent),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ApexCard(
      tone: ApexCardTone.elevated,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(children: [
        Icon(icon, size: 20, color: AppColors.cyan),
        const SizedBox(width: 10),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: text.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(value, style: text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ApexCard(
      tone: ApexCardTone.muted,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: AppColors.cyan, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: text.labelMedium?.copyWith(color: AppColors.cyan)),
            const SizedBox(height: 2),
            Text(body, style: text.bodyMedium),
          ]),
        ),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: const BorderRadius.all(Radius.circular(AppRadii.pill)),
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
      );
}
