<?php

namespace App\Http\Requests\Admin\Matches;

use Illuminate\Foundation\Http\FormRequest;

class CoachRequest extends FormRequest
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
            'firstname' => ['nullable', 'string', 'max:255'],
            'lastname' => ['nullable', 'string', 'max:255'],
            'date_of_birth' => ['nullable', 'date', 'before:today'],
            'birth_place' => ['nullable', 'string', 'max:255'],
            'birth_country' => ['nullable', 'string', 'max:255'],
            'nationality' => ['nullable', 'string', 'max:255'],
            'height' => ['nullable', 'string', 'max:20'],
            'weight' => ['nullable', 'string', 'max:20'],
            'team_id' => ['nullable', 'integer', 'exists:teams,id'],
            'photo_path' => ['nullable', 'string', 'max:2048'],
        ];
    }
}
