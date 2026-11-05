import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../data/profile_models.dart';
import '../../data/training_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/training_view_models.dart';
import '../../widgets/widgets.dart';
import '../ai/ai_training_screen.dart';
import 'exercise_detail_screen.dart';
import 'exercises_tab.dart';
import 'program_detail_screen.dart';
import 'programs_tab.dart';
import 'progress_tab.dart';
import 'session_player_screen.dart';

class TrainingModuleScreen extends StatelessWidget {
  const TrainingModuleScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) {
          final repos = context.read<AppRepositories>();
          return TrainingViewModel(repos.training, repos.profile)..load();
        },
        child: const _TrainingView(),
      );
}

class _TrainingView extends StatelessWidget {
  const _TrainingView();

  Future<void> _play(BuildContext context, WorkoutSession session, String programTitle, String programId) async {
    final vm = context.read<TrainingViewModel>();
    final catalog = vm.catalog;
    if (catalog == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final log = await Navigator.of(context).push<SessionLog>(
      MaterialPageRoute(
        builder: (_) => SessionPlayerScreen(
          catalog: catalog,
          session: session,
          programTitle: programTitle,
          onComplete: (sets) => vm.saveSession(session, programId, sets),
        ),
      ),
    );
    if (log == null) return;
    vm.addLog(log);
    messenger.showSnackBar(const SnackBar(content: Text('Séance ajoutée à l\'historique')));
  }

  Future<void> _openExercise(BuildContext context, CatalogExercise exercise) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(
          exercise: exercise,
          onStartExpress: () => _play(context, expressSessionForExercise(exercise), 'Séance express', 'express'),
        ),
      ),
    );
  }

  Future<void> _openProgram(BuildContext context, TrainingProgram program) async {
    final catalog = context.read<TrainingViewModel>().catalog;
    if (catalog == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProgramDetailScreen(
          catalog: catalog,
          program: program,
          onStartSession: (session) => _play(context, session, program.title, program.id),
        ),
      ),
    );
  }

  /// AI recommendation; if the user picks a program there, open it.
  Future<void> _openAi(BuildContext context) async {
    final vm = context.read<TrainingViewModel>();
    final programId = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const AiTrainingScreen()));
    if (programId == null || !context.mounted) return;
    final program = vm.catalog?.programs.where((p) => p.id == programId).firstOrNull;
    if (program != null) await _openProgram(context, program);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<TrainingViewModel>();
    if (vm.loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final catalog = vm.catalog;
    if (catalog == null) {
      return Scaffold(body: Center(child: TextButton.icon(onPressed: vm.load, icon: const Icon(Icons.refresh), label: Text(vm.error ?? 'Réessayer'))));
    }
    const tabs = ['Exercices', 'Programmes', 'Progression'];

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.md),
            child: Row(children: [
              ApexIconButton(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Entraînement · niveau ${vm.userLevel.label.toLowerCase()}', style: text.labelSmall),
                  Text('Exercices & programmes', style: text.headlineMedium),
                ]),
              ),
              Icon(Icons.bolt_rounded, color: AppColors.cyan.withValues(alpha: 0.9)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadii.mdAll, border: Border.all(color: AppColors.border)),
              child: Row(children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(child: _TabPill(label: tabs[i], selected: vm.tab == i, onTap: () => vm.selectTab(i))),
              ]),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: vm.tab,
              children: [
                ExercisesTab(onOpenExercise: (e) => _openExercise(context, e)),
                ProgramsTab(
                  programs: vm.programs,
                  isMyLevel: vm.isMyLevel,
                  onOpenProgram: (p) => _openProgram(context, p),
                  onOpenAi: () => _openAi(context),
                ),
                ProgressTab(catalog: catalog),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: selected ? AppColors.cyan : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: selected ? AppColors.textOnVolt : AppColors.textSecondary),
          ),
        ),
      );
}
