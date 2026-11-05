import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../core/api/nutrition_coach_repositories.dart';
import '../../core/currency_formatter.dart';
import '../../core/shop_keys.dart';
import '../../data/nutrition_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/admin_view_models.dart';
import '../../widgets/widgets.dart';
import 'admin_orders_screen.dart';

// ═══ Shared helpers ═══════════════════════════════════════════════════

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.title, this.onRefresh});
  final String title;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.sm),
      child: Row(children: [
        ApexIconButton(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.of(context).maybePop()),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Administration', style: text.labelSmall?.copyWith(color: AppColors.coral)),
            Text(title, style: text.headlineMedium),
          ]),
        ),
        if (onRefresh != null) ApexIconButton(icon: Icons.refresh_rounded, onPressed: onRefresh),
      ]),
    );
  }
}

void _snack(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

Future<bool> _confirm(BuildContext context, String title, String message) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Annuler')),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Confirmer', style: TextStyle(color: AppColors.coral)),
        ),
      ],
    ),
  );
  return ok == true;
}

double? _num(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.').trim());

List<String> _lines(TextEditingController c) =>
    c.text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

Widget _field(TextEditingController c, String label, {bool number = false, int maxLines = 1, String? hint}) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        minLines: 1,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );

Widget _chips<T>(BuildContext context, String label, Map<T, String> options, T? value, ValueChanged<T> onChanged, {Color accent = AppColors.coral}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final e in options.entries) ApexChip(label: e.value, selected: value == e.key, accent: accent, onTap: () => onChanged(e.key)),
        ]),
      ]),
    );

// ═══ Admin home ═══════════════════════════════════════════════════════

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget tile(IconData icon, Color color, String title, String subtitle, Widget screen) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ApexCard(
            tone: ApexCardTone.glow,
            accent: color,
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen)),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: AppRadii.mdAll),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: text.titleMedium),
                  Text(subtitle, style: text.bodySmall),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            ]),
          ),
        );

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(children: [
          const _AdminHeader(title: 'Tableau de bord'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                tile(Icons.receipt_long_rounded, AppColors.amber, 'Commandes', 'Accepter, expédier, livrer, annuler', const AdminOrdersScreen()),
                tile(Icons.storefront_rounded, AppColors.coral, 'Boutique', 'Ajouter / modifier des articles, gérer le stock', const AdminProductsScreen()),
                tile(Icons.restaurant_menu_rounded, AppColors.mint, 'Nutrition', 'Ajouter des aliments et des recettes', const AdminNutritionScreen()),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══ Products ═════════════════════════════════════════════════════════

class AdminProductsScreen extends StatelessWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => AdminProductsViewModel(context.read<AppRepositories>().adminCatalog)..load(),
        child: const _AdminProductsView(),
      );
}

class _AdminProductsView extends StatefulWidget {
  const _AdminProductsView();

  @override
  State<_AdminProductsView> createState() => _AdminProductsViewState();
}

class _AdminProductsViewState extends State<_AdminProductsView> {
  final _search = TextEditingController();

  AdminProductsViewModel get vm => Provider.of<AdminProductsViewModel>(context, listen: false);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() => vm.load(_search.text);

  void _showMessage() {
    final m = vm.takeMessage();
    if (m != null && mounted) _snack(context, m);
  }

  Future<void> _openForm([AdminProduct? product]) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)));
    if (saved == true) _load();
  }

  Future<void> _changeStock(AdminProduct p, int delta) async {
    await vm.changeStock(p, delta);
    _showMessage();
  }

  Future<void> _toggleActive(AdminProduct p) async {
    final activate = p.isDeactivated;
    if (!activate && !await _confirm(context, 'Désactiver ${p.name} ?', 'Il ne sera plus visible dans la boutique. Les anciennes commandes restent intactes.')) return;
    await vm.setActive(p, activate);
    _showMessage();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<AdminProductsViewModel>();
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.coral,
        foregroundColor: AppColors.textOnVolt,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvel article'),
      ),
      body: SafeArea(
        child: Column(children: [
          _AdminHeader(title: 'Boutique', onRefresh: _load),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: TextField(
              controller: _search,
              onSubmitted: (_) => _load(),
              decoration: const InputDecoration(hintText: 'Chercher un article…', prefixIcon: Icon(Icons.search_rounded)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: vm.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.coral))
                : vm.error != null
                    ? Center(child: TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: Text(vm.error!)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.sm, AppSpacing.screenH, 100),
                          itemCount: vm.products.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (_, i) {
                            final p = vm.products[i];
                            final color = colorFromKey(p.color);
                            return Opacity(
                              opacity: p.isDeactivated ? 0.5 : 1,
                              child: ApexCard(
                                onTap: () => _openForm(p),
                                padding: const EdgeInsets.all(12),
                                child: Row(children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: AppRadii.mdAll),
                                    child: Icon(iconFromKey(p.icon), color: color),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(p.name, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text('${p.brand} · ${formatDinar(p.price)}', style: text.bodySmall),
                                      Text(
                                        p.isDeactivated ? 'Désactivé' : 'Stock : ${p.stock}',
                                        style: text.labelSmall?.copyWith(color: p.isDeactivated ? AppColors.coral : (p.stock <= 3 ? AppColors.amber : AppColors.mint)),
                                      ),
                                    ]),
                                  ),
                                  if (!p.isDeactivated) ...[
                                    IconButton(onPressed: () => _changeStock(p, -1), icon: const Icon(Icons.remove_circle_outline, color: AppColors.textTertiary)),
                                    IconButton(onPressed: () => _changeStock(p, 1), icon: const Icon(Icons.add_circle_rounded, color: AppColors.mint)),
                                  ],
                                  IconButton(
                                    tooltip: p.isDeactivated ? 'Réactiver' : 'Désactiver',
                                    onPressed: () => _toggleActive(p),
                                    icon: Icon(p.isDeactivated ? Icons.visibility_rounded : Icons.visibility_off_outlined, color: AppColors.coral),
                                  ),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ]),
      ),
    );
  }
}

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});
  final AdminProduct? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  static const _categories = {'shoes': 'Chaussures', 'apparel': 'Textile', 'strength': 'Force', 'accessories': 'Accessoires', 'recovery': 'Récupération'};
  static const _icons = {
    'fitness_center': 'Haltère',
    'directions_run': 'Running',
    'checkroom': 'Vêtement',
    'sports_handball': 'Accessoire',
    'recovery': 'Récup',
    'directions_walk': 'Marche',
    'local_mall': 'Sac',
  };
  static const _colors = {'cyan': 'Cyan', 'coral': 'Corail', 'violet': 'Violet', 'mint': 'Menthe', 'amber': 'Ambre', 'volt': 'Volt'};
  static const _badges = {'': 'Aucun', 'new': 'Nouveau', 'best_seller': 'Best-seller'};

  late final _name = TextEditingController(text: widget.product?.name);
  late final _brand = TextEditingController(text: widget.product?.brand ?? 'Apex');
  late final _price = TextEditingController(text: widget.product == null ? '' : widget.product!.price.toString());
  late final _stock = TextEditingController(text: widget.product == null ? '10' : widget.product!.stock.toString());
  late final _description = TextEditingController(text: widget.product?.json['description']?.toString());
  late final _features = TextEditingController(text: ((widget.product?.json['features'] as List?) ?? const []).join('\n'));
  late String _category = widget.product?.category ?? 'strength';
  late String _icon = widget.product?.icon ?? 'fitness_center';
  late String _color = widget.product?.color ?? 'coral';
  late String _badge = widget.product?.json['badge']?.toString() ?? '';
  late final CatalogFormViewModel _form;

  @override
  void initState() {
    super.initState();
    _form = CatalogFormViewModel(context.read<AppRepositories>().adminCatalog)..addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_name, _brand, _price, _stock, _description, _features]) {
      c.dispose();
    }
    _form.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final price = _num(_price);
    final stock = int.tryParse(_stock.text.trim());
    if (_name.text.trim().isEmpty || price == null || stock == null || _description.text.trim().isEmpty) {
      _snack(context, 'Nom, prix, stock et description sont obligatoires.');
      return;
    }
    final body = {
      'name': _name.text.trim(),
      'brand': _brand.text.trim().isEmpty ? 'Apex' : _brand.text.trim(),
      'category': _category,
      'price': price,
      'description': _description.text.trim(),
      'features': _lines(_features),
      'colorKey': _color,
      'iconKey': _icon,
      'badgeKey': _badge.isEmpty ? null : _badge,
      'stockQuantity': stock,
    };
    final ok = await _form.saveProduct(body, slug: widget.product?.id);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      _snack(context, _form.error ?? 'Erreur');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(children: [
          _AdminHeader(title: widget.product == null ? 'Nouvel article' : 'Modifier l’article'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                _field(_name, 'Nom de l’article'),
                _field(_brand, 'Marque'),
                Row(children: [
                  Expanded(child: _field(_price, 'Prix (DT)', number: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_stock, 'Stock', number: true)),
                ]),
                _field(_description, 'Description', maxLines: 4),
                _field(_features, 'Caractéristiques (une par ligne)', maxLines: 5, hint: 'Cuir véritable\n10 mm'),
                const SizedBox(height: AppSpacing.sm),
                _chips<String>(context, 'Catégorie', _categories, _category, (v) => setState(() => _category = v)),
                _chips<String>(context, 'Icône', _icons, _icon, (v) => setState(() => _icon = v)),
                _chips<String>(context, 'Couleur', _colors, _color, (v) => setState(() => _color = v)),
                _chips<String>(context, 'Badge', _badges, _badge, (v) => setState(() => _badge = v)),
                const SizedBox(height: AppSpacing.md),
                ApexButton(label: _form.busy ? 'Enregistrement…' : 'Enregistrer', icon: Icons.save_rounded, onPressed: _form.busy ? null : _save),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══ Nutrition (foods + recipes) ══════════════════════════════════════

class AdminNutritionScreen extends StatelessWidget {
  const AdminNutritionScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) {
          final repos = context.read<AppRepositories>();
          return AdminNutritionViewModel(repos.nutrition, repos.adminCatalog)..load();
        },
        child: const _AdminNutritionView(),
      );
}

class _AdminNutritionView extends StatefulWidget {
  const _AdminNutritionView();

  @override
  State<_AdminNutritionView> createState() => _AdminNutritionViewState();
}

class _AdminNutritionViewState extends State<_AdminNutritionView> {
  final _search = TextEditingController();

  AdminNutritionViewModel get vm => Provider.of<AdminNutritionViewModel>(context, listen: false);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() => vm.load();

  Future<void> _openFood([FoodItem? food]) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => FoodFormScreen(food: food)));
    if (saved == true) _load();
  }

  Future<void> _openRecipe([NutritionRecipe? recipe]) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => RecipeFormScreen(recipe: recipe)));
    if (saved == true) _load();
  }

  Future<void> _delete({FoodItem? food, NutritionRecipe? recipe}) async {
    final name = food?.name ?? recipe!.name;
    if (!await _confirm(context, 'Supprimer « $name » ?', 'Les repas déjà notés par les utilisateurs restent dans leur journal.')) return;
    await vm.delete(food: food, recipe: recipe);
    final m = vm.takeMessage();
    if (m != null && mounted) _snack(context, m);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<AdminNutritionViewModel>();
    final recipes = vm.visibleRecipes;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.mint,
        foregroundColor: AppColors.textOnVolt,
        onPressed: () => vm.tab == 0 ? _openFood() : _openRecipe(),
        icon: const Icon(Icons.add_rounded),
        label: Text(vm.tab == 0 ? 'Nouvel aliment' : 'Nouvelle recette'),
      ),
      body: SafeArea(
        child: Column(children: [
          _AdminHeader(title: 'Nutrition', onRefresh: _load),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: Row(children: [
              ApexChip(label: 'Aliments (${vm.foods.length})', selected: vm.tab == 0, accent: AppColors.mint, onTap: () => vm.selectTab(0)),
              const SizedBox(width: 8),
              ApexChip(label: 'Recettes (${vm.recipes.length})', selected: vm.tab == 1, accent: AppColors.mint, onTap: () => vm.selectTab(1)),
            ]),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: TextField(
              controller: _search,
              onChanged: vm.setQuery,
              onSubmitted: (_) => _load(),
              decoration: const InputDecoration(hintText: 'Chercher…', prefixIcon: Icon(Icons.search_rounded)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: vm.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.mint))
                : vm.error != null
                    ? Center(child: TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: Text(vm.error!)))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.sm, AppSpacing.screenH, 100),
                        children: vm.tab == 0
                            ? [
                                for (final f in vm.foods.where((f) => f.name.toLowerCase().contains(_search.text.trim().toLowerCase())))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                    child: ApexCard(
                                      onTap: () => _openFood(f),
                                      padding: const EdgeInsets.all(12),
                                      child: Row(children: [
                                        Expanded(
                                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text('${f.isTunisian ? '🇹🇳 ' : ''}${f.name}', style: text.titleSmall),
                                            Text('${f.categoryLabel} · ${f.serving} · ${f.calories} kcal · P ${fmtNum(f.protein)} g', style: text.bodySmall),
                                          ]),
                                        ),
                                        IconButton(onPressed: () => _delete(food: f), icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral)),
                                      ]),
                                    ),
                                  ),
                              ]
                            : [
                                for (final r in recipes)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                    child: ApexCard(
                                      onTap: () => _openRecipe(r),
                                      accent: r.accent,
                                      padding: const EdgeInsets.all(12),
                                      child: Row(children: [
                                        Icon(r.icon, color: r.accent),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text('${r.isTunisian ? '🇹🇳 ' : ''}${r.name}', style: text.titleSmall),
                                            Text('${r.calories} kcal · P ${fmtNum(r.protein)} g · ${r.duration} min · ${r.mealType?.label ?? 'tout repas'}', style: text.bodySmall),
                                          ]),
                                        ),
                                        IconButton(onPressed: () => _delete(recipe: r), icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral)),
                                      ]),
                                    ),
                                  ),
                              ],
                      ),
          ),
        ]),
      ),
    );
  }
}

class FoodFormScreen extends StatefulWidget {
  const FoodFormScreen({super.key, this.food});
  final FoodItem? food;

  @override
  State<FoodFormScreen> createState() => _FoodFormScreenState();
}

class _FoodFormScreenState extends State<FoodFormScreen> {
  late final _name = TextEditingController(text: widget.food?.name);
  late final _serving = TextEditingController(text: widget.food?.serving ?? '100 g');
  late final _kcal = TextEditingController(text: widget.food?.calories.toString());
  late final _protein = TextEditingController(text: widget.food == null ? '' : fmtNum(widget.food!.protein));
  late final _carbs = TextEditingController(text: widget.food == null ? '' : fmtNum(widget.food!.carbs));
  late final _fat = TextEditingController(text: widget.food == null ? '' : fmtNum(widget.food!.fat));
  late String _category = widget.food?.category ?? 'protein';
  late bool _tunisian = widget.food?.isTunisian ?? false;
  late final CatalogFormViewModel _form;

  @override
  void initState() {
    super.initState();
    _form = CatalogFormViewModel(context.read<AppRepositories>().adminCatalog)..addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_name, _serving, _kcal, _protein, _carbs, _fat]) {
      c.dispose();
    }
    _form.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final kcal = _num(_kcal);
    if (_name.text.trim().isEmpty || _serving.text.trim().isEmpty || kcal == null) {
      _snack(context, 'Nom, portion et calories sont obligatoires.');
      return;
    }
    final ok = await _form.saveFood({
        'name': _name.text.trim(),
        'category': _category,
        'serving': _serving.text.trim(),
        'calories': kcal.round(),
        'protein': _num(_protein) ?? 0,
        'carbs': _num(_carbs) ?? 0,
        'fat': _num(_fat) ?? 0,
        'isTunisian': _tunisian,
      }, id: widget.food?.id);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      _snack(context, _form.error ?? 'Erreur');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(children: [
          _AdminHeader(title: widget.food == null ? 'Nouvel aliment' : 'Modifier l’aliment'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                _field(_name, 'Nom'),
                _field(_serving, 'Portion', hint: '100 g, 1 pièce, 1 bol (300 g)…'),
                Row(children: [
                  Expanded(child: _field(_kcal, 'kcal', number: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_protein, 'Prot. (g)', number: true)),
                ]),
                Row(children: [
                  Expanded(child: _field(_carbs, 'Gluc. (g)', number: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_fat, 'Lip. (g)', number: true)),
                ]),
                const SizedBox(height: AppSpacing.sm),
                _chips<String>(context, 'Catégorie', foodCategoryLabels, _category, (v) => setState(() => _category = v), accent: AppColors.mint),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _tunisian,
                  onChanged: (v) => setState(() => _tunisian = v),
                  title: const Text('🇹🇳 Plat / aliment tunisien'),
                ),
                const SizedBox(height: AppSpacing.md),
                ApexButton(label: _form.busy ? 'Enregistrement…' : 'Enregistrer', icon: Icons.save_rounded, onPressed: _form.busy ? null : _save),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class RecipeFormScreen extends StatefulWidget {
  const RecipeFormScreen({super.key, this.recipe});
  final NutritionRecipe? recipe;

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  static const _goals = {
    'lose_weight': 'Perte de poids',
    'gain_muscle': 'Prise de muscle',
    'clean_bulk': 'Prise de masse',
    'maintain': 'Maintien',
    'endurance': 'Endurance',
  };
  static const _icons = {'rice_bowl': 'Bol', 'breakfast': 'Petit-déj', 'lunch': 'Burger', 'dinner': 'Assiette', 'blender': 'Shake', 'snack': 'Snack'};
  static const _accents = {'mint': 'Menthe', 'amber': 'Ambre', 'violet': 'Violet', 'coral': 'Corail', 'cyan': 'Cyan', 'volt': 'Volt'};

  late final _name = TextEditingController(text: widget.recipe?.name);
  late final _subtitle = TextEditingController(text: widget.recipe?.subtitle);
  late final _kcal = TextEditingController(text: widget.recipe?.calories.toString());
  late final _protein = TextEditingController(text: widget.recipe == null ? '' : fmtNum(widget.recipe!.protein));
  late final _carbs = TextEditingController(text: widget.recipe == null ? '' : fmtNum(widget.recipe!.carbs));
  late final _fat = TextEditingController(text: widget.recipe == null ? '' : fmtNum(widget.recipe!.fat));
  late final _duration = TextEditingController(text: widget.recipe?.duration.toString() ?? '15');
  late final _ingredients = TextEditingController(text: widget.recipe?.ingredients.join('\n'));
  late final _steps = TextEditingController(text: widget.recipe?.steps.join('\n'));
  late MealType? _mealType = widget.recipe?.mealType ?? MealType.lunch;
  late final Set<String> _goalTags = {...(widget.recipe?.goalTags ?? _goals.keys)};
  late String _icon = widget.recipe?.iconKey ?? 'dinner';
  late String _accent = widget.recipe?.accentKey ?? 'mint';
  late bool _tunisian = widget.recipe?.isTunisian ?? false;
  late final CatalogFormViewModel _form;

  @override
  void initState() {
    super.initState();
    _form = CatalogFormViewModel(context.read<AppRepositories>().adminCatalog)..addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_name, _subtitle, _kcal, _protein, _carbs, _fat, _duration, _ingredients, _steps]) {
      c.dispose();
    }
    _form.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final kcal = _num(_kcal);
    final protein = _num(_protein);
    final duration = int.tryParse(_duration.text.trim());
    if (_name.text.trim().isEmpty || kcal == null || protein == null || duration == null) {
      _snack(context, 'Nom, kcal, protéines et durée sont obligatoires.');
      return;
    }
    final ok = await _form.saveRecipe({
        'name': _name.text.trim(),
        'subtitle': _subtitle.text.trim(),
        'calories': kcal.round(),
        'protein': protein,
        'carbs': _num(_carbs) ?? 0,
        'fat': _num(_fat) ?? 0,
        'duration': duration,
        'mealType': _mealType?.name,
        'goalTags': _goalTags.toList(),
        'ingredients': _lines(_ingredients),
        'steps': _lines(_steps),
        'icon': _icon,
        'accent': _accent,
        'isTunisian': _tunisian,
      }, id: widget.recipe?.id);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      _snack(context, _form.error ?? 'Erreur');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(children: [
          _AdminHeader(title: widget.recipe == null ? 'Nouvelle recette' : 'Modifier la recette'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                _field(_name, 'Nom de la recette'),
                _field(_subtitle, 'Sous-titre', hint: 'Poulet · riz · légumes'),
                Row(children: [
                  Expanded(child: _field(_kcal, 'kcal', number: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_protein, 'Prot. (g)', number: true)),
                ]),
                Row(children: [
                  Expanded(child: _field(_carbs, 'Gluc. (g)', number: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_fat, 'Lip. (g)', number: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_duration, 'Durée (min)', number: true)),
                ]),
                _field(_ingredients, 'Ingrédients (un par ligne)', maxLines: 6),
                _field(_steps, 'Étapes (une par ligne)', maxLines: 6),
                const SizedBox(height: AppSpacing.sm),
                _chips<MealType?>(
                  context,
                  'Repas',
                  {for (final t in MealType.values) t: t.label, null: 'Tous'},
                  _mealType,
                  (v) => setState(() => _mealType = v),
                  accent: AppColors.mint,
                ),
                Text('Objectifs adaptés', style: text.labelSmall),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final g in _goals.entries)
                    ApexChip(
                      label: g.value,
                      selected: _goalTags.contains(g.key),
                      accent: AppColors.violet,
                      onTap: () => setState(() => _goalTags.contains(g.key) ? _goalTags.remove(g.key) : _goalTags.add(g.key)),
                    ),
                ]),
                const SizedBox(height: AppSpacing.md),
                _chips<String>(context, 'Icône', _icons, _icon, (v) => setState(() => _icon = v), accent: AppColors.mint),
                _chips<String>(context, 'Couleur', _accents, _accent, (v) => setState(() => _accent = v), accent: AppColors.mint),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _tunisian,
                  onChanged: (v) => setState(() => _tunisian = v),
                  title: const Text('🇹🇳 Recette tunisienne'),
                ),
                const SizedBox(height: AppSpacing.md),
                ApexButton(label: _form.busy ? 'Enregistrement…' : 'Enregistrer', icon: Icons.save_rounded, onPressed: _form.busy ? null : _save),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
