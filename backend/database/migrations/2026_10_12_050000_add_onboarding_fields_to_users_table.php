<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('sex')->nullable()->after('bio');
            $table->string('main_goal')->nullable()->after('sex');
            $table->string('experience_level')->nullable()->after('main_goal');
            $table->unsignedTinyInteger('days_per_week')->nullable()->after('experience_level');
            $table->string('equipment')->nullable()->after('days_per_week');
            $table->timestamp('onboarding_completed_at')->nullable()->after('equipment');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'sex',
                'main_goal',
                'experience_level',
                'days_per_week',
                'equipment',
                'onboarding_completed_at',
            ]);
        });
    }
};
