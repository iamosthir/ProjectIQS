<?php

namespace App\Http\Requests\Api\Marketplace;

use App\Models\MarketplaceCategory;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;

class StoreListingRequest extends FormRequest
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
            'category_id' => ['required', 'integer', 'exists:marketplace_categories,id'],
            'title_ar' => ['required', 'string', 'max:255'],
            'title_en' => ['nullable', 'string', 'max:255'],
            'full_name' => ['nullable', 'string', 'max:255'],
            'photo_path' => ['nullable', 'string', 'max:2048'],
            'date_of_birth' => ['nullable', 'date'],
            'country' => ['nullable', 'string', 'max:255'],
            'nationality' => ['nullable', 'string', 'max:255'],
            'governorate' => ['nullable', 'string', 'max:255'],
            'city' => ['nullable', 'string', 'max:255'],
            'contact_phone' => ['nullable', 'string', 'max:30'],
            'contact_whatsapp' => ['nullable', 'string', 'max:30'],
            'contact_email' => ['nullable', 'email', 'max:255'],
            'show_contact' => ['sometimes', 'boolean'],
            'attributes' => ['nullable', 'array'],
            'cv_path' => ['nullable', 'string', 'max:2048'],
        ];
    }

    /**
     * Enforce required category-specific fields declared in field_schema.
     */
    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $category = MarketplaceCategory::find($this->input('category_id'));

            if ($category === null) {
                return;
            }

            foreach ($category->field_schema['fields'] ?? [] as $field) {
                if (($field['required'] ?? false) && blank(data_get($this->input('attributes'), $field['key']))) {
                    $validator->errors()->add("attributes.{$field['key']}", __('This field is required.'));
                }
            }
        });
    }
}
