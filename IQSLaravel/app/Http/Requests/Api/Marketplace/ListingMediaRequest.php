<?php

namespace App\Http\Requests\Api\Marketplace;

use App\Support\Enums\ListingMediaType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ListingMediaRequest extends FormRequest
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
            'type' => ['required', Rule::enum(ListingMediaType::class)],
            'file' => ['required', 'file', 'max:20480'], // 20 MB
            'title' => ['nullable', 'string', 'max:255'],
        ];
    }
}
