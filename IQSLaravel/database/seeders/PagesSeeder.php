<?php

namespace Database\Seeders;

use App\Models\Page;
use Illuminate\Database\Seeder;

/**
 * Seeds the legal/static pages the app and store review need (§8.1).
 */
class PagesSeeder extends Seeder
{
    /**
     * @var list<array{slug: string, ar: string, en: string}>
     */
    protected array $pages = [
        ['slug' => 'privacy', 'ar' => 'سياسة الخصوصية', 'en' => 'Privacy Policy'],
        ['slug' => 'terms', 'ar' => 'الشروط والأحكام', 'en' => 'Terms & Conditions'],
        ['slug' => 'about', 'ar' => 'عن التطبيق', 'en' => 'About IQS'],
    ];

    public function run(): void
    {
        foreach ($this->pages as $page) {
            Page::updateOrCreate(
                ['slug' => $page['slug']],
                [
                    'title_ar' => $page['ar'],
                    'title_en' => $page['en'],
                    'content_ar' => "محتوى {$page['ar']} — يُحدَّث من لوحة التحكم.",
                    'content_en' => "{$page['en']} content — edit from the admin panel.",
                    'is_active' => true,
                ],
            );
        }
    }
}
