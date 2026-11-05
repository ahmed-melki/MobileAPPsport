import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../data/onboarding_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/onboarding_view_models.dart';
import '../../widgets/widgets.dart';
import 'recommended_programs_screen.dart';

class OnboardingFlowScreen extends StatelessWidget {
  const OnboardingFlowScreen({super.key, required this.onFinished, this.initialValues});

  final VoidCallback onFinished;
  final OnboardingPayload? initialValues;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => OnboardingViewModel(context.read<AppRepositories>().profile, initial: initialValues),
        child: _OnboardingView(onFinished: onFinished, initialValues: initialValues),
      );
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView({required this.onFinished, this.initialValues});
  final VoidCallback onFinished;
  final OnboardingPayload? initialValues;

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  late final _ageController = TextEditingController(text: widget.initialValues?.age.toString() ?? '25');
  late final _heightController = TextEditingController(text: widget.initialValues?.heightCm.toString() ?? '175');
  late final _weightController = TextEditingController(text: widget.initialValues?.weightKg.toString() ?? '70');

  OnboardingViewModel get vm => Provider.of<OnboardingViewModel>(context, listen: false);

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final recommendations = await vm.next(age: _ageController.text, height: _heightController.text, weight: _weightController.text);
    if (recommendations == null || !mounted) return;
    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) => RecommendedProgramsScreen(recommendations: recommendations, onFinished: widget.onFinished),
      ),
    );
  }

  void _back() {
    if (!vm.back()) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<OnboardingViewModel>();
    final progress = vm.progress;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        leading: ApexIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: vm.busy ? null : _back,
        ),
        title: Text('Étape ${vm.step + 1}/$OnboardingViewModel.totalSteps'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.volt),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepHeader(text),
                    const SizedBox(height: AppSpacing.lg),
                    _buildStepContent(text),
                    if (vm.error != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: 0.12),
                          borderRadius: AppRadii.mdAll,
                          border: Border.all(color: AppColors.coral.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.coral, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                vm.error!,
                                style: const TextStyle(color: AppColors.coral),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Bottom Action
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.sm,
                AppSpacing.screenH,
                AppSpacing.lg,
              ),
              child: ApexButton(
                label: vm.busy
                    ? 'Génération de tes programmes…'
                    : (vm.isLastStep ? 'Terminer et voir mes recommandations' : 'Suivant'),
                icon: vm.busy
                    ? null
                    : (vm.isLastStep ? Icons.auto_awesome_rounded : Icons.arrow_forward_rounded),
                onPressed: vm.busy ? null : _next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader(TextTheme text) {
    final title = switch (vm.step) {
      0 => 'Quel est ton sexe ?',
      1 => 'Quel est ton âge ?',
      2 => 'Morphologie de départ',
      3 => 'Ton objectif principal',
      4 => 'Ton niveau d\'expérience',
      5 => 'Rythme & matériel',
      _ => '',
    };

    final subtitle = switch (vm.step) {
      0 => 'Utilisé pour calibrer tes métabolismes et recommandations.',
      1 => 'Pour ajuster les volumes d\'effort et de récupération.',
      2 => 'Indique ta taille et ton poids pour calculer ta charge idéale.',
      3 => 'Choisis le moteur qui définira tes cycles d\'entraînement.',
      4 => 'Sois honnête avec toi-même pour éviter la surcharge.',
      5 => 'Sélectionne tes séances par semaine et ton équipement.',
      _ => '',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: text.headlineLarge),
        const SizedBox(height: 6),
        Text(subtitle, style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildStepContent(TextTheme text) {
    return switch (vm.step) {
      0 => _buildSexStep(text),
      1 => _buildAgeStep(text),
      2 => _buildHeightWeightStep(text),
      3 => _buildGoalStep(text),
      4 => _buildExperienceStep(text),
      5 => _buildFrequencyAndEquipmentStep(text),
      _ => const SizedBox.shrink(),
    };
  }

  // Step 1: Sex
  Widget _buildSexStep(TextTheme text) {
    return Column(
      children: [
        for (final sex in OnboardingSex.values) ...[
          _SelectableOptionCard(
            title: sex.label,
            icon: sex.icon,
            selected: vm.sex == sex,
            onTap: () => vm.setSex(sex),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  // Step 2: Age
  Widget _buildAgeStep(TextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ApexCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          tone: ApexCardTone.elevated,
          child: Column(
            children: [
              Text('Âge (années)', style: text.labelLarge?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: text.displaySmall?.copyWith(color: AppColors.volt, fontWeight: FontWeight.bold),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '25',
                  errorText: vm.fieldError('age'),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (_) => vm.clearError(),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Entre 14 et 90 ans',
                style: text.bodySmall?.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 3: Height & Weight
  Widget _buildHeightWeightStep(TextTheme text) {
    return Column(
      children: [
        ApexCard(
          tone: ApexCardTone.elevated,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.height_rounded, color: AppColors.volt, size: 22),
                  const SizedBox(width: 8),
                  Text('Taille', style: text.titleMedium),
                  const Spacer(),
                  Text('120 - 230 cm', style: text.labelSmall?.copyWith(color: AppColors.textTertiary)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Taille en centimètres',
                  suffixText: 'cm',
                  errorText: vm.fieldError('heightCm'),
                ),
                onChanged: (_) => vm.clearError(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ApexCard(
          tone: ApexCardTone.elevated,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.monitor_weight_outlined, color: AppColors.cyan, size: 22),
                  const SizedBox(width: 8),
                  Text('Poids de corps', style: text.titleMedium),
                  const Spacer(),
                  Text('30 - 300 kg', style: text.labelSmall?.copyWith(color: AppColors.textTertiary)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Poids en kilogrammes',
                  suffixText: 'kg',
                  errorText: vm.fieldError('weightKg'),
                ),
                onChanged: (_) => vm.clearError(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 4: Main Goal
  Widget _buildGoalStep(TextTheme text) {
    return Column(
      children: [
        for (final goal in OnboardingGoal.values) ...[
          ApexCard(
            tone: vm.mainGoal == goal ? ApexCardTone.glow : ApexCardTone.standard,
            accent: vm.mainGoal == goal ? goal.accent : null,
            onTap: () => vm.setGoal(goal),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: goal.accent.withValues(alpha: 0.15),
                    borderRadius: AppRadii.mdAll,
                    border: Border.all(color: goal.accent.withValues(alpha: 0.4)),
                  ),
                  child: Icon(goal.icon, color: goal.accent, size: 26),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.label,
                        style: text.titleMedium?.copyWith(
                          color: vm.mainGoal == goal ? AppColors.textPrimary : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal.description,
                        style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: vm.mainGoal == goal ? goal.accent : AppColors.border,
                      width: 2,
                    ),
                    color: vm.mainGoal == goal ? goal.accent : Colors.transparent,
                  ),
                  child: vm.mainGoal == goal
                      ? const Icon(Icons.check, size: 16, color: AppColors.voidBlack)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  // Step 5: Experience
  Widget _buildExperienceStep(TextTheme text) {
    return Column(
      children: [
        for (final exp in OnboardingExperience.values) ...[
          ApexCard(
            tone: vm.experience == exp ? ApexCardTone.glow : ApexCardTone.standard,
            accent: vm.experience == exp ? AppColors.volt : null,
            onTap: () => vm.setExperience(exp),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exp.label,
                        style: text.titleMedium?.copyWith(
                          color: vm.experience == exp ? AppColors.volt : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        exp.explanation,
                        style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: vm.experience == exp ? AppColors.volt : AppColors.border,
                      width: 2,
                    ),
                    color: vm.experience == exp ? AppColors.volt : Colors.transparent,
                  ),
                  child: vm.experience == exp
                      ? const Icon(Icons.check, size: 16, color: AppColors.voidBlack)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  // Step 6: Days per week & Equipment
  Widget _buildFrequencyAndEquipmentStep(TextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Séances par semaine', style: text.titleMedium),
        const SizedBox(height: 4),
        Text('Combien de fois peux-tu t\'entraîner chaque semaine ?', style: text.bodySmall),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            for (var d = 2; d <= 6; d++) ...[
              if (d > 2) const SizedBox(width: 8),
              Expanded(
                child: _DayCountCard(
                  days: d,
                  selected: vm.daysPerWeek == d,
                  onTap: () => vm.setDays(d),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Équipement disponible', style: text.titleMedium),
        const SizedBox(height: 4),
        Text('Où s\'effectuent tes entraînements ?', style: text.bodySmall),
        const SizedBox(height: AppSpacing.md),
        for (final eq in OnboardingEquipment.values) ...[
          _SelectableOptionCard(
            title: eq.label,
            icon: eq.icon,
            selected: vm.equipment == eq,
            onTap: () => vm.setEquipment(eq),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _SelectableOptionCard extends StatelessWidget {
  const _SelectableOptionCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ApexCard(
      tone: selected ? ApexCardTone.glow : ApexCardTone.standard,
      accent: selected ? AppColors.volt : null,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: selected ? AppColors.volt : AppColors.textTertiary, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: text.titleMedium?.copyWith(
                color: selected ? AppColors.volt : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle_rounded, color: AppColors.volt, size: 22),
        ],
      ),
    );
  }
}

class _DayCountCard extends StatelessWidget {
  const _DayCountCard({
    required this.days,
    required this.selected,
    required this.onTap,
  });

  final int days;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.mdAll,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.volt.withValues(alpha: 0.16) : AppColors.surface,
            borderRadius: AppRadii.mdAll,
            border: Border.all(
              color: selected ? AppColors.volt : AppColors.border,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$days',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: selected ? AppColors.volt : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'j/sem.',
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? AppColors.volt : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
