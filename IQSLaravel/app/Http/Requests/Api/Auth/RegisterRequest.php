<?php

namespace App\Http\Requests\Api\Auth;

use App\Support\Enums\UserGender;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Completes the post-OTP profile (§1.4 `/auth/register`).
 */
class RegisterRequest extends FormRequest
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
            'name' => ['required', 'string', 'max:255'],
            'email' => [
                'nullable', 'email', 'max:255',
                Rule::unique('users', 'email')->ignore($this->user()->id),
            ],
            'supported_club_id' => ['nullable', 'integer'],
            'supported_team_id' => ['nullable', 'integer'],
            'governorate' => ['nullable', 'string', 'max:255'],
            'gender' => ['nullable', Rule::enum(UserGender::class)],
            'date_of_birth' => ['nullable', 'date', 'before:today'],
        ];
    }
}
