import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

enum ApexCardTone { standard, elevated, muted, glow }

class ApexCard extends StatelessWidget {
  const ApexCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.tone = ApexCardTone.standard,
    this.accent,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final ApexCardTone tone;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = switch (tone) {
      ApexCardTone.standard => AppColors.surface,
      ApexCardTone.elevated => AppColors.surfaceElevated,
      ApexCardTone.muted => AppColors.surfaceMuted,
      ApexCardTone.glow => AppColors.surface,
    };

    final borderColor = accent?.withValues(alpha: 0.35) ??
        (tone == ApexCardTone.glow ? AppColors.volt.withValues(alpha: 0.28) : AppColors.border);

    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.lgAll,
        border: Border.all(color: borderColor),
        boxShadow: tone == ApexCardTone.glow
            ? [
                BoxShadow(
                  color: (accent ?? AppColors.volt).withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.lgAll,
        splashColor: AppColors.voltGlow,
        child: card,
      ),
    );
  }
}
