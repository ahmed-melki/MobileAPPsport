# Apex API design (condensed from approved Phase 2)

Stack: Laravel 11+, PHP 8.2, MySQL/MariaDB (port 3307), Sanctum.

## Global rules
- All JSON keys camelCase (requests and responses).
- Envelope: {"data":..., "meta":..., "message":...}. Errors: {"message":..., "errors":{field:[...]}}.
- Decimals cast to float in API Resources. Money rounded to 2 decimals.
- Catalog entities (exercises, programs, sessions, recipes, foods, products, coaches) expose their slug as "id". User-owned records expose the numeric id.
- Enums are lowercase English values. No Color/IconData stored (use keys).
- Register always creates role "member". Roles: member, coach, admin.
- Admin CRUD, messaging, push, real payments are out of scope. Catalogs come from seeders.

## Build Order 1: Auth + Profile
users: id, first_name, last_name, email unique, password, role enum(member,coach,admin) default member,
city, age, height_cm, bio, sport_level enum(beginner,intermediate,advanced), member_since date, timestamps.
user_sports: user_id, sport_key, unique(user_id, sport_key).
goals: user_id, kind enum(mass_gain,weight_loss,endurance,fitness), detail, target, deadline date nullable,
progress decimal(5,4), is_active, is_primary, timestamps. Only one primary per user (transaction in PATCH).
body_measurements: user_id, measured_at date, weight_kg, chest_cm, waist_cm, hips_cm, arm_cm, thigh_cm decimal(6,2),
index(user_id, measured_at).

Endpoints:
- POST /api/auth/register {firstName,lastName,email,password,passwordConfirmation} -> {user, token}
- POST /api/auth/login {email,password} -> {user, token} (rate limited)
- POST /api/auth/logout (auth)
- GET /api/me -> id, firstName, lastName, email, role, city, age, heightCm, bio, level, sports[], memberSince
- PUT /api/me {firstName,lastName,city,age,heightCm,bio,level,sports[]}
- GET /api/me/goals ; POST /api/me/goals ; PATCH /api/me/goals/{goal} ; DELETE /api/me/goals/{goal}
  goal JSON: id, kind, detail, target, deadline (Y-m-d), progress (0..1), active, primary
- GET /api/me/measurements ; POST /api/me/measurements
  JSON: id, date, weightKg, chestCm, waistCm, hipsCm, armCm, thighCm
- GET /api/me/dashboard -> firstName, readiness, streakDays, weeklySessions (computed from session_logs; 0 until Training exists)

Readiness = round(min(sessions_last_7_days/5,1)*100*0.5 + distinct_active_weeks_last_28_days/4*100*0.3 + min(streak/7,1)*100*0.2), capped 0..100.

## Later build orders (do NOT build yet)
2 Training, 3 Nutrition, 4 Coaches, 5 Shop. Full details will be provided per step.
Key rules for later: coach_bookings has NO unique (coach_id, scheduled_at); unique only on coach_availabilities,
booking locks availability row and sets it booked, cancel/decline sets it available. session_log_sets has a kind column.
Coach confirm creates coach_athletes row if missing. Product rating/review_count recomputed on review. Favorites idempotent.
Orders in a DB transaction (stock check, copy cart to order_items with unit_price snapshot, decrement stock, clear cart).
Shipping: subtotal >= 90 -> 0.00 else 6.90 (config value).
