<?php

namespace Database\Factories;

use App\Models\FanGroup;
use App\Models\User;
use App\Support\Enums\VerificationMethod;
use App\Support\Enums\VerificationStatus;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\FanGroupVerification>
 */
class FanGroupVerificationFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'fan_group_id' => FanGroup::factory(),
            'user_id' => User::factory(),
            'method' => VerificationMethod::Message,
            'status' => VerificationStatus::Pending,
        ];
    }
}
