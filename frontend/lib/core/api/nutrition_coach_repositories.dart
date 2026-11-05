import '../../data/ai_coach_models.dart';
import '../../data/ai_recommendation_models.dart';
import '../../data/nutrition_models.dart';
import '../../data/shop_models.dart';
import '../../data/training_models.dart';
import 'api_client.dart';

// ─── Nutrition ─────────────────────────────────────────────────────────

class NutritionRepository {
  NutritionRepository(this._client);
  final ApiClient _client;

  Future<DailyNutrition> summary(DateTime day) async =>
      DailyNutrition.fromJson(Map<String, dynamic>.from(await _client.get('/me/nutrition/summary', queryParameters: {'date': apiDate(day)}) as Map));

  Future<NutritionWeek> week() async => NutritionWeek.fromJson(Map<String, dynamic>.from(await _client.get('/me/nutrition/week') as Map));

  Future<List<NutritionRecipe>> recipes() async =>
      (await _client.get('/nutrition/recipes') as List).map((e) => NutritionRecipe.fromJson(Map<String, dynamic>.from(e as Map))).toList();

  Future<List<FoodItem>> foods({String? search, String? category, bool tunisian = false}) async {
    final query = <String, dynamic>{
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (category != null) 'category': category,
      if (tunisian) 'tunisian': 1,
    };
    return (await _client.get('/nutrition/foods', queryParameters: query) as List)
        .map((e) => FoodItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Set<String>> favoriteRecipeIds() async =>
      (await _client.get('/me/favorites/recipes') as List).map((e) => (e as Map)['id'].toString()).toSet();

  Future<void> setFavorite(String recipeId, bool favorite) async {
    if (favorite) {
      await _client.post('/me/favorites/recipes/$recipeId');
    } else {
      await _client.delete('/me/favorites/recipes/$recipeId');
    }
  }

  Future<MealEntry> addMeal({
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
  }) async {
    final data = await _client.post('/me/meals', data: {
      'date': apiDate(day),
      'type': type.name,
      'name': name,
      'time': time,
      'calories': calories,
      'protein': double.parse(protein.toStringAsFixed(1)),
      'carbs': double.parse(carbs.toStringAsFixed(1)),
      'fat': double.parse(fat.toStringAsFixed(1)),
      if (foodId != null) 'foodId': foodId,
      if (recipeId != null) 'recipeId': recipeId,
    });
    return MealEntry.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> deleteMeal(int id) async => _client.delete('/me/meals/$id');
}

// ─── Coach Apex (AI) ───────────────────────────────────────────────────

class CoachRepository {
  CoachRepository(this._client);
  final ApiClient _client;

  Future<DailyPlan> today() async {
    final now = DateTime.now();
    final data = await _client.get('/me/coach/today', queryParameters: {'date': apiDate(now), 'hour': now.hour});
    return DailyPlan.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<ChatMessage> chat(String message, List<ChatMessage> history) async {
    final now = DateTime.now();
    final data = Map<String, dynamic>.from(await _client.post('/me/coach/chat', data: {
      'message': message,
      'history': history.length > 10 ? history.sublist(history.length - 10).map((m) => m.toJson()).toList() : history.map((m) => m.toJson()).toList(),
      'date': apiDate(now),
      'hour': now.hour,
    }) as Map);
    return ChatMessage(role: 'assistant', content: data['reply']?.toString() ?? '', source: data['source']?.toString());
  }

  /// AI training recommendation (goal + level).
  Future<AiTrainingAdvice> trainingAdvice() async =>
      AiTrainingAdvice.fromJson(Map<String, dynamic>.from(await _client.get('/me/ai/training') as Map));

  /// AI nutrition recommendation (goal + today's meals).
  Future<AiNutritionAdvice> nutritionAdvice() async => AiNutritionAdvice.fromJson(
      Map<String, dynamic>.from(await _client.get('/me/ai/nutrition', queryParameters: {'hour': DateTime.now().hour}) as Map));
}

// ─── Exercises ─────────────────────────────────────────────────────────

class ExerciseRepository {
  ExerciseRepository(this._client);
  final ApiClient _client;

  Future<ExerciseDetail> detail(String id) async =>
      ExerciseDetail.fromJson(Map<String, dynamic>.from(await _client.get('/exercises/$id') as Map));
}

// ─── Admin (orders) ────────────────────────────────────────────────────

class AdminOrder {
  const AdminOrder({required this.order, this.customerName, this.customerEmail});

  final ShopOrder order;
  final String? customerName;
  final String? customerEmail;

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] is Map ? Map<String, dynamic>.from(json['customer'] as Map) : null;
    return AdminOrder(
      order: ShopOrder.fromJson(json),
      customerName: customer?['name']?.toString(),
      customerEmail: customer?['email']?.toString(),
    );
  }
}

class AdminRepository {
  AdminRepository(this._client);
  final ApiClient _client;

  Future<List<AdminOrder>> orders({String? status}) async {
    final data = await _client.get('/admin/orders', queryParameters: {
      'perPage': 100,
      if (status != null) 'status': status,
    });
    return (data as List).map((e) => AdminOrder.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<AdminOrder> order(String orderNumber) async =>
      AdminOrder.fromJson(Map<String, dynamic>.from(await _client.get('/admin/orders/$orderNumber') as Map));

  Future<AdminOrder> updateStatus(String orderNumber, String status, {String? comment}) async {
    final data = await _client.patch('/admin/orders/$orderNumber/status', data: {
      'status': status,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    });
    return AdminOrder.fromJson(Map<String, dynamic>.from(data as Map));
  }
}

// ─── Admin (catalog: products, foods, recipes) ────────────────────────

/// Product row for the admin (raw JSON kept so the form can prefill everything).
class AdminProduct {
  const AdminProduct(this.json);
  final Map<String, dynamic> json;

  String get id => json['id']?.toString() ?? '';
  String get name => json['name']?.toString() ?? '';
  String get brand => json['brand']?.toString() ?? '';
  String get category => json['category']?.toString() ?? '';
  double get price => (json['price'] as num? ?? 0).toDouble();
  int get stock => (json['stockQuantity'] as num? ?? 0).toInt();
  bool get isDeactivated => json['isDeactivated'] == true;
  String? get color => json['color']?.toString();
  String? get icon => json['icon']?.toString();
}

class AdminCatalogRepository {
  AdminCatalogRepository(this._client);
  final ApiClient _client;

  Future<List<AdminProduct>> products({String? search}) async {
    final data = await _client.get('/admin/products', queryParameters: {
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    });
    return (data as List).map((e) => AdminProduct(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<AdminProduct> createProduct(Map<String, dynamic> body) async =>
      AdminProduct(Map<String, dynamic>.from(await _client.post('/admin/products', data: body) as Map));

  Future<AdminProduct> updateProduct(String slug, Map<String, dynamic> body) async =>
      AdminProduct(Map<String, dynamic>.from(await _client.put('/admin/products/$slug', data: body) as Map));

  Future<AdminProduct> updateStock(String slug, int stock) async =>
      AdminProduct(Map<String, dynamic>.from(await _client.patch('/admin/products/$slug/stock', data: {'stockQuantity': stock}) as Map));

  Future<void> setProductActive(String slug, bool active) async =>
      _client.patch('/admin/products/$slug/${active ? 'restore' : 'deactivate'}');

  Future<FoodItem> saveFood(Map<String, dynamic> body, {String? id}) async {
    final data = id == null ? await _client.post('/admin/foods', data: body) : await _client.put('/admin/foods/$id', data: body);
    return FoodItem.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> deleteFood(String id) async => _client.delete('/admin/foods/$id');

  Future<NutritionRecipe> saveRecipe(Map<String, dynamic> body, {String? id}) async {
    final data = id == null ? await _client.post('/admin/recipes', data: body) : await _client.put('/admin/recipes/$id', data: body);
    return NutritionRecipe.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> deleteRecipe(String id) async => _client.delete('/admin/recipes/$id');
}

/// Allowed admin transitions (mirror of OrderStatusService on the backend).
const adminTransitions = <String, List<String>>{
  'pending': ['confirmed', 'cancelled'],
  'confirmed': ['shipped', 'cancelled'],
  'shipped': ['delivered'],
  'delivered': [],
  'cancelled': [],
};
