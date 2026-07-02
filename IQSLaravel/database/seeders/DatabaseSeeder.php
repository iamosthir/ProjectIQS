<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            RolesPermissionsSeeder::class,
            DemoAdminSeeder::class,
            SettingsSeeder::class,
            CompetitionsSeeder::class,
            InternationalSeeder::class,
            MarketplaceCategoriesSeeder::class,
            PagesSeeder::class,
            DemoDataSeeder::class,
        ]);
    }
}
