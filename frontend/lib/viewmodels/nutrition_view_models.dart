import 'dart:async';

import '../core/api/nutrition_coach_repositories.dart';
import '../data/nutrition_models.dart';
import 'base_view_model.dart';

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Nutrition module: daily summary, journal, recipes, food database.
class NutritionViewModel extends BaseViewModel {
  NutritionViewModel(this._repo, {int initialTab = 0}) : _tab = initialTab;
  final NutritionRepository _repo;

  int _tab;
  DateTime _day = DateTime.now();
  DailyNutrition? _summary;
  NutritionWeek? _week;
  List<NutritionRecipe> _recipes = const [];
  Set<String> _favorites = {};
  bool _loading = true;
  String? _message;

  String _recipeFilter = 'all'; // all | favorites | <mealType>
  String _foodQuery = '';
  String? _foodCategory;
  List<FoodItem> _foods = const [];
  bool _foodsLoading = false;
  Timer? _debounce;

  int get tab => _tab;
  DateTime get day => _day;
  bool get isToday => _sameDay(_day, DateTime.now());
  DailyNutrition? get summary => _summary;
  NutritionWeek? get week => _week;
  List<NutritionRecipe> get allRecipes => _recipes;
  Set<String> get favorites => _favorites;
  bool get loading => _loading;
  String get recipeFilter => _recipeFilter;
  String? get foodCategory => _foodCategory;
  List<FoodItem> get foods => _foods;
  bool get foodsLoading => _foodsLoading;

  String? takeMessage() {
    final m = _message;
    _message = null;
    return m;
  }

  List<NutritionRecipe> get recipes => switch (_recipeFilter) {
        'favorites' => _recipes.where((r) => _favorites.contains(r.id)).toList(),
        'all' => _recipes,
        _ => _recipes.where((r) => r.mealType?.name == _recipeFilter).toList(),
      };

  int get remainingCalories => (_summary?.targets?.calories ?? 0) - (_summary?.calories ?? 0);

  void selectTab(int index) {
    _tab = index;
    notify();
  }

  Future<void> load() async {
    _loading = true;
    notify();
    await guard(() async {
      final results = await Future.wait([_repo.summary(_day), _repo.week(), _repo.recipes(), _repo.favoriteRecipeIds()]);
      _summary = results[0] as DailyNutrition;
      _week = results[1] as NutritionWeek;
      _recipes = results[2] as List<NutritionRecipe>;
      _favorites = results[3] as Set<String>;
    });
    _loading = false;
    notify();
    await searchFoods();
  }

  Future<void> refreshDay() async {
    try {
      final results = await Future.wait([_repo.summary(_day), _repo.week()]);
      _summary = results[0] as DailyNutrition;
      _week = results[1] as NutritionWeek;
    } catch (e) {
      _message = e.toString();
    }
    notify();
  }

  void changeDay(int delta) {
    final next = _day.add(Duration(days: delta));
    if (next.isAfter(DateTime.now())) return;
    _day = next;
    notify();
    refreshDay();
  }

  /// Called after a meal was added from a sheet.
  Future<void> mealAdded() async {
    _message = 'Ajouté au journal ✔';
    await refreshDay();
  }

  Future<void> deleteMeal(MealEntry meal) async {
    final s = _summary;
    if (meal.id == null || s == null) return;
    // Optimistic update (the Dismissible must leave the tree immediately).
    _summary = DailyNutrition(
      date: s.date,
      meals: s.meals.where((m) => m.id != meal.id).toList(),
      calories: s.calories - meal.calories,
      protein: s.protein - meal.protein,
      carbs: s.carbs - meal.carbs,
      fat: s.fat - meal.fat,
      targets: s.targets,
    );
    notify();
    try {
      await _repo.deleteMeal(meal.id!);
    } catch (e) {
      _message = e.toString();
    }
    await refreshDay();
  }

  Future<void> toggleFavorite(NutritionRecipe recipe) async {
    final fav = !_favorites.contains(recipe.id);
    fav ? _favorites.add(recipe.id) : _favorites.remove(recipe.id);
    notify();
    try {
      await _repo.setFavorite(recipe.id, fav);
    } catch (e) {
      fav ? _favorites.remove(recipe.id) : _favorites.add(recipe.id);
      _message = e.toString();
      notify();
    }
  }

  void setRecipeFilter(String filter) {
    _recipeFilter = filter;
    notify();
  }

  void setFoodQuery(String query) {
    _foodQuery = query;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), searchFoods);
  }

  void setFoodCategory(String? category) {
    _foodCategory = category;
    notify();
    searchFoods();
  }

  Future<void> searchFoods() async {
    _foodsLoading = true;
    notify();
    try {
      _foods = await _repo.foods(search: _foodQuery, category: _foodCategory);
    } catch (_) {
      _foods = const [];
    }
    _foodsLoading = false;
    notify();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

/// Logs one meal (used by the food / recipe / manual-entry sheets).
class AddMealViewModel extends BaseViewModel {
  AddMealViewModel(this._repo);
  final NutritionRepository _repo;

  Future<bool> add({
    required DateTime day,
    required MealType type,
    required String name,
    required String time,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    String? foodId,
    String? recipeId,
  }) =>
      guard(() => _repo.addMeal(
            day: day,
            type: type,
            name: name,
            time: time,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            foodId: foodId,
            recipeId: recipeId,
          ));
}
