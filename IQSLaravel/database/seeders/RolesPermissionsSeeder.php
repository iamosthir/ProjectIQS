<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

class RolesPermissionsSeeder extends Seeder
{
    /**
     * Admin permissions (web guard). One per resource-action (§1.3).
     *
     * @var list<string>
     */
    protected array $adminPermissions = [
        'manage matches',
        'sync matches',
        'moderate comments',
        'manage marketplace',
        'approve listings',
        'manage clubs',
        'manage fan-groups',
        'manage users',
        'ban users',
        'manage admins',
        'manage roles',
        'manage payments',
        'send notifications',
        'manage settings',
        'manage banners',
    ];

    /**
     * Admin roles (web guard) → granted permissions.
     *
     * @var array<string, list<string>>
     */
    protected array $adminRoles = [
        'super-admin' => ['*'],
        'admin' => [
            'manage matches', 'sync matches', 'moderate comments',
            'manage marketplace', 'approve listings',
            'manage clubs', 'manage fan-groups',
            'manage users', 'ban users',
            'manage payments', 'send notifications',
            'manage settings', 'manage banners',
        ],
        'content-editor' => ['manage matches', 'sync matches', 'moderate comments'],
        'marketplace-moderator' => ['manage marketplace', 'approve listings'],
        'club-manager' => ['manage clubs', 'manage fan-groups'],
        'support' => ['manage users'],
    ];

    /**
     * App-user capability roles (sanctum guard). No permissions attached —
     * they are assigned when the user creates/owns the matching entity.
     *
     * @var list<string>
     */
    protected array $appRoles = ['seller', 'club-admin', 'group-admin'];

    public function run(): void
    {
        app(PermissionRegistrar::class)->forgetCachedPermissions();

        foreach ($this->adminPermissions as $permission) {
            Permission::findOrCreate($permission, 'web');
        }

        foreach ($this->adminRoles as $roleName => $permissions) {
            $role = Role::findOrCreate($roleName, 'web');

            if ($permissions === ['*']) {
                $role->syncPermissions(Permission::where('guard_name', 'web')->get());

                continue;
            }

            $role->syncPermissions($permissions);
        }

        foreach ($this->appRoles as $roleName) {
            Role::findOrCreate($roleName, 'sanctum');
        }

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }
}
