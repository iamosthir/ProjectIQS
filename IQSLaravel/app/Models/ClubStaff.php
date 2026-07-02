<?php

namespace App\Models;

use App\Support\Enums\ClubStaffType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ClubStaff extends Model
{
    protected $table = 'club_staff';

    /**
     * @var list<string>
     */
    protected $fillable = [
        'club_id', 'name_ar', 'name_en', 'role_ar', 'role_en', 'type',
        'photo_path', 'bio', 'display_order',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return ['type' => ClubStaffType::class];
    }

    /**
     * @return BelongsTo<Club, $this>
     */
    public function club(): BelongsTo
    {
        return $this->belongsTo(Club::class);
    }
}
