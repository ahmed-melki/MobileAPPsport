import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../core/api/app_repositories.dart';
import '../data/profile_models.dart';
import '../theme/app_colors.dart';
import '../viewmodels/hub_view_model.dart';
import '../theme/app_spacing.dart';
import '../theme/module_accents.dart';
import '../widgets/widgets.dart';
import 'admin/admin_catalog_screens.dart';
import 'coach/coach_ai_screen.dart';
import 'nutrition/nutrition_module_screen.dart';
import 'profile/profile_module_screen.dart';
import 'shop/shop_module_screen.dart';
import 'training/training_module_screen.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key, this.onLogout});
  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => HubViewModel(context.read<AppRepositories>().profile)..load(),
        child: _HubView(onLogout: onLogout),
      );
}

class _HubView extends StatelessWidget {
  const _HubView({this.onLogout});
  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<HubViewModel>();
    final firstName = vm.firstName;
    final readiness = vm.readiness;
    final streakDays = vm.streakDays;
    final weeklySessions = vm.weeklySessions;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF12180C), AppColors.scaffold, Color(0xFF0A1214)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.xxxl),
                sliver: SliverList.list(
                  children: [
                    Row(children: [
                      Text('APEX', style: text.headlineLarge),
                      const SizedBox(width: 8),
                      Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.volt, shape: BoxShape.circle)),
                      const Spacer(),
                      const ApexIconButton(icon: Icons.notifications_none_rounded),
                      const SizedBox(width: 8),
                      ApexAvatar(initials: vm.user?.initials ?? '?'),
                      if (onLogout != null) ...[
                        const SizedBox(width: 8),
                        ApexIconButton(icon: Icons.logout_rounded, onPressed: () => onLogout!()),
                      ],
                    ]),
                    const SizedBox(height: AppSpacing.xxl),
                    Text('Bonjour, $firstName.', style: text.bodyMedium),
                    const SizedBox(height: 6),
                    Text('Cinq univers.\nUne cadence.', style: text.displayMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Profils, entraînement, boutique, coach IA et nutrition — une seule expérience sombre, nette, volt.', style: text.bodyMedium),
                    if (vm.isAdmin) ...[
                      const SizedBox(height: AppSpacing.xl),
                      ApexCard(
                        tone: ApexCardTone.glow,
                        accent: AppColors.coral,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AdminHomeScreen())),
                        child: Row(children: [
                          const Icon(Icons.admin_panel_settings_rounded, color: AppColors.coral, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('ADMIN', style: text.labelSmall?.copyWith(color: AppColors.coral)),
                              Text('Espace admin', style: text.titleMedium),
                              Text('Commandes, boutique, aliments & recettes', style: text.bodySmall),
                            ]),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                        ]),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    ApexCard(
                      tone: ApexCardTone.glow,
                      accent: AppColors.violet,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CoachAiScreen())),
                      child: Row(children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(color: AppColors.violet.withValues(alpha: 0.18), shape: BoxShape.circle),
                          child: const Icon(Icons.auto_awesome_rounded, color: AppColors.violet),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('COACH APEX · IA', style: text.labelSmall?.copyWith(color: AppColors.violet)),
                            Text('Que faire aujourd’hui ?', style: text.titleMedium),
                            Text('Séance, charges, repas et eau — calculés pour toi', style: text.bodySmall),
                          ]),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                      ]),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ApexCard(
                      tone: ApexCardTone.glow,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('IDENTITÉ VISUELLE', style: text.labelSmall),
                        const SizedBox(height: 8),
                        Text('Dark athletic × neon volt', style: text.headlineSmall),
                        const SizedBox(height: 6),
                        Text('Cartes bordées, CTA lime, accents par module. Réutilise AppColors, ApexCard et ApexButton partout.', style: text.bodySmall),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(spacing: 8, runSpacing: 8, children: const [
                          ApexChip(label: 'Force', selected: true),
                          ApexChip(label: 'Endurance'),
                          ApexChip(label: 'Mobility'),
                          ApexChip(label: 'Hyrox', accent: AppColors.cyan, selected: true),
                        ]),
                        const SizedBox(height: AppSpacing.md),
                        ApexButton(label: 'Ouvrir mon profil', icon: Icons.north_east_rounded, onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ProfileModuleScreen(onLogout: onLogout)))),
                      ]),
                    ),
                    if (vm.activeProgram != null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Builder(builder: (context) {
                        final rawProg = vm.activeProgram!['program'];
                        final prog = rawProg is Map ? rawProg : vm.activeProgram!;
                        final title = prog['title']?.toString() ?? 'Programme en cours';
                        final subtitle = prog['subtitle']?.toString() ?? 'Suis ton plan d\'entraînement personnalisé.';
                        final weeks = prog['weeks'] != null ? '${prog['weeks']} sem.' : null;
                        final days = prog['daysPerWeek'] != null ? '${prog['daysPerWeek']}j/sem.' : null;
                        final level = prog['level']?.toString();

                        return ApexCard(
                          tone: ApexCardTone.glow,
                          accent: AppColors.volt,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.volt.withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.bolt_rounded, size: 14, color: AppColors.volt),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'PROGRAMME RECOMMANDÉ ACTIF',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: text.labelSmall?.copyWith(
                                                color: AppColors.volt,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(title, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(subtitle, style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
                              const SizedBox(height: AppSpacing.md),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (weeks != null)
                                    ApexChip(label: weeks, selected: true, accent: AppColors.volt),
                                  if (days != null)
                                    ApexChip(label: days, accent: AppColors.cyan, selected: true),
                                  if (level != null)
                                    ApexChip(label: level.toUpperCase(), accent: AppColors.violet),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ApexButton(
                                label: 'Continuer l\'entraînement',
                                icon: Icons.play_arrow_rounded,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(builder: (_) => const TrainingModuleScreen()),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    Row(children: [
                      Expanded(child: ApexStat(value: '$readiness', unit: '%', label: 'Readiness', accent: AppColors.volt)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: ApexStat(value: '$streakDays', unit: 'j', label: 'Streak', accent: AppColors.cyan)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: ApexStat(value: '$weeklySessions', label: 'Séances', accent: AppColors.violet)),
                    ]),
                    const SizedBox(height: AppSpacing.xxl),
                    const ApexSectionHeader(title: 'Modules'),
                    const SizedBox(height: AppSpacing.md),
                    for (final module in ApexModule.values) ...[
                      ModulePreviewCard(
                        module: module,
                        comingSoon: false,
                        onTap: () {
                          final screen = switch (module) {
                            ApexModule.profiles => ProfileModuleScreen(onLogout: onLogout),
                            ApexModule.training => const TrainingModuleScreen(),
                            ApexModule.shop => const ShopModuleScreen(),
                            ApexModule.coaches => const CoachAiScreen(),
                            ApexModule.nutrition => const NutritionModuleScreen(),
                          };
                          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    if (vm.error != null) TextButton.icon(onPressed: vm.load, icon: const Icon(Icons.refresh), label: Text(vm.error!)),
                    if (vm.user != null) Text('${vm.user!.fullName}  ·  ${vm.user!.level.label}', textAlign: TextAlign.center, style: text.labelSmall),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
