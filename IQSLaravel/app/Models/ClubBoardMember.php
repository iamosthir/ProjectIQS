<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ClubBoardMember extends Model
{
    /** @use HasFactory<\Database\Factories\ClubBoardMemberFactory> */
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'club_id', 'parent_id', 'name_ar', 'name_en', 'position_ar', 'position_en',
        'photo_path', 'display_order', 'is_active',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return ['is_active' => 'boolean'];
    }

    /**
     * @return BelongsTo<Club, $this>
     */
    public function club(): BelongsTo
    {
        return $this->belongsTo(Club::class);
    }

    /**
     * @return HasMany<ClubBoardMember, $this>
     */
    public function children(): HasMany
    {
        return $this->hasMany(ClubBoardMember::class, 'parent_id');
    }
}
