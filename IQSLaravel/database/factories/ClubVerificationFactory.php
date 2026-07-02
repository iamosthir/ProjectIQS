<?php

namespace Database\Factories;

use App\Models\Club;
use App\Models\User;
use App\Support\Enums\VerificationMethod;
use App\Support\Enums\VerificationStatus;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\ClubVerification>
 */
class ClubVerificationFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $user = User::factory();

        return [
            'club_id' => Club::factory(),
            'verifiable_type' => (new User)->getMorphClass(),
            'verifiable_id' => $user,
            'requested_by' => $user,
            'method' => VerificationMethod::Message,
            'status' => VerificationStatus::Pending,
        ];
    }
}
