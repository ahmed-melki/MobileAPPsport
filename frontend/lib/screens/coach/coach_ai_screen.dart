import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../data/ai_coach_models.dart';
import '../../data/nutrition_models.dart';
import '../../data/training_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/coach_view_models.dart';
import '../../widgets/widgets.dart';
import '../nutrition/nutrition_module_screen.dart';
import '../nutrition/nutrition_sheets.dart';
import '../profile/profile_module_screen.dart';
import '../training/session_player_screen.dart';
import '../training/training_module_screen.dart';
import 'coach_chat_screen.dart';

/// Coach Apex — the AI plan of the day (View). Logic in [CoachViewModel].
class CoachAiScreen extends StatelessWidget {
  const CoachAiScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) {
          final repos = context.read<AppRepositories>();
          return CoachViewModel(repos.coach, repos.training)..load();
        },
        child: const _CoachView(),
      );
}

class _CoachView extends StatelessWidget {
  const _CoachView();

  Future<void> _startWorkout(BuildContext context, CoachWorkout workout) async {
    final vm = context.read<CoachViewModel>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final catalog = await vm.prepareWorkout();
    if (catalog == null) {
      messenger.showSnackBar(SnackBar(content: Text(vm.error ?? 'Erreur')));
      return;
    }
    final log = await navigator.push<SessionLog>(
      MaterialPageRoute(
        builder: (_) => SessionPlayerScreen(
          catalog: catalog,
          session: workout.toWorkoutSession(),
          programTitle: workout.programTitle,
          onComplete: (sets) => vm.saveWorkout(workout, sets),
        ),
      ),
    );
    if (log != null) {
      messenger.showSnackBar(const SnackBar(content: Text('Séance enregistrée 💪')));
      vm.load();
    }
  }

  Future<void> _open(BuildContext context, Widget screen) async {
    final vm = context.read<CoachViewModel>();
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    vm.load();
  }

  void _onTask(BuildContext context, CoachTask task) {
    final vm = context.read<CoachViewModel>();
    final plan = vm.plan!;
    switch (task.action) {
      case 'workout':
        if (plan.isTrainingDay && plan.workout != null && !task.done) _startWorkout(context, plan.workout!);
      case 'program':
        _open(context, const TrainingModuleScreen());
      case 'nutrition':
        _open(context, const NutritionModuleScreen());
      case 'water':
        vm.addGlass(1);
      case 'measure':
        _open(context, const ProfileModuleScreen());
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<CoachViewModel>();
    final plan = vm.plan;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      floatingActionButton: plan == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.violet,
              foregroundColor: AppColors.textOnVolt,
              icon: const Icon(Icons.chat_bubble_rounded),
              label: const Text('Parler au coach'),
              onPressed: () => _open(context, CoachChatScreen(firstName: plan.firstName)),
            ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.sm),
            child: Row(children: [
              ApexIconButton(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Coach Apex', style: text.labelSmall?.copyWith(color: AppColors.violet)),
                  Text('Ton plan du jour', style: text.headlineMedium),
                ]),
              ),
              ApexIconButton(icon: Icons.refresh_rounded, onPressed: vm.load),
            ]),
          ),
          Expanded(
            child: vm.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.violet))
                : plan == null
                    ? Center(child: TextButton.icon(onPressed: vm.load, icon: const Icon(Icons.refresh), label: Text(vm.error ?? 'Réessayer')))
                    : RefreshIndicator(
                        color: AppColors.violet,
                        onRefresh: vm.load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.sm, AppSpacing.screenH, 110),
                          children: [
                            _MessageCard(plan: plan),
                            const SizedBox(height: AppSpacing.md),
                            Row(children: [
                              Expanded(child: ApexStat(value: '${plan.readiness}', unit: '%', label: 'Readiness', accent: AppColors.volt)),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(child: ApexStat(value: '${plan.weeklySessions}/${plan.weeklyTarget}', label: 'Semaine', accent: AppColors.cyan)),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(child: ApexStat(value: '${plan.streakDays}', unit: 'j', label: 'Streak', accent: AppColors.violet)),
                            ]),
                            const SizedBox(height: AppSpacing.xl),
                            Text('À faire aujourd’hui', style: text.headlineSmall),
                            const SizedBox(height: AppSpacing.sm),
                            for (final task in plan.tasks) ...[
                              _TaskTile(
                                task: task.id == 'water'
                                    ? CoachTask(
                                        id: task.id,
                                        title: task.title,
                                        detail: '${vm.glasses} verre(s) de 25 cl · ${vm.waterLiters.toStringAsFixed(2).replaceAll('.', ',')} L',
                                        icon: task.icon,
                                        done: vm.waterDone,
                                        action: task.action,
                                      )
                                    : task,
                                onTap: () => _onTask(context, task),
                                trailing: task.id == 'water'
                                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                                        IconButton(onPressed: () => vm.addGlass(-1), icon: const Icon(Icons.remove_circle_outline, color: AppColors.textTertiary)),
                                        IconButton(onPressed: () => vm.addGlass(1), icon: const Icon(Icons.add_circle_rounded, color: AppColors.cyan)),
                                      ])
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                            ],
                            const SizedBox(height: AppSpacing.xl),
                            if (plan.workout != null && plan.dayType != 'no_program')
                              _WorkoutCard(
                                plan: plan,
                                starting: vm.starting,
                                onStart: plan.isTrainingDay ? () => _startWorkout(context, plan.workout!) : null,
                              ),
                            if (plan.dayType == 'no_program')
                              ApexCard(
                                tone: ApexCardTone.glow,
                                accent: AppColors.volt,
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('PROGRAMME CONSEILLÉ', style: text.labelSmall?.copyWith(color: AppColors.volt)),
                                  const SizedBox(height: 6),
                                  Text(plan.recommendedProgramTitle ?? 'Full body débutant', style: text.headlineSmall),
                                  const SizedBox(height: AppSpacing.md),
                                  ApexButton(label: 'Voir les programmes', icon: Icons.bolt_rounded, onPressed: () => _open(context, const TrainingModuleScreen())),
                                ]),
                              ),
                            if (plan.recoveryItems.isNotEmpty && !plan.isTrainingDay) ...[
                              const SizedBox(height: AppSpacing.md),
                              _RecoveryCard(plan: plan),
                            ],
                            const SizedBox(height: AppSpacing.xl),
                            _NutritionCard(plan: plan, onOpen: () => _open(context, const NutritionModuleScreen())),
                            const SizedBox(height: AppSpacing.sm),
                            for (final recipe in plan.suggestions) ...[
                              _SuggestionTile(
                                recipe: recipe,
                                onTap: () async {
                                  final added = await showRecipeSheet(context, recipe: recipe, day: DateTime.now());
                                  if (added == true) vm.load();
                                },
                              ),
                              const SizedBox(height: AppSpacing.xs),
                            ],
                            if (plan.tips.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xl),
                              Text('Conseils du coach', style: text.headlineSmall),
                              const SizedBox(height: AppSpacing.sm),
                              for (final tip in plan.tips)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    const Icon(Icons.lightbulb_outline_rounded, color: AppColors.amber, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(tip, style: text.bodyMedium)),
                                  ]),
                                ),
                            ],
                          ],
                        ),
                      ),
          ),
        ]),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.plan});
  final DailyPlan plan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ai = plan.source == 'ai';
    return ApexCard(
      tone: ApexCardTone.glow,
      accent: AppColors.violet,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.violet.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.violet),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(plan.headline, style: text.titleLarge)),
        ]),
        const SizedBox(height: AppSpacing.md),
        Text(plan.message, style: text.bodyLarge),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(6)),
          child: Text(
            ai ? 'Généré par l’IA à partir de tes données' : 'Calculé à partir de tes données',
            style: text.labelSmall?.copyWith(color: ai ? AppColors.violet : AppColors.textTertiary),
          ),
        ),
      ]),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.onTap, this.trailing});
  final CoachTask task;
  final VoidCallback onTap;
  final Widget? trailing;

  IconData get _icon => switch (task.icon) {
        'bolt' => Icons.bolt_rounded,
        'egg' => Icons.egg_alt_outlined,
        'restaurant' => Icons.restaurant_rounded,
        'water' => Icons.water_drop_outlined,
        'scale' => Icons.monitor_weight_outlined,
        'bed' => Icons.bedtime_outlined,
        'spa' => Icons.self_improvement_rounded,
        _ => Icons.check_circle_outline,
      };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = task.done ? AppColors.mint : AppColors.textSecondary;
    return ApexCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Icon(task.done ? Icons.check_circle_rounded : _icon, color: task.done ? AppColors.mint : AppColors.violet),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              task.title,
              style: text.titleSmall?.copyWith(decoration: task.done ? TextDecoration.lineThrough : null, color: task.done ? AppColors.textSecondary : null),
            ),
            const SizedBox(height: 2),
            Text(task.detail, style: text.bodySmall?.copyWith(color: color)),
          ]),
        ),
        if (trailing != null) trailing! else if (!task.done) const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
      ]),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.plan, required this.starting, required this.onStart});
  final DailyPlan plan;
  final bool starting;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final w = plan.workout!;
    final label = switch (plan.dayType) {
      'training' => 'SÉANCE DU JOUR',
      'done' => 'PROCHAINE SÉANCE',
      _ => 'PROCHAINE SÉANCE (après le repos)',
    };
    return ApexCard(
      tone: ApexCardTone.glow,
      accent: AppColors.cyan,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: text.labelSmall?.copyWith(color: AppColors.cyan)),
        const SizedBox(height: 6),
        Text(w.title, style: text.headlineSmall),
        Text('${w.programTitle} · ${w.durationMin} min · ${w.focus}', style: text.bodySmall),
        if (w.light) ...[
          const SizedBox(height: 8),
          Text('Readiness basse : charges réduites de 10 %.', style: text.bodySmall?.copyWith(color: AppColors.amber)),
        ],
        const SizedBox(height: AppSpacing.md),
        for (final e in w.exercises)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(color: AppColors.cyan, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(e.name, style: text.titleSmall)),
                    Text(e.prescription, style: text.labelLarge?.copyWith(color: AppColors.cyan)),
                  ]),
                  if (e.suggestion != null) ...[
                    const SizedBox(height: 2),
                    Text(e.suggestion!, style: text.bodySmall?.copyWith(color: AppColors.violet)),
                  ],
                ]),
              ),
            ]),
          ),
        if (onStart != null) ...[
          const SizedBox(height: AppSpacing.sm),
          ApexButton(
            label: starting ? 'Chargement…' : 'Démarrer la séance',
            icon: Icons.play_arrow_rounded,
            onPressed: starting ? null : onStart,
          ),
        ],
      ]),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard({required this.plan});
  final DailyPlan plan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ApexCard(
      accent: AppColors.mint,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.self_improvement_rounded, color: AppColors.mint),
          const SizedBox(width: 8),
          Expanded(child: Text(plan.recoveryTitle ?? 'Récupération', style: text.titleMedium)),
        ]),
        const SizedBox(height: AppSpacing.sm),
        for (final item in plan.recoveryItems)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Expanded(child: Text(item.name, style: text.bodyMedium)),
              Text(item.detail, style: text.labelMedium?.copyWith(color: AppColors.mint)),
            ]),
          ),
        Text('+ 30 min de marche tranquille', style: text.bodySmall),
      ]),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  const _NutritionCard({required this.plan, required this.onOpen});
  final DailyPlan plan;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final kcal = plan.targetCalories > 0 ? (plan.consumedCalories / plan.targetCalories).clamp(0.0, 1.0) : 0.0;
    final prot = plan.targetProtein > 0 ? (plan.consumedProtein / plan.targetProtein).clamp(0.0, 1.0) : 0.0;
    return ApexCard(
      onTap: onOpen,
      accent: AppColors.mint,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Nutrition', style: text.titleMedium)),
          Text(plan.nextMeal != null ? 'Prochain : ${plan.nextMeal!.label}' : 'Journée complète', style: text.labelSmall?.copyWith(color: AppColors.mint)),
        ]),
        const SizedBox(height: AppSpacing.md),
        _bar(context, 'Calories', '${plan.consumedCalories} / ${plan.targetCalories} kcal', kcal, AppColors.mint),
        const SizedBox(height: AppSpacing.sm),
        _bar(context, 'Protéines', '${fmtNum(plan.consumedProtein.round())} / ${fmtNum(plan.targetProtein.round())} g', prot, AppColors.coral),
        if (plan.suggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Suggestions pour ton ${plan.nextMeal?.label.toLowerCase() ?? 'prochain repas'} :', style: text.bodySmall),
        ],
      ]),
    );
  }

  Widget _bar(BuildContext context, String label, String value, double progress, Color color) {
    final text = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label, style: text.labelMedium)),
        Text(value, style: text.labelMedium?.copyWith(color: color)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: progress, minHeight: 6, color: color, backgroundColor: color.withValues(alpha: 0.12)),
      ),
    ]);
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.recipe, required this.onTap});
  final NutritionRecipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ApexCard(
      onTap: onTap,
      tone: ApexCardTone.elevated,
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: recipe.accent.withValues(alpha: 0.15), borderRadius: AppRadii.mdAll),
          child: Icon(recipe.icon, color: recipe.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${recipe.isTunisian ? '🇹🇳 ' : ''}${recipe.name}', style: text.titleSmall),
            const SizedBox(height: 2),
            Text(recipe.reason ?? recipe.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodySmall),
          ]),
        ),
        const SizedBox(width: 8),
        Text('${recipe.calories}\nkcal', textAlign: TextAlign.right, style: text.labelLarge),
      ]),
    );
  }
}
