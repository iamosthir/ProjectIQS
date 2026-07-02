<?php

namespace App\Http\Requests\Admin\Matches;

use Illuminate\Foundation\Http\FormRequest;

class FixtureNewsRequest extends FormRequest
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
        // Arabic is the primary column (required on create); the rest are
        // optional. On update everything is `sometimes` (partial edit).
        $required = $this->isMethod('POST') ? 'required' : 'sometimes';

        return [
            'title_ar' => [$required, 'string', 'max:255'],
            'title_en' => ['nullable', 'string', 'max:255'],
            'excerpt_ar' => ['nullable', 'string', 'max:1000'],
            'excerpt_en' => ['nullable', 'string', 'max:1000'],
            'content_ar' => ['nullable', 'string'],
            'content_en' => ['nullable', 'string'],
            'cover_path' => ['nullable', 'string', 'max:2048'],
            'url' => ['nullable', 'url', 'max:2048'],
            'is_published' => ['sometimes', 'boolean'],
            'published_at' => ['nullable', 'date'],
            'display_order' => ['nullable', 'integer', 'min:0'],
        ];
    }
}
