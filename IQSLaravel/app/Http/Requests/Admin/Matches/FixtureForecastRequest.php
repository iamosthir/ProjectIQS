<?php

namespace App\Http\Requests\Admin\Matches;

use Illuminate\Foundation\Http\FormRequest;

class FixtureForecastRequest extends FormRequest
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
            'winner_team_id' => ['nullable', 'integer', 'exists:teams,id'],
            'winner_comment' => ['nullable', 'string', 'max:255'],
            'win_or_draw' => ['sometimes', 'boolean'],
            'under_over' => ['nullable', 'string', 'max:10'],
            'goals_home' => ['nullable', 'string', 'max:10'],
            'goals_away' => ['nullable', 'string', 'max:10'],
            'advice' => ['nullable', 'string', 'max:255'],
            'percent_home' => ['nullable', 'integer', 'min:0', 'max:100'],
            'percent_draw' => ['nullable', 'integer', 'min:0', 'max:100'],
            'percent_away' => ['nullable', 'integer', 'min:0', 'max:100'],
            'comparison' => ['nullable', 'array'],
        ];
    }
}
