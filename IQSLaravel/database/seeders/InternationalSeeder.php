<?php

namespace Database\Seeders;

use App\Models\League;
use App\Models\Team;
use App\Support\Enums\LeagueCategory;
use App\Support\Enums\LeagueType;
use App\Support\Enums\Source;
use Illuminate\Database\Seeder;

/**
 * Seeds international (country-vs-country) support: a FIFA World Cup
 * qualifiers competition plus the national teams Iraq regularly faces, each
 * with its country flag as the team logo (flagcdn.com — public domain PNGs,
 * passed through verbatim by every client since logo_path supports absolute
 * URLs). Idempotent: keyed on (source, name_en).
 */
class InternationalSeeder extends Seeder
{
    /**
     * @var list<array{name_en: string, name_ar: string, country: string, code: string, flag: string}>
     */
    protected array $nationalTeams = [
        ['name_en' => 'Iraq', 'name_ar' => 'منتخب العراق', 'country' => 'Iraq', 'code' => 'IRQ', 'flag' => 'iq'],
        ['name_en' => 'Saudi Arabia', 'name_ar' => 'منتخب السعودية', 'country' => 'Saudi Arabia', 'code' => 'KSA', 'flag' => 'sa'],
        ['name_en' => 'Iran', 'name_ar' => 'منتخب إيران', 'country' => 'Iran', 'code' => 'IRN', 'flag' => 'ir'],
        ['name_en' => 'Jordan', 'name_ar' => 'منتخب الأردن', 'country' => 'Jordan', 'code' => 'JOR', 'flag' => 'jo'],
        ['name_en' => 'United Arab Emirates', 'name_ar' => 'منتخب الإمارات', 'country' => 'United Arab Emirates', 'code' => 'UAE', 'flag' => 'ae'],
        ['name_en' => 'Qatar', 'name_ar' => 'منتخب قطر', 'country' => 'Qatar', 'code' => 'QAT', 'flag' => 'qa'],
        ['name_en' => 'Kuwait', 'name_ar' => 'منتخب الكويت', 'country' => 'Kuwait', 'code' => 'KUW', 'flag' => 'kw'],
        ['name_en' => 'Oman', 'name_ar' => 'منتخب عُمان', 'country' => 'Oman', 'code' => 'OMA', 'flag' => 'om'],
        ['name_en' => 'Bahrain', 'name_ar' => 'منتخب البحرين', 'country' => 'Bahrain', 'code' => 'BHR', 'flag' => 'bh'],
        ['name_en' => 'Syria', 'name_ar' => 'منتخب سوريا', 'country' => 'Syria', 'code' => 'SYR', 'flag' => 'sy'],
        ['name_en' => 'Lebanon', 'name_ar' => 'منتخب لبنان', 'country' => 'Lebanon', 'code' => 'LBN', 'flag' => 'lb'],
        ['name_en' => 'Palestine', 'name_ar' => 'منتخب فلسطين', 'country' => 'Palestine', 'code' => 'PLE', 'flag' => 'ps'],
        ['name_en' => 'Yemen', 'name_ar' => 'منتخب اليمن', 'country' => 'Yemen', 'code' => 'YEM', 'flag' => 'ye'],
        ['name_en' => 'Australia', 'name_ar' => 'منتخب أستراليا', 'country' => 'Australia', 'code' => 'AUS', 'flag' => 'au'],
        ['name_en' => 'Japan', 'name_ar' => 'منتخب اليابان', 'country' => 'Japan', 'code' => 'JPN', 'flag' => 'jp'],
        ['name_en' => 'South Korea', 'name_ar' => 'منتخب كوريا الجنوبية', 'country' => 'South Korea', 'code' => 'KOR', 'flag' => 'kr'],
        ['name_en' => 'Uzbekistan', 'name_ar' => 'منتخب أوزبكستان', 'country' => 'Uzbekistan', 'code' => 'UZB', 'flag' => 'uz'],
        ['name_en' => 'Indonesia', 'name_ar' => 'منتخب إندونيسيا', 'country' => 'Indonesia', 'code' => 'IDN', 'flag' => 'id'],
    ];

    public function run(): void
    {
        League::updateOrCreate(
            ['source' => Source::Manual->value, 'name_en' => 'FIFA World Cup Qualifiers — Asia'],
            [
                'name_ar' => 'تصفيات كأس العالم — آسيا',
                'type' => LeagueType::League,
                'category' => LeagueCategory::Other,
                'is_iraqi' => false,
                'tier' => 1,
                'requires_auth' => false,
                'display_order' => 100,
                'is_active' => true,
            ],
        );

        foreach ($this->nationalTeams as $team) {
            Team::updateOrCreate(
                ['source' => Source::Manual->value, 'name_en' => $team['name_en'], 'is_national' => true],
                [
                    'name_ar' => $team['name_ar'],
                    'short_code' => $team['code'],
                    'country_name' => $team['country'],
                    'logo_path' => "https://flagcdn.com/w320/{$team['flag']}.png",
                    'is_active' => true,
                ],
            );
        }
    }
}
