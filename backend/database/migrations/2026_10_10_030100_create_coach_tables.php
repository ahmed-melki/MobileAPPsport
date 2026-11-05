<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('coach_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('slug')->unique();
            $table->string('name');
            $table->string('role');
            $table->text('bio');
            $table->decimal('rating', 3, 2);
            $table->unsignedInteger('review_count');
            $table->unsignedInteger('sessions');
            $table->unsignedInteger('price');
            $table->string('initials', 8);
            $table->string('accent_key')->nullable();
            $table->boolean('is_online')->default(false);
            $table->timestamps();
        });

        Schema::create('coach_specialties', function (Blueprint $table) {
            $table->id();
            $table->foreignId('coach_profile_id')->constrained()->cascadeOnDelete();
            $table->string('specialty');
            $table->unique(['coach_profile_id', 'specialty']);
        });

        Schema::create('coach_availabilities', function (Blueprint $table) {
            $table->id();
            $table->foreignId('coach_profile_id')->constrained()->cascadeOnDelete();
            $table->dateTime('scheduled_at');
            $table->unsignedInteger('duration_min')->default(30);
            $table->string('status')->default('available');
            $table->unique(['coach_profile_id', 'scheduled_at']);
        });

        Schema::create('coach_bookings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('coach_profile_id')->constrained()->cascadeOnDelete();
            $table->foreignId('availability_id')->nullable()->constrained('coach_availabilities')->nullOnDelete();
            $table->dateTime('scheduled_at');
            $table->string('type');
            $table->string('status')->default('pending');
            $table->timestamps();
        });

        Schema::create('coach_athletes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('coach_profile_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('goal')->nullable();
            $table->decimal('progress', 5, 4)->default(0);
            $table->dateTime('last_session_at')->nullable();
            $table->timestamps();
            $table->unique(['coach_profile_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('coach_athletes');
        Schema::dropIfExists('coach_bookings');
        Schema::dropIfExists('coach_availabilities');
        Schema::dropIfExists('coach_specialties');
        Schema::dropIfExists('coach_profiles');
    }
};
