<?php

namespace App\Http\Requests\Api\Auth;

use App\Http\Requests\Api\Auth\Concerns\NormalizesIraqiPhone;
use App\Support\Enums\OtpPurpose;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class VerifyOtpRequest extends FormRequest
{
    use NormalizesIraqiPhone;

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
            'phone' => ['required', 'string', 'phone:IQ'],
            'otp' => ['required', 'string'],
            'purpose' => ['sometimes', Rule::enum(OtpPurpose::class)],
        ];
    }
}
