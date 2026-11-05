import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Maps API string keys (colorKey, iconKey, badgeKey) coming from the
/// ProductResource to Flutter Color / IconData / badge-label values.
///
/// The API never sends Color or IconData objects — it sends short string
/// keys such as "cyan", "directions_run", "best_seller".

// ─── Colors ───────────────────────────────────────────────────────────

Color colorFromKey(String? key) => switch (key) {
      'cyan' => AppColors.cyan,
      'coral' => AppColors.coral,
      'violet' => AppColors.violet,
      'mint' => AppColors.mint,
      'amber' => AppColors.amber,
      'volt' => AppColors.volt,
      _ => AppColors.cyan,
    };

// ─── Icons ────────────────────────────────────────────────────────────

IconData iconFromKey(String? key) => switch (key) {
      'directions_run' => Icons.directions_run_rounded,
      'fitness_center' => Icons.fitness_center_rounded,
      'checkroom' => Icons.checkroom_rounded,
      'sports_handball' => Icons.sports_handball_rounded,
      'recovery' => Icons.battery_charging_full_rounded,
      'battery_charging_full' => Icons.battery_charging_full_rounded,
      'directions_walk' => Icons.directions_walk_rounded,
      'local_mall' => Icons.local_mall_rounded,
      _ => Icons.shopping_bag_outlined,
    };

// ─── Badge labels ─────────────────────────────────────────────────────

String? badgeLabelFromKey(String? key) => switch (key) {
      'best_seller' || 'BEST-SELLER' => 'BEST-SELLER',
      'new' || 'NOUVEAU' => 'NOUVEAU',
      null || '' => null,
      _ => key.toUpperCase(),
    };

// ─── Order-status labels (French) ─────────────────────────────────────

String orderStatusLabel(String? status) => switch (status) {
      'pending' => 'En attente',
      'confirmed' => 'Confirmée',
      'shipped' => 'Expédiée',
      'delivered' => 'Livrée',
      'cancelled' => 'Annulée',
      _ => status ?? '',
    };

Color orderStatusColor(String? status) => switch (status) {
      'pending' => AppColors.amber,
      'confirmed' => AppColors.cyan,
      'shipped' => AppColors.violet,
      'delivered' => AppColors.mint,
      'cancelled' => AppColors.coral,
      _ => AppColors.textSecondary,
    };
