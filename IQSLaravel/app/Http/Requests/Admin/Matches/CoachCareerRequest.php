<?php

namespace App\Http\Requests\Admin\Matches;

use Illuminate\Foundation\Http\FormRequest;

class CoachCareerRequest extends FormRequest
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
        $teamName = ['nullable', 'string', 'max:255'];

        if ($this->isMethod('POST')) {
            $teamName[] = 'required_without:team_id';
        }

        return [
            'team_id' => ['nullable', 'integer', 'exists:teams,id'],
            'team_name' => $teamName,
            'start_date' => ['nullable', 'date'],
            'end_date' => ['nullable', 'date', 'after_or_equal:start_date'],
        ];
    }
}
