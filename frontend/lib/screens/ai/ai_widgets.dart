import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';

/// Header shared by the AI recommendation screens.
class AiHeader extends StatelessWidget {
  const AiHeader({super.key, required this.overline, required this.title, required this.accent, this.onRefresh});
  final String overline;
  final String title;
  final Color accent;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.md),
      child: Row(children: [
        ApexIconButton(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.of(context).maybePop()),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(overline, style: text.labelSmall?.copyWith(color: accent)),
            Text(title, style: text.headlineMedium),
          ]),
        ),
        if (onRefresh != null) ApexIconButton(icon: Icons.refresh_rounded, onPressed: onRefresh),
      ]),
    );
  }
}

/// "IA" or "Règles" badge: shows where the text comes from.
class AiSourceBadge extends StatelessWidget {
  const AiSourceBadge({super.key, required this.fromAi, required this.accent});
  final bool fromAi;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final color = fromAi ? accent : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.pill)),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(fromAi ? Icons.auto_awesome_rounded : Icons.rule_rounded, size: 14, color: color),
        const SizedBox(width: 4),
        Text(fromAi ? 'Généré par l’IA' : 'Moteur de règles', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
      ]),
    );
  }
}

/// Summary card (AI text) at the top of the screen.
class AiSummaryCard extends StatelessWidget {
  const AiSummaryCard({super.key, required this.title, required this.summary, required this.fromAi, required this.accent, this.chips = const []});
  final String title;
  final String summary;
  final bool fromAi;
  final Color accent;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ApexCard(
      tone: ApexCardTone.glow,
      accent: accent,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(Icons.psychology_alt_rounded, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: text.titleMedium)),
          AiSourceBadge(fromAi: fromAi, accent: accent),
        ]),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final c in chips) ApexChip(label: c, selected: true, accent: accent)]),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(summary, style: text.bodyMedium?.copyWith(height: 1.5, color: AppColors.textPrimary)),
      ]),
    );
  }
}

class AiTipsCard extends StatelessWidget {
  const AiTipsCard({super.key, required this.tips, required this.accent});
  final List<String> tips;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ApexCard(
      tone: ApexCardTone.elevated,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Conseils personnalisés', style: text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < tips.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: Text('${i + 1}', style: text.labelSmall?.copyWith(color: accent)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(tips[i], style: text.bodyMedium)),
            ]),
          ),
      ]),
    );
  }
}

class AiSectionTitle extends StatelessWidget {
  const AiSectionTitle(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      );
}

/// Loading / error states.
class AiStateView extends StatelessWidget {
  const AiStateView({super.key, required this.loading, required this.error, required this.onRetry, required this.accent});
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: accent),
          const SizedBox(height: AppSpacing.md),
          Text('L’IA analyse ton profil…', style: Theme.of(context).textTheme.bodyMedium),
        ]),
      );
    }
    return Center(
      child: TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: Text(error ?? 'Réessayer')),
    );
  }
}
