<?php

namespace App\Http\Requests\Api\Marketplace;

use Illuminate\Foundation\Http\FormRequest;

class UpdateListingRequest extends FormRequest
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
            'title_ar' => ['sometimes', 'required', 'string', 'max:255'],
            'title_en' => ['sometimes', 'nullable', 'string', 'max:255'],
            'full_name' => ['sometimes', 'nullable', 'string', 'max:255'],
            'photo_path' => ['sometimes', 'nullable', 'string', 'max:2048'],
            'date_of_birth' => ['sometimes', 'nullable', 'date'],
            'country' => ['sometimes', 'nullable', 'string', 'max:255'],
            'nationality' => ['sometimes', 'nullable', 'string', 'max:255'],
            'governorate' => ['sometimes', 'nullable', 'string', 'max:255'],
            'city' => ['sometimes', 'nullable', 'string', 'max:255'],
            'contact_phone' => ['sometimes', 'nullable', 'string', 'max:30'],
            'contact_whatsapp' => ['sometimes', 'nullable', 'string', 'max:30'],
            'contact_email' => ['sometimes', 'nullable', 'email', 'max:255'],
            'show_contact' => ['sometimes', 'boolean'],
            'attributes' => ['sometimes', 'nullable', 'array'],
            'cv_path' => ['sometimes', 'nullable', 'string', 'max:2048'],
        ];
    }
}
