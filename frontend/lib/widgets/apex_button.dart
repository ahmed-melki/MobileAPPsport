import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

enum ApexButtonVariant { primary, secondary, ghost }

class ApexButton extends StatelessWidget {
  const ApexButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = ApexButtonVariant.primary,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ApexButtonVariant variant;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(
      label,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        if (expand) Flexible(child: labelWidget) else labelWidget,
      ],
    );

    final button = switch (variant) {
      ApexButtonVariant.primary => FilledButton(
          onPressed: onPressed,
          child: child,
        ),
      ApexButtonVariant.secondary => OutlinedButton(
          onPressed: onPressed,
          child: child,
        ),
      ApexButtonVariant.ghost => TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size.fromHeight(48),
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
          ),
          child: child,
        ),
    };

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
