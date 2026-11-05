import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/profile_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, required this.profile});

  final SportProfile profile;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _city;
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _bio;
  late SportLevel _level;
  late Set<String> _sports;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _first = TextEditingController(text: p.firstName);
    _last = TextEditingController(text: p.lastName);
    _city = TextEditingController(text: p.city);
    _age = TextEditingController(text: '${p.age}');
    _height = TextEditingController(text: '${p.heightCm}');
    _bio = TextEditingController(text: p.bio);
    _level = p.level;
    _sports = {...p.sports};
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _city.dispose();
    _age.dispose();
    _height.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _save() {
    final age = int.tryParse(_age.text.trim()) ?? widget.profile.age;
    final height = int.tryParse(_height.text.trim()) ?? widget.profile.heightCm;
    Navigator.of(context).pop(
      widget.profile.copyWith(
        firstName: _first.text.trim().isEmpty ? widget.profile.firstName : _first.text.trim(),
        lastName: _last.text.trim().isEmpty ? widget.profile.lastName : _last.text.trim(),
        city: _city.text.trim(),
        age: age,
        heightCm: height,
        bio: _bio.text.trim(),
        level: _level,
        sports: _sports,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.md,
                AppSpacing.screenH,
                0,
              ),
              child: Row(
                children: [
                  ApexIconButton(
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Éditer le profil', style: text.headlineMedium)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  AppSpacing.xl,
                  AppSpacing.screenH,
                  AppSpacing.xxxl,
                ),
                children: [
                  Text('Identité', style: text.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _first,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Prénom'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _last,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nom'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Ville'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _age,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(labelText: 'Âge'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _height,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(labelText: 'Taille (cm)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _bio,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Bio sportive'),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text('Niveau', style: text.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  for (final level in SportLevel.values) ...[
                    _LevelTile(
                      level: level,
                      selected: _level == level,
                      onTap: () => setState(() => _level = level),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Text('Sports préférés', style: text.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Sélectionne ce que tu pratiques vraiment — ça colorera tes reco plus tard.',
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final sport in catalogSports)
                        ApexChip(
                          label: sport,
                          selected: _sports.contains(sport),
                          onTap: () {
                            setState(() {
                              if (_sports.contains(sport)) {
                                if (_sports.length > 1) _sports.remove(sport);
                              } else {
                                _sports.add(sport);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ApexButton(
                    label: 'Enregistrer',
                    icon: Icons.check_rounded,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final SportLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ApexCard(
      tone: selected ? ApexCardTone.glow : ApexCardTone.standard,
      accent: selected ? AppColors.volt : null,
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
            color: selected ? AppColors.volt : AppColors.textTertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(level.label, style: text.titleMedium),
                Text(level.hint, style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
