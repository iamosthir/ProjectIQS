<?php

namespace Database\Factories;

use App\Models\Club;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\ClubBoardMember>
 */
class ClubBoardMemberFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $name = fake()->name('male');

        return [
            'club_id' => Club::factory(),
            'name_ar' => $name,
            'name_en' => $name,
            'position_ar' => 'عضو',
            'position_en' => 'Member',
            'is_active' => true,
        ];
    }
}
