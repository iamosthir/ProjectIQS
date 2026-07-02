<?php

namespace App\Http\Resources;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin User
 */
class UserResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'phone' => $this->phone,
            'name' => $this->name,
            'email' => $this->email,
            'avatar' => $this->avatar,
            'governorate' => $this->governorate,
            'gender' => $this->gender?->value,
            'date_of_birth' => $this->date_of_birth?->toDateString(),
            'locale' => $this->locale,
            'supported_club_id' => $this->supported_club_id,
            'supported_team_id' => $this->supported_team_id,
            'phone_verified' => $this->phone_verified_at !== null,
            'is_registration_completed' => $this->registration_completed_at !== null,
            'roles' => $this->getRoleNames(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
