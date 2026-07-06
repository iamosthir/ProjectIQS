<?php

namespace App\Http\Requests\Admin\Matches;

use Illuminate\Foundation\Http\FormRequest;

class FixturePlayerStatisticRequest extends FormRequest
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
            'team_id' => [$required, 'integer', 'exists:teams,id'],
            'player_id' => ['nullable', 'integer', 'exists:players,id'],
            'player_name' => ['nullable', 'string', 'max:255', 'required_without:player_id'],
            'minutes' => ['nullable', 'integer', 'min:0'],
            'number' => ['nullable', 'integer', 'min:1', 'max:99'],
            'position' => ['nullable', 'string', 'max:5'],
            'rating' => ['nullable', 'numeric', 'min:0', 'max:10'],
            'captain' => ['sometimes', 'boolean'],
            'substitute' => ['sometimes', 'boolean'],
            'offsides' => ['nullable', 'integer', 'min:0'],
            'shots_total' => ['nullable', 'integer', 'min:0'],
            'shots_on' => ['nullable', 'integer', 'min:0'],
            'goals_total' => ['nullable', 'integer', 'min:0'],
            'goals_conceded' => ['nullable', 'integer', 'min:0'],
            'goals_assists' => ['nullable', 'integer', 'min:0'],
            'goals_saves' => ['nullable', 'integer', 'min:0'],
            'passes_total' => ['nullable', 'integer', 'min:0'],
            'passes_key' => ['nullable', 'integer', 'min:0'],
            'passes_accuracy' => ['nullable', 'string', 'max:10'],
            'tackles_total' => ['nullable', 'integer', 'min:0'],
            'tackles_blocks' => ['nullable', 'integer', 'min:0'],
            'tackles_interceptions' => ['nullable', 'integer', 'min:0'],
            'duels_total' => ['nullable', 'integer', 'min:0'],
            'duels_won' => ['nullable', 'integer', 'min:0'],
            'dribbles_attempts' => ['nullable', 'integer', 'min:0'],
            'dribbles_success' => ['nullable', 'integer', 'min:0'],
            'dribbles_past' => ['nullable', 'integer', 'min:0'],
            'fouls_drawn' => ['nullable', 'integer', 'min:0'],
            'fouls_committed' => ['nullable', 'integer', 'min:0'],
            'cards_yellow' => ['nullable', 'integer', 'min:0'],
            'cards_red' => ['nullable', 'integer', 'min:0'],
            'penalty_won' => ['nullable', 'integer', 'min:0'],
            'penalty_committed' => ['nullable', 'integer', 'min:0'],
            'penalty_scored' => ['nullable', 'integer', 'min:0'],
            'penalty_missed' => ['nullable', 'integer', 'min:0'],
            'penalty_saved' => ['nullable', 'integer', 'min:0'],
        ];
    }
}
