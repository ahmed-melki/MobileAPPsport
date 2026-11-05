import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/training_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/session_player_view_model.dart';
import '../../widgets/widgets.dart';

class SessionPlayerScreen extends StatelessWidget {
  const SessionPlayerScreen({
    super.key,
    required this.catalog,
    required this.session,
    required this.programTitle,
    required this.onComplete,
  });

  final TrainingCatalog catalog;
  final WorkoutSession session;
  final String programTitle;
  final Future<SessionLog> Function(List<Map<String, dynamic>> sets) onComplete;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => SessionPlayerViewModel(catalog: catalog, session: session, programTitle: programTitle, save: onComplete),
        child: const _SessionPlayerView(),
      );
}

class _SessionPlayerView extends StatelessWidget {
  const _SessionPlayerView();

  Future<void> _finish(BuildContext context) async {
    final vm = context.read<SessionPlayerViewModel>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final log = await vm.finish();
    if (log != null) {
      navigator.pop(log);
    } else if (vm.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(vm.error!)));
    }
  }

  void _completeSet(BuildContext context) {
    final done = context.read<SessionPlayerViewModel>().completeSet();
    if (done) _finish(context);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<SessionPlayerViewModel>();
    final rx = vm.rx;
    final exercise = vm.exercise;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                ApexIconButton(icon: Icons.close_rounded, onPressed: () => Navigator.of(context).maybePop()),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(vm.programTitle, style: text.labelSmall),
                    Text(vm.session.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleMedium),
                  ]),
                ),
              ]),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(99)),
                        child: LinearProgressIndicator(value: vm.progress, minHeight: 8, backgroundColor: AppColors.surface, color: AppColors.cyan),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Exercice ${vm.exerciseIndex + 1}/${vm.session.exercises.length}  ·  Série ${vm.setIndex + 1}/${rx.sets}',
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(exercise.name, style: text.displaySmall),
                      Text(exercise.cue, style: text.bodySmall),
                      const SizedBox(height: AppSpacing.lg),
                      if (vm.resting)
                        ApexCard(
                          tone: ApexCardTone.glow,
                          accent: AppColors.cyan,
                          child: Column(children: [
                            Text('TEMPS DE REPOS', style: text.labelSmall),
                            const SizedBox(height: 8),
                            Text('${vm.restLeft} s', style: text.displayMedium?.copyWith(color: AppColors.cyan)),
                            const SizedBox(height: AppSpacing.md),
                            ApexButton(label: 'Passer le repos', variant: ApexButtonVariant.secondary, onPressed: vm.skipRest),
                          ]),
                        )
                      else ...[
                        Row(children: [
                          Expanded(
                            child: _StepperCard(
                              label: vm.repsLabel,
                              value: vm.repsValue,
                              onMinus: () => vm.adjustReps(-1),
                              onPlus: () => vm.adjustReps(1),
                            ),
                          ),
                          if (vm.showLoad) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _StepperCard(
                                label: vm.loadLabel,
                                value: vm.loadValue,
                                onMinus: () => vm.adjustLoad(-2.5),
                                onPlus: () => vm.adjustLoad(2.5),
                              ),
                            ),
                          ],
                        ]),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          for (var i = 0; i < rx.sets; i++)
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: vm.sets[vm.exerciseIndex][i].done
                                    ? AppColors.volt
                                    : (i == vm.setIndex ? AppColors.cyan.withValues(alpha: 0.2) : AppColors.surface),
                                borderRadius: AppRadii.smAll,
                                border: Border.all(color: i == vm.setIndex ? AppColors.cyan : AppColors.border),
                              ),
                              child: Text(
                                '${i + 1}',
                                style: text.labelMedium?.copyWith(
                                  color: vm.sets[vm.exerciseIndex][i].done ? AppColors.textOnVolt : AppColors.textPrimary,
                                ),
                              ),
                            ),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
              if (!vm.resting)
                ApexButton(
                  label: vm.busy ? 'Enregistrement…' : 'Valider la série',
                  icon: Icons.check_rounded,
                  onPressed: vm.busy ? null : () => _completeSet(context),
                ),
              const SizedBox(height: AppSpacing.sm),
              ApexButton(
                label: 'Terminer la séance',
                variant: ApexButtonVariant.ghost,
                onPressed: vm.busy ? null : () => _finish(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepperCard extends StatelessWidget {
  const _StepperCard({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ApexCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          Text(
            label,
            style: text.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _RoundBtn(icon: Icons.remove, onTap: onMinus),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.headlineSmall,
                ),
              ),
              _RoundBtn(icon: Icons.add, onTap: onPlus),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}
