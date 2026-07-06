<?php

namespace App\Http\Requests\Admin\Matches;

use Illuminate\Foundation\Http\FormRequest;

class TrophyRequest extends FormRequest
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
            'player_id' => ['nullable', 'integer', 'exists:players,id', 'required_without:coach_id'],
            'coach_id' => ['nullable', 'integer', 'exists:coaches,id', 'required_without:player_id'],
            'league_name' => [$required, 'string', 'max:255'],
            'country' => ['nullable', 'string', 'max:255'],
            'season' => ['nullable', 'string', 'max:255'],
            'place' => ['nullable', 'string', 'max:255'],
        ];
    }
}
