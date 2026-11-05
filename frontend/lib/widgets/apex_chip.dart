import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

class ApexChip extends StatelessWidget {
  const ApexChip({
    super.key,
    required this.label,
    this.selected = false,
    this.accent,
    this.onTap,
  });

  final String label;
  final bool selected;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.volt;
    final bg = selected ? color.withValues(alpha: 0.16) : AppColors.surfaceElevated;
    final border = selected ? color.withValues(alpha: 0.55) : AppColors.border;
    final fg = selected ? color : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.pill)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.all(Radius.circular(AppRadii.pill)),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
          ),
        ),
      ),
    );
  }
}
