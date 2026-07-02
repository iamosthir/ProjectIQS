<?php

namespace App\Models;

use App\Support\Enums\Currency;
use App\Support\Enums\PaymentGatewayType;
use App\Support\Enums\PaymentStatus;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use Illuminate\Support\Str;

class Payment extends Model
{
    /** @use HasFactory<\Database\Factories\PaymentFactory> */
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'user_id', 'payable_type', 'payable_id', 'payment_number', 'gateway',
        'amount', 'currency', 'status', 'gateway_transaction_id', 'gateway_reference',
        'gateway_payload', 'paid_at', 'expires_at', 'failure_reason', 'metadata',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'gateway' => PaymentGatewayType::class,
            'currency' => Currency::class,
            'status' => PaymentStatus::class,
            'amount' => 'decimal:2',
            'gateway_payload' => 'array',
            'metadata' => 'array',
            'paid_at' => 'datetime',
            'expires_at' => 'datetime',
        ];
    }

    /**
     * Generate a unique human-friendly reference (e.g. IQS-PAY-20260705-AB12CD).
     */
    public static function generateNumber(): string
    {
        do {
            $number = 'IQS-PAY-'.now()->format('Ymd').'-'.strtoupper(Str::random(6));
        } while (self::where('payment_number', $number)->exists());

        return $number;
    }

    public function isPaid(): bool
    {
        return $this->status === PaymentStatus::Paid;
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * @return MorphTo<Model, $this>
     */
    public function payable(): MorphTo
    {
        return $this->morphTo();
    }

    /**
     * @return HasMany<PaymentWebhook, $this>
     */
    public function webhooks(): HasMany
    {
        return $this->hasMany(PaymentWebhook::class);
    }
}
