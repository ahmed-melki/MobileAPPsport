import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../data/profile_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/profile_view_model.dart';
import '../../widgets/widgets.dart';
import '../onboarding/onboarding_flow_screen.dart';
import 'goals_tab.dart';
import 'measures_tab.dart';
import 'profile_edit_screen.dart';
import 'profile_overview_tab.dart';

class ProfileModuleScreen extends StatelessWidget {
  const ProfileModuleScreen({super.key, this.onLogout});
  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => ProfileViewModel(context.read<AppRepositories>().profile)..load(),
        child: _ProfileView(onLogout: onLogout),
      );
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({this.onLogout});
  final Future<void> Function()? onLogout;

  Future<void> _run(BuildContext context, Future<void> Function(ProfileViewModel vm) action) async {
    final vm = context.read<ProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    await action(vm);
    final message = vm.takeMessage();
    if (message != null) messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit(BuildContext context, SportProfile profile) async {
    final updated = await Navigator.of(context).push<SportProfile>(
      MaterialPageRoute(builder: (_) => ProfileEditScreen(profile: profile)),
    );
    if (updated != null && context.mounted) await _run(context, (vm) => vm.saveProfile(updated));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<ProfileViewModel>();
    const tabs = ['Profil', 'Objectifs', 'Mesures'];

    if (vm.loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final data = vm.data;
    if (data == null) {
      return Scaffold(body: Center(child: TextButton.icon(onPressed: vm.load, icon: const Icon(Icons.refresh), label: Text(vm.error ?? 'Réessayer'))));
    }

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
                  Text('Utilisateurs', style: text.labelSmall),
                  Text('Profils sportifs', style: text.headlineMedium),
                ]),
              ),
              ApexAvatar(initials: data.profile.initials, size: 40),
              if (onLogout != null) ApexIconButton(icon: Icons.logout_rounded, onPressed: () => onLogout!()),
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
                ProfileOverviewTab(
                  profile: data.profile,
                  onEdit: () => _edit(context, data.profile),
                  onLevelChanged: (level) => _run(context, (vm) => vm.setLevel(level)),
                  onToggleSport: (sport) => _run(context, (vm) => vm.toggleSport(sport)),
                  onRedoOnboarding: () async {
                    // Keep the navigator: the onboarding route is replaced by the
                    // recommendations screen, so its own context is no longer valid.
                    final navigator = Navigator.of(context);
                    await navigator.push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => OnboardingFlowScreen(onFinished: () => navigator.pop()),
                      ),
                    );
                    vm.load();
                  },
                ),
                GoalsTab(
                  goals: data.goals,
                  onSetPrimary: (kind) => _run(context, (vm) => vm.setPrimaryGoal(kind)),
                  onToggleActive: (kind) => _run(context, (vm) => vm.toggleGoal(kind)),
                  onAdd: (goal) => _run(context, (vm) => vm.addGoal(goal)),
                  onDelete: (goal) => _run(context, (vm) => vm.deleteGoal(goal)),
                ),
                MeasuresTab(
                  measurements: data.measurements,
                  activity: data.activity,
                  heightCm: data.profile.heightCm,
                  onAddMeasure: (snapshot) => _run(context, (vm) => vm.addMeasure(snapshot)),
                ),
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
          decoration: BoxDecoration(color: selected ? AppColors.volt : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: selected ? AppColors.textOnVolt : AppColors.textSecondary),
          ),
        ),
      );
}
