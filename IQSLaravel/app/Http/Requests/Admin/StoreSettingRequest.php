<?php

namespace App\Http\Requests\Admin;

use App\Support\Enums\SettingType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreSettingRequest extends FormRequest
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
            'group' => ['required', 'string', 'max:255'],
            'key' => [
                'required', 'string', 'max:255',
                Rule::unique('settings', 'key')->where('group', $this->input('group')),
            ],
            'type' => ['required', Rule::enum(SettingType::class)],
            'value' => ['nullable'],
            'is_public' => ['sometimes', 'boolean'],
        ];
    }
}
