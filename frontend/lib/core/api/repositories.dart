import '../../data/onboarding_models.dart';
import '../../data/profile_models.dart';
import '../../data/shop_models.dart';
import '../../data/training_models.dart';
import 'api_client.dart';

abstract interface class ProfileRepository {
  Future<ProfileBundle> loadProfile();
  Future<SportProfile> loadMe();
  Future<SportProfile> updateProfile(SportProfile profile);
  Future<List<SportGoal>> loadGoals();
  Future<SportGoal> createGoal(SportGoal goal);
  Future<SportGoal> updateGoal(SportGoal goal);
  Future<void> deleteGoal(int goalId);
  Future<List<BodySnapshot>> loadMeasurements();
  Future<BodySnapshot> addMeasurement(BodySnapshot measurement);
  Future<DashboardData> loadDashboard();
  Future<List<RecommendedProgramItem>> submitOnboarding(OnboardingPayload payload);
  Future<List<RecommendedProgramItem>> loadRecommendations();
  Future<void> startProgram(String slug);
  Future<List<Map<String, dynamic>>> loadUserPrograms();
}

class DashboardData {
  const DashboardData({required this.firstName, required this.readiness, required this.streakDays, required this.weeklySessions});
  final String firstName;
  final int readiness;
  final int streakDays;
  final int weeklySessions;
  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(firstName: json['firstName']?.toString() ?? '', readiness: (json['readiness'] as num? ?? 0).toInt(), streakDays: (json['streakDays'] as num? ?? 0).toInt(), weeklySessions: (json['weeklySessions'] as num? ?? 0).toInt());
}

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._client);
  final ApiClient _client;
  @override
  Future<ProfileBundle> loadProfile() async {
    final profile = SportProfile.fromJson(Map<String, dynamic>.from(await _client.get('/me') as Map));
    final goals = await loadGoals();
    final measurements = await loadMeasurements();
    final logs = (await _client.get('/me/session-logs') as List)
        .map((item) => SessionLog.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    return ProfileBundle(profile: profile, goals: goals, measurements: measurements, activity: _activityFor(logs));
  }
  @override
  Future<SportProfile> loadMe() async => SportProfile.fromJson(Map<String, dynamic>.from(await _client.get('/me') as Map));
  @override
  Future<SportProfile> updateProfile(SportProfile profile) async => SportProfile.fromJson(Map<String, dynamic>.from(await _client.put('/me', data: profile.toJson()) as Map));
  @override
  Future<List<SportGoal>> loadGoals() async => (await _client.get('/me/goals') as List).map((item) => SportGoal.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  @override
  Future<SportGoal> createGoal(SportGoal goal) async => SportGoal.fromJson(Map<String, dynamic>.from(await _client.post('/me/goals', data: goal.toJson()) as Map));
  @override
  Future<SportGoal> updateGoal(SportGoal goal) async => SportGoal.fromJson(Map<String, dynamic>.from(await _client.patch('/me/goals/${goal.id}', data: goal.toJson()) as Map));
  @override
  Future<void> deleteGoal(int goalId) async { await _client.delete('/me/goals/$goalId'); }
  @override
  Future<List<BodySnapshot>> loadMeasurements() async => (await _client.get('/me/measurements') as List).map((item) => BodySnapshot.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  @override
  Future<BodySnapshot> addMeasurement(BodySnapshot measurement) async => BodySnapshot.fromJson(Map<String, dynamic>.from(await _client.post('/me/measurements', data: measurement.toJson()) as Map));
  @override
  Future<DashboardData> loadDashboard() async => DashboardData.fromJson(Map<String, dynamic>.from(await _client.get('/me/dashboard') as Map));

  @override
  Future<List<RecommendedProgramItem>> submitOnboarding(OnboardingPayload payload) async {
    final res = await _client.post('/me/onboarding', data: payload.toJson());
    if (res is Map && res['recommendations'] is List) {
      return (res['recommendations'] as List)
          .map((item) => RecommendedProgramItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return loadRecommendations();
  }

  @override
  Future<List<RecommendedProgramItem>> loadRecommendations() async {
    final list = await _client.get('/me/recommendations') as List;
    return list
        .map((item) => RecommendedProgramItem.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  @override
  Future<void> startProgram(String slug) async {
    await _client.post('/me/programs/$slug/start');
  }

  @override
  Future<List<Map<String, dynamic>>> loadUserPrograms() async {
    final list = await _client.get('/me/programs') as List;
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  List<ActivityWeek> _activityFor(List<SessionLog> logs) {
    if (logs.isEmpty) return const [];
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final buckets = <DateTime, List<SessionLog>>{
      for (var index = 7; index >= 0; index--)
        monday.subtract(Duration(days: index * 7)): <SessionLog>[],
    };
    for (final log in logs) {
      final date = log.date.toLocal();
      final week = DateTime(date.year, date.month, date.day - (date.weekday - 1));
      if (buckets.containsKey(week)) buckets[week]!.add(log);
    }
    return buckets.entries.map((entry) {
      final minutes = entry.value.fold<int>(0, (sum, log) => sum + log.durationMin);
      return ActivityWeek(start: entry.key, sessions: entry.value.length, minutes: minutes, kcal: minutes * 8);
    }).toList();
  }
}

abstract interface class TrainingRepository {
  Future<TrainingCatalog> loadCatalog();
  Future<SessionLog> createSessionLog({required String sessionId, required String programId, required DateTime completedAt, required int durationMin, required String highlight, required List<Map<String, dynamic>> sets});
}

class ApiTrainingRepository implements TrainingRepository {
  ApiTrainingRepository(this._client);
  final ApiClient _client;
  @override
  Future<TrainingCatalog> loadCatalog() async {
    // 4 requests in parallel (the program list already contains its sessions).
    final results = await Future.wait([
      _client.get('/exercises'),
      _client.get('/training/programs'),
      _client.get('/me/session-logs'),
      _client.get('/me/training-progress'),
    ]);
    final exercises = results[0] as List;
    final programs = results[1] as List;
    final sessions = <Map<String, dynamic>>[
      for (final program in programs)
        ...((program as Map)['sessions'] as List? ?? const []).map((item) => Map<String, dynamic>.from(item as Map)),
    ];
    final logs = results[2] as List;
    final lifts = results[3] as List;
    return TrainingCatalog(
      exercises: exercises.map((e) => CatalogExercise.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      programs: programs.map((p) => TrainingProgram.fromJson(Map<String, dynamic>.from(p as Map))).toList(),
      sessions: sessions.map(WorkoutSession.fromJson).toList(),
      logs: logs.map((l) => SessionLog.fromJson(Map<String, dynamic>.from(l as Map))).toList(),
      lifts: lifts.map((l) => LiftProgress.fromJson(Map<String, dynamic>.from(l as Map))).toList(),
    );
  }
  @override
  Future<SessionLog> createSessionLog({required String sessionId, required String programId, required DateTime completedAt, required int durationMin, required String highlight, required List<Map<String, dynamic>> sets}) async => SessionLog.fromJson(Map<String, dynamic>.from(await _client.post('/me/session-logs', data: {'sessionId': sessionId, 'programId': programId, 'completedAt': completedAt.toUtc().toIso8601String().replaceFirst('+00:00', 'Z'), 'durationMin': durationMin, 'highlight': highlight, 'sets': sets}) as Map));
}

// ─── Shop Repository ──────────────────────────────────────────────────

abstract interface class ShopRepository {
  Future<List<ShopProduct>> getProducts({String? category, String? search});
  Future<ShopProduct> getProduct(String slug);
  Future<List<ShopProduct>> getFavorites();
  Future<void> addFavorite(String slug);
  Future<void> removeFavorite(String slug);
  Future<CartData> getCart();
  Future<CartData> addToCart(String productSlug, int quantity);
  Future<CartData> updateCartItem(String slug, int quantity);
  Future<CartData> removeCartItem(String slug);
  Future<List<String>> getGovernorates();
  Future<ShopOrder> createOrder(Map<String, dynamic> data);
  Future<List<ShopOrder>> getOrders();
  Future<ShopOrder> getOrder(String orderNumber);
  Future<ShopOrder> cancelOrder(String orderNumber);
  Future<ShopProduct> submitReview(String slug, double rating, String comment);
}

class ApiShopRepository implements ShopRepository {
  ApiShopRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<ShopProduct>> getProducts({String? category, String? search}) async {
    final params = <String, dynamic>{};
    if (category != null) params['category'] = category;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final result = await _client.get('/products', queryParameters: params);
    final list = result is List ? result : (result is Map && result['data'] is List ? result['data'] as List : <dynamic>[]);
    return list.map((e) => ShopProduct.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<ShopProduct> getProduct(String slug) async {
    final data = await _client.get('/products/$slug');
    return ShopProduct.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<List<ShopProduct>> getFavorites() async {
    final result = await _client.get('/me/favorites/products');
    final list = result is List ? result : <dynamic>[];
    return list.map((e) => ShopProduct.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<void> addFavorite(String slug) async {
    await _client.post('/me/favorites/products/$slug');
  }

  @override
  Future<void> removeFavorite(String slug) async {
    await _client.delete('/me/favorites/products/$slug');
  }

  @override
  Future<CartData> getCart() async {
    final data = await _client.get('/me/cart');
    return CartData.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<CartData> addToCart(String productSlug, int quantity) async {
    final data = await _client.post('/me/cart/items', data: {'productId': productSlug, 'quantity': quantity});
    return CartData.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<CartData> updateCartItem(String slug, int quantity) async {
    final data = await _client.patch('/me/cart/items/$slug', data: {'quantity': quantity});
    return CartData.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<CartData> removeCartItem(String slug) async {
    final data = await _client.delete('/me/cart/items/$slug');
    return CartData.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<List<String>> getGovernorates() async {
    final data = await _client.get('/shop/governorates');
    if (data is List) return data.map((e) => e.toString()).toList();
    return const [];
  }

  @override
  Future<ShopOrder> createOrder(Map<String, dynamic> data) async {
    final result = await _client.post('/me/orders', data: data);
    return ShopOrder.fromJson(Map<String, dynamic>.from(result as Map));
  }

  @override
  Future<List<ShopOrder>> getOrders() async {
    final result = await _client.get('/me/orders');
    final list = result is List ? result : <dynamic>[];
    return list.map((e) => ShopOrder.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<ShopOrder> getOrder(String orderNumber) async {
    final data = await _client.get('/me/orders/$orderNumber');
    return ShopOrder.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<ShopOrder> cancelOrder(String orderNumber) async {
    final data = await _client.post('/me/orders/$orderNumber/cancel');
    return ShopOrder.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<ShopProduct> submitReview(String slug, double rating, String comment) async {
    final data = await _client.post('/products/$slug/reviews', data: {'rating': rating, 'comment': comment});
    return ShopProduct.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
