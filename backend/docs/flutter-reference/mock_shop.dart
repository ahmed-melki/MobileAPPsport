import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'shop_models.dart';

final mockShopProducts = <ShopProduct>[
  const ShopProduct(
    id: 'aero-runner-x',
    name: 'Aero Runner X',
    brand: 'Nord Athletics',
    category: ShopCategory.shoes,
    price: 149.90,
    description: 'Une chaussure légère et nerveuse pour les séances tempo, les sorties longues et les transitions Hyrox.',
    features: [
      'Plaque de propulsion composite',
      'Mousse retour d’énergie',
      'Drop 6 mm · 238 g',
    ],
    rating: 4.8,
    reviewCount: 126,
    color: AppColors.cyan,
    icon: Icons.directions_run_rounded,
    badge: 'BEST-SELLER',
  ),
  const ShopProduct(
    id: 'apex-lift-02',
    name: 'Apex Lift 02',
    brand: 'Forge Lab',
    category: ShopCategory.strength,
    price: 119.00,
    description: 'Stabilité maximale et maintien précis pour vos séances de force, du squat au deadlift.',
    features: ['Semelle rigide 20 mm', 'Talon renforcé', 'Empeigne respirante'],
    rating: 4.9,
    reviewCount: 84,
    color: AppColors.coral,
    icon: Icons.fitness_center_rounded,
    badge: 'NOUVEAU',
  ),
  const ShopProduct(
    id: 'motion-tee',
    name: 'Motion Tee',
    brand: 'Apex Studio',
    category: ShopCategory.apparel,
    price: 44.00,
    description: 'T-shirt technique ultra léger, coupe athlétique et séchage rapide pour bouger sans contrainte.',
    features: [
      'Tissu recyclé 140 g',
      'Anti-odeurs longue durée',
      'Coupe regular athlétique',
    ],
    rating: 4.7,
    reviewCount: 53,
    color: AppColors.violet,
    icon: Icons.checkroom_rounded,
  ),
  const ShopProduct(
    id: 'training-straps',
    name: 'Training Straps Pro',
    brand: 'Grip Culture',
    category: ShopCategory.accessories,
    price: 24.90,
    description: 'Des sangles robustes pour verrouiller votre prise et pousser plus loin vos tirages.',
    features: [
      'Coton tissé 4 cm',
      'Boucle acier brossé',
      'Charge testée à 250 kg',
    ],
    rating: 4.6,
    reviewCount: 39,
    color: AppColors.amber,
    icon: Icons.sports_handball_rounded,
  ),
  const ShopProduct(
    id: 'recovery-roll',
    name: 'Recovery Roll',
    brand: 'Reset Athletics',
    category: ShopCategory.recovery,
    price: 39.90,
    description: 'Rouleau dense à reliefs pour relâcher les jambes après une séance chargée.',
    features: [
      'Noyau haute densité',
      'Reliefs 3 zones',
      'Format compact 30 cm',
    ],
    rating: 4.8,
    reviewCount: 67,
    color: AppColors.mint,
    icon: Icons.battery_charging_full_rounded,
  ),
  const ShopProduct(
    id: 'velocity-shorts',
    name: 'Velocity Shorts',
    brand: 'Apex Studio',
    category: ShopCategory.apparel,
    price: 52.00,
    description: 'Short de training avec poche téléphone sécurisée et liberté de mouvement totale.',
    features: [
      'Doublure intégrée',
      'Poche zippée',
      'Tissu stretch 4 directions',
    ],
    rating: 4.5,
    reviewCount: 31,
    color: AppColors.violet,
    icon: Icons.directions_walk_rounded,
  ),
];

final mockShopReviews = <String, List<ShopReview>>{
  'aero-runner-x': const [
    ShopReview(
      author: 'Thomas R.',
      date: 'Il y a 4 jours',
      rating: 5,
      comment: 'Très dynamique sur les intervalles, et aucune gêne après 15 km. La taille est fidèle.',
      initials: 'TR',
    ),
    ShopReview(
      author: 'Camille D.',
      date: 'Il y a 2 semaines',
      rating: 4.5,
      comment: 'Bonne accroche sur piste et chemins secs. J’aurais aimé plus de coloris.',
      initials: 'CD',
    ),
  ],
  'apex-lift-02': const [
    ShopReview(
      author: 'Sami B.',
      date: 'Il y a 6 jours',
      rating: 5,
      comment:
          'La différence sur mes squats est immédiate. Maintien impeccable.',
      initials: 'SB',
    ),
  ],
};

final mockShopOrders = <ShopOrder>[
  const ShopOrder(
    id: 'APX-20481',
    date: '18 septembre 2026',
    status: 'Livrée',
    total: 173.90,
    items: ['Aero Runner X', 'Training Straps Pro'],
  ),
  const ShopOrder(
    id: 'APX-19872',
    date: '02 août 2026',
    status: 'Livrée',
    total: 44.00,
    items: ['Motion Tee'],
  ),
];
