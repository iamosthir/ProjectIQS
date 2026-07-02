<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\SendNotificationRequest;
use App\Http\Resources\Admin\NotificationBatchResource;
use App\Jobs\ProcessNotificationBatchJob;
use App\Models\Club;
use App\Models\NotificationBatch;
use App\Models\User;
use App\Support\Enums\NotificationBatchStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * Composer metadata: target options, clubs and governorates to choose from.
     */
    public function compose(): JsonResponse
    {
        return $this->ok([
            'targets' => ['all', 'club_supporters', 'governorate', 'custom'],
            'types' => ['general', 'match', 'listing', 'club', 'fan_group', 'payment', 'system'],
            'action_types' => ['none', 'url', 'fixture', 'listing', 'club', 'fan_group'],
            'clubs' => Club::query()->where('is_active', true)->orderBy('name_en')->get(['id', 'name_ar', 'name_en']),
            'governorates' => User::query()->whereNotNull('governorate')->distinct()->orderBy('governorate')->pluck('governorate'),
        ]);
    }

    public function send(SendNotificationRequest $request): JsonResponse
    {
        $batch = NotificationBatch::create(array_merge($request->validated(), [
            'admin_id' => $request->user()->id,
            'status' => NotificationBatchStatus::Queued,
        ]));

        $job = ProcessNotificationBatchJob::dispatch($batch->id);

        if ($batch->scheduled_at !== null && $batch->scheduled_at->isFuture()) {
            $job->delay($batch->scheduled_at);
        }

        return $this->created(new NotificationBatchResource($batch), __('Broadcast queued.'));
    }

    public function batches(Request $request): JsonResponse
    {
        $batches = NotificationBatch::query()
            ->with('admin')
            ->latest()
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(NotificationBatchResource::collection($batches));
    }

    public function batch(NotificationBatch $batch): JsonResponse
    {
        return $this->ok(new NotificationBatchResource($batch->load('admin')));
    }
}
