import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

class ApexIconButton extends StatelessWidget {
  const ApexIconButton({
    super.key,
    required this.icon,
    this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.mdAll,
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadii.mdAll,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }
}
