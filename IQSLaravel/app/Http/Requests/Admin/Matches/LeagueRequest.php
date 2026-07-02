<?php

namespace App\Http\Requests\Admin\Matches;

use App\Support\Enums\LeagueCategory;
use App\Support\Enums\LeagueType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class LeagueRequest extends FormRequest
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
            'name_ar' => [$required, 'string', 'max:255'],
            'name_en' => [$required, 'string', 'max:255'],
            'type' => ['sometimes', Rule::enum(LeagueType::class)],
            'logo_path' => ['nullable', 'string', 'max:2048'],
            'country_name' => ['nullable', 'string', 'max:255'],
            'country_code' => ['nullable', 'string', 'max:10'],
            'country_flag' => ['nullable', 'string', 'max:2048'],
            'is_iraqi' => ['sometimes', 'boolean'],
            'category' => ['nullable', Rule::enum(LeagueCategory::class)],
            'tier' => ['nullable', 'integer', 'min:1', 'max:255'],
            'requires_auth' => ['sometimes', 'boolean'],
            'is_featured' => ['sometimes', 'boolean'],
            'display_order' => ['sometimes', 'integer'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
