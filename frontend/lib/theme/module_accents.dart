import 'package:flutter/material.dart';

import 'app_colors.dart';

enum ApexModule { profiles, training, shop, coaches, nutrition }

extension ApexModuleX on ApexModule {
  String get label => switch (this) {
        ApexModule.profiles => 'Profils',
        ApexModule.training => 'Entraînement',
        ApexModule.shop => 'Boutique',
        ApexModule.coaches => 'Coach IA',
        ApexModule.nutrition => 'Nutrition',
      };

  String get tagline => switch (this) {
        ApexModule.profiles => 'Identité, stats, historique',
        ApexModule.training => 'Plans, séances, progression',
        ApexModule.shop => 'Équipement & essentials',
        ApexModule.coaches => 'Ton plan du jour, séance & repas',
        ApexModule.nutrition => 'Fuel, macros, récupération',
      };

  IconData get icon => switch (this) {
        ApexModule.profiles => Icons.person_rounded,
        ApexModule.training => Icons.bolt_rounded,
        ApexModule.shop => Icons.shopping_bag_rounded,
        ApexModule.coaches => Icons.auto_awesome_rounded,
        ApexModule.nutrition => Icons.eco_rounded,
      };

  Color get accent => switch (this) {
        ApexModule.profiles => AppColors.volt,
        ApexModule.training => AppColors.cyan,
        ApexModule.shop => AppColors.coral,
        ApexModule.coaches => AppColors.violet,
        ApexModule.nutrition => AppColors.mint,
      };
}
