<?php

namespace Database\Seeders;

use App\Models\CoachAthlete;
use App\Models\CoachAvailability;
use App\Models\CoachBooking;
use App\Models\CoachProfile;
use App\Models\Food;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductReview;
use App\Models\Recipe;
use App\Models\User;
use App\Models\UserProgram;
use App\Support\TrainingCatalog;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $user = User::factory()->create([
            'first_name' => 'Lina',
            'last_name' => 'Moreau',
            'email' => 'lina.moreau@apex.app',
            'password' => Hash::make('Password123!'),
            'role' => 'member',
            'city' => 'Lyon',
            'age' => 28,
            'height_cm' => 168,
            'bio' => 'Hyrox et force, 5 séances par semaine. Je veux tenir un 10 km sous 50 min sans casser mes perfs de squat.',
            'sex' => 'female',
            'main_goal' => 'endurance',
            'experience_level' => 'expert',
            'sport_level' => 'advanced',
            'days_per_week' => 5,
            'equipment' => 'gym',
            'onboarding_completed_at' => '2024-03-01 10:00:00',
            'email_verified_at' => '2024-03-01 10:00:00',
            'member_since' => '2024-03-01',
        ]);

        $user->sports()->createMany([
            ['sport_key' => 'Hyrox'],
            ['sport_key' => 'Force'],
            ['sport_key' => 'Course'],
        ]);

        $user->goals()->createMany([
            [
                'kind' => 'endurance',
                'detail' => 'Tenir le rythme sur un 10 km, sans exploser au km 7.',
                'target' => '10 km < 50 min',
                'deadline' => '2026-11-30',
                'progress' => 0.74,
                'is_active' => true,
                'is_primary' => true,
            ],
            [
                'kind' => 'weight_loss',
                'detail' => 'Descendre en douceur, garder la force sur les composés.',
                'target' => '64,0 kg',
                'deadline' => '2026-12-31',
                'progress' => 0.58,
                'is_active' => true,
                'is_primary' => false,
            ],
            [
                'kind' => 'fitness',
                'detail' => 'Ancrer 5 séances, sommeil et mobilité du lundi.',
                'target' => '5 séances / sem.',
                'deadline' => null,
                'progress' => 0.82,
                'is_active' => true,
                'is_primary' => false,
            ],
            [
                'kind' => 'mass_gain',
                'detail' => 'Cycle hypertrophie off-season — en pause pour l’instant.',
                'target' => '+3 kg lean',
                'deadline' => '2027-03-01',
                'progress' => 0.12,
                'is_active' => false,
                'is_primary' => false,
            ],
        ]);

        $user->measurements()->createMany([
            ['measured_at' => '2026-09-22', 'weight_kg' => 66.4, 'chest_cm' => 88.0, 'waist_cm' => 71.0, 'hips_cm' => 94.0, 'arm_cm' => 29.0, 'thigh_cm' => 54.5],
            ['measured_at' => '2026-09-08', 'weight_kg' => 66.9, 'chest_cm' => 88.0, 'waist_cm' => 72.0, 'hips_cm' => 94.5, 'arm_cm' => 28.8, 'thigh_cm' => 54.8],
            ['measured_at' => '2026-08-25', 'weight_kg' => 67.3, 'chest_cm' => 87.5, 'waist_cm' => 72.5, 'hips_cm' => 95.0, 'arm_cm' => 28.5, 'thigh_cm' => 55.0],
            ['measured_at' => '2026-08-11', 'weight_kg' => 67.8, 'chest_cm' => 87.5, 'waist_cm' => 73.0, 'hips_cm' => 95.0, 'arm_cm' => 28.5, 'thigh_cm' => 55.2],
            ['measured_at' => '2026-07-28', 'weight_kg' => 68.1, 'chest_cm' => 87.0, 'waist_cm' => 73.5, 'hips_cm' => 95.5, 'arm_cm' => 28.2, 'thigh_cm' => 55.5],
            ['measured_at' => '2026-07-14', 'weight_kg' => 68.4, 'chest_cm' => 87.0, 'waist_cm' => 74.0, 'hips_cm' => 96.0, 'arm_cm' => 28.0, 'thigh_cm' => 55.8],
        ]);

        TrainingCatalog::ensureSeeded();
        \App\Support\ExerciseLibrary::seed();
        \App\Support\NutritionLibrary::seed();

        $this->seedLinaHistory($user);

        UserProgram::firstOrCreate([
            'user_id' => $user->id,
            'program_slug' => 'hyrox-engine',
        ], [
            'status' => 'active',
            'started_at' => now()->subDays(2),
        ]);

        $admin = User::firstOrCreate([
            'email' => 'admin@apex.app',
        ], [
            'first_name' => 'Admin',
            'last_name' => 'Apex',
            'password' => Hash::make('Password123!'),
            'role' => 'admin',
            'city' => 'Tunis',
            'sport_level' => 'advanced',
            'experience_level' => 'expert',
            'email_verified_at' => '2024-03-01 10:00:00',
            'member_since' => '2024-03-01',
        ]);

        $this->seedNutritionAndCoaches($user);
        $this->seedShop($user);
    }

    private function seedShop(User $lina): void
    {
        $products = [
            ['slug' => 'aero-runner-x', 'name' => 'Aero Runner X', 'brand' => 'Nord Athletics', 'category' => 'shoes', 'price' => 380.000, 'description' => 'Une chaussure légère et nerveuse pour les séances tempo, les sorties longues et les transitions Hyrox.', 'features' => ['Plaque de propulsion composite', 'Mousse retour d’énergie', 'Drop 6 mm · 238 g'], 'rating' => 4.8, 'review_count' => 126, 'color_key' => 'cyan', 'icon_key' => 'directions_run', 'badge_key' => 'best_seller', 'stock_quantity' => 12],
            ['slug' => 'apex-lift-02', 'name' => 'Apex Lift 02', 'brand' => 'Forge Lab', 'category' => 'strength', 'price' => 290.000, 'description' => 'Stabilité maximale et maintien précis pour vos séances de force, du squat au deadlift.', 'features' => ['Semelle rigide 20 mm', 'Talon renforcé', 'Empeigne respirante'], 'rating' => 4.9, 'review_count' => 84, 'color_key' => 'coral', 'icon_key' => 'fitness_center', 'badge_key' => 'new', 'stock_quantity' => 9],
            ['slug' => 'motion-tee', 'name' => 'Motion Tee', 'brand' => 'Apex Studio', 'category' => 'apparel', 'price' => 85.000, 'description' => 'T-shirt technique ultra léger, coupe athlétique et séchage rapide pour bouger sans contrainte.', 'features' => ['Tissu recyclé 140 g', 'Anti-odeurs longue durée', 'Coupe regular athlétique'], 'rating' => 4.7, 'review_count' => 53, 'color_key' => 'violet', 'icon_key' => 'checkroom', 'badge_key' => null, 'stock_quantity' => 18],
            ['slug' => 'training-straps', 'name' => 'Training Straps Pro', 'brand' => 'Grip Culture', 'category' => 'accessories', 'price' => 35.000, 'description' => 'Des sangles robustes pour verrouiller votre prise et pousser plus loin vos tirages.', 'features' => ['Coton tissé 4 cm', 'Boucle acier brossé', 'Charge testée à 250 kg'], 'rating' => 4.6, 'review_count' => 39, 'color_key' => 'amber', 'icon_key' => 'sports_handball', 'badge_key' => null, 'stock_quantity' => 25],
            ['slug' => 'recovery-roll', 'name' => 'Recovery Roll', 'brand' => 'Reset Athletics', 'category' => 'recovery', 'price' => 65.000, 'description' => 'Rouleau dense à reliefs pour relâcher les jambes après une séance chargée.', 'features' => ['Noyau haute densité', 'Reliefs 3 zones', 'Format compact 30 cm'], 'rating' => 4.8, 'review_count' => 67, 'color_key' => 'mint', 'icon_key' => 'recovery', 'badge_key' => null, 'stock_quantity' => 14],
            ['slug' => 'velocity-shorts', 'name' => 'Velocity Shorts', 'brand' => 'Apex Studio', 'category' => 'apparel', 'price' => 95.000, 'description' => 'Short de training avec poche téléphone sécurisée et liberté de mouvement totale.', 'features' => ['Doublure intégrée', 'Poche zippée', 'Tissu stretch 4 directions'], 'rating' => 4.5, 'review_count' => 31, 'color_key' => 'violet', 'icon_key' => 'directions_walk', 'badge_key' => null, 'stock_quantity' => 20],
        ];
        foreach ($products as $product) Product::firstOrCreate(['slug' => $product['slug']], $product);

        $reviewers = [
            ['email' => 'thomas.shop@apex.app', 'first_name' => 'Thomas', 'last_name' => 'R'],
            ['email' => 'camille.shop@apex.app', 'first_name' => 'Camille', 'last_name' => 'D'],
            ['email' => 'sami.shop@apex.app', 'first_name' => 'Sami', 'last_name' => 'B'],
        ];
        foreach ($reviewers as $reviewer) {
            User::firstOrCreate(['email' => $reviewer['email']], ['first_name' => $reviewer['first_name'], 'last_name' => $reviewer['last_name'], 'email_verified_at' => now(), 'password' => Hash::make('Password123!'), 'role' => 'member']);
        }
        $reviews = [
            ['email' => 'thomas.shop@apex.app', 'product' => 'aero-runner-x', 'rating' => 5, 'comment' => 'Très dynamique sur les intervalles, et aucune gêne après 15 km.'],
            ['email' => 'camille.shop@apex.app', 'product' => 'aero-runner-x', 'rating' => 4.5, 'comment' => 'Bonne accroche sur piste et chemins secs.'],
            ['email' => 'sami.shop@apex.app', 'product' => 'apex-lift-02', 'rating' => 5, 'comment' => 'La différence sur mes squats est immédiate. Maintien impeccable.'],
        ];
        foreach ($reviews as $review) {
            $reviewer = User::where('email', $review['email'])->firstOrFail();
            $product = Product::where('slug', $review['product'])->firstOrFail();
            ProductReview::firstOrCreate(['user_id' => $reviewer->id, 'product_id' => $product->id], ['rating' => $review['rating'], 'comment' => $review['comment']]);
        }
        foreach (Product::all() as $product) {
            $reviewsForProduct = $product->reviews();
            if ($reviewsForProduct->count() > 0) $product->update(['rating' => round((float) $reviewsForProduct->avg('rating'), 2), 'review_count' => $reviewsForProduct->count()]);
        }

        $lina->productFavorites()->firstOrCreate(['product_id' => Product::where('slug', 'aero-runner-x')->value('id')]);
        $cart = $lina->cart()->firstOrCreate([]);
        $cart->items()->firstOrCreate(['product_id' => Product::where('slug', 'recovery-roll')->value('id')], ['quantity' => 1]);

        $orders = [
            [
                'number' => 'APX-20481',
                'daysAgo' => 22,
                'status' => 'delivered',
                'subtotal' => 415.000,
                'shipping' => 0.000,
                'total' => 415.000,
                'items' => [
                    ['slug' => 'aero-runner-x', 'quantity' => 1],
                    ['slug' => 'training-straps', 'quantity' => 1],
                ],
            ],
            [
                'number' => 'APX-19872',
                'daysAgo' => 69,
                'status' => 'delivered',
                'subtotal' => 85.000,
                'shipping' => 8.000,
                'total' => 93.000,
                'items' => [
                    ['slug' => 'motion-tee', 'quantity' => 1],
                ],
            ],
        ];
        foreach ($orders as $orderData) {
            $order = Order::firstOrCreate(
                ['order_number' => $orderData['number']],
                [
                    'user_id' => $lina->id,
                    'subtotal' => $orderData['subtotal'],
                    'shipping' => $orderData['shipping'],
                    'total' => $orderData['total'],
                    'currency' => 'TND',
                    'status' => $orderData['status'],
                    'payment_status' => 'paid',
                    'payment_method' => 'cash_on_delivery',
                    'paid_at' => now()->subDays($orderData['daysAgo']),
                    'shipping_address' => [
                        'fullName' => 'Lina Moreau',
                        'phone' => '+21698123456',
                        'addressLine1' => '12 rue des Sports',
                        'addressLine2' => null,
                        'city' => 'Tunis',
                        'governorate' => 'Tunis',
                        'postalCode' => '1001',
                    ],
                ]
            );
            foreach ($orderData['items'] as $item) {
                $product = Product::where('slug', $item['slug'])->firstOrFail();
                $order->items()->firstOrCreate(
                    ['product_id' => $product->id],
                    [
                        'product_name' => $product->name,
                        'quantity' => $item['quantity'],
                        'unit_price' => $product->price,
                        'line_total' => round($product->price * $item['quantity'], 3),
                    ]
                );
            }
            $createdAt = now()->subDays($orderData['daysAgo']);
            $order->created_at = $createdAt;
            $order->save();

            if ($order->statusHistories()->count() === 0) {
                $order->statusHistories()->createMany([
                    ['from_status' => null, 'to_status' => 'pending', 'comment' => 'Order placed by customer.', 'changed_by_user_id' => $lina->id, 'created_at' => $createdAt],
                    ['from_status' => 'pending', 'to_status' => 'confirmed', 'comment' => 'Order confirmed.', 'changed_by_user_id' => null, 'created_at' => $createdAt->copy()->addHours(1)],
                    ['from_status' => 'confirmed', 'to_status' => 'shipped', 'comment' => 'Order shipped.', 'changed_by_user_id' => null, 'created_at' => $createdAt->copy()->addDays(1)],
                    ['from_status' => 'shipped', 'to_status' => 'delivered', 'comment' => 'Order delivered and paid.', 'changed_by_user_id' => null, 'created_at' => $createdAt->copy()->addDays(2)],
                ]);
            }
        }
    }

    private function seedNutritionAndCoaches(User $lina): void
    {
        $foods = [
            ['slug' => 'roast-chicken', 'name' => 'Blanc de poulet rôti', 'category' => 'protein', 'serving' => '100 g', 'calories' => 165, 'protein' => 31, 'carbs' => 0, 'fat' => 4],
            ['slug' => 'cooked-basmati-rice', 'name' => 'Riz basmati cuit', 'category' => 'starch', 'serving' => '150 g', 'calories' => 195, 'protein' => 4, 'carbs' => 42, 'fat' => 0],
            ['slug' => 'plain-skyr', 'name' => 'Skyr nature', 'category' => 'dairy', 'serving' => '150 g', 'calories' => 92, 'protein' => 16, 'carbs' => 6, 'fat' => 0],
            ['slug' => 'banana', 'name' => 'Banane', 'category' => 'fruit', 'serving' => '1 moyenne', 'calories' => 105, 'protein' => 1, 'carbs' => 27, 'fat' => 0],
            ['slug' => 'avocado', 'name' => 'Avocat', 'category' => 'fruit', 'serving' => '1/2 pièce', 'calories' => 160, 'protein' => 2, 'carbs' => 8, 'fat' => 15],
            ['slug' => 'almonds', 'name' => 'Amandes', 'category' => 'nuts', 'serving' => '30 g', 'calories' => 174, 'protein' => 6, 'carbs' => 6, 'fat' => 15],
        ];
        foreach ($foods as $food) Food::firstOrCreate(['slug' => $food['slug']], $food);

        $recipes = [
            ['slug' => 'power-bowl', 'name' => 'Power bowl poulet', 'subtitle' => 'Riz complet · avocat · légumes verts', 'calories' => 610, 'protein' => 46, 'duration' => 25, 'icon_key' => 'rice_bowl', 'accent_key' => 'mint'],
            ['slug' => 'recovery-toast', 'name' => 'Tartines recovery', 'subtitle' => 'Pain complet · œufs · cottage cheese', 'calories' => 430, 'protein' => 31, 'duration' => 12, 'icon_key' => 'breakfast', 'accent_key' => 'amber'],
            ['slug' => 'smoothie-pro', 'name' => 'Smoothie post-training', 'subtitle' => 'Banane · cacao · whey · lait', 'calories' => 360, 'protein' => 29, 'duration' => 5, 'icon_key' => 'blender', 'accent_key' => 'violet'],
            ['slug' => 'salmon-pasta', 'name' => 'Pasta saumon citron', 'subtitle' => 'Pâtes · saumon · épinards frais', 'calories' => 720, 'protein' => 42, 'duration' => 30, 'icon_key' => 'dinner', 'accent_key' => 'coral'],
        ];
        foreach ($recipes as $recipe) Recipe::firstOrCreate(['slug' => $recipe['slug']], $recipe);

        $lina->nutritionTarget()->updateOrCreate([], ['calories' => 2350, 'protein' => 150, 'carbs' => 260, 'fat' => 70]);
        $meals = [
            ['type' => 'breakfast', 'name' => 'Porridge banane & whey', 'time' => '07:40', 'calories' => 520, 'protein' => 32, 'carbs' => 68, 'fat' => 14, 'food_id' => 'banana'],
            ['type' => 'lunch', 'name' => 'Bowl poulet, riz & légumes', 'time' => '12:45', 'calories' => 680, 'protein' => 48, 'carbs' => 76, 'fat' => 18, 'food_id' => 'roast-chicken'],
            ['type' => 'snack', 'name' => 'Skyr, fruits rouges & amandes', 'time' => '16:20', 'calories' => 290, 'protein' => 24, 'carbs' => 25, 'fat' => 10, 'food_id' => 'plain-skyr'],
        ];
        foreach ($meals as $meal) $lina->mealEntries()->create(array_merge($meal, ['date' => now()->toDateString()]));
        $lina->favoriteRecipes()->firstOrCreate(['recipe_slug' => 'power-bowl']);

        $coachData = [
            ['slug' => 'marion-leroy', 'email' => 'marion.leroy@apex.app', 'first_name' => 'Marion', 'last_name' => 'Leroy', 'name' => 'Marion Leroy', 'role' => 'Coach performance & force', 'specialties' => ['strength', 'hyrox'], 'bio' => 'J’accompagne les sportifs qui veulent devenir plus forts sans perdre leur vitesse.', 'rating' => 4.9, 'review_count' => 118, 'sessions' => 642, 'price' => 55, 'initials' => 'ML', 'accent_key' => 'coral', 'is_online' => true],
            ['slug' => 'antoine-bazin', 'email' => 'antoine.bazin@apex.app', 'first_name' => 'Antoine', 'last_name' => 'Bazin', 'name' => 'Antoine Bazin', 'role' => 'Coach running & endurance', 'specialties' => ['running', 'mobility'], 'bio' => 'Du premier 10 km au marathon, je construis une progression durable.', 'rating' => 4.8, 'review_count' => 86, 'sessions' => 391, 'price' => 48, 'initials' => 'AB', 'accent_key' => 'cyan', 'is_online' => false],
            ['slug' => 'ines-roche', 'email' => 'ines.roche@apex.app', 'first_name' => 'Inès', 'last_name' => 'Roche', 'name' => 'Inès Roche', 'role' => 'Coach nutrition sportive', 'specialties' => ['nutrition', 'hyrox'], 'bio' => 'Une alimentation simple, flexible et adaptée à votre charge d’entraînement.', 'rating' => 5.0, 'review_count' => 64, 'sessions' => 248, 'price' => 42, 'initials' => 'IR', 'accent_key' => 'mint', 'is_online' => true],
            ['slug' => 'lucas-meyer', 'email' => 'lucas.meyer@apex.app', 'first_name' => 'Lucas', 'last_name' => 'Meyer', 'name' => 'Lucas Meyer', 'role' => 'Coach mobilité & prévention', 'specialties' => ['mobility', 'strength'], 'bio' => 'Retrouver de l’amplitude, bouger sans appréhension et mieux récupérer.', 'rating' => 4.7, 'review_count' => 51, 'sessions' => 207, 'price' => 45, 'initials' => 'LM', 'accent_key' => 'violet', 'is_online' => true],
        ];
        foreach ($coachData as $data) {
            $coachUser = User::firstOrCreate(['email' => $data['email']], ['first_name' => $data['first_name'], 'last_name' => $data['last_name'], 'email_verified_at' => now(), 'password' => Hash::make('Password123!'), 'role' => 'coach']);
            $profile = CoachProfile::firstOrCreate(['slug' => $data['slug']], array_diff_key($data, array_flip(['email', 'first_name', 'last_name', 'specialties'])) + ['user_id' => $coachUser->id]);
            foreach ($data['specialties'] as $specialty) $profile->specialties()->firstOrCreate(['specialty' => $specialty]);
            for ($slot = 1; $slot <= 3; $slot++) $profile->availabilities()->firstOrCreate(['scheduled_at' => now()->addDays($slot)->setTime(7 + $slot, 30)], ['duration_min' => 30, 'status' => 'available']);
        }

        $marion = CoachProfile::where('slug', 'marion-leroy')->firstOrFail();
        $availability = $marion->availabilities()->orderBy('scheduled_at')->firstOrFail();
        $availability->update(['status' => 'booked']);
        $booking = CoachBooking::firstOrCreate(['user_id' => $lina->id, 'availability_id' => $availability->id], ['coach_profile_id' => $marion->id, 'scheduled_at' => $availability->scheduled_at, 'type' => 'performance_review', 'status' => 'confirmed']);
        CoachAthlete::firstOrCreate(['coach_profile_id' => $marion->id, 'user_id' => $lina->id], ['goal' => 'Hyrox · 12 weeks', 'progress' => 0.72, 'last_session_at' => now()->subDay()]);
    }

    private function seedLinaHistory(User $user): void
    {
        $history = [
            ['daysAgo' => 20, 'sessionId' => 'f5-b', 'programId' => 'five-five', 'sessionTitle' => 'Séance B · Deadlift / press', 'programTitle' => 'Force 5×5', 'durationMin' => 52, 'highlight' => 'Deadlift 5×5 @ 100 kg', 'exercises' => [['exerciseId' => 'deadlift', 'sets' => 5, 'reps' => 5, 'loadKg' => 100]]],
            ['daysAgo' => 18, 'sessionId' => 'hyrox-s3', 'programId' => 'hyrox-engine', 'sessionTitle' => 'S3 · Upper + carries', 'programTitle' => 'Hyrox Engine', 'durationMin' => 55, 'highlight' => 'Bench 4×6 @ 47.5 kg', 'exercises' => [['exerciseId' => 'bench', 'sets' => 4, 'reps' => 6, 'loadKg' => 47.5]]],
            ['daysAgo' => 16, 'sessionId' => 'hyrox-s1', 'programId' => 'hyrox-engine', 'sessionTitle' => 'S1 · Lower power', 'programTitle' => 'Hyrox Engine', 'durationMin' => 64, 'highlight' => 'Squat 4×6 @ 82.5 kg', 'exercises' => [['exerciseId' => 'squat', 'sets' => 4, 'reps' => 6, 'loadKg' => 82.5], ['exerciseId' => 'deadlift', 'sets' => 3, 'reps' => 5, 'loadKg' => 95]]],
            ['daysAgo' => 14, 'sessionId' => 'f5-a', 'programId' => 'five-five', 'sessionTitle' => 'Séance A · Squat / bench', 'programTitle' => 'Force 5×5', 'durationMin' => 50, 'highlight' => 'Squat 5×5 @ 85 kg', 'exercises' => [['exerciseId' => 'squat', 'sets' => 5, 'reps' => 5, 'loadKg' => 85], ['exerciseId' => 'bench', 'sets' => 5, 'reps' => 5, 'loadKg' => 45]]],
            ['daysAgo' => 12, 'sessionId' => 'hyrox-s4', 'programId' => 'hyrox-engine', 'sessionTitle' => 'S4 · Mixed piece', 'programTitle' => 'Hyrox Engine', 'durationMin' => 40, 'highlight' => 'Wall balls 3×25', 'exercises' => [['exerciseId' => 'wallball', 'sets' => 3, 'reps' => 25, 'loadKg' => 6]]],
            ['daysAgo' => 10, 'sessionId' => 'f5-b', 'programId' => 'five-five', 'sessionTitle' => 'Séance B · Deadlift / press', 'programTitle' => 'Force 5×5', 'durationMin' => 52, 'highlight' => 'Deadlift 5×5 @ 102.5 kg', 'exercises' => [['exerciseId' => 'deadlift', 'sets' => 5, 'reps' => 5, 'loadKg' => 102.5]]],
            ['daysAgo' => 8, 'sessionId' => 'hyrox-s3', 'programId' => 'hyrox-engine', 'sessionTitle' => 'S3 · Upper + carries', 'programTitle' => 'Hyrox Engine', 'durationMin' => 55, 'highlight' => 'Bench 4×6 @ 50 kg', 'exercises' => [['exerciseId' => 'bench', 'sets' => 4, 'reps' => 6, 'loadKg' => 50]]],
            ['daysAgo' => 8, 'sessionId' => 'hyrox-s2', 'programId' => 'hyrox-engine', 'sessionTitle' => 'S2 · Engine', 'programTitle' => 'Hyrox Engine', 'durationMin' => 47, 'highlight' => 'Engine intervals', 'exercises' => [['exerciseId' => 'ski', 'sets' => 4, 'reps' => 500, 'loadKg' => 0, 'kind' => 'distance']]],
            ['daysAgo' => 4, 'sessionId' => 'hyrox-s1', 'programId' => 'hyrox-engine', 'sessionTitle' => 'S1 · Lower power', 'programTitle' => 'Hyrox Engine', 'durationMin' => 64, 'highlight' => 'Squat 4×6 @ 85 kg', 'exercises' => [['exerciseId' => 'squat', 'sets' => 4, 'reps' => 6, 'loadKg' => 85], ['exerciseId' => 'deadlift', 'sets' => 3, 'reps' => 5, 'loadKg' => 100]]],
            ['daysAgo' => 3, 'sessionId' => 'f5-a', 'programId' => 'five-five', 'sessionTitle' => 'Séance A · Squat / bench', 'programTitle' => 'Force 5×5', 'durationMin' => 50, 'highlight' => 'Squat 5×5 @ 87.5 kg', 'exercises' => [['exerciseId' => 'squat', 'sets' => 5, 'reps' => 5, 'loadKg' => 87.5], ['exerciseId' => 'bench', 'sets' => 5, 'reps' => 5, 'loadKg' => 47.5]]],
            ['daysAgo' => 2, 'sessionId' => 'hyrox-s3', 'programId' => 'hyrox-engine', 'sessionTitle' => 'S3 · Upper + carries', 'programTitle' => 'Hyrox Engine', 'durationMin' => 55, 'highlight' => 'Bench 4×6 @ 52.5 kg', 'exercises' => [['exerciseId' => 'bench', 'sets' => 4, 'reps' => 6, 'loadKg' => 52.5]]],
            ['daysAgo' => 1, 'sessionId' => 'f5-b', 'programId' => 'five-five', 'sessionTitle' => 'Séance B · Deadlift / press', 'programTitle' => 'Force 5×5', 'durationMin' => 52, 'highlight' => 'Deadlift 5×5 @ 105 kg', 'exercises' => [['exerciseId' => 'deadlift', 'sets' => 5, 'reps' => 5, 'loadKg' => 105]]],
            ['daysAgo' => 0, 'sessionId' => 'hyrox-s1', 'programId' => 'hyrox-engine', 'sessionTitle' => 'S1 · Lower power', 'programTitle' => 'Hyrox Engine', 'durationMin' => 64, 'highlight' => 'Squat 4×6 @ 90 kg', 'exercises' => [['exerciseId' => 'squat', 'sets' => 4, 'reps' => 6, 'loadKg' => 90], ['exerciseId' => 'deadlift', 'sets' => 3, 'reps' => 5, 'loadKg' => 105]]],
        ];

        foreach ($history as $entry) {
            $completedAt = now()->subDays($entry['daysAgo'])->setTime(18, 30);
            $log = $user->sessionLogs()->create([
                'session_slug' => $entry['sessionId'],
                'program_slug' => $entry['programId'],
                'session_title' => $entry['sessionTitle'],
                'program_title' => $entry['programTitle'],
                'completed_at' => $completedAt,
                'date' => $completedAt->toDateString(),
                'duration_min' => $entry['durationMin'],
                'highlight' => $entry['highlight'],
            ]);

            foreach ($entry['exercises'] as $exercise) {
                for ($setNumber = 1; $setNumber <= $exercise['sets']; $setNumber++) {
                    $log->sets()->create([
                        'exercise_slug' => $exercise['exerciseId'],
                        'set_number' => $setNumber,
                        'reps' => $exercise['reps'],
                        'load_kg' => $exercise['loadKg'],
                        'kind' => $exercise['kind'] ?? 'load',
                    ]);
                }
            }
        }
    }
}
