import 'package:flutter/material.dart';

import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/module_accents.dart';
import 'apex_card.dart';

class ModulePreviewCard extends StatelessWidget {
  const ModulePreviewCard({
    super.key,
    required this.module,
    this.comingSoon = true,
    this.onTap,
  });

  final ApexModule module;
  final bool comingSoon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accent = module.accent;

    return ApexCard(
      tone: ApexCardTone.elevated,
      accent: accent,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: AppRadii.smAll,
                ),
                child: Icon(module.icon, color: accent, size: 22),
              ),
              const Spacer(),
              if (comingSoon)
                Text(
                  'BIENTÔT',
                  style: text.labelSmall?.copyWith(
                    color: accent,
                    letterSpacing: 1.2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(module.label, style: text.titleLarge),
          const SizedBox(height: 4),
          Text(module.tagline, style: text.bodySmall),
        ],
      ),
    );
  }
}
