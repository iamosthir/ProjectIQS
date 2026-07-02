<?php

namespace App\Http\Requests\Admin\Matches;

use Illuminate\Foundation\Http\FormRequest;

class TeamRequest extends FormRequest
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
            'short_code' => ['nullable', 'string', 'max:10'],
            'country_name' => ['nullable', 'string', 'max:255'],
            'founded_year' => ['nullable', 'integer', 'min:1850', 'max:2100'],
            'is_national' => ['sometimes', 'boolean'],
            'logo_path' => ['nullable', 'string', 'max:2048'],
            'venue_id' => ['nullable', 'integer', 'exists:venues,id'],
            'club_id' => ['nullable', 'integer'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
