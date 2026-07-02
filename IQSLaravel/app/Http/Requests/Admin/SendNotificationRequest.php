<?php

namespace App\Http\Requests\Admin;

use App\Support\Enums\NotificationActionType;
use App\Support\Enums\NotificationTarget;
use App\Support\Enums\NotificationType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class SendNotificationRequest extends FormRequest
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
            'title_ar' => ['required', 'string', 'max:255'],
            'title_en' => ['required', 'string', 'max:255'],
            'body_ar' => ['required', 'string', 'max:2000'],
            'body_en' => ['required', 'string', 'max:2000'],
            'target' => ['required', Rule::enum(NotificationTarget::class)],
            'target_value' => ['nullable', 'array'],
            'target_value.club_id' => ['required_if:target,club_supporters', 'integer', 'exists:clubs,id'],
            'target_value.governorate' => ['required_if:target,governorate', 'string'],
            'target_value.user_ids' => ['required_if:target,custom', 'array'],
            'target_value.user_ids.*' => ['integer'],
            'type' => ['sometimes', Rule::enum(NotificationType::class)],
            'action_type' => ['sometimes', Rule::enum(NotificationActionType::class)],
            'action_value' => ['nullable', 'string', 'max:255'],
            'image_path' => ['nullable', 'string', 'max:2048'],
            'scheduled_at' => ['nullable', 'date'],
        ];
    }
}
