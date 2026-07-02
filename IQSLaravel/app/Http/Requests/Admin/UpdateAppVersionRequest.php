<?php

namespace App\Http\Requests\Admin;

use App\Support\Enums\DevicePlatform;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateAppVersionRequest extends FormRequest
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
            'platform' => ['sometimes', Rule::enum(DevicePlatform::class)],
            'version' => ['sometimes', 'required', 'string', 'max:30'],
            'build_number' => ['sometimes', 'required', 'integer', 'min:1'],
            'min_supported_version' => ['sometimes', 'required', 'string', 'max:30'],
            'is_force_update' => ['sometimes', 'boolean'],
            'changelog_ar' => ['sometimes', 'nullable', 'string'],
            'changelog_en' => ['sometimes', 'nullable', 'string'],
            'store_url' => ['sometimes', 'required', 'url', 'max:2048'],
            'is_active' => ['sometimes', 'boolean'],
            'released_at' => ['sometimes', 'nullable', 'date'],
        ];
    }
}
