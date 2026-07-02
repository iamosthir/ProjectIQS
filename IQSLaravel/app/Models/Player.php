<?php

namespace App\Models;

use App\Models\Concerns\HasCanonicalSource;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Player extends Model
{
    /** @use HasFactory<\Database\Factories\PlayerFactory> */
    use HasCanonicalSource, HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'source', 'external_id', 'name_ar', 'name_en', 'firstname', 'lastname',
        'date_of_birth', 'birth_place', 'birth_country', 'nationality',
        'height', 'weight', 'photo_path', 'position', 'is_injured',
        'external_payload', 'last_synced_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'date_of_birth' => 'date',
            'is_injured' => 'boolean',
        ];
    }

    /**
     * @return BelongsToMany<Team, $this>
     */
    public function teams(): BelongsToMany
    {
        return $this->belongsToMany(Team::class, 'team_player')
            ->withPivot(['season_id', 'number', 'position', 'is_active'])
            ->withTimestamps();
    }
}
