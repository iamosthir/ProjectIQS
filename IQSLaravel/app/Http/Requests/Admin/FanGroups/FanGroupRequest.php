<?php

namespace App\Http\Requests\Admin\FanGroups;

use App\Support\Enums\FanGroupStatus;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class FanGroupRequest extends FormRequest
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
        $required = $this->isMethod('POST') ? 'required' : 'sometimes';

        return [
            'club_id' => ['nullable', 'integer', 'exists:clubs,id'],
            'name_ar' => [$required, 'string', 'max:255'],
            'name_en' => [$required, 'string', 'max:255'],
            'founded_year' => ['nullable', 'integer', 'min:1900', 'max:2100'],
            'group_logo_path' => ['nullable', 'string', 'max:2048'],
            'club_logo_path' => ['nullable', 'string', 'max:2048'],
            'cover_path' => ['nullable', 'string', 'max:2048'],
            'description_ar' => ['nullable', 'string'],
            'description_en' => ['nullable', 'string'],
            'governorate' => ['nullable', 'string', 'max:255'],
            'city' => ['nullable', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:30'],
            'facebook' => ['nullable', 'string', 'max:255'],
            'instagram' => ['nullable', 'string', 'max:255'],
            'twitter' => ['nullable', 'string', 'max:255'],
            'managed_by' => ['nullable', 'integer', 'exists:users,id'],
            'is_official' => ['sometimes', 'boolean'],
            'status' => ['sometimes', Rule::enum(FanGroupStatus::class)],
            'is_active' => ['sometimes', 'boolean'],
            'display_order' => ['sometimes', 'integer'],
        ];
    }
}
