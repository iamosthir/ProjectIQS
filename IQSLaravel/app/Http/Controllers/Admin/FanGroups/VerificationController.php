<?php

namespace App\Http\Controllers\Admin\FanGroups;

use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\FanGroupVerificationAdminResource;
use App\Models\FanGroupVerification;
use App\Support\Enums\VerificationStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VerificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $verifications = FanGroupVerification::query()
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->string('status')))
            ->when($request->filled('fan_group_id'), fn ($q) => $q->where('fan_group_id', $request->integer('fan_group_id')))
            ->with(['fanGroup', 'user'])
            ->latest()
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(FanGroupVerificationAdminResource::collection($verifications));
    }

    public function approve(FanGroupVerification $verification): JsonResponse
    {
        $verification->update(['status' => VerificationStatus::Approved, 'reviewed_at' => now()]);

        return $this->ok(new FanGroupVerificationAdminResource($verification->load('fanGroup', 'user')), __('Verification approved.'));
    }

    public function reject(Request $request, FanGroupVerification $verification): JsonResponse
    {
        $data = $request->validate(['note' => ['nullable', 'string', 'max:500']]);

        $verification->update([
            'status' => VerificationStatus::Rejected,
            'reviewed_at' => now(),
            'note' => $data['note'] ?? $verification->note,
        ]);

        return $this->ok(new FanGroupVerificationAdminResource($verification->load('fanGroup', 'user')), __('Verification rejected.'));
    }
}
