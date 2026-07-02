<?php

namespace App\Http\Requests\Admin;

use App\Support\Enums\SettingType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateSettingRequest extends FormRequest
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
            'type' => ['sometimes', Rule::enum(SettingType::class)],
            'value' => ['sometimes', 'nullable'],
            'is_public' => ['sometimes', 'boolean'],
        ];
    }
}
