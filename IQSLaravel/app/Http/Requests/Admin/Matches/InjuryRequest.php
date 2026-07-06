<?php

namespace App\Http\Requests\Admin\Matches;

use App\Models\Injury;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class InjuryRequest extends FormRequest
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
            'player_id' => [$required, 'integer', 'exists:players,id'],
            'team_id' => ['nullable', 'integer', 'exists:teams,id'],
            'league_id' => ['nullable', 'integer', 'exists:leagues,id'],
            'season_id' => ['nullable', 'integer', 'exists:seasons,id'],
            'fixture_id' => ['nullable', 'integer', 'exists:fixtures,id'],
            'type' => [$required, Rule::in([Injury::TYPE_MISSING_FIXTURE, Injury::TYPE_QUESTIONABLE])],
            'reason' => ['nullable', 'string', 'max:255'],
            'date' => ['nullable', 'date'],
        ];
    }
}
