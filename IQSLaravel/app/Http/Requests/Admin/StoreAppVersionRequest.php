<?php

namespace App\Http\Requests\Admin;

use App\Support\Enums\DevicePlatform;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreAppVersionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'platform' => ['required', Rule::enum(DevicePlatform::class)],
            'version' => ['required', 'string', 'max:30'],
            'build_number' => ['required', 'integer', 'min:1'],
            'min_supported_version' => ['required', 'string', 'max:30'],
            'is_force_update' => ['sometimes', 'boolean'],
            'changelog_ar' => ['nullable', 'string'],
            'changelog_en' => ['nullable', 'string'],
            'store_url' => ['required', 'url', 'max:2048'],
            'is_active' => ['sometimes', 'boolean'],
            'released_at' => ['nullable', 'date'],
        ];
    }
}
