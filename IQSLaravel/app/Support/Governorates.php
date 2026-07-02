<?php

namespace App\Support;

/**
 * The 18 Iraqi governorates, served statically for app dropdowns (§8.2).
 */
class Governorates
{
    /**
     * @var list<array{code: string, ar: string, en: string}>
     */
    public const ALL = [
        ['code' => 'baghdad', 'ar' => 'بغداد', 'en' => 'Baghdad'],
        ['code' => 'basra', 'ar' => 'البصرة', 'en' => 'Basra'],
        ['code' => 'nineveh', 'ar' => 'نينوى', 'en' => 'Nineveh'],
        ['code' => 'erbil', 'ar' => 'أربيل', 'en' => 'Erbil'],
        ['code' => 'sulaymaniyah', 'ar' => 'السليمانية', 'en' => 'Sulaymaniyah'],
        ['code' => 'dohuk', 'ar' => 'دهوك', 'en' => 'Dohuk'],
        ['code' => 'kirkuk', 'ar' => 'كركوك', 'en' => 'Kirkuk'],
        ['code' => 'najaf', 'ar' => 'النجف', 'en' => 'Najaf'],
        ['code' => 'karbala', 'ar' => 'كربلاء', 'en' => 'Karbala'],
        ['code' => 'babylon', 'ar' => 'بابل', 'en' => 'Babylon'],
        ['code' => 'wasit', 'ar' => 'واسط', 'en' => 'Wasit'],
        ['code' => 'maysan', 'ar' => 'ميسان', 'en' => 'Maysan'],
        ['code' => 'dhi_qar', 'ar' => 'ذي قار', 'en' => 'Dhi Qar'],
        ['code' => 'muthanna', 'ar' => 'المثنى', 'en' => 'Muthanna'],
        ['code' => 'qadisiyyah', 'ar' => 'القادسية', 'en' => 'Al-Qadisiyyah'],
        ['code' => 'diyala', 'ar' => 'ديالى', 'en' => 'Diyala'],
        ['code' => 'anbar', 'ar' => 'الأنبار', 'en' => 'Anbar'],
        ['code' => 'salaheddin', 'ar' => 'صلاح الدين', 'en' => 'Saladin'],
    ];

    /**
     * @return list<array{code: string, name: string}>
     */
    public static function localized(string $locale): array
    {
        return array_map(fn (array $g) => [
            'code' => $g['code'],
            'name' => $locale === 'en' ? $g['en'] : $g['ar'],
        ], self::ALL);
    }
}
