<?php

namespace App\Models;

use App\Support\Enums\SettingType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

class Setting extends Model
{
    /**
     * @var list<string>
     */
    protected $fillable = [
        'group',
        'key',
        'value',
        'type',
        'is_public',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'type' => SettingType::class,
            'is_public' => 'boolean',
        ];
    }

    protected static function booted(): void
    {
        // Keep the cache coherent on any write.
        static::saved(fn () => Cache::forget(self::cacheKey()));
        static::deleted(fn () => Cache::forget(self::cacheKey()));
    }

    /**
     * The typed value of this setting.
     */
    public function typedValue(): mixed
    {
        return $this->type->cast($this->value);
    }

    /**
     * Read a setting's typed value, cached. Returns $default when missing.
     */
    public static function get(string $group, string $key, mixed $default = null): mixed
    {
        $all = self::cached();

        return $all["{$group}.{$key}"] ?? $default;
    }

    /**
     * Create or update a setting and return the model.
     */
    public static function set(string $group, string $key, mixed $value, SettingType $type = SettingType::String, bool $isPublic = false): self
    {
        return self::updateOrCreate(
            ['group' => $group, 'key' => $key],
            [
                'value' => $type->serialize($value),
                'type' => $type,
                'is_public' => $isPublic,
            ],
        );
    }

    /**
     * All public settings grouped, keyed "group.key" => typed value.
     *
     * @return array<string, mixed>
     */
    public static function publicValues(): array
    {
        return self::query()
            ->where('is_public', true)
            ->get()
            ->mapWithKeys(fn (self $s) => ["{$s->group}.{$s->key}" => $s->typedValue()])
            ->all();
    }

    /**
     * @return array<string, mixed>
     */
    protected static function cached(): array
    {
        return Cache::rememberForever(self::cacheKey(), fn () => self::query()
            ->get()
            ->mapWithKeys(fn (self $s) => ["{$s->group}.{$s->key}" => $s->typedValue()])
            ->all());
    }

    protected static function cacheKey(): string
    {
        return 'settings.all';
    }
}
