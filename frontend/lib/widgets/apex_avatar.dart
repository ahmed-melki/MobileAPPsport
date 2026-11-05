import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ApexAvatar extends StatelessWidget {
  const ApexAvatar({
    super.key,
    required this.initials,
    this.size = 44,
    this.ringColor = AppColors.volt,
  });

  final String initials;
  final double size;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 1.6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ringColor.withValues(alpha: 0.35),
            AppColors.surfaceElevated,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
