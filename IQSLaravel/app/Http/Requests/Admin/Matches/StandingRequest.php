<?php

namespace App\Http\Requests\Admin\Matches;

use Illuminate\Foundation\Http\FormRequest;

class StandingRequest extends FormRequest
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
        $int = ['sometimes', 'integer'];

        return [
            'league_id' => [$required, 'integer', 'exists:leagues,id'],
            'season_id' => [$required, 'integer', 'exists:seasons,id'],
            'team_id' => [$required, 'integer', 'exists:teams,id'],
            'group_label' => ['sometimes', 'string', 'max:255'],
            'rank' => $int,
            'points' => $int,
            'goals_diff' => $int,
            'played' => $int,
            'win' => $int,
            'draw' => $int,
            'lose' => $int,
            'goals_for' => $int,
            'goals_against' => $int,
            'home_played' => $int,
            'home_win' => $int,
            'home_draw' => $int,
            'home_lose' => $int,
            'home_goals_for' => $int,
            'home_goals_against' => $int,
            'away_played' => $int,
            'away_win' => $int,
            'away_draw' => $int,
            'away_lose' => $int,
            'away_goals_for' => $int,
            'away_goals_against' => $int,
            'form' => ['nullable', 'string', 'max:50'],
            'status' => ['nullable', 'string', 'max:50'],
            'description' => ['nullable', 'string', 'max:255'],
        ];
    }
}
