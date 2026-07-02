<?php

namespace App\Http\Requests\Admin\Matches;

use App\Support\Enums\FixtureStatusGroup;
use App\Support\Enums\MatchWinner;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class FixtureRequest extends FormRequest
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
            'league_id' => [$required, 'integer', 'exists:leagues,id'],
            'season_id' => ['nullable', 'integer', 'exists:seasons,id'],
            'round' => ['nullable', 'string', 'max:255'],
            'home_team_id' => [$required, 'integer', 'exists:teams,id'],
            'away_team_id' => [$required, 'integer', 'exists:teams,id', 'different:home_team_id'],
            'venue_id' => ['nullable', 'integer', 'exists:venues,id'],
            'referee' => ['nullable', 'string', 'max:255'],
            'referee_assistant_1' => ['nullable', 'string', 'max:255'],
            'referee_assistant_2' => ['nullable', 'string', 'max:255'],
            'referee_fourth_official' => ['nullable', 'string', 'max:255'],
            'supervisor' => ['nullable', 'string', 'max:255'],
            'match_datetime' => [$required, 'date'],
            'timezone' => ['sometimes', 'string', 'max:64'],
            'status_short' => ['sometimes', 'string', 'max:10'],
            'status_group' => ['sometimes', Rule::enum(FixtureStatusGroup::class)],
            'elapsed' => ['nullable', 'integer', 'min:0', 'max:130'],
            'home_goals' => ['nullable', 'integer', 'min:0', 'max:99'],
            'away_goals' => ['nullable', 'integer', 'min:0', 'max:99'],
            'home_ht' => ['nullable', 'integer', 'min:0', 'max:99'],
            'away_ht' => ['nullable', 'integer', 'min:0', 'max:99'],
            'home_ft' => ['nullable', 'integer', 'min:0', 'max:99'],
            'away_ft' => ['nullable', 'integer', 'min:0', 'max:99'],
            'home_et' => ['nullable', 'integer', 'min:0', 'max:99'],
            'away_et' => ['nullable', 'integer', 'min:0', 'max:99'],
            'home_pen' => ['nullable', 'integer', 'min:0', 'max:99'],
            'away_pen' => ['nullable', 'integer', 'min:0', 'max:99'],
            'winner' => ['nullable', Rule::enum(MatchWinner::class)],
            'is_featured' => ['sometimes', 'boolean'],
        ];
    }
}
