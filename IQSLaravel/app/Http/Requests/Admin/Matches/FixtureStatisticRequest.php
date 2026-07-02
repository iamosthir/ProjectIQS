<?php

namespace App\Http\Requests\Admin\Matches;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Bulk save of a fixture's manual statistics (home vs away rows). The console
 * submits the full set; the controller replaces the fixture's manual rows.
 */
class FixtureStatisticRequest extends FormRequest
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
            'statistics' => ['present', 'array'],
            'statistics.*.team_id' => ['required', 'integer', 'exists:teams,id'],
            'statistics.*.type' => ['required', 'string', 'max:255'],
            'statistics.*.value' => ['nullable', 'string', 'max:255'],
            'statistics.*.value_numeric' => ['nullable', 'numeric'],
            'statistics.*.display_order' => ['nullable', 'integer', 'min:0'],
        ];
    }
}
