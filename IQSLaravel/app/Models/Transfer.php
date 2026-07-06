<?php

namespace App\Models;

use App\Support\Enums\Source;
use Database\Factories\TransferFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Transfer extends Model
{
    /** @use HasFactory<TransferFactory> */
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'source', 'player_id', 'transfer_date', 'type',
        'team_in_id', 'team_out_id', 'last_synced_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'source' => Source::class,
            'transfer_date' => 'date',
            'last_synced_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<Player, $this>
     */
    public function player(): BelongsTo
    {
        return $this->belongsTo(Player::class);
    }

    /**
     * @return BelongsTo<Team, $this>
     */
    public function teamIn(): BelongsTo
    {
        return $this->belongsTo(Team::class, 'team_in_id');
    }

    /**
     * @return BelongsTo<Team, $this>
     */
    public function teamOut(): BelongsTo
    {
        return $this->belongsTo(Team::class, 'team_out_id');
    }
}
