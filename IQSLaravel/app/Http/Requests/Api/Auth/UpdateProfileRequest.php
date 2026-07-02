<?php

namespace App\Http\Requests\Api\Auth;

use App\Support\Enums\UserGender;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProfileRequest extends FormRequest
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
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'email' => [
                'sometimes', 'nullable', 'email', 'max:255',
                Rule::unique('users', 'email')->ignore($this->user()->id),
            ],
            'avatar' => ['sometimes', 'nullable', 'string', 'max:2048'],
            'governorate' => ['sometimes', 'nullable', 'string', 'max:255'],
            'gender' => ['sometimes', 'nullable', Rule::enum(UserGender::class)],
            'date_of_birth' => ['sometimes', 'nullable', 'date', 'before:today'],
            'locale' => ['sometimes', Rule::in(['ar', 'en'])],
            'supported_club_id' => ['sometimes', 'nullable', 'integer'],
            'supported_team_id' => ['sometimes', 'nullable', 'integer'],
        ];
    }
}
