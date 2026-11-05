import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../data/onboarding_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/onboarding_view_models.dart';
import '../../widgets/widgets.dart';

class RecommendedProgramsScreen extends StatelessWidget {
  const RecommendedProgramsScreen({super.key, required this.recommendations, required this.onFinished});
  final List<RecommendedProgramItem> recommendations;
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => RecommendedProgramsViewModel(context.read<AppRepositories>().profile, recommendations),
        child: _RecommendedProgramsView(onFinished: onFinished),
      );
}

class _RecommendedProgramsView extends StatelessWidget {
  const _RecommendedProgramsView({required this.onFinished});
  final VoidCallback onFinished;

  Future<void> _startProgram(BuildContext context, RecommendedProgramItem program) async {
    final ok = await context.read<RecommendedProgramsViewModel>().start(program);
    if (ok) onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<RecommendedProgramsViewModel>();
    final topThree = vm.topThree;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Recommandations'),
        actions: [
          TextButton(
            onPressed: onFinished,
            child: const Text('Passer', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.sm,
            AppSpacing.screenH,
            AppSpacing.xxxl,
          ),
          children: [
            Text(
              'Programmes recommandés',
              style: text.headlineLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Basé sur ton profil, tes objectifs et ton rythme d\'entraînement.',
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            if (vm.error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.12),
                  borderRadius: AppRadii.mdAll,
                  border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.coral, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(vm.error!, style: const TextStyle(color: AppColors.coral))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (topThree.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.fitness_center_outlined, color: AppColors.textTertiary, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun programme trouvé pour ces critères.',
                        style: text.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ApexButton(
                        label: 'Aller au Hub',
                        onPressed: onFinished,
                      ),
                    ],
                  ),
                ),
              )
            else
              for (var i = 0; i < topThree.length; i++) ...[
                _ProgramRecommendationCard(
                  program: topThree[i],
                  isFirst: i == 0,
                  isLoading: vm.startingSlug == topThree[i].id,
                  onStart: () => _startProgram(context, topThree[i]),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
          ],
        ),
      ),
    );
  }
}

class _ProgramRecommendationCard extends StatelessWidget {
  const _ProgramRecommendationCard({
    required this.program,
    required this.isFirst,
    required this.isLoading,
    required this.onStart,
  });

  final RecommendedProgramItem program;
  final bool isFirst;
  final bool isLoading;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ApexCard(
      tone: isFirst ? ApexCardTone.glow : ApexCardTone.standard,
      accent: isFirst ? AppColors.volt : null,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFirst)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'MEILLEURE CORRESPONDANCE',
                          style: text.labelSmall?.copyWith(
                            color: AppColors.volt,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    Text(
                      program.title,
                      style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.volt.withValues(alpha: 0.16),
                  borderRadius: AppRadii.smAll,
                  border: Border.all(color: AppColors.volt.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 14, color: AppColors.volt),
                    const SizedBox(width: 2),
                    Text(
                      '${program.score}%',
                      style: text.labelMedium?.copyWith(
                        color: AppColors.volt,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            program.subtitle,
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _BadgePill(icon: Icons.calendar_today_rounded, label: '${program.weeks} sem.'),
              _BadgePill(icon: Icons.repeat_rounded, label: '${program.daysPerWeek}j / sem.'),
              _BadgePill(
                icon: Icons.speed_rounded,
                label: switch (program.level.toLowerCase()) {
                  'beginner' => 'Débutant',
                  'intermediate' => 'Intermédiaire',
                  'expert' => 'Expert',
                  _ => program.level,
                },
              ),
            ],
          ),
          if (program.reasons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pourquoi ce programme :',
              style: text.labelSmall?.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 6),
            for (final reason in program.reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4, right: 8),
                      child: Icon(Icons.check_circle_rounded, size: 14, color: AppColors.volt),
                    ),
                    Expanded(
                      child: Text(
                        reason,
                        style: text.bodySmall?.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.md),
          ApexButton(
            label: isLoading ? 'Démarrage…' : 'Commencer ce programme',
            icon: Icons.play_arrow_rounded,
            onPressed: isLoading ? null : onStart,
          ),
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textTertiary),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
