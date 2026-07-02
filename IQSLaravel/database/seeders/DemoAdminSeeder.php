<?php

namespace Database\Seeders;

use App\Models\Admin;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DemoAdminSeeder extends Seeder
{
    public function run(): void
    {
        $admin = Admin::updateOrCreate(
            ['email' => env('ADMIN_EMAIL', 'admin@iqs.app')],
            [
                'name' => 'System Admin',
                'password' => Hash::make(env('ADMIN_PASSWORD', 'password')),
                'is_active' => true,
                'email_verified_at' => now(),
            ],
        );

        $admin->syncRoles(['super-admin']);
    }
}
