<?php

namespace App\Models;

use App\Support\Enums\VerificationMethod;
use App\Support\Enums\VerificationStatus;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FanGroupVerification extends Model
{
    /** @use HasFactory<\Database\Factories\FanGroupVerificationFactory> */
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'fan_group_id', 'user_id', 'status', 'method', 'note', 'reviewed_by', 'reviewed_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'status' => VerificationStatus::class,
            'method' => VerificationMethod::class,
            'reviewed_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<FanGroup, $this>
     */
    public function fanGroup(): BelongsTo
    {
        return $this->belongsTo(FanGroup::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function reviewedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }
}
