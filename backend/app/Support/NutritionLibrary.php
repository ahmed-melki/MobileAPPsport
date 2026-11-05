<?php

namespace App\Support;

use App\Models\Food;
use App\Models\Recipe;

/**
 * Healthy food + recipe library (French).
 * Only whole / minimally processed foods and balanced recipes:
 * no fried dishes, pastries, sodas or fatty street food.
 * Values are per serving (standard food composition tables).
 *
 * Seed: `php artisan db:seed --class=LibrarySeeder`
 */
class NutritionLibrary
{
    /** Old non-healthy entries removed from the database when seeding. */
    public const REMOVED_FOODS = [
        'lamb', 'merguez', 'tuna-oil', 'bread-baguette', 'mlawi', 'tabouna', 'butter', 'bsissa', 'makroudh', 'bambalouni',
        'citronnade', 'tea-mint-sugar', 'soda', 'coffee-milk', 'couscous-chicken', 'couscous-lamb', 'couscous-fish', 'lablabi',
        'brik-egg', 'brik-tuna', 'ojja', 'ojja-light', 'kafteji', 'mloukhia', 'makloub', 'chapati-tn', 'fricasse', 'tajine-tn',
        'kammounia', 'marka-jelbana', 'loubia', 'spaghetti-tn', 'mhamsa', 'assida-zgougou', 'harissa', 'pasta-cooked',
        'potato', 'honey', 'dark-chocolate', 'chorba-frik',
    ];

    public const REMOVED_RECIPES = [
        'ojja-fit', 'lablabi-fit', 'couscous-fit', 'mloukhia-light', 'kammounia-fit', 'bsissa-shake', 'tajine-fit', 'brik-oven',
        'mhamsa-chicken', 'mass-gainer-shake', 'peanut-banana-toast', 'chorba-frik-fit', 'mechouia-tuna', 'salade-tunisienne-fit',
        'dates-energy-balls', 'grilled-sardines', 'chicken-wrap', 'beef-rice-bowl', 'white-fish-veggies',
        'greek-yogurt-bowl', 'turkey-sweet-potato', 'lentil-soup', 'quinoa-salad', 'egg-white-omelette', 'tuna-salad', 'overnight-oats',
    ];

    /** [slug, name, category, serving, kcal, protein, carbs, fat, local (Tunisian product)] */
    public static function foods(): array
    {
        return [
            // Protéines maigres
            ['roast-chicken', 'Blanc de poulet grillé', 'protein', '100 g', 165, 31, 0, 3.6, false],
            ['turkey-breast', 'Escalope de dinde', 'protein', '100 g', 135, 29, 0, 2, false],
            ['chicken-thigh', 'Cuisse de poulet sans peau', 'protein', '100 g', 177, 24, 0, 9, false],
            ['lean-beef', 'Bœuf haché 5 %', 'protein', '100 g', 137, 21, 0, 5, false],
            ['beef-steak', 'Steak de bœuf maigre', 'protein', '100 g', 160, 28, 0, 5, false],
            ['egg', 'Œuf entier', 'protein', '1 œuf (50 g)', 72, 6, 0.4, 5, false],
            ['egg-white', 'Blancs d’œufs', 'protein', '100 g', 52, 11, 0.7, 0.2, false],
            ['tuna-can', 'Thon au naturel', 'protein', '1 boîte (100 g)', 116, 26, 0, 1, false],
            ['salmon', 'Saumon', 'protein', '100 g', 208, 20, 0, 13, false],
            ['smoked-salmon', 'Saumon fumé', 'protein', '50 g', 90, 11, 0, 5, false],
            ['sardines', 'Sardines grillées', 'protein', '100 g', 208, 25, 0, 11, true],
            ['white-fish', 'Poisson blanc grillé (daurade, loup)', 'protein', '100 g', 120, 22, 0, 3, true],
            ['shrimp', 'Crevettes', 'protein', '100 g', 99, 24, 0.2, 0.3, false],
            ['whey', 'Whey protéine', 'protein', '1 dose (30 g)', 120, 24, 3, 1.5, false],
            ['tofu', 'Tofu', 'protein', '100 g', 144, 15, 3, 9, false],
            ['tempeh', 'Tempeh', 'protein', '100 g', 192, 20, 8, 11, false],
            ['edamame', 'Edamame', 'protein', '100 g', 121, 12, 9, 5, false],
            // Laitages
            ['plain-skyr', 'Skyr nature', 'dairy', '150 g', 92, 16, 6, 0, false],
            ['greek-yogurt', 'Yaourt grec 0 %', 'dairy', '150 g', 88, 15, 6, 0.5, false],
            ['yogurt', 'Yaourt nature', 'dairy', '1 pot (125 g)', 75, 5, 6, 3.5, false],
            ['milk-semi', 'Lait demi-écrémé', 'dairy', '250 ml', 115, 8, 12, 4, false],
            ['almond-milk', 'Lait d’amande sans sucre', 'dairy', '250 ml', 35, 1, 1, 2.5, false],
            ['leben', 'Leben (lait fermenté)', 'dairy', '250 ml', 110, 8, 11, 4, true],
            ['cottage-cheese', 'Cottage cheese', 'dairy', '100 g', 98, 11, 3, 4, false],
            ['ricotta', 'Ricotta allégée', 'dairy', '100 g', 138, 11, 5, 8, false],
            ['feta', 'Feta', 'dairy', '30 g', 79, 4, 1, 6, false],
            // Féculents complets
            ['oats', 'Flocons d’avoine', 'starch', '50 g', 190, 7, 32, 3.5, false],
            ['bread-whole', 'Pain complet', 'starch', '2 tranches (60 g)', 150, 6, 26, 2, false],
            ['sourdough', 'Pain au levain complet', 'starch', '1 tranche (40 g)', 100, 4, 19, 0.6, false],
            ['rye-bread', 'Pain de seigle', 'starch', '1 tranche (35 g)', 90, 3, 17, 0.6, false],
            ['wholegrain-wrap', 'Tortilla complète', 'starch', '1 pièce (60 g)', 170, 5, 28, 4, false],
            ['brown-rice', 'Riz complet cuit', 'starch', '150 g', 165, 4, 34, 1.3, false],
            ['cooked-basmati-rice', 'Riz basmati cuit', 'starch', '150 g', 195, 4, 42, 0, false],
            ['quinoa', 'Quinoa cuit', 'starch', '150 g', 180, 7, 32, 3, false],
            ['wholewheat-pasta', 'Pâtes complètes cuites', 'starch', '150 g', 186, 8, 37, 1.5, false],
            ['couscous-cooked', 'Couscous complet cuit', 'starch', '150 g', 165, 6, 33, 0.6, true],
            ['borghol', 'Boulgour cuit', 'starch', '150 g', 125, 5, 28, 0.4, true],
            ['frik', 'Frik (blé vert) cuit', 'starch', '150 g', 170, 6, 33, 1, true],
            ['sweet-potato', 'Patate douce cuite', 'starch', '200 g', 180, 3, 41, 0.3, false],
            ['buckwheat', 'Sarrasin cuit', 'starch', '150 g', 138, 5, 30, 1, false],
            ['rice-cakes', 'Galettes de riz complet', 'starch', '2 galettes (18 g)', 70, 1.4, 15, 0.5, false],
            // Légumineuses
            ['chickpeas', 'Pois chiches cuits', 'legume', '150 g', 246, 13, 41, 4, true],
            ['lentils', 'Lentilles cuites', 'legume', '150 g', 174, 14, 30, 0.6, true],
            ['white-beans', 'Haricots blancs cuits', 'legume', '150 g', 209, 14, 37, 0.6, false],
            ['red-beans', 'Haricots rouges cuits', 'legume', '150 g', 190, 13, 34, 0.8, false],
            ['hummus', 'Houmous', 'legume', '2 c. à soupe (40 g)', 70, 3, 6, 4, false],
            ['green-peas', 'Petits pois', 'legume', '150 g', 120, 8, 21, 0.6, false],
            // Fruits
            ['avocado', 'Avocat', 'fruit', '1/2 pièce', 160, 2, 8, 15, false],
            ['banana', 'Banane', 'fruit', '1 moyenne', 105, 1, 27, 0, false],
            ['apple', 'Pomme', 'fruit', '1 moyenne', 95, 0.5, 25, 0.3, false],
            ['orange', 'Orange', 'fruit', '1 moyenne', 62, 1.2, 15, 0.2, true],
            ['kiwi', 'Kiwi', 'fruit', '2 pièces', 84, 1.6, 20, 0.7, false],
            ['blueberries', 'Myrtilles', 'fruit', '100 g', 57, 0.7, 14, 0.3, false],
            ['strawberries', 'Fraises', 'fruit', '150 g', 48, 1, 11, 0.5, false],
            ['raspberries', 'Framboises', 'fruit', '100 g', 52, 1.2, 12, 0.7, false],
            ['mixed-berries', 'Fruits rouges (surgelés)', 'fruit', '100 g', 50, 1, 11, 0.3, false],
            ['pear', 'Poire', 'fruit', '1 moyenne', 100, 0.6, 27, 0.2, false],
            ['grapes', 'Raisin', 'fruit', '150 g', 104, 1, 27, 0.2, false],
            ['watermelon', 'Pastèque', 'fruit', '300 g', 90, 1.8, 23, 0.5, true],
            ['pomegranate', 'Grenade', 'fruit', '1/2 grenade (100 g)', 83, 1.7, 19, 1.2, true],
            ['figs', 'Figues fraîches', 'fruit', '2 figues (100 g)', 74, 0.8, 19, 0.3, true],
            ['dates', 'Dattes deglet nour', 'fruit', '3 dattes (25 g)', 70, 0.6, 19, 0.1, true],
            ['mango', 'Mangue', 'fruit', '150 g', 90, 1.2, 22, 0.6, false],
            ['pineapple', 'Ananas', 'fruit', '150 g', 75, 0.8, 20, 0.2, false],
            // Légumes
            ['broccoli', 'Brocoli', 'vegetable', '150 g', 51, 4, 10, 0.6, false],
            ['spinach', 'Épinards', 'vegetable', '150 g', 35, 4, 5, 0.6, false],
            ['kale', 'Chou kale', 'vegetable', '80 g', 28, 2.4, 4, 0.5, false],
            ['tomato', 'Tomate', 'vegetable', '1 moyenne (120 g)', 22, 1, 5, 0.2, false],
            ['cherry-tomato', 'Tomates cerises', 'vegetable', '100 g', 18, 0.9, 4, 0.2, false],
            ['cucumber', 'Concombre', 'vegetable', '150 g', 23, 1, 5, 0.2, false],
            ['pepper', 'Poivron', 'vegetable', '1 pièce (150 g)', 30, 1.3, 7, 0.3, false],
            ['carrot', 'Carotte', 'vegetable', '1 moyenne (80 g)', 33, 0.7, 8, 0.2, false],
            ['zucchini', 'Courgette', 'vegetable', '200 g', 34, 2.4, 6, 0.6, false],
            ['green-beans', 'Haricots verts', 'vegetable', '150 g', 47, 2.7, 10, 0.2, false],
            ['asparagus', 'Asperges', 'vegetable', '150 g', 30, 3.3, 6, 0.2, false],
            ['mushrooms', 'Champignons', 'vegetable', '100 g', 22, 3, 3, 0.3, false],
            ['green-salad', 'Salade verte', 'vegetable', '1 bol (80 g)', 12, 1, 2, 0.2, false],
            ['beetroot', 'Betterave cuite', 'vegetable', '100 g', 44, 1.7, 10, 0.2, false],
            ['cauliflower', 'Chou-fleur', 'vegetable', '150 g', 38, 3, 7, 0.4, false],
            ['salade-tunisienne', 'Salade tunisienne (sans œuf ni thon)', 'vegetable', '1 bol (200 g)', 90, 2, 10, 5, true],
            ['salade-mechouia', 'Salade méchouia (légumes grillés)', 'vegetable', '1 portion (150 g)', 110, 2.5, 10, 7, true],
            // Bonnes graisses
            ['olive-oil', 'Huile d’olive extra vierge', 'fat', '1 c. à soupe (10 ml)', 90, 0, 0, 10, true],
            ['olives', 'Olives', 'fat', '10 olives (40 g)', 58, 0.4, 1.5, 6, true],
            ['almonds', 'Amandes', 'nuts', '30 g', 174, 6, 6, 15, false],
            ['walnuts', 'Noix', 'nuts', '30 g', 196, 4.5, 4, 19.5, false],
            ['pistachios', 'Pistaches', 'nuts', '30 g', 170, 6, 8, 13.5, false],
            ['cashews', 'Noix de cajou', 'nuts', '30 g', 165, 5, 9, 13, false],
            ['peanut-butter', 'Beurre de cacahuète 100 %', 'nuts', '1 c. à soupe (16 g)', 94, 4, 3, 8, false],
            ['chia-seeds', 'Graines de chia', 'nuts', '1 c. à soupe (12 g)', 58, 2, 5, 3.7, false],
            ['flax-seeds', 'Graines de lin', 'nuts', '1 c. à soupe (10 g)', 53, 1.8, 2.9, 4.2, false],
            ['pumpkin-seeds', 'Graines de courge', 'nuts', '20 g', 112, 6, 2, 9.5, false],
            // Snacks sains & boissons
            ['protein-bar', 'Barre protéinée (sans sucre ajouté)', 'snack', '1 barre (60 g)', 210, 20, 20, 7, false],
            ['dark-chocolate-85', 'Chocolat noir 85 %', 'snack', '15 g', 90, 1.5, 3, 7.5, false],
            ['orange-juice', 'Jus d’orange pressé', 'drink', '200 ml', 90, 1.4, 21, 0.4, true],
            ['green-tea', 'Thé vert sans sucre', 'drink', '1 tasse', 2, 0, 0, 0, false],
            ['black-coffee', 'Café noir', 'drink', '1 tasse', 2, 0.3, 0, 0, false],
            ['coconut-water', 'Eau de coco', 'drink', '250 ml', 48, 0.5, 11, 0.5, false],
        ];
    }

    /**
     * [slug, name, subtitle, kcal, protein, carbs, fat, duration, mealType, goalTags, ingredients, steps, icon, accent, local]
     */
    public static function recipes(): array
    {
        $all = ['lose_weight', 'maintain', 'gain_muscle', 'clean_bulk', 'endurance'];
        $cut = ['lose_weight', 'maintain'];
        $bulk = ['gain_muscle', 'clean_bulk', 'endurance'];

        return [
            // Petit-déjeuner
            ['avocado-toast-egg', 'Avocado toast & œuf poché', 'Pain complet · avocat · œuf · graines', 390, 17, 30, 22, 10, 'breakfast', $all, ['2 tranches de pain complet', '1/2 avocat', '1 œuf', 'Citron, piment, graines de courge'], ['Toaste le pain.', 'Écrase l’avocat avec citron, sel et poivre.', 'Poche l’œuf 3 min et dépose-le sur la tartine.'], 'breakfast', 'mint', false],
            ['avocado-toast-salmon', 'Avocado toast saumon fumé', 'Pain au levain · avocat · saumon', 360, 19, 22, 21, 8, 'breakfast', $all, ['2 tranches de pain au levain', '1/2 avocat', '50 g saumon fumé', 'Aneth, citron'], ['Toaste le pain.', 'Étale l’avocat écrasé.', 'Ajoute le saumon, l’aneth et un filet de citron.'], 'breakfast', 'coral', false],
            ['avocado-toast-cottage', 'Toast avocat & cottage cheese', 'Seigle · avocat · cottage · tomates cerises', 330, 18, 26, 16, 7, 'breakfast', $cut, ['2 tranches de pain de seigle', '1/4 avocat', '100 g cottage cheese', 'Tomates cerises'], ['Toaste le pain.', 'Tartine le cottage puis l’avocat en tranches.', 'Ajoute les tomates, sel, poivre.'], 'breakfast', 'mint', false],
            ['recovery-toast', 'Tartines recovery', 'Pain complet · œufs · cottage cheese', 430, 31, 38, 15, 12, 'breakfast', $all, ['2 tranches pain complet', '2 œufs', '80 g cottage cheese', 'Tomate'], ['Toaste le pain.', 'Prépare des œufs brouillés.', 'Tartine cottage cheese puis œufs et tomate.'], 'breakfast', 'amber', false],
            ['protein-oats', 'Porridge protéiné aux fruits rouges', 'Avoine · whey · fruits rouges', 410, 31, 52, 8, 7, 'breakfast', $all, ['50 g flocons d’avoine', '200 ml lait d’amande', '1/2 dose whey', '100 g fruits rouges'], ['Cuis l’avoine dans le lait 3 min.', 'Hors du feu, ajoute la whey.', 'Garnis de fruits rouges.'], 'breakfast', 'violet', false],
            ['overnight-oats-skyr', 'Overnight oats skyr & myrtilles', 'Avoine · skyr · chia · myrtilles', 400, 28, 54, 8, 5, 'breakfast', $all, ['50 g avoine', '150 g skyr', '1 c. graines de chia', '100 ml lait', 'Myrtilles'], ['Mélange avoine, skyr, chia et lait.', 'Laisse une nuit au frigo.', 'Ajoute les myrtilles le matin.'], 'breakfast', 'violet', false],
            ['chia-pudding', 'Chia pudding mangue', 'Chia · lait d’amande · mangue', 280, 9, 30, 14, 5, 'breakfast', $cut, ['3 c. graines de chia', '250 ml lait d’amande', '100 g mangue'], ['Mélange chia et lait.', 'Laisse gonfler 2 h ou une nuit.', 'Ajoute la mangue en dés.'], 'blender', 'amber', false],
            ['spinach-omelette', 'Omelette épinards & feta', '2 œufs · blancs · épinards · feta', 300, 28, 5, 18, 10, 'breakfast', $cut, ['2 œufs', '100 g blancs d’œufs', 'Épinards', '30 g feta', '1 c. café huile d’olive'], ['Fais tomber les épinards dans l’huile.', 'Verse les œufs battus.', 'Ajoute la feta, plie et sers.'], 'breakfast', 'mint', false],
            ['smoothie-bowl', 'Smoothie bowl açaï-banane', 'Fruits rouges · banane · skyr · granola maison', 380, 20, 60, 7, 8, 'breakfast', $all, ['150 g fruits rouges surgelés', '1 banane', '100 g skyr', '20 g flocons d’avoine', 'Graines de chia'], ['Mixe fruits, banane et skyr bien épais.', 'Verse dans un bol.', 'Garnis d’avoine et de chia.'], 'blender', 'violet', false],
            // Déjeuner
            ['power-bowl', 'Power bowl poulet', 'Riz complet · avocat · légumes verts', 610, 46, 62, 18, 25, 'lunch', $bulk, ['150 g poulet', '150 g riz complet cuit', '1/2 avocat', 'Brocoli, concombre'], ['Grille le poulet assaisonné.', 'Dispose riz, légumes et avocat.', 'Ajoute le poulet tranché.'], 'rice_bowl', 'mint', false],
            ['quinoa-chicken-bowl', 'Bowl quinoa poulet & avocat', 'Quinoa · poulet · avocat · tomates', 560, 42, 48, 20, 20, 'lunch', $all, ['150 g quinoa cuit', '120 g poulet grillé', '1/2 avocat', 'Tomates cerises, concombre', 'Citron'], ['Cuis le quinoa.', 'Grille le poulet.', 'Assemble avec les légumes et l’avocat, citron.'], 'rice_bowl', 'mint', false],
            ['poke-tuna', 'Poke bowl thon', 'Riz complet · thon · edamame · avocat', 540, 38, 58, 16, 15, 'lunch', $all, ['150 g riz complet cuit', '1 boîte thon au naturel', '80 g edamame', '1/4 avocat', 'Concombre, carotte, sauce soja légère'], ['Dispose le riz dans un bol.', 'Ajoute thon, edamame, légumes et avocat.', 'Assaisonne avec un peu de sauce soja.'], 'rice_bowl', 'cyan', false],
            ['buddha-bowl', 'Buddha bowl pois chiches', 'Pois chiches rôtis · patate douce · houmous', 520, 20, 70, 16, 30, 'lunch', $all, ['150 g pois chiches', '200 g patate douce', 'Épinards', '2 c. houmous', 'Cumin, paprika'], ['Rôtis pois chiches et patate douce 25 min avec les épices.', 'Dispose sur les épinards.', 'Ajoute le houmous.'], 'rice_bowl', 'amber', false],
            ['lentil-salad', 'Salade de lentilles & feta', 'Lentilles · feta · légumes croquants', 420, 24, 45, 14, 15, 'lunch', $cut, ['150 g lentilles cuites', '30 g feta', 'Concombre, tomate, oignon rouge', 'Persil, citron, 1 c. huile d’olive'], ['Rince les lentilles.', 'Coupe les légumes.', 'Mélange avec feta, persil et vinaigrette citron.'], 'lunch', 'mint', false],
            ['turkey-wrap', 'Wrap complet dinde & crudités', 'Tortilla complète · dinde · yaourt grec', 430, 36, 40, 11, 10, 'lunch', $all, ['1 tortilla complète', '120 g dinde grillée', 'Salade, tomate, carotte', '50 g yaourt grec + ail'], ['Grille la dinde.', 'Prépare la sauce yaourt-ail.', 'Garnis et roule le wrap.'], 'lunch', 'amber', false],
            ['salmon-quinoa-salad', 'Salade saumon, quinoa & avocat', 'Saumon · quinoa · roquette · avocat', 580, 34, 40, 30, 20, 'lunch', $bulk, ['120 g saumon', '120 g quinoa cuit', '1/4 avocat', 'Roquette, concombre', 'Citron'], ['Cuis le saumon 10 min au four.', 'Assemble quinoa, roquette, concombre.', 'Ajoute saumon effeuillé et avocat.'], 'rice_bowl', 'coral', false],
            ['shrimp-zoodles', 'Crevettes & spaghetti de courgette', 'Crevettes · courgettes · tomates cerises', 300, 30, 14, 12, 15, 'lunch', $cut, ['150 g crevettes', '2 courgettes en spirale', 'Tomates cerises, ail', '1 c. huile d’olive'], ['Saisis les crevettes à l’ail.', 'Ajoute courgettes et tomates 3 min.', 'Assaisonne citron, basilic.'], 'dinner', 'coral', false],
            ['salade-tunisienne-thon', 'Salade tunisienne au thon', 'Tomate · concombre · poivron · thon · olives', 330, 28, 12, 18, 10, 'lunch', $cut, ['Tomate, concombre, poivron, oignon', '1 boîte thon au naturel', '1 œuf dur', '5 olives', '1 c. huile d’olive'], ['Coupe les légumes en petits dés.', 'Ajoute thon, œuf et olives.', 'Assaisonne citron, menthe séchée, huile d’olive.'], 'lunch', 'mint', true],
            // Dîner
            ['salmon-sweet-potato', 'Saumon, patate douce & brocoli', 'Oméga-3 · glucides complets', 560, 36, 45, 24, 30, 'dinner', $all, ['130 g saumon', '200 g patate douce', '150 g brocoli', 'Citron, aneth'], ['Rôtis la patate douce 25 min.', 'Cuis le saumon 12 min au four.', 'Brocoli vapeur 6 min.'], 'dinner', 'coral', false],
            ['chicken-veggies-tray', 'Poulet & légumes rôtis', 'Poulet · courgette · poivron · oignon', 420, 42, 20, 18, 35, 'dinner', $all, ['150 g blanc de poulet', 'Courgette, poivron, oignon rouge', '1 c. huile d’olive', 'Herbes de Provence'], ['Coupe tout en morceaux.', 'Assaisonne huile et herbes.', 'Rôtis 30 min à 200 °C.'], 'dinner', 'amber', false],
            ['grilled-fish-salad', 'Poisson grillé & salade méchouia', 'Daurade · légumes grillés · citron', 380, 34, 14, 20, 25, 'dinner', $cut, ['200 g poisson blanc', 'Poivrons et tomates grillés', '1 c. huile d’olive', 'Citron, carvi'], ['Grille le poisson 5 min par face.', 'Grille, pèle et hache poivrons et tomates.', 'Assaisonne et sers avec du citron.'], 'dinner', 'cyan', true],
            ['turkey-quinoa-stuffed', 'Poivrons farcis dinde & quinoa', 'Dinde hachée · quinoa · tomate', 450, 38, 40, 12, 40, 'dinner', $all, ['2 poivrons', '120 g dinde hachée', '100 g quinoa cuit', 'Coulis de tomate, épices'], ['Fais revenir la dinde avec les épices.', 'Mélange avec quinoa et tomate.', 'Farcis les poivrons et cuis 25 min au four.'], 'dinner', 'coral', false],
            ['tofu-stir-fry', 'Wok tofu & légumes', 'Tofu · brocoli · poivron · riz complet', 480, 26, 50, 18, 20, 'dinner', $all, ['150 g tofu', 'Brocoli, poivron, carotte', '120 g riz complet cuit', 'Sauce soja légère, gingembre'], ['Dore le tofu en cubes.', 'Ajoute les légumes 5 min.', 'Sers sur le riz.'], 'dinner', 'violet', false],
            ['lentil-dahl', 'Dahl de lentilles & épinards', 'Lentilles corail · épinards · curcuma', 420, 22, 60, 9, 30, 'dinner', $all, ['80 g lentilles corail sèches', 'Épinards', 'Tomate, oignon, ail', 'Curcuma, cumin', 'Lait de coco léger (50 ml)'], ['Fais revenir oignon et épices.', 'Ajoute lentilles, tomate et eau, cuis 20 min.', 'Ajoute épinards et lait de coco.'], 'dinner', 'amber', false],
            ['beef-broccoli', 'Bœuf maigre, brocoli & riz complet', 'Bœuf 5 % · brocoli · riz complet', 580, 40, 55, 18, 20, 'dinner', $bulk, ['150 g bœuf haché 5 %', '150 g riz complet cuit', '150 g brocoli', 'Ail, sauce soja légère'], ['Fais revenir le bœuf avec l’ail.', 'Ajoute le brocoli 4 min.', 'Sers avec le riz.'], 'dinner', 'coral', false],
            ['chicken-soup', 'Soupe poulet & légumes', 'Poulet · carotte · courgette · frik', 320, 28, 28, 8, 35, 'dinner', $cut, ['120 g poulet', '40 g frik', 'Carotte, courgette, céleri', 'Coriandre, citron'], ['Cuis le poulet dans l’eau avec les légumes.', 'Ajoute le frik et cuis 20 min.', 'Finis avec coriandre et citron.'], 'dinner', 'mint', true],
            // Collations
            ['smoothie-pro', 'Smoothie post-training', 'Banane · cacao · whey · lait', 360, 29, 45, 6, 5, 'snack', $all, ['1 banane', '1 dose whey', '250 ml lait demi-écrémé', '1 c. cacao'], ['Mets tout dans le blender.', 'Mixe 30 s.', 'Bois dans l’heure après la séance.'], 'blender', 'violet', false],
            ['green-smoothie', 'Smoothie vert', 'Épinards · kiwi · banane · yaourt grec', 250, 15, 40, 3, 5, 'snack', $cut, ['Une poignée d’épinards', '1 kiwi', '1/2 banane', '150 g yaourt grec', 'Eau'], ['Mets tout dans le blender.', 'Mixe jusqu’à texture lisse.'], 'blender', 'mint', false],
            ['yogurt-berries', 'Yaourt grec, fruits rouges & noix', 'Yaourt grec · fruits rouges · noix', 280, 20, 22, 12, 3, 'snack', $all, ['200 g yaourt grec', '100 g fruits rouges', '15 g noix'], ['Verse le yaourt.', 'Ajoute fruits rouges et noix.'], 'snack', 'violet', false],
            ['hummus-veggies', 'Houmous & bâtonnets de légumes', 'Houmous · carotte · concombre · poivron', 180, 6, 18, 9, 5, 'snack', $cut, ['80 g houmous', 'Carotte, concombre, poivron'], ['Coupe les légumes en bâtonnets.', 'Sers avec le houmous.'], 'snack', 'amber', false],
            ['apple-peanut', 'Pomme & beurre de cacahuète', 'Pomme · beurre de cacahuète 100 %', 190, 4, 27, 8, 2, 'snack', ['maintain', 'gain_muscle', 'clean_bulk', 'endurance'], ['1 pomme', '1 c. beurre de cacahuète'], ['Coupe la pomme en quartiers.', 'Tartine de beurre de cacahuète.'], 'snack', 'coral', false],
            ['cottage-pineapple', 'Cottage cheese & ananas', 'Cottage · ananas · graines de chia', 200, 17, 22, 5, 3, 'snack', $cut, ['150 g cottage cheese', '100 g ananas', '1 c. café chia'], ['Mélange le cottage et l’ananas.', 'Parsème de chia.'], 'snack', 'amber', false],
            ['egg-avocado-ricecake', 'Galettes de riz, avocat & œuf', 'Galettes complètes · avocat · œuf dur', 250, 10, 20, 15, 8, 'snack', $all, ['2 galettes de riz complet', '1/4 avocat', '1 œuf dur'], ['Écrase l’avocat sur les galettes.', 'Ajoute l’œuf en rondelles, sel, poivre.'], 'snack', 'mint', false],
        ];
    }

    public static function seed(): array
    {
        Food::query()->whereIn('slug', self::REMOVED_FOODS)->delete();
        Recipe::query()->whereIn('slug', self::REMOVED_RECIPES)->delete();

        foreach (self::foods() as [$slug, $name, $category, $serving, $kcal, $protein, $carbs, $fat, $local]) {
            Food::updateOrCreate(['slug' => $slug], [
                'name' => $name,
                'category' => $category,
                'serving' => $serving,
                'calories' => $kcal,
                'protein' => $protein,
                'carbs' => $carbs,
                'fat' => $fat,
                'is_tunisian' => $local,
            ]);
        }

        foreach (self::recipes() as $row) {
            [$slug, $name, $subtitle, $kcal, $protein, $carbs, $fat, $duration, $mealType, $tags, $ingredients, $steps, $icon, $accent, $local] = $row;
            Recipe::updateOrCreate(['slug' => $slug], [
                'name' => $name,
                'subtitle' => $subtitle,
                'calories' => $kcal,
                'protein' => $protein,
                'carbs' => $carbs,
                'fat' => $fat,
                'duration' => $duration,
                'meal_type' => $mealType,
                'goal_tags' => $tags,
                'ingredients' => $ingredients,
                'steps' => $steps,
                'icon_key' => $icon,
                'accent_key' => $accent,
                'is_tunisian' => $local,
            ]);
        }

        return ['foods' => count(self::foods()), 'recipes' => count(self::recipes())];
    }
}
