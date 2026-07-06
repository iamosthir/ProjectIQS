<?php

namespace App\Http\Requests\Admin\Matches;

use Illuminate\Foundation\Http\FormRequest;

class TransferRequest extends FormRequest
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
            'transfer_date' => ['nullable', 'date'],
            'type' => ['nullable', 'string', 'max:255'],
            'team_in_id' => ['nullable', 'integer', 'exists:teams,id'],
            'team_out_id' => ['nullable', 'integer', 'exists:teams,id'],
        ];
    }
}
