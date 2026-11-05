import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'apex_card.dart';

class ApexStat extends StatelessWidget {
  const ApexStat({
    super.key,
    required this.value,
    required this.label,
    this.unit,
    this.accent,
  });

  final String value;
  final String label;
  final String? unit;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = accent ?? AppColors.volt;

    return ApexCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: text.labelSmall?.copyWith(letterSpacing: 1.1),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: text.displaySmall?.copyWith(color: color),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(unit!, style: text.bodySmall),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
