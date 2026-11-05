import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ApexSectionHeader extends StatelessWidget {
  const ApexSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(title, style: text.headlineMedium)),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!, style: text.labelLarge?.copyWith(color: AppColors.volt)),
          ),
      ],
    );
  }
}
