import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../data/ai_recommendation_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/ai_recommendation_view_models.dart';
import '../../widgets/widgets.dart';
import 'ai_widgets.dart';

/// AI nutrition recommendation (View).
class AiNutritionScreen extends StatelessWidget {
  const AiNutritionScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => AiNutritionViewModel(context.read<AppRepositories>().coach)..load(),
        child: const _AiNutritionView(),
      );
}

class _AiNutritionView extends StatelessWidget {
  const _AiNutritionView();

  static const _accent = AppColors.mint;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AiNutritionViewModel>();
    final advice = vm.advice;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(children: [
          AiHeader(overline: 'Nutritionniste IA', title: 'Que manger aujourd’hui ?', accent: _accent, onRefresh: vm.load),
          Expanded(
            child: advice == null
                ? AiStateView(loading: vm.loading, error: vm.error, onRetry: vm.load, accent: _accent)
                : RefreshIndicator(color: _accent, onRefresh: vm.load, child: _content(context, vm, advice)),
          ),
        ]),
      ),
    );
  }

  Widget _content(BuildContext context, AiNutritionViewModel vm, AiNutritionAdvice a) {
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.xxxl),
      children: [
        AiSummaryCard(
          title: 'Bilan du jour',
          summary: a.summary,
          fromAi: a.fromAi,
          accent: _accent,
          chips: [a.goalLabel, 'Prochain repas : ${a.nextMealLabel}'],
        ),
        const AiSectionTitle('Où tu en es'),
        ApexCard(
          tone: ApexCardTone.elevated,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(children: [
            _MacroBar(label: 'Calories', unit: 'kcal', eaten: a.today.calories, target: a.targets.calories, color: _accent, progress: vm.progress(a.today.calories, a.targets.calories)),
            _MacroBar(label: 'Protéines', unit: 'g', eaten: a.today.protein, target: a.targets.protein, color: AppColors.coral, progress: vm.progress(a.today.protein, a.targets.protein)),
            _MacroBar(label: 'Glucides', unit: 'g', eaten: a.today.carbs, target: a.targets.carbs, color: AppColors.amber, progress: vm.progress(a.today.carbs, a.targets.carbs)),
            _MacroBar(label: 'Lipides', unit: 'g', eaten: a.today.fat, target: a.targets.fat, color: AppColors.violet, progress: vm.progress(a.today.fat, a.targets.fat)),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              const Icon(Icons.flag_rounded, size: 16, color: _accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Reste : ${a.remaining.calories.round()} kcal · ${a.remaining.protein.round()} g de protéines',
                  style: text.labelMedium?.copyWith(color: _accent),
                ),
              ),
            ]),
          ]),
        ),
        AiSectionTitle('Recettes pour ton ${a.nextMealLabel}'),
        for (final r in a.recipes) ...[
          ApexCard(
            tone: ApexCardTone.elevated,
            accent: _accent,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.all(Radius.circular(AppRadii.md)),
                  ),
                  child: const Icon(Icons.restaurant_rounded, color: _accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.name, style: text.titleSmall),
                    if (r.subtitle.isNotEmpty) Text(r.subtitle, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ]),
              const SizedBox(height: AppSpacing.sm),
              Wrap(spacing: 6, runSpacing: 6, children: [
                _Tag('${r.calories} kcal', _accent),
                _Tag('P ${r.protein.round()} g', AppColors.coral),
                _Tag('G ${r.carbs.round()} g', AppColors.amber),
                _Tag('L ${r.fat.round()} g', AppColors.violet),
                _Tag('${r.duration} min', AppColors.textSecondary),
              ]),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                const Icon(Icons.auto_awesome_rounded, size: 14, color: _accent),
                const SizedBox(width: 6),
                Expanded(child: Text(r.why, style: text.bodySmall)),
              ]),
            ]),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const AiSectionTitle('Aliments conseillés'),
        ApexCard(
          tone: ApexCardTone.standard,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Column(children: [
            for (final f in a.foods)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.eco_rounded, color: _accent),
                title: Text(f.name, style: text.titleSmall),
                subtitle: Text('${f.serving} · ${f.why}', style: text.bodySmall),
                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${f.calories} kcal', style: text.labelMedium),
                  Text('${f.protein.toStringAsFixed(0)} g prot.', style: text.labelSmall?.copyWith(color: AppColors.coral)),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        AiTipsCard(tips: a.tips, accent: _accent),
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({required this.label, required this.unit, required this.eaten, required this.target, required this.color, required this.progress});
  final String label;
  final String unit;
  final double eaten;
  final double target;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: text.labelMedium)),
          Text('${eaten.round()} / ${target.round()} $unit', style: text.labelMedium?.copyWith(color: color)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadii.pill)),
          child: LinearProgressIndicator(value: progress, minHeight: 8, color: color, backgroundColor: color.withValues(alpha: 0.12)),
        ),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: const BorderRadius.all(Radius.circular(AppRadii.pill)),
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
      );
}
