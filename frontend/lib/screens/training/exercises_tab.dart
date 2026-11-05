import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/profile_models.dart';

import '../../data/training_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/training_view_models.dart';
import '../../widgets/widgets.dart';

IconData muscleGroupIcon(String group) => switch (group) {
      'chest' => Icons.fitness_center_rounded,
      'back' => Icons.rowing_rounded,
      'shoulders' => Icons.accessibility_new_rounded,
      'arms' => Icons.sports_mma_rounded,
      'legs' => Icons.directions_walk_rounded,
      'glutes' => Icons.airline_seat_legroom_extra_rounded,
      'core' => Icons.center_focus_strong_rounded,
      'cardio' => Icons.directions_run_rounded,
      'mobility' => Icons.self_improvement_rounded,
      _ => Icons.bolt_rounded,
    };

/// Exercise library (View): filters live in [TrainingViewModel].
class ExercisesTab extends StatefulWidget {
  const ExercisesTab({super.key, required this.onOpenExercise});

  final ValueChanged<CatalogExercise> onOpenExercise;

  @override
  State<ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends State<ExercisesTab> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<TrainingViewModel>();
    final items = vm.exercises;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.xxxl),
      children: [
        TextField(
          controller: _search,
          onChanged: vm.setSearch,
          decoration: InputDecoration(
            hintText: 'Chercher un exercice, un muscle, du matériel…',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: vm.search.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _search.clear();
                      vm.setSearch('');
                    },
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            ApexChip(label: 'Tous', selected: vm.muscleGroup == null, accent: AppColors.cyan, onTap: () => vm.setMuscleGroup(null)),
            const SizedBox(width: 8),
            for (final g in vm.muscleGroups) ...[
              ApexChip(label: muscleGroupLabels[g]!, selected: vm.muscleGroup == g, accent: AppColors.cyan, onTap: () => vm.setMuscleGroup(g)),
              const SizedBox(width: 8),
            ],
          ]),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Niveau : ${vm.userLevel.label}', style: text.labelMedium?.copyWith(color: AppColors.volt)),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: vm.homeOnly,
          onChanged: vm.setHomeOnly,
          title: Text(vm.homeOnly ? 'À la maison' : 'En salle', style: text.titleSmall),
          subtitle: Text(
            vm.homeOnly ? 'Exercices sans matériel de salle' : 'Active pour voir les exercices à faire chez toi',
            style: text.bodySmall,
          ),
        ),
        Text('${items.length} exercice(s)', style: text.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: Center(child: Text('Aucun exercice ne correspond.', style: text.bodyMedium)),
          ),
        for (final ex in items) ...[
          ApexCard(
            tone: ApexCardTone.elevated,
            accent: ex.category.accent,
            onTap: () => widget.onOpenExercise(ex),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: ex.category.accent.withValues(alpha: 0.14), borderRadius: AppRadii.smAll),
                child: Icon(muscleGroupIcon(ex.muscleGroup), color: ex.category.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(ex.name, style: text.titleMedium, overflow: TextOverflow.ellipsis)),
                    if (ex.atHome) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.home_rounded, size: 14, color: AppColors.mint),
                    ],
                    if (!vm.isForMyLevel(ex)) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.amber),
                    ],
                  ]),
                  Text('${ex.muscleGroupLabel}  ·  ${ex.muscles}', maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
                  Text(
                    ex.neverDone ? '${levelLabel(ex.level)} · jamais fait' : 'Dernière fois : ${ex.lastPerf}',
                    style: text.labelMedium?.copyWith(color: ex.neverDone ? AppColors.textTertiary : AppColors.cyan),
                  ),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            ]),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
