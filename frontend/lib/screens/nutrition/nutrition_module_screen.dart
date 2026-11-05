import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../data/nutrition_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/nutrition_view_models.dart';
import '../../widgets/widgets.dart';
import '../ai/ai_nutrition_screen.dart';
import 'nutrition_sheets.dart';

const _weekdays = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
const _months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
const _weekdayShort = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

String _longDate(DateTime d) => '${_weekdays[d.weekday - 1][0].toUpperCase()}${_weekdays[d.weekday - 1].substring(1)} ${d.day} ${_months[d.month - 1]}';

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

class NutritionModuleScreen extends StatelessWidget {
  const NutritionModuleScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => NutritionViewModel(context.read<AppRepositories>().nutrition, initialTab: initialTab)..load(),
        child: const _NutritionView(),
      );
}

class _NutritionView extends StatefulWidget {
  const _NutritionView();

  @override
  State<_NutritionView> createState() => _NutritionViewState();
}

class _NutritionViewState extends State<_NutritionView> {
  final _foodQuery = TextEditingController();

  NutritionViewModel get vm => Provider.of<NutritionViewModel>(context, listen: false);

  @override
  void dispose() {
    _foodQuery.dispose();
    super.dispose();
  }

  void _showPendingMessage() {
    final message = vm.takeMessage();
    if (message != null && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _afterAdd(bool? added) async {
    if (added == true) {
      await vm.mealAdded();
      _showPendingMessage();
    }
  }

  void _openAddMenu({MealType? type}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.search_rounded, color: AppColors.mint),
              title: const Text('Chercher un aliment'),
              subtitle: const Text('Base d’aliments sains'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                vm.selectTab(3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded, color: AppColors.mint),
              title: const Text('Choisir une recette'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                vm.selectTab(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note_rounded, color: AppColors.mint),
              title: const Text('Saisie libre'),
              subtitle: const Text('Calories et macros à la main'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                _afterAdd(await showManualMealSheet(context, day: vm.day, type: type));
              },
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<NutritionViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPendingMessage());
    const tabs = ['Aujourd’hui', 'Journal', 'Recettes', 'Aliments'];
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      floatingActionButton: vm.tab <= 1 && vm.summary != null
          ? FloatingActionButton(
              backgroundColor: AppColors.mint,
              foregroundColor: AppColors.textOnVolt,
              onPressed: () => _openAddMenu(),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: SafeArea(
        child: Column(children: [
          const _NutritionHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: _NutritionTabs(tabs: tabs, selected: vm.tab, onSelected: vm.selectTab),
          ),
          Expanded(
            child: vm.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.mint))
                : vm.summary == null
                    ? Center(child: TextButton.icon(onPressed: vm.load, icon: const Icon(Icons.refresh), label: Text(vm.error ?? 'Réessayer')))
                    : switch (vm.tab) {
                        0 => _buildDashboard(text, vm),
                        1 => _buildJournal(text, vm),
                        2 => _buildRecipes(text, vm),
                        _ => _buildFoods(text, vm),
                      },
          ),
        ]),
      ),
    );
  }

  EdgeInsets get _listPadding => const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.lg, AppSpacing.screenH, 96);

  Widget _dayPicker(TextTheme text, NutritionViewModel vm) => Row(children: [
        ApexIconButton(icon: Icons.chevron_left_rounded, onPressed: () => vm.changeDay(-1)),
        Expanded(
          child: Column(children: [
            Text(vm.isToday ? 'AUJOURD’HUI' : 'JOURNAL', style: text.labelSmall?.copyWith(color: AppColors.mint)),
            const SizedBox(height: 2),
            Text(_longDate(vm.day), style: text.titleMedium),
          ]),
        ),
        ApexIconButton(icon: Icons.chevron_right_rounded, onPressed: vm.isToday ? null : () => vm.changeDay(1)),
      ]);

  Widget _buildDashboard(TextTheme text, NutritionViewModel vm) {
    final s = vm.summary!;
    final t = s.targets;
    final targetKcal = t?.calories ?? 0;
    final remaining = targetKcal - s.calories;
    final progress = targetKcal > 0 ? (s.calories / targetKcal).clamp(0.0, 1.0) : 0.0;

    return RefreshIndicator(
      color: AppColors.mint,
      onRefresh: vm.refreshDay,
      child: ListView(
        padding: _listPadding,
        children: [
          _dayPicker(text, vm),
          const SizedBox(height: AppSpacing.lg),
          ApexCard(
            tone: ApexCardTone.glow,
            accent: AppColors.volt,
            onTap: () async {
              await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => const AiNutritionScreen()));
            },
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: AppColors.volt.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.volt),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Recommandation IA', style: text.titleMedium),
                  const SizedBox(height: 2),
                  Text('Que manger maintenant selon ton objectif et ta journée.', style: text.bodySmall),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.volt),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),
          ApexCard(
            tone: ApexCardTone.glow,
            accent: AppColors.mint,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Énergie consommée', style: text.bodyMedium),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(style: text.displaySmall, children: [
                        TextSpan(text: '${s.calories}', style: const TextStyle(color: AppColors.textPrimary)),
                        TextSpan(text: targetKcal > 0 ? ' / $targetKcal kcal' : ' kcal', style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                      ]),
                    ),
                  ]),
                ),
                const Icon(Icons.local_fire_department_rounded, color: AppColors.coral, size: 38),
              ]),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: progress, minHeight: 9, color: remaining < 0 ? AppColors.coral : AppColors.mint, backgroundColor: AppColors.voltGlow),
              ),
              const SizedBox(height: 10),
              Text(
                targetKcal == 0
                    ? 'Fais l’onboarding pour obtenir tes objectifs caloriques.'
                    : remaining >= 0
                        ? 'Il te reste $remaining kcal aujourd’hui.'
                        : 'Tu as dépassé ton objectif de ${-remaining} kcal.',
                style: text.bodySmall,
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Répartition des macros', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: _MacroCard(label: 'Protéines', value: s.protein, target: t?.protein, color: AppColors.coral)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _MacroCard(label: 'Glucides', value: s.carbs, target: t?.carbs, color: AppColors.amber)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _MacroCard(label: 'Lipides', value: s.fat, target: t?.fat, color: AppColors.violet)),
          ]),
          if (vm.week != null) ...[
            const SizedBox(height: AppSpacing.xl),
            _WeekChart(week: vm.week!, selected: vm.day),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(children: [
            Expanded(child: Text('Repas du jour', style: text.headlineSmall)),
            TextButton(onPressed: () => vm.selectTab(1), child: const Text('Voir le journal')),
          ]),
          const SizedBox(height: AppSpacing.sm),
          if (s.meals.isEmpty)
            ApexCard(
              tone: ApexCardTone.muted,
              onTap: () => _openAddMenu(),
              child: Row(children: [
                const Icon(Icons.add_circle_outline_rounded, color: AppColors.mint),
                const SizedBox(width: 10),
                Expanded(child: Text('Aucun repas noté. Ajoute ton premier repas.', style: text.bodyMedium)),
              ]),
            ),
          for (final meal in s.meals) ...[
            _MealCard(meal: meal, onDelete: () => vm.deleteMeal(meal)),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  Widget _buildJournal(TextTheme text, NutritionViewModel vm) {
    final s = vm.summary!;
    return RefreshIndicator(
      color: AppColors.mint,
      onRefresh: vm.refreshDay,
      child: ListView(
        padding: _listPadding,
        children: [
          _dayPicker(text, vm),
          const SizedBox(height: AppSpacing.sm),
          Center(child: Text('${s.calories} kcal · ${fmtNum(s.protein)} g de protéines', style: text.bodyMedium)),
          const SizedBox(height: AppSpacing.lg),
          for (final type in MealType.values) ...[
            Row(children: [
              Icon(type.icon, color: AppColors.mint, size: 20),
              const SizedBox(width: 8),
              Text(type.label, style: text.titleMedium),
              const Spacer(),
              Text('${s.meals.where((m) => m.type == type).fold<int>(0, (sum, m) => sum + m.calories)} kcal', style: text.labelSmall),
              IconButton(onPressed: () => _openAddMenu(type: type), icon: const Icon(Icons.add_rounded, color: AppColors.mint), tooltip: 'Ajouter'),
            ]),
            ...s.meals.where((m) => m.type == type).map(
                  (meal) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _MealCard(meal: meal, onDelete: () => vm.deleteMeal(meal)),
                  ),
                ),
            if (!s.meals.any((m) => m.type == type))
              Padding(padding: const EdgeInsets.only(bottom: AppSpacing.lg), child: Text('Aucun repas enregistré', style: text.bodySmall)),
          ],
        ],
      ),
    );
  }

  Widget _buildRecipes(TextTheme text, NutritionViewModel vm) {
    final recipes = vm.recipes;
    final filters = <String, String>{
      'all': 'Toutes',
      'breakfast': 'Petit-déj',
      'lunch': 'Déjeuner',
      'dinner': 'Dîner',
      'snack': 'Collation',
      'favorites': '♥ Favoris',
    };
    return ListView(
      padding: _listPadding,
      children: [
        Text('Recettes healthy', style: text.headlineSmall),
        const SizedBox(height: 6),
        Text('${vm.allRecipes.length} recettes équilibrées avec les macros calculées.', style: text.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final f in filters.entries)
            ApexChip(label: f.value, selected: vm.recipeFilter == f.key, accent: f.key == 'favorites' ? AppColors.violet : AppColors.mint, onTap: () => vm.setRecipeFilter(f.key)),
        ]),
        const SizedBox(height: AppSpacing.lg),
        if (recipes.isEmpty) Text('Aucune recette ici pour l’instant.', style: text.bodySmall),
        for (final recipe in recipes) ...[
          _RecipeCard(
            recipe: recipe,
            favorite: vm.favorites.contains(recipe.id),
            onFavorite: () => vm.toggleFavorite(recipe),
            onTap: () async => _afterAdd(await showRecipeSheet(context, recipe: recipe, day: vm.day)),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _buildFoods(TextTheme text, NutritionViewModel vm) {
    final categories = <String?, String>{
      null: 'Tous',
      ...foodCategoryLabels.map((k, v) => MapEntry<String?, String>(k, v)),
    };
    return ListView(
      padding: _listPadding,
      children: [
        Text('Base d’aliments sains', style: text.headlineSmall),
        const SizedBox(height: 6),
        Text('Touche un aliment pour l’ajouter à ton journal (${_longDate(vm.day).toLowerCase()}).', style: text.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _foodQuery,
          onChanged: vm.setFoodQuery,
          decoration: const InputDecoration(hintText: 'Ex. avocat, poulet, quinoa', prefixIcon: Icon(Icons.search_rounded)),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final entry in categories.entries) ...[
              ApexChip(label: entry.value, selected: vm.foodCategory == entry.key, accent: AppColors.mint, onTap: () => vm.setFoodCategory(entry.key)),
              const SizedBox(width: 8),
            ],
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        if (vm.foodsLoading) const LinearProgressIndicator(color: AppColors.mint, minHeight: 2),
        if (!vm.foodsLoading && vm.foods.isEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Aucun aliment trouvé.', style: text.bodySmall),
          TextButton.icon(
            onPressed: () async => _afterAdd(await showManualMealSheet(context, day: vm.day)),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Saisir à la main'),
          ),
        ],
        for (final food in vm.foods) ...[
          _FoodCard(food: food, onTap: () async => _afterAdd(await showAddFoodSheet(context, food: food, day: vm.day))),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _NutritionHeader extends StatelessWidget {
  const _NutritionHeader();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.md),
        child: Row(children: [
          ApexIconButton(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.of(context).maybePop()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Nutrition', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.mint)),
              Text('Alimentation sportive', style: Theme.of(context).textTheme.headlineMedium),
            ]),
          ),
          const Icon(Icons.restaurant_rounded, color: AppColors.mint),
        ]),
      );
}

class _NutritionTabs extends StatelessWidget {
  const _NutritionTabs({required this.tabs, required this.selected, required this.onSelected});
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadii.mdAll, border: Border.all(color: AppColors.border)),
        child: Row(children: [
          for (var index = 0; index < tabs.length; index++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: selected == index ? AppColors.mint : Colors.transparent, borderRadius: AppRadii.smAll),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: selected == index ? AppColors.textOnVolt : AppColors.textSecondary),
                  ),
                ),
              ),
            ),
        ]),
      );
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({required this.label, required this.value, required this.target, required this.color});
  final String label;
  final double value;
  final double? target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final progress = (target ?? 0) > 0 ? (value / target!).clamp(0.0, 1.0) : 0.0;
    return ApexCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.labelSmall),
        const SizedBox(height: 8),
        Text('${fmtNum(value.round())} g', style: text.titleMedium?.copyWith(color: color)),
        const SizedBox(height: 3),
        Text(target != null ? '/ ${fmtNum(target!.round())} g' : '—', style: text.labelSmall),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: progress, minHeight: 5, color: color, backgroundColor: color.withValues(alpha: 0.12)),
        ),
      ]),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.week, required this.selected});
  final NutritionWeek week;
  final DateTime selected;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final target = week.targetCalories ?? 0;
    final maxValue = [target, ...week.days.map((d) => d.calories)].fold<int>(1, (a, b) => a > b ? a : b);
    return ApexCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('7 derniers jours', style: text.titleMedium)),
          Text('moy. ${week.averageCalories} kcal', style: text.labelSmall?.copyWith(color: AppColors.mint)),
        ]),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 110,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (final day in week.days)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text(day.calories > 0 ? '${(day.calories / 100).round() / 10}k' : '', style: text.labelSmall?.copyWith(fontSize: 9)),
                    const SizedBox(height: 4),
                    Container(
                      height: 70 * (day.calories / maxValue).clamp(0.02, 1.0),
                      decoration: BoxDecoration(
                        color: _sameDay(day.date, selected)
                            ? AppColors.mint
                            : (target > 0 && day.calories > target * 1.1 ? AppColors.coral : AppColors.mint.withValues(alpha: 0.35)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_weekdayShort[day.date.weekday - 1], style: text.labelSmall),
                  ]),
                ),
              ),
          ]),
        ),
        if (target > 0) ...[
          const SizedBox(height: 8),
          Text('Objectif : $target kcal / jour', style: text.bodySmall),
        ],
      ]),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal, required this.onDelete});
  final MealEntry meal;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Dismissible(
        key: ValueKey('meal-${meal.id}-${meal.name}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(color: AppColors.coral.withValues(alpha: 0.2), borderRadius: AppRadii.lgAll),
          child: const Icon(Icons.delete_outline_rounded, color: AppColors.coral),
        ),
        onDismissed: (_) => onDelete(),
        child: ApexCard(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: AppColors.mint.withValues(alpha: 0.14), borderRadius: AppRadii.mdAll),
              child: Icon(meal.type.icon, color: AppColors.mint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(meal.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  '${meal.time} · P ${fmtNum(meal.protein.round())} g · G ${fmtNum(meal.carbs.round())} g · L ${fmtNum(meal.fat.round())} g',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ]),
            ),
            Text('${meal.calories}\nkcal', textAlign: TextAlign.right, style: Theme.of(context).textTheme.labelLarge),
          ]),
        ),
      );
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe, required this.favorite, required this.onFavorite, required this.onTap});
  final NutritionRecipe recipe;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ApexCard(
      onTap: onTap,
      accent: recipe.accent,
      child: Row(children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(color: recipe.accent.withValues(alpha: 0.15), borderRadius: AppRadii.mdAll),
          child: Icon(recipe.icon, color: recipe.accent, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${recipe.isTunisian ? '🇹🇳 ' : ''}${recipe.name}', style: text.titleMedium),
            const SizedBox(height: 3),
            Text(recipe.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
            const SizedBox(height: 6),
            Text('${recipe.calories} kcal · ${fmtNum(recipe.protein.round())} g prot. · ${recipe.duration} min', style: text.labelSmall),
          ]),
        ),
        IconButton(
          onPressed: onFavorite,
          icon: Icon(favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: favorite ? AppColors.coral : AppColors.textTertiary),
        ),
      ]),
    );
  }
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({required this.food, required this.onTap});
  final FoodItem food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ApexCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${food.isTunisian ? '🇹🇳 ' : ''}${food.name}', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text('${food.categoryLabel} · ${food.serving}', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${food.calories} kcal', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.mint)),
            const SizedBox(height: 4),
            Text(
              'P ${fmtNum(food.protein.round())} · G ${fmtNum(food.carbs.round())} · L ${fmtNum(food.fat.round())}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ]),
          const SizedBox(width: 6),
          const Icon(Icons.add_circle_outline_rounded, color: AppColors.mint, size: 20),
        ]),
      );
}
