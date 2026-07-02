<?php

namespace Database\Seeders;

use App\Models\MarketplaceCategory;
use App\Support\Enums\Currency;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

/**
 * Seeds the marketplace category tree from the client's list (§3.1/§3.2):
 * a free basic player profile, paid professional cards, the coaching family,
 * and the professional-services cards.
 */
class MarketplaceCategoriesSeeder extends Seeder
{
    /**
     * @var list<array{key: string, ar: string, en: string, price: int, free?: bool, parent?: string, fields?: list<string>}>
     */
    protected array $categories = [
        ['key' => 'player_profile', 'ar' => 'بطاقة لاعب', 'en' => 'Player Profile', 'price' => 0, 'free' => true, 'fields' => ['position', 'height', 'weight', 'preferred_foot']],
        ['key' => 'professional_no_agent', 'ar' => 'محترف بدون وكيل', 'en' => 'Professional (no agent)', 'price' => 20000, 'fields' => ['position', 'preferred_foot', 'current_club']],
        ['key' => 'professional_with_agent', 'ar' => 'محترف مع وكيل', 'en' => 'Professional (with agent)', 'price' => 20000, 'fields' => ['position', 'agent_name', 'agent_phone']],
        ['key' => 'coach', 'ar' => 'مدرب', 'en' => 'Head Coach', 'price' => 25000, 'parent' => 'coaches', 'fields' => ['coaching_license', 'target_team_category']],
        ['key' => 'assistant_coach', 'ar' => 'مدرب مساعد', 'en' => 'Assistant Coach', 'price' => 25000, 'parent' => 'coaches', 'fields' => ['coaching_license']],
        ['key' => 'gk_coach', 'ar' => 'مدرب حراس مرمى', 'en' => 'Goalkeeping Coach', 'price' => 25000, 'parent' => 'coaches', 'fields' => ['coaching_license']],
        ['key' => 'fitness_coach', 'ar' => 'مدرب لياقة', 'en' => 'Fitness Coach', 'price' => 25000, 'parent' => 'coaches', 'fields' => ['certifications']],
        ['key' => 'ex_manager', 'ar' => 'مدير سابق', 'en' => 'Ex-Manager', 'price' => 25000, 'fields' => ['experience_years']],
        ['key' => 'lawyer', 'ar' => 'محامٍ', 'en' => 'Lawyer', 'price' => 25000, 'fields' => ['practice_areas', 'languages']],
        ['key' => 'accountant', 'ar' => 'محاسب', 'en' => 'Accountant', 'price' => 25000, 'fields' => ['certifications']],
        ['key' => 'executive_director', 'ar' => 'مدير تنفيذي', 'en' => 'Executive Director', 'price' => 25000, 'fields' => ['experience_years']],
        ['key' => 'team_supervisor', 'ar' => 'مشرف فريق', 'en' => 'Team Supervisor', 'price' => 25000, 'fields' => ['experience_years']],
        ['key' => 'tactical_plan', 'ar' => 'خطة تكتيكية', 'en' => 'Tactical Plan', 'price' => 25000, 'fields' => ['formation', 'description']],
        ['key' => 'sports_specialist', 'ar' => 'أخصائي رياضي', 'en' => 'Sports Specialist', 'price' => 25000, 'fields' => ['specialty']],
        ['key' => 'sports_lawyer', 'ar' => 'محامٍ رياضي', 'en' => 'Sports Lawyer', 'price' => 25000, 'fields' => ['practice_areas']],
    ];

    public function run(): void
    {
        $coaches = MarketplaceCategory::updateOrCreate(
            ['key' => 'coaches'],
            ['name_ar' => 'المدربون', 'name_en' => 'Coaches', 'is_active' => true, 'display_order' => 0],
        );

        $parents = ['coaches' => $coaches->id];
        $order = 1;

        foreach ($this->categories as $category) {
            MarketplaceCategory::updateOrCreate(
                ['key' => $category['key']],
                [
                    'parent_id' => isset($category['parent']) ? $parents[$category['parent']] : null,
                    'name_ar' => $category['ar'],
                    'name_en' => $category['en'],
                    'base_price' => $category['price'],
                    'currency' => Currency::IQD,
                    'is_free' => $category['free'] ?? false,
                    'requires_contact_button' => true,
                    'listing_duration_days' => 30,
                    'field_schema' => $this->schema($category['fields'] ?? []),
                    'display_order' => $order++,
                    'is_active' => true,
                ],
            );
        }
    }

    /**
     * @param  list<string>  $fields
     * @return array<string, mixed>
     */
    protected function schema(array $fields): array
    {
        return [
            'fields' => array_map(fn (string $key) => [
                'key' => $key,
                'label_en' => Str::headline($key),
                'label_ar' => $key,
                'type' => 'text',
                'required' => false,
            ], $fields),
            'media' => ['image' => 6, 'video' => 1, 'document' => 1],
        ];
    }
}
