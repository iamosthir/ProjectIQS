<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Columns present in API-Football v3 payloads that the original schema was
 * missing. All additive/nullable, safe to run on a live database. Existing
 * denormalized country strings are kept for back-compat; the new country_id
 * FKs are the canonical link going forward.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('leagues', function (Blueprint $table) {
            $table->foreignId('country_id')->nullable()->after('logo_path')
                ->constrained()->nullOnDelete();
        });

        Schema::table('venues', function (Blueprint $table) {
            // Venue payload carries a country ("England").
            $table->foreignId('country_id')->nullable()->after('city')
                ->constrained()->nullOnDelete();
            $table->string('country_name')->nullable()->after('country_id');
        });

        Schema::table('teams', function (Blueprint $table) {
            $table->foreignId('country_id')->nullable()->after('country_name')
                ->constrained()->nullOnDelete();
        });

        Schema::table('players', function (Blueprint $table) {
            // players/profiles exposes the preferred shirt number.
            $table->unsignedTinyInteger('number')->nullable()->after('position');
        });

        Schema::table('coaches', function (Blueprint $table) {
            // coachs payload: birth{date,place,country}, height, weight, team.
            $table->string('birth_place')->nullable()->after('date_of_birth');
            $table->string('birth_country')->nullable()->after('birth_place');
            $table->string('height')->nullable()->after('nationality');
            $table->string('weight')->nullable()->after('height');
            $table->foreignId('team_id')->nullable()->after('weight')
                ->constrained()->nullOnDelete();
        });

        Schema::table('fixtures', function (Blueprint $table) {
            // fixture.periods.{first,second} kick-off timestamps.
            $table->dateTime('period_first_at')->nullable()->after('elapsed');
            $table->dateTime('period_second_at')->nullable()->after('period_first_at');
            // fixture.status.extra — additional time played in the half.
            $table->unsignedTinyInteger('status_extra')->nullable()->after('period_second_at');
        });

        Schema::table('fixture_lineups', function (Blueprint $table) {
            // lineups team.colors {player,goalkeeper}{primary,number,border}.
            $table->json('colors')->nullable()->after('formation');
        });
    }

    public function down(): void
    {
        Schema::table('fixture_lineups', function (Blueprint $table) {
            $table->dropColumn('colors');
        });

        Schema::table('fixtures', function (Blueprint $table) {
            $table->dropColumn(['period_first_at', 'period_second_at', 'status_extra']);
        });

        Schema::table('coaches', function (Blueprint $table) {
            $table->dropConstrainedForeignId('team_id');
            $table->dropColumn(['birth_place', 'birth_country', 'height', 'weight']);
        });

        Schema::table('players', function (Blueprint $table) {
            $table->dropColumn('number');
        });

        Schema::table('teams', function (Blueprint $table) {
            $table->dropConstrainedForeignId('country_id');
        });

        Schema::table('venues', function (Blueprint $table) {
            $table->dropConstrainedForeignId('country_id');
            $table->dropColumn('country_name');
        });

        Schema::table('leagues', function (Blueprint $table) {
            $table->dropConstrainedForeignId('country_id');
        });
    }
};
