import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../data/nutrition_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/nutrition_view_models.dart';
import '../../widgets/widgets.dart';

String _timeFor(DateTime day, MealType type) {
  final now = DateTime.now();
  final isToday = now.year == day.year && now.month == day.month && now.day == day.day;
  if (!isToday) return type.defaultTime;
  return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
}

Future<T?> _sheet<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
      builder: (sheetContext) => ChangeNotifierProvider(
        create: (_) => AddMealViewModel(context.read<AppRepositories>().nutrition),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: child,
        ),
      ),
    );

class _MealTypePicker extends StatelessWidget {
  const _MealTypePicker({required this.value, required this.onChanged});
  final MealType value;
  final ValueChanged<MealType> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final type in MealType.values)
            ApexChip(label: type.label, selected: value == type, accent: AppColors.mint, onTap: () => onChanged(type)),
        ],
      );
}

class _MacroLine extends StatelessWidget {
  const _MacroLine({required this.calories, required this.protein, required this.carbs, required this.fat});
  final num calories;
  final num protein;
  final num carbs;
  final num fat;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget cell(String label, String value, Color color) => Expanded(
          child: Column(children: [
            Text(value, style: text.titleMedium?.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(label, style: text.labelSmall),
          ]),
        );
    return ApexCard(
      tone: ApexCardTone.muted,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        cell('kcal', fmtNum(calories.round()), AppColors.mint),
        cell('Prot.', '${fmtNum(protein)} g', AppColors.coral),
        cell('Gluc.', '${fmtNum(carbs)} g', AppColors.amber),
        cell('Lip.', '${fmtNum(fat)} g', AppColors.violet),
      ]),
    );
  }
}

/// Food → choose portion & meal → logs a meal. Returns true if added.
Future<bool?> showAddFoodSheet(BuildContext context, {required FoodItem food, required DateTime day, MealType? type}) =>
    _sheet<bool>(context, _AddFoodSheet(food: food, day: day, initialType: type ?? MealTypeX.forHour(DateTime.now().hour)));

class _AddFoodSheet extends StatefulWidget {
  const _AddFoodSheet({required this.food, required this.day, required this.initialType});
  final FoodItem food;
  final DateTime day;
  final MealType initialType;

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  late MealType _type = widget.initialType;
  double _portions = 1;

  Future<void> _save() async {
    final f = widget.food;
    final vm = context.read<AddMealViewModel>();
    final ok = await vm.add(
            day: widget.day,
            type: _type,
            name: _portions == 1 ? f.name : '${f.name} ×${fmtNum(_portions)}',
            time: _timeFor(widget.day, _type),
            calories: (f.calories * _portions).round(),
            protein: f.protein * _portions,
            carbs: f.carbs * _portions,
            fat: f.fat * _portions,
            foodId: f.id,
          );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.error ?? 'Erreur')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final f = widget.food;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(f.name, style: text.headlineSmall),
            const SizedBox(height: 4),
            Text('${f.categoryLabel} · portion : ${f.serving}', style: text.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            Text('Nombre de portions', style: text.labelSmall),
            Row(children: [
              ApexIconButton(icon: Icons.remove_rounded, onPressed: _portions > 0.5 ? () => setState(() => _portions -= 0.5) : null),
              Expanded(child: Center(child: Text(fmtNum(_portions), style: text.headlineMedium))),
              ApexIconButton(icon: Icons.add_rounded, onPressed: _portions < 10 ? () => setState(() => _portions += 0.5) : null),
            ]),
            const SizedBox(height: AppSpacing.md),
            _MacroLine(calories: f.calories * _portions, protein: f.protein * _portions, carbs: f.carbs * _portions, fat: f.fat * _portions),
            const SizedBox(height: AppSpacing.lg),
            Text('Repas', style: text.labelSmall),
            const SizedBox(height: 8),
            _MealTypePicker(value: _type, onChanged: (t) => setState(() => _type = t)),
            const SizedBox(height: AppSpacing.xl),
            ApexButton(label: context.watch<AddMealViewModel>().busy ? 'Ajout…' : 'Ajouter au journal', icon: Icons.add_rounded, onPressed: context.watch<AddMealViewModel>().busy ? null : _save),
          ],
        ),
      ),
    );
  }
}

/// Recipe details (ingredients, steps) + "add to journal". Returns true if logged.
Future<bool?> showRecipeSheet(BuildContext context, {required NutritionRecipe recipe, required DateTime day}) =>
    _sheet<bool>(context, _RecipeSheet(recipe: recipe, day: day));

class _RecipeSheet extends StatefulWidget {
  const _RecipeSheet({required this.recipe, required this.day});
  final NutritionRecipe recipe;
  final DateTime day;

  @override
  State<_RecipeSheet> createState() => _RecipeSheetState();
}

class _RecipeSheetState extends State<_RecipeSheet> {
  late MealType _type = widget.recipe.mealType ?? MealTypeX.forHour(DateTime.now().hour);

  Future<void> _save() async {
    final r = widget.recipe;
    final vm = context.read<AddMealViewModel>();
    final ok = await vm.add(
            day: widget.day,
            type: _type,
            name: r.name,
            time: _timeFor(widget.day, _type),
            calories: r.calories,
            protein: r.protein,
            carbs: r.carbs,
            fat: r.fat,
            recipeId: r.id,
          );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.error ?? 'Erreur')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final r = widget.recipe;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(AppSpacing.screenH),
        children: [
          Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: r.accent.withValues(alpha: 0.15), borderRadius: AppRadii.mdAll),
              child: Icon(r.icon, color: r.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.name, style: text.headlineSmall),
                Text('${r.duration} min${r.isTunisian ? ' · 🇹🇳 Tunisien' : ''}', style: text.bodySmall),
              ]),
            ),
          ]),
          if (r.reason != null) ...[
            const SizedBox(height: AppSpacing.md),
            ApexCard(
              tone: ApexCardTone.muted,
              accent: AppColors.violet,
              child: Row(children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.violet, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(r.reason!, style: text.bodySmall)),
              ]),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _MacroLine(calories: r.calories, protein: r.protein, carbs: r.carbs, fat: r.fat),
          if (r.ingredients.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Ingrédients', style: text.titleMedium),
            const SizedBox(height: 8),
            for (final i in r.ingredients)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 6, color: AppColors.mint)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(i, style: text.bodyMedium)),
                ]),
              ),
          ],
          if (r.steps.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Préparation', style: text.titleMedium),
            const SizedBox(height: 8),
            for (var i = 0; i < r.steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${i + 1}.', style: text.labelLarge?.copyWith(color: AppColors.mint)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r.steps[i], style: text.bodyMedium)),
                ]),
              ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('Ajouter comme', style: text.labelSmall),
          const SizedBox(height: 8),
          _MealTypePicker(value: _type, onChanged: (t) => setState(() => _type = t)),
          const SizedBox(height: AppSpacing.lg),
          ApexButton(label: context.watch<AddMealViewModel>().busy ? 'Ajout…' : 'J’ai mangé ça', icon: Icons.check_rounded, onPressed: context.watch<AddMealViewModel>().busy ? null : _save),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Free entry (home-made dish, restaurant...). Returns true if added.
Future<bool?> showManualMealSheet(BuildContext context, {required DateTime day, MealType? type}) =>
    _sheet<bool>(context, _ManualMealSheet(day: day, initialType: type ?? MealTypeX.forHour(DateTime.now().hour)));

class _ManualMealSheet extends StatefulWidget {
  const _ManualMealSheet({required this.day, required this.initialType});
  final DateTime day;
  final MealType initialType;

  @override
  State<_ManualMealSheet> createState() => _ManualMealSheetState();
}

class _ManualMealSheetState extends State<_ManualMealSheet> {
  final _name = TextEditingController();
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  late MealType _type = widget.initialType;

  @override
  void dispose() {
    for (final c in [_name, _kcal, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.').trim()) ?? 0;

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _num(_kcal) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Donne un nom et les calories.')));
      return;
    }
    final vm = context.read<AddMealViewModel>();
    final ok = await vm.add(
            day: widget.day,
            type: _type,
            name: _name.text.trim(),
            time: _timeFor(widget.day, _type),
            calories: _num(_kcal).round(),
            protein: _num(_protein),
            carbs: _num(_carbs),
            fat: _num(_fat),
          );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.error ?? 'Erreur')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget field(TextEditingController c, String label) => Expanded(
          child: TextField(
            controller: c,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: label),
          ),
        );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saisie libre', style: text.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nom du repas')),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [field(_kcal, 'kcal'), const SizedBox(width: 8), field(_protein, 'Prot. g')]),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [field(_carbs, 'Gluc. g'), const SizedBox(width: 8), field(_fat, 'Lip. g')]),
            const SizedBox(height: AppSpacing.lg),
            _MealTypePicker(value: _type, onChanged: (t) => setState(() => _type = t)),
            const SizedBox(height: AppSpacing.xl),
            ApexButton(label: context.watch<AddMealViewModel>().busy ? 'Ajout…' : 'Ajouter', icon: Icons.add_rounded, onPressed: context.watch<AddMealViewModel>().busy ? null : _save),
          ],
        ),
      ),
    );
  }
}
