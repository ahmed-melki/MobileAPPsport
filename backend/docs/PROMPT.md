Context: Laravel backend for Flutter app "Apex". Build Orders 1-4 are done. Do not change them.
Read docs/PHASE2.md and docs/flutter-reference/ (shop_models.dart, mock_shop.dart).

Build Order 5 (Shop): tables products (slug unique, soft deletes, stock_quantity, colorKey/iconKey/badgeKey strings),
product_reviews (unique user_id+product_id), favorites, carts, cart_items (unique cart_id+product_id), orders, order_items
(product_id nullable nullOnDelete, product_name, quantity, unit_price, line_total).
Endpoints: GET /api/products (category, search, page), GET /api/products/{slug} (with reviews),
POST /api/products/{slug}/reviews (recompute rating and review_count),
GET /api/me/favorites/products, POST/DELETE /api/me/favorites/products/{slug} (idempotent),
GET /api/me/cart, POST /api/me/cart/items, PATCH/DELETE /api/me/cart/items/{slug},
POST /api/me/orders (shipping object), GET /api/me/orders.
Order creation in ONE DB transaction: lock cart, check stock, subtotal, shipping (subtotal >= 90 -> 0.00 else 6.90,
from config), create order, copy lines with unit_price snapshot, decrement stock, clear cart; rollback if stock insufficient.
Round money to 2 decimals. Order public id = orderNumber (e.g. APX-20502). payment_status is only a column, no gateway.
Seed products, reviews and past orders for Lina from mock_shop.dart.
Rules: slug is public id, camelCase, floats not strings, meta as {} when empty, English enums, all routes auth:sanctum,
no BOM. Add feature tests (stock rollback, shipping rule, review recompute, idempotent favorites).
Run php artisan migrate:fresh --seed and php artisan test. Do not stop for confirmation.
At the end print the endpoint list and one PowerShell example.
