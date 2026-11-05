import '../core/api/api_client.dart';
import '../core/api/repositories.dart';
import '../data/shop_models.dart';
import 'base_view_model.dart';

/// Tunisian governorates (used when the API list is not available yet).
const kGovernorates = <String>[
  'Ariana', 'Béja', 'Ben Arous', 'Bizerte', 'Gabès', 'Gafsa',
  'Jendouba', 'Kairouan', 'Kasserine', 'Kébili', 'Le Kef', 'Mahdia',
  'La Manouba', 'Médenine', 'Monastir', 'Nabeul', 'Sfax', 'Sidi Bouzid',
  'Siliana', 'Sousse', 'Tataouine', 'Tozeur', 'Tunis', 'Zaghouan',
];

String _err(Object e) => e is ApiException ? e.message : '$e';

/// Shop module: catalog, favorites, cart, orders.
class ShopViewModel extends BaseViewModel {
  ShopViewModel(this._repo);
  final ShopRepository _repo;

  List<ShopProduct> products = [];
  List<ShopProduct> favoriteProducts = [];
  final favoriteIds = <String>{};
  CartData? cart;
  List<ShopOrder> orders = [];
  int tab = 0;
  ShopCategory? category;

  bool loadingProducts = true, loadingFavorites = true, loadingCart = true, loadingOrders = true;
  String? errorProducts, errorFavorites, errorCart, errorOrders;

  /// One-shot message for a SnackBar.
  String? _message;
  String? takeMessage() {
    final m = _message;
    _message = null;
    return m;
  }

  List<ShopProduct> get filteredProducts => products.where((p) => category == null || p.category == category).toList();
  int get cartCount => cart?.itemCount ?? 0;
  double get shippingCost => (cart?.subtotal ?? 0) >= 250 ? 0.0 : 8.0;

  void selectTab(int index) {
    tab = index;
    notify();
  }

  void setCategory(ShopCategory? value) {
    category = value;
    notify();
  }

  Future<void> loadAll() => Future.wait([loadProducts(), loadFavorites(), loadCart(), loadOrders()]);

  Future<void> loadProducts() async {
    loadingProducts = true;
    errorProducts = null;
    notify();
    try {
      products = await _repo.getProducts();
    } catch (e) {
      errorProducts = _err(e);
    }
    loadingProducts = false;
    notify();
  }

  Future<void> loadFavorites() async {
    loadingFavorites = true;
    errorFavorites = null;
    notify();
    try {
      favoriteProducts = await _repo.getFavorites();
      favoriteIds
        ..clear()
        ..addAll(favoriteProducts.map((p) => p.id));
    } catch (e) {
      errorFavorites = _err(e);
    }
    loadingFavorites = false;
    notify();
  }

  Future<void> loadCart() async {
    loadingCart = true;
    errorCart = null;
    notify();
    try {
      cart = await _repo.getCart();
    } catch (e) {
      errorCart = _err(e);
    }
    loadingCart = false;
    notify();
  }

  Future<void> loadOrders() async {
    loadingOrders = true;
    errorOrders = null;
    notify();
    try {
      orders = await _repo.getOrders();
    } catch (e) {
      errorOrders = _err(e);
    }
    loadingOrders = false;
    notify();
  }

  Future<ShopProduct?> productDetail(String id) async {
    try {
      return await _repo.getProduct(id);
    } catch (e) {
      _message = _err(e);
      notify();
      return null;
    }
  }

  Future<void> toggleFavorite(String slug) async {
    try {
      if (favoriteIds.contains(slug)) {
        await _repo.removeFavorite(slug);
        favoriteIds.remove(slug);
        favoriteProducts.removeWhere((p) => p.id == slug);
        notify();
      } else {
        await _repo.addFavorite(slug);
        favoriteIds.add(slug);
        notify();
        await loadFavorites();
      }
    } catch (e) {
      _message = _err(e);
      notify();
    }
  }

  Future<void> addToCart(ShopProduct product, [int quantity = 1]) async {
    try {
      cart = await _repo.addToCart(product.id, quantity);
      _message = '${product.name} ajouté au panier';
    } catch (e) {
      _message = _err(e);
    }
    notify();
  }

  Future<void> updateCartQuantity(String slug, int quantity) async {
    try {
      cart = quantity <= 0 ? await _repo.removeCartItem(slug) : await _repo.updateCartItem(slug, quantity);
    } catch (e) {
      _message = _err(e);
    }
    notify();
  }

  void orderCreated() {
    tab = 3;
    _message = 'Commande confirmée · merci pour votre confiance';
    notify();
    loadCart();
    loadOrders();
  }
}

/// Product detail: quantity, favorite, reviews.
class ProductDetailViewModel extends BaseViewModel {
  ProductDetailViewModel(this._repo, this.product, {required this.favorite});
  final ShopRepository _repo;

  ShopProduct product;
  bool favorite;
  int quantity = 1;

  void increment() {
    quantity++;
    notify();
  }

  void decrement() {
    if (quantity > 1) quantity--;
    notify();
  }

  void toggleFavorite() {
    favorite = !favorite;
    notify();
  }

  Future<bool> submitReview(double rating, String comment) async {
    if (comment.trim().isEmpty) {
      setError('Veuillez saisir un commentaire');
      return false;
    }
    return guard(() async => product = await _repo.submitReview(product.id, rating, comment.trim()));
  }
}

/// Checkout form (cash on delivery).
class CheckoutViewModel extends BaseViewModel {
  CheckoutViewModel(this._repo, this.cart);
  final ShopRepository _repo;
  final CartData cart;

  List<String> governorates = kGovernorates;
  String? selectedGovernorate;
  bool loadingGovernorates = true;

  double get shippingCost => cart.subtotal >= 250 ? 0.0 : 8.0;
  double get total => cart.subtotal + shippingCost;

  Future<void> loadGovernorates() async {
    try {
      final list = await _repo.getGovernorates();
      if (list.isNotEmpty) governorates = list;
    } catch (_) {}
    loadingGovernorates = false;
    notify();
  }

  void selectGovernorate(String? value) {
    selectedGovernorate = value;
    notify();
  }

  /// Field error by camelCase or snake_case key.
  String? fieldErrorFor(String key) {
    final camel = fieldError(key);
    if (camel != null) return camel;
    final snake = key.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');
    return fieldError(snake);
  }

  Future<ShopOrder?> submit(Map<String, dynamic> data) async {
    ShopOrder? order;
    await guard(() async => order = await _repo.createOrder({...data, 'governorate': selectedGovernorate ?? ''}));
    return order;
  }
}

/// Order detail + cancellation.
class OrderDetailViewModel extends BaseViewModel {
  OrderDetailViewModel(this._repo, this.orderNumber);
  final ShopRepository _repo;
  final String orderNumber;

  ShopOrder? order;
  bool loading = true;
  bool cancelling = false;

  Future<void> load() async {
    loading = true;
    notify();
    await guard(() async => order = await _repo.getOrder(orderNumber));
    loading = false;
    notify();
  }

  Future<bool> cancel() async {
    cancelling = true;
    notify();
    try {
      order = await _repo.cancelOrder(orderNumber);
      return true;
    } on ApiException catch (e) {
      setError(e.message);
      return false;
    } finally {
      cancelling = false;
      notify();
    }
  }
}
