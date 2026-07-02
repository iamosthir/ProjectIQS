<?php

namespace App\Http\Requests\Admin\Marketplace;

use App\Support\Enums\Currency;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class CategoryRequest extends FormRequest
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
        $create = $this->isMethod('POST');
        $required = $create ? 'required' : 'sometimes';
        $categoryId = $this->route('category')?->id;

        return [
            'key' => [
                $required, 'string', 'max:255',
                Rule::unique('marketplace_categories', 'key')->ignore($categoryId),
            ],
            'parent_id' => ['nullable', 'integer', 'exists:marketplace_categories,id'],
            'name_ar' => [$required, 'string', 'max:255'],
            'name_en' => [$required, 'string', 'max:255'],
            'description_ar' => ['nullable', 'string'],
            'description_en' => ['nullable', 'string'],
            'icon_path' => ['nullable', 'string', 'max:2048'],
            'base_price' => [$required, 'numeric', 'min:0'],
            'currency' => ['sometimes', Rule::enum(Currency::class)],
            'is_free' => ['sometimes', 'boolean'],
            'pricing_note' => ['nullable', 'string', 'max:255'],
            'field_schema' => ['nullable', 'array'],
            'requires_contact_button' => ['sometimes', 'boolean'],
            'listing_duration_days' => ['nullable', 'integer', 'min:1'],
            'display_order' => ['sometimes', 'integer'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
