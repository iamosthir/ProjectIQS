<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreRoleRequest;
use App\Http\Requests\Admin\UpdateRoleRequest;
use App\Http\Resources\Admin\RoleResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class RoleController extends Controller
{
    /**
     * Admin roles only ever use the `web` guard.
     */
    protected const GUARD = 'web';

    public function index(Request $request): JsonResponse
    {
        $roles = Role::query()
            ->where('guard_name', self::GUARD)
            ->with('permissions')
            ->withCount('users')
            ->orderBy('name')
            ->get();

        return $this->ok(RoleResource::collection($roles));
    }

    public function store(StoreRoleRequest $request): JsonResponse
    {
        $role = Role::create([
            'name' => $request->validated('name'),
            'guard_name' => self::GUARD,
        ]);

        $role->syncPermissions($request->validated('permissions') ?? []);

        return $this->created(new RoleResource($role->load('permissions')), __('Role created.'));
    }

    public function show(Role $role): JsonResponse
    {
        return $this->ok(new RoleResource($role->load('permissions')->loadCount('users')));
    }

    public function update(UpdateRoleRequest $request, Role $role): JsonResponse
    {
        if ($role->name === 'super-admin') {
            return $this->fail(__('The super-admin role cannot be modified.'), null, 422);
        }

        if ($request->filled('name')) {
            $role->update(['name' => $request->validated('name')]);
        }

        if ($request->has('permissions')) {
            $role->syncPermissions($request->validated('permissions') ?? []);
        }

        return $this->ok(new RoleResource($role->load('permissions')), __('Role updated.'));
    }

    public function destroy(Role $role): JsonResponse
    {
        if ($role->name === 'super-admin') {
            return $this->fail(__('The super-admin role cannot be deleted.'), null, 422);
        }

        if ($role->users()->exists()) {
            return $this->fail(__('This role is assigned to admins and cannot be deleted.'), null, 422);
        }

        $role->delete();

        return $this->noContentMessage(__('Role deleted.'));
    }

    /**
     * All assignable admin permissions (for the role editor UI).
     */
    public function permissions(): JsonResponse
    {
        $permissions = Permission::query()
            ->where('guard_name', self::GUARD)
            ->orderBy('name')
            ->pluck('name');

        return $this->ok($permissions);
    }
}
