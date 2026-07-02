<?php

namespace App\Support\Enums;

enum SettingType: string
{
    case String = 'string';
    case Integer = 'integer';
    case Boolean = 'boolean';
    case Json = 'json';

    /**
     * Cast a stored string value into its typed PHP representation.
     */
    public function cast(?string $value): mixed
    {
        if ($value === null) {
            return null;
        }

        return match ($this) {
            self::String => $value,
            self::Integer => (int) $value,
            self::Boolean => filter_var($value, FILTER_VALIDATE_BOOLEAN),
            self::Json => json_decode($value, true),
        };
    }

    /**
     * Serialize a typed value into its stored string representation.
     */
    public function serialize(mixed $value): ?string
    {
        if ($value === null) {
            return null;
        }

        return match ($this) {
            self::String => (string) $value,
            self::Integer => (string) (int) $value,
            self::Boolean => $value ? '1' : '0',
            self::Json => json_encode($value),
        };
    }
}
