<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreAdminRequest;
use App\Http\Requests\Admin\UpdateAdminRequest;
use App\Http\Resources\Admin\AdminResource;
use App\Models\Admin;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Spatie\QueryBuilder\AllowedFilter;
use Spatie\QueryBuilder\QueryBuilder;

class AdminController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $admins = QueryBuilder::for(Admin::class)
            ->allowedFilters([
                AllowedFilter::partial('name'),
                AllowedFilter::partial('email'),
                AllowedFilter::exact('is_active'),
                AllowedFilter::callback('search', function ($query, $value): void {
                    $query->where(fn ($q) => $q->where('name', 'like', "%{$value}%")
                        ->orWhere('email', 'like', "%{$value}%"));
                }),
            ])
            ->allowedSorts(['name', 'email', 'created_at', 'last_login_at'])
            ->defaultSort('-created_at')
            ->with('roles')
            ->paginate(min((int) $request->integer('per_page', 20), 50))
            ->appends($request->query());

        return $this->ok(AdminResource::collection($admins));
    }

    public function store(StoreAdminRequest $request): JsonResponse
    {
        $data = $request->validated();

        $admin = Admin::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => $data['password'],
            'phone' => $data['phone'] ?? null,
            'is_active' => $data['is_active'] ?? true,
        ]);

        $admin->syncRoles($data['roles'] ?? []);

        return $this->created(new AdminResource($admin->load('roles')), __('Admin created.'));
    }

    public function show(Admin $admin): JsonResponse
    {
        return $this->ok(new AdminResource($admin->load('roles')));
    }

    public function update(UpdateAdminRequest $request, Admin $admin): JsonResponse
    {
        $data = $request->validated();

        $admin->fill(collect($data)->except(['password', 'roles'])->all());

        if (! empty($data['password'])) {
            $admin->password = $data['password'];
        }

        $admin->save();

        if (array_key_exists('roles', $data)) {
            $admin->syncRoles($data['roles']);
        }

        return $this->ok(new AdminResource($admin->load('roles')), __('Admin updated.'));
    }

    public function destroy(Request $request, Admin $admin): JsonResponse
    {
        if ($request->user()->is($admin)) {
            return $this->fail(__('You cannot delete your own account.'), null, 422);
        }

        $admin->delete();

        return $this->noContentMessage(__('Admin deleted.'));
    }
}
