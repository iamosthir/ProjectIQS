<?php

namespace App\Http\Requests\Admin;

use App\Support\Enums\BannerPlacement;
use App\Support\Enums\NotificationActionType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateBannerRequest extends FormRequest
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
            'title_ar' => ['sometimes', 'nullable', 'string', 'max:255'],
            'title_en' => ['sometimes', 'nullable', 'string', 'max:255'],
            'image_path' => ['sometimes', 'string', 'max:2048'],
            'action_type' => ['sometimes', Rule::enum(NotificationActionType::class)],
            'action_value' => ['sometimes', 'nullable', 'string', 'max:2048'],
            'placement' => ['sometimes', Rule::enum(BannerPlacement::class)],
            'position' => ['sometimes', 'integer', 'min:0'],
            'is_active' => ['sometimes', 'boolean'],
            'starts_at' => ['sometimes', 'nullable', 'date'],
            'ends_at' => ['sometimes', 'nullable', 'date', 'after_or_equal:starts_at'],
        ];
    }
}
