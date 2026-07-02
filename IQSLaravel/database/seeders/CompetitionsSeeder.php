<?php

namespace Database\Seeders;

use App\Models\League;
use App\Support\Enums\LeagueCategory;
use App\Support\Enums\LeagueType;
use App\Support\Enums\Source;
use Illuminate\Database\Seeder;

/**
 * Seeds the 10 manual competition categories from the client's Match-Results
 * spec (§2 intro): 4 league divisions + the national team at 6 levels.
 */
class CompetitionsSeeder extends Seeder
{
    /**
     * @var list<array{category: LeagueCategory, tier: int, name_ar: string, name_en: string}>
     */
    protected array $competitions = [
        ['category' => LeagueCategory::Premier, 'tier' => 1, 'name_ar' => 'الدوري العراقي الممتاز', 'name_en' => 'Iraqi Premier League'],
        ['category' => LeagueCategory::FirstDiv, 'tier' => 2, 'name_ar' => 'دوري الدرجة الأولى', 'name_en' => 'First Division'],
        ['category' => LeagueCategory::SecondDiv, 'tier' => 3, 'name_ar' => 'دوري الدرجة الثانية', 'name_en' => 'Second Division'],
        ['category' => LeagueCategory::ThirdDiv, 'tier' => 4, 'name_ar' => 'دوري الدرجة الثالثة', 'name_en' => 'Third Division'],
        ['category' => LeagueCategory::NtSenior, 'tier' => 5, 'name_ar' => 'المنتخب الوطني العراقي', 'name_en' => 'Iraq National Team'],
        ['category' => LeagueCategory::NtU21, 'tier' => 6, 'name_ar' => 'المنتخب الأولمبي (تحت 21)', 'name_en' => 'Iraq U-21'],
        ['category' => LeagueCategory::NtU19, 'tier' => 7, 'name_ar' => 'منتخب الشباب (تحت 19)', 'name_en' => 'Iraq U-19'],
        ['category' => LeagueCategory::NtU17, 'tier' => 8, 'name_ar' => 'منتخب الناشئين (تحت 17)', 'name_en' => 'Iraq U-17'],
        ['category' => LeagueCategory::NtU16, 'tier' => 9, 'name_ar' => 'منتخب تحت 16', 'name_en' => 'Iraq U-16'],
        ['category' => LeagueCategory::NtU14, 'tier' => 10, 'name_ar' => 'منتخب تحت 14', 'name_en' => 'Iraq U-14'],
    ];

    public function run(): void
    {
        foreach ($this->competitions as $index => $competition) {
            League::updateOrCreate(
                ['source' => Source::Manual->value, 'category' => $competition['category']->value],
                [
                    'name_ar' => $competition['name_ar'],
                    'name_en' => $competition['name_en'],
                    'type' => LeagueType::League,
                    'is_iraqi' => true,
                    'tier' => $competition['tier'],
                    'requires_auth' => true,
                    'display_order' => $index,
                    'is_active' => true,
                ],
            );
        }
    }
}
