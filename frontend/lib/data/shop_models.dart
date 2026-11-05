import 'package:flutter/material.dart';

import '../core/shop_keys.dart';

// ─── Category ─────────────────────────────────────────────────────────

enum ShopCategory { shoes, apparel, strength, accessories, recovery }

extension ShopCategoryX on ShopCategory {
  String get label => switch (this) {
    ShopCategory.shoes => 'Chaussures',
    ShopCategory.apparel => 'Textile',
    ShopCategory.strength => 'Force',
    ShopCategory.accessories => 'Accessoires',
    ShopCategory.recovery => 'Récupération',
  };

  IconData get icon => switch (this) {
    ShopCategory.shoes => Icons.directions_run_rounded,
    ShopCategory.apparel => Icons.checkroom_rounded,
    ShopCategory.strength => Icons.fitness_center_rounded,
    ShopCategory.accessories => Icons.sports_handball_rounded,
    ShopCategory.recovery => Icons.battery_charging_full_rounded,
  };

  Color get accent => switch (this) {
    ShopCategory.shoes => colorFromKey('cyan'),
    ShopCategory.apparel => colorFromKey('violet'),
    ShopCategory.strength => colorFromKey('coral'),
    ShopCategory.accessories => colorFromKey('amber'),
    ShopCategory.recovery => colorFromKey('mint'),
  };

  String get wireValue => name; // API uses the same lowercase names
}

ShopCategory _categoryFromString(String? value) => switch (value) {
  'shoes' => ShopCategory.shoes,
  'apparel' => ShopCategory.apparel,
  'strength' => ShopCategory.strength,
  'accessories' => ShopCategory.accessories,
  'recovery' => ShopCategory.recovery,
  _ => ShopCategory.accessories,
};

// ─── Product ──────────────────────────────────────────────────────────

class ShopProduct {
  ShopProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.description,
    required this.features,
    required this.rating,
    required this.reviewCount,
    required this.colorKey,
    required this.iconKey,
    this.badgeKey,
    this.stockQuantity = 0,
    this.reviews = const [],
  });

  final String id;
  final String name;
  final String brand;
  final ShopCategory category;
  final double price;
  final String description;
  final List<String> features;
  final double rating;
  final int reviewCount;
  final String colorKey;
  final String iconKey;
  final String? badgeKey;
  final int stockQuantity;
  final List<ShopReview> reviews;

  // Derived visual properties from keys
  Color get color => colorFromKey(colorKey);
  IconData get icon => iconFromKey(iconKey);
  String? get badgeLabel => badgeLabelFromKey(badgeKey);

  factory ShopProduct.fromJson(Map<String, dynamic> json) => ShopProduct(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    brand: json['brand']?.toString() ?? '',
    category: _categoryFromString(json['category']?.toString()),
    price: (json['price'] as num?)?.toDouble() ?? 0,
    description: json['description']?.toString() ?? '',
    features: (json['features'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    colorKey: json['color']?.toString() ?? 'cyan',
    iconKey: json['icon']?.toString() ?? 'shopping_bag',
    badgeKey: json['badge']?.toString(),
    stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
    reviews: (json['reviews'] as List?)
        ?.map((e) => ShopReview.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList() ?? const [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'category': category.wireValue,
    'price': price,
    'description': description,
    'features': features,
    'rating': rating,
    'reviewCount': reviewCount,
    'color': colorKey,
    'icon': iconKey,
    'badge': badgeKey,
    'stockQuantity': stockQuantity,
  };
}

// ─── Review ───────────────────────────────────────────────────────────

class ShopReview {
  const ShopReview({
    this.id,
    required this.author,
    required this.date,
    required this.rating,
    required this.comment,
    required this.initials,
  });

  final int? id;
  final String author;
  final String date;
  final double rating;
  final String comment;
  final String initials;

  factory ShopReview.fromJson(Map<String, dynamic> json) => ShopReview(
    id: (json['id'] as num?)?.toInt(),
    author: json['author']?.toString() ?? '',
    date: json['date']?.toString() ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    comment: json['comment']?.toString() ?? '',
    initials: json['initials']?.toString() ?? '',
  );
}

// ─── Shipping Address ─────────────────────────────────────────────────

class ShippingAddress {
  const ShippingAddress({
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.governorate,
    required this.postalCode,
  });

  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String governorate;
  final String postalCode;

  factory ShippingAddress.fromJson(Map<String, dynamic> json) => ShippingAddress(
    fullName: json['fullName']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    addressLine1: json['addressLine1']?.toString() ?? '',
    addressLine2: json['addressLine2']?.toString(),
    city: json['city']?.toString() ?? '',
    governorate: json['governorate']?.toString() ?? '',
    postalCode: json['postalCode']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'phone': phone,
    'addressLine1': addressLine1,
    'addressLine2': addressLine2,
    'city': city,
    'governorate': governorate,
    'postalCode': postalCode,
  };
}

// ─── Order Item ───────────────────────────────────────────────────────

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json['productId']?.toString() ?? '',
    productName: json['productName']?.toString() ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
  );
}

// ─── Status History Entry ─────────────────────────────────────────────

class StatusHistoryEntry {
  const StatusHistoryEntry({
    this.fromStatus,
    required this.toStatus,
    this.comment,
    required this.createdAt,
  });

  final String? fromStatus;
  final String toStatus;
  final String? comment;
  final DateTime createdAt;

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) => StatusHistoryEntry(
    fromStatus: json['fromStatus']?.toString(),
    toStatus: json['toStatus']?.toString() ?? '',
    comment: json['comment']?.toString(),
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
  );
}

// ─── Order ────────────────────────────────────────────────────────────

class ShopOrder {
  ShopOrder({
    required this.orderNumber,
    required this.date,
    this.createdAt,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    this.paidAt,
    required this.currency,
    required this.subtotal,
    required this.shippingCost,
    required this.total,
    this.notes,
    this.shippingAddress,
    this.items = const [],
    this.statusHistory = const [],
  });

  final String orderNumber;
  final String date;
  final DateTime? createdAt;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final DateTime? paidAt;
  final String currency;
  final double subtotal;
  final double shippingCost;
  final double total;
  final String? notes;
  final ShippingAddress? shippingAddress;
  final List<OrderItem> items;
  final List<StatusHistoryEntry> statusHistory;

  /// Use orderNumber as the display id.
  String get id => orderNumber;

  bool get isPending => status == 'pending';

  factory ShopOrder.fromJson(Map<String, dynamic> json) {
    ShippingAddress? address;
    if (json['shippingAddress'] != null && json['shippingAddress'] is Map) {
      address = ShippingAddress.fromJson(Map<String, dynamic>.from(json['shippingAddress'] as Map));
    }
    return ShopOrder(
      orderNumber: json['orderNumber']?.toString() ?? json['id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      status: json['status']?.toString() ?? 'pending',
      paymentStatus: json['paymentStatus']?.toString() ?? 'unpaid',
      paymentMethod: json['paymentMethod']?.toString() ?? 'cash_on_delivery',
      paidAt: DateTime.tryParse(json['paidAt']?.toString() ?? ''),
      currency: json['currency']?.toString() ?? 'TND',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      shippingCost: (json['shippingCost'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      notes: json['notes']?.toString(),
      shippingAddress: address,
      items: (json['items'] as List?)
          ?.map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList() ?? const [],
      statusHistory: (json['statusHistory'] as List?)
          ?.map((e) => StatusHistoryEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList() ?? const [],
    );
  }
}

// ─── Cart (API shape) ─────────────────────────────────────────────────

class CartData {
  const CartData({
    this.id,
    required this.items,
    required this.currency,
    required this.subtotal,
    required this.itemCount,
  });

  final int? id;
  final List<CartItem> items;
  final String currency;
  final double subtotal;
  final int itemCount;

  factory CartData.fromJson(Map<String, dynamic> json) => CartData(
    id: (json['id'] as num?)?.toInt(),
    items: (json['items'] as List?)
        ?.map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList() ?? const [],
    currency: json['currency']?.toString() ?? 'TND',
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
    itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
  );
}

class CartItem {
  const CartItem({
    this.id,
    required this.product,
    required this.quantity,
    required this.lineTotal,
  });

  final int? id;
  final ShopProduct product;
  final int quantity;
  final double lineTotal;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: (json['id'] as num?)?.toInt(),
    product: ShopProduct.fromJson(Map<String, dynamic>.from(json['product'] as Map)),
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
  );
}

// ─── Legacy local cart line (kept for UI convenience) ─────────────────

class ShopCartLine {
  const ShopCartLine({required this.product, required this.quantity});

  final ShopProduct product;
  final int quantity;

  ShopCartLine copyWith({int? quantity}) =>
      ShopCartLine(product: product, quantity: quantity ?? this.quantity);
}
