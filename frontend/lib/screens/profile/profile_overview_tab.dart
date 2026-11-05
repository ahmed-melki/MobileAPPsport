import 'package:flutter/material.dart';

import '../../data/profile_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';
import 'change_password_screen.dart';

class ProfileOverviewTab extends StatelessWidget {
  const ProfileOverviewTab({
    super.key,
    required this.profile,
    required this.onEdit,
    required this.onLevelChanged,
    required this.onToggleSport,
    this.onRedoOnboarding,
  });

  final SportProfile profile;
  final VoidCallback onEdit;
  final ValueChanged<SportLevel> onLevelChanged;
  final ValueChanged<String> onToggleSport;
  final VoidCallback? onRedoOnboarding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.xxxl,
      ),
      children: [
        ApexCard(
          tone: ApexCardTone.glow,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              ApexAvatar(initials: profile.initials, size: 76),
              const SizedBox(height: AppSpacing.md),
              Text(profile.fullName, style: text.headlineLarge),
              const SizedBox(height: 4),
              Text(
                '${profile.city}  ·  ${profile.age} ans  ·  ${profile.heightCm} cm',
                style: text.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                profile.email,
                style: text.labelMedium?.copyWith(color: AppColors.volt),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                profile.bio,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.lg),
              ApexButton(
                label: 'Modifier le profil',
                icon: Icons.edit_outlined,
                onPressed: onEdit,
              ),
              const SizedBox(height: AppSpacing.sm),
              ApexButton(
                label: 'Refaire mon profil',
                icon: Icons.refresh_rounded,
                variant: ApexButtonVariant.secondary,
                onPressed: onRedoOnboarding,
              ),
              const SizedBox(height: AppSpacing.sm),
              ApexButton(
                label: 'Changer le mot de passe',
                icon: Icons.lock_outline_rounded,
                variant: ApexButtonVariant.ghost,
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => const ChangePasswordScreen()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const ApexSectionHeader(title: 'Niveau'),
        const SizedBox(height: 6),
        Text(
          'Ajuste selon ta charge réelle — pas ton ego.',
          style: text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final level in SportLevel.values) ...[
              if (level != SportLevel.beginner) const SizedBox(width: 8),
              Expanded(
                child: _LevelPick(
                  label: level.label,
                  selected: profile.level == level,
                  onTap: () => onLevelChanged(level),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        const ApexSectionHeader(title: 'Préférences sportives'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final sport in profile.sports)
              ApexChip(label: sport, selected: true, onTap: () => onToggleSport(sport)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Touche un sport pour le retirer, ou édite le profil pour en ajouter.',
          style: text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xxl),
        ApexCard(
          tone: ApexCardTone.muted,
          child: Row(
            children: [
              const Icon(Icons.verified_outlined, color: AppColors.volt),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Membre APEX depuis ${profile.memberSince}',
                  style: text.titleSmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LevelPick extends StatelessWidget {
  const _LevelPick({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.mdAll,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.volt.withValues(alpha: 0.14) : AppColors.surface,
            borderRadius: AppRadii.mdAll,
            border: Border.all(
              color: selected ? AppColors.volt.withValues(alpha: 0.7) : AppColors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.labelMedium?.copyWith(
              color: selected ? AppColors.volt : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
