<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->decimal('price', 12, 3)->change();
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->decimal('subtotal', 12, 3)->change();
            $table->decimal('shipping', 12, 3)->change();
            $table->decimal('total', 12, 3)->change();
            $table->string('currency', 3)->default('TND')->after('total');
            $table->string('payment_method')->default('cash_on_delivery')->after('payment_status');
            $table->timestamp('paid_at')->nullable()->after('payment_status');
            $table->text('notes')->nullable()->after('shipping_address');
        });

        Schema::table('order_items', function (Blueprint $table) {
            $table->decimal('unit_price', 12, 3)->change();
            $table->decimal('line_total', 12, 3)->change();
        });

        Schema::create('order_status_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->string('from_status')->nullable();
            $table->string('to_status');
            $table->text('comment')->nullable();
            $table->foreignId('changed_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_status_histories');

        Schema::table('order_items', function (Blueprint $table) {
            $table->decimal('unit_price', 10, 2)->change();
            $table->decimal('line_total', 10, 2)->change();
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['currency', 'payment_method', 'paid_at', 'notes']);
            $table->decimal('subtotal', 10, 2)->change();
            $table->decimal('shipping', 10, 2)->change();
            $table->decimal('total', 10, 2)->change();
        });

        Schema::table('products', function (Blueprint $table) {
            $table->decimal('price', 10, 2)->change();
        });
    }
};
