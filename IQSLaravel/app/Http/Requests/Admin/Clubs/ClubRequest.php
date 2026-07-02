<?php

namespace App\Http\Requests\Admin\Clubs;

use App\Support\Enums\ClubStatus;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ClubRequest extends FormRequest
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
            'team_id' => ['nullable', 'integer', 'exists:teams,id'],
            'name_ar' => [$required, 'string', 'max:255'],
            'name_en' => [$required, 'string', 'max:255'],
            'logo_path' => ['nullable', 'string', 'max:2048'],
            'cover_path' => ['nullable', 'string', 'max:2048'],
            'founded_year' => ['nullable', 'integer', 'min:1850', 'max:2100'],
            'description_ar' => ['nullable', 'string'],
            'description_en' => ['nullable', 'string'],
            'governorate' => ['nullable', 'string', 'max:255'],
            'city' => ['nullable', 'string', 'max:255'],
            'address' => ['nullable', 'string', 'max:255'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'phone' => ['nullable', 'string', 'max:30'],
            'email' => ['nullable', 'email', 'max:255'],
            'website' => ['nullable', 'string', 'max:255'],
            'facebook' => ['nullable', 'string', 'max:255'],
            'instagram' => ['nullable', 'string', 'max:255'],
            'twitter' => ['nullable', 'string', 'max:255'],
            'managed_by' => ['nullable', 'integer', 'exists:users,id'],
            'status' => ['sometimes', Rule::enum(ClubStatus::class)],
            'is_active' => ['sometimes', 'boolean'],
            'display_order' => ['sometimes', 'integer'],
        ];
    }
}
