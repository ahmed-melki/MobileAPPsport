import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'nutrition_models.dart';

final mockMeals = <MealEntry>[
  const MealEntry(
    type: MealType.breakfast,
    name: 'Porridge banane & whey',
    time: '07:40',
    calories: 520,
    protein: 32,
    carbs: 68,
    fat: 14,
  ),
  const MealEntry(
    type: MealType.lunch,
    name: 'Bowl poulet, riz & légumes',
    time: '12:45',
    calories: 680,
    protein: 48,
    carbs: 76,
    fat: 18,
  ),
  const MealEntry(
    type: MealType.snack,
    name: 'Skyr, fruits rouges & amandes',
    time: '16:20',
    calories: 290,
    protein: 24,
    carbs: 25,
    fat: 10,
  ),
];

final mockRecipes = <NutritionRecipe>[
  const NutritionRecipe(
    id: 'power-bowl',
    name: 'Power bowl poulet',
    subtitle: 'Riz complet · avocat · légumes verts',
    calories: 610,
    protein: 46,
    duration: 25,
    icon: Icons.rice_bowl_rounded,
    accent: AppColors.mint,
  ),
  const NutritionRecipe(
    id: 'recovery-toast',
    name: 'Tartines recovery',
    subtitle: 'Pain complet · œufs · cottage cheese',
    calories: 430,
    protein: 31,
    duration: 12,
    icon: Icons.breakfast_dining_rounded,
    accent: AppColors.amber,
  ),
  const NutritionRecipe(
    id: 'smoothie-pro',
    name: 'Smoothie post-training',
    subtitle: 'Banane · cacao · whey · lait',
    calories: 360,
    protein: 29,
    duration: 5,
    icon: Icons.blender_rounded,
    accent: AppColors.violet,
  ),
  const NutritionRecipe(
    id: 'salmon-pasta',
    name: 'Pasta saumon citron',
    subtitle: 'Pâtes · saumon · épinards frais',
    calories: 720,
    protein: 42,
    duration: 30,
    icon: Icons.dinner_dining_rounded,
    accent: AppColors.coral,
  ),
];

final mockFoods = <FoodItem>[
  const FoodItem(
    name: 'Blanc de poulet rôti',
    category: 'Protéines',
    serving: '100 g',
    calories: 165,
    protein: 31,
    carbs: 0,
    fat: 4,
  ),
  const FoodItem(
    name: 'Riz basmati cuit',
    category: 'Féculents',
    serving: '150 g',
    calories: 195,
    protein: 4,
    carbs: 42,
    fat: 0,
  ),
  const FoodItem(
    name: 'Skyr nature',
    category: 'Laitages',
    serving: '150 g',
    calories: 92,
    protein: 16,
    carbs: 6,
    fat: 0,
  ),
  const FoodItem(
    name: 'Banane',
    category: 'Fruits',
    serving: '1 moyenne',
    calories: 105,
    protein: 1,
    carbs: 27,
    fat: 0,
  ),
  const FoodItem(
    name: 'Avocat',
    category: 'Fruits',
    serving: '1/2 pièce',
    calories: 160,
    protein: 2,
    carbs: 8,
    fat: 15,
  ),
  const FoodItem(
    name: 'Amandes',
    category: 'Oléagineux',
    serving: '30 g',
    calories: 174,
    protein: 6,
    carbs: 6,
    fat: 15,
  ),
];
