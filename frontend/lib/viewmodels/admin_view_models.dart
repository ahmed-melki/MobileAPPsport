import '../core/api/api_client.dart';
import '../core/api/nutrition_coach_repositories.dart';
import '../data/nutrition_models.dart';
import 'base_view_model.dart';

/// Admin: list of orders with a status filter.
class AdminOrdersViewModel extends BaseViewModel {
  AdminOrdersViewModel(this._repo);
  final AdminRepository _repo;

  static const filters = <String?>[null, 'pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];

  List<AdminOrder> orders = const [];
  String? filter = 'pending';
  bool loading = true;

  List<AdminOrder> get visible => filter == null ? orders : orders.where((o) => o.order.status == filter).toList();
  double get pendingTotal => orders.where((o) => o.order.status == 'pending').fold<double>(0, (s, o) => s + o.order.total);
  int count(String? status) => status == null ? orders.length : orders.where((o) => o.order.status == status).length;

  void setFilter(String? value) {
    filter = value;
    notify();
  }

  Future<void> load() async {
    loading = orders.isEmpty;
    notify();
    await guard(
      () async => orders = await _repo.orders(),
      errorMessage: (e) => e.statusCode == 403 ? 'Accès réservé aux administrateurs.' : e.message,
    );
    loading = false;
    notify();
  }
}

/// Admin: one order and its status transitions.
class AdminOrderDetailViewModel extends BaseViewModel {
  AdminOrderDetailViewModel(this._repo, this.orderNumber);
  final AdminRepository _repo;
  final String orderNumber;

  AdminOrder? item;
  bool changed = false;

  Future<void> load() => guard(() async => item = await _repo.order(orderNumber));

  Future<bool> transition(String status, String comment) async {
    final ok = await guard(() async => item = await _repo.updateStatus(orderNumber, status, comment: comment));
    if (ok) changed = true;
    return ok;
  }
}

String apiError(Object e) => e is ApiException ? e.message : '$e';

/// Admin: shop products (stock, activation).
class AdminProductsViewModel extends BaseViewModel {
  AdminProductsViewModel(this._repo);
  final AdminCatalogRepository _repo;

  List<AdminProduct> products = const [];
  bool loading = true;
  String search = '';
  String? _message;

  String? takeMessage() {
    final m = _message;
    _message = null;
    return m;
  }

  Future<void> load([String? query]) async {
    if (query != null) search = query;
    await guard(() async => products = await _repo.products(search: search));
    loading = false;
    notify();
  }

  Future<void> changeStock(AdminProduct p, int delta) => _run(() => _repo.updateStock(p.id, (p.stock + delta).clamp(0, 100000)));

  Future<void> setActive(AdminProduct p, bool active) => _run(() => _repo.setProductActive(p.id, active));

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      await load();
    } catch (e) {
      _message = apiError(e);
      notify();
    }
  }
}

/// Admin: foods and recipes library.
class AdminNutritionViewModel extends BaseViewModel {
  AdminNutritionViewModel(this._nutrition, this._catalog);
  final NutritionRepository _nutrition;
  final AdminCatalogRepository _catalog;

  int tab = 0;
  String query = '';
  List<FoodItem> foods = const [];
  List<NutritionRecipe> recipes = const [];
  bool loading = true;
  String? _message;

  String? takeMessage() {
    final m = _message;
    _message = null;
    return m;
  }

  List<NutritionRecipe> get visibleRecipes {
    final q = query.trim().toLowerCase();
    return q.isEmpty ? recipes : recipes.where((r) => r.name.toLowerCase().contains(q)).toList();
  }

  void selectTab(int value) {
    tab = value;
    notify();
  }

  void setQuery(String value) {
    query = value;
    notify();
  }

  Future<void> load() async {
    await guard(() async {
      final results = await Future.wait([_nutrition.foods(search: query), _nutrition.recipes()]);
      foods = results[0] as List<FoodItem>;
      recipes = results[1] as List<NutritionRecipe>;
    });
    loading = false;
    notify();
  }

  Future<void> delete({FoodItem? food, NutritionRecipe? recipe}) async {
    try {
      if (food != null) {
        await _catalog.deleteFood(food.id);
      } else if (recipe != null) {
        await _catalog.deleteRecipe(recipe.id);
      }
      await load();
    } catch (e) {
      _message = apiError(e);
      notify();
    }
  }
}

/// Admin forms (product, food, recipe): validation is done in the View,
/// the ViewModel sends the data to the API and exposes busy / error.
class CatalogFormViewModel extends BaseViewModel {
  CatalogFormViewModel(this._repo);
  final AdminCatalogRepository _repo;

  Future<bool> saveProduct(Map<String, dynamic> body, {String? slug}) => guard(() async {
        if (slug == null) {
          await _repo.createProduct(body);
        } else {
          await _repo.updateProduct(slug, body);
        }
      });

  Future<bool> saveFood(Map<String, dynamic> body, {String? id}) => guard(() => _repo.saveFood(body, id: id));

  Future<bool> saveRecipe(Map<String, dynamic> body, {String? id}) => guard(() => _repo.saveRecipe(body, id: id));
}
