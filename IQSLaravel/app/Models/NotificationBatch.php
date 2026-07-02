<?php

namespace App\Models;

use App\Support\Enums\NotificationActionType;
use App\Support\Enums\NotificationBatchStatus;
use App\Support\Enums\NotificationTarget;
use App\Support\Enums\NotificationType;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NotificationBatch extends Model
{
    /** @use HasFactory<\Database\Factories\NotificationBatchFactory> */
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'admin_id', 'title_ar', 'title_en', 'body_ar', 'body_en', 'target',
        'target_value', 'type', 'action_type', 'action_value', 'image_path',
        'total_recipients', 'sent_count', 'failed_count', 'status',
        'scheduled_at', 'sent_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'target' => NotificationTarget::class,
            'type' => NotificationType::class,
            'action_type' => NotificationActionType::class,
            'status' => NotificationBatchStatus::class,
            'target_value' => 'array',
            'scheduled_at' => 'datetime',
            'sent_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<Admin, $this>
     */
    public function admin(): BelongsTo
    {
        return $this->belongsTo(Admin::class);
    }
}
