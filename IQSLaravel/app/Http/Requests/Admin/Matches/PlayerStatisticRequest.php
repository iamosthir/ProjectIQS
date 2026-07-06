<?php

namespace App\Http\Requests\Admin\Matches;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class PlayerStatisticRequest extends FormRequest
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
        $statistic = $this->route('player_statistic');

        return [
            'player_id' => [
                $required, 'integer', 'exists:players,id',
                Rule::unique('player_statistics', 'player_id')
                    ->where('team_id', $this->integer('team_id') ?: $statistic?->team_id)
                    ->where('season_id', $this->integer('season_id') ?: $statistic?->season_id)
                    ->ignore($statistic?->id),
            ],
            'team_id' => [$required, 'integer', 'exists:teams,id'],
            'league_id' => [$required, 'integer', 'exists:leagues,id'],
            'season_id' => [$required, 'integer', 'exists:seasons,id'],

            'appearances' => ['nullable', 'integer', 'min:0'],
            'lineups' => ['nullable', 'integer', 'min:0'],
            'minutes' => ['nullable', 'integer', 'min:0'],
            'number' => ['nullable', 'integer', 'min:1', 'max:99'],
            'position' => ['nullable', 'string', 'max:50'],
            'rating' => ['nullable', 'numeric', 'min:0', 'max:10'],
            'captain' => ['sometimes', 'boolean'],
            'substitutes_in' => ['nullable', 'integer', 'min:0'],
            'substitutes_out' => ['nullable', 'integer', 'min:0'],
            'substitutes_bench' => ['nullable', 'integer', 'min:0'],
            'shots_total' => ['nullable', 'integer', 'min:0'],
            'shots_on' => ['nullable', 'integer', 'min:0'],
            'goals_total' => ['nullable', 'integer', 'min:0'],
            'goals_conceded' => ['nullable', 'integer', 'min:0'],
            'goals_assists' => ['nullable', 'integer', 'min:0'],
            'goals_saves' => ['nullable', 'integer', 'min:0'],
            'passes_total' => ['nullable', 'integer', 'min:0'],
            'passes_key' => ['nullable', 'integer', 'min:0'],
            'passes_accuracy' => ['nullable', 'integer', 'min:0', 'max:100'],
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
            'cards_yellowred' => ['nullable', 'integer', 'min:0'],
            'cards_red' => ['nullable', 'integer', 'min:0'],
            'penalty_won' => ['nullable', 'integer', 'min:0'],
            'penalty_committed' => ['nullable', 'integer', 'min:0'],
            'penalty_scored' => ['nullable', 'integer', 'min:0'],
            'penalty_missed' => ['nullable', 'integer', 'min:0'],
            'penalty_saved' => ['nullable', 'integer', 'min:0'],
        ];
    }
}
