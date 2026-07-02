<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class InitiatePaymentRequest extends FormRequest
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
            'payable_type' => ['required', 'string', Rule::in(array_keys((array) config('payments.payables')))],
            'payable_id' => ['required', 'integer'],
            // Customers choose a real gateway; `manual` is admin-only.
            'gateway' => ['required', Rule::in(['zaincash', 'fib'])],
        ];
    }
}
