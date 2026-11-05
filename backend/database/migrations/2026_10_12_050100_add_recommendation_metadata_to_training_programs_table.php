<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('training_programs', function (Blueprint $table) {
            $table->json('goal_tags')->nullable()->after('level');
            $table->string('equipment')->nullable()->after('goal_tags');
        });
    }

    public function down(): void
    {
        Schema::table('training_programs', function (Blueprint $table) {
            $table->dropColumn(['goal_tags', 'equipment']);
        });
    }
};
