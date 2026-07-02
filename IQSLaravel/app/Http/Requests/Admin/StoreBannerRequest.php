<?php

namespace App\Http\Requests\Admin;

use App\Support\Enums\BannerPlacement;
use App\Support\Enums\NotificationActionType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreBannerRequest extends FormRequest
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
            'title_ar' => ['nullable', 'string', 'max:255'],
            'title_en' => ['nullable', 'string', 'max:255'],
            'image_path' => ['required', 'string', 'max:2048'],
            'action_type' => ['required', Rule::enum(NotificationActionType::class)],
            'action_value' => ['nullable', 'string', 'max:2048'],
            'placement' => ['required', Rule::enum(BannerPlacement::class)],
            'position' => ['sometimes', 'integer', 'min:0'],
            'is_active' => ['sometimes', 'boolean'],
            'starts_at' => ['nullable', 'date'],
            'ends_at' => ['nullable', 'date', 'after_or_equal:starts_at'],
        ];
    }
}
