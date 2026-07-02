<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreSettingRequest;
use App\Http\Requests\Admin\UpdateSettingRequest;
use App\Http\Resources\Admin\SettingResource;
use App\Models\Setting;
use App\Support\Enums\SettingType;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SettingController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $settings = Setting::query()
            ->when($request->filled('group'), fn ($q) => $q->where('group', $request->string('group')))
            ->orderBy('group')
            ->orderBy('key')
            ->get();

        return $this->ok(SettingResource::collection($settings));
    }

    public function store(StoreSettingRequest $request): JsonResponse
    {
        $type = SettingType::from($request->validated('type'));

        $setting = Setting::create([
            'group' => $request->validated('group'),
            'key' => $request->validated('key'),
            'type' => $type,
            'value' => $type->serialize($request->validated('value')),
            'is_public' => $request->boolean('is_public'),
        ]);

        return $this->created(new SettingResource($setting), __('Setting created.'));
    }

    public function update(UpdateSettingRequest $request, Setting $setting): JsonResponse
    {
        $type = $request->filled('type')
            ? SettingType::from($request->validated('type'))
            : $setting->type;

        $setting->type = $type;

        if ($request->has('value')) {
            $setting->value = $type->serialize($request->input('value'));
        }

        if ($request->has('is_public')) {
            $setting->is_public = $request->boolean('is_public');
        }

        $setting->save();

        return $this->ok(new SettingResource($setting), __('Setting updated.'));
    }

    public function destroy(Setting $setting): JsonResponse
    {
        $setting->delete();

        return $this->noContentMessage(__('Setting deleted.'));
    }
}
