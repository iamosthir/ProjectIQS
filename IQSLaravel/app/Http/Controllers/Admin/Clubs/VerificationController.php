<?php

namespace App\Http\Controllers\Admin\Clubs;

use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\VerificationAdminResource;
use App\Models\ClubVerification;
use App\Support\Enums\VerificationStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VerificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $verifications = ClubVerification::query()
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->string('status')))
            ->when($request->filled('club_id'), fn ($q) => $q->where('club_id', $request->integer('club_id')))
            ->with(['club', 'requestedBy'])
            ->latest()
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(VerificationAdminResource::collection($verifications));
    }

    public function approve(ClubVerification $verification): JsonResponse
    {
        $verification->update(['status' => VerificationStatus::Approved, 'reviewed_at' => now()]);

        return $this->ok(new VerificationAdminResource($verification->load('club', 'requestedBy')), __('Verification approved.'));
    }

    public function reject(Request $request, ClubVerification $verification): JsonResponse
    {
        $data = $request->validate(['note' => ['nullable', 'string', 'max:500']]);

        $verification->update([
            'status' => VerificationStatus::Rejected,
            'reviewed_at' => now(),
            'note' => $data['note'] ?? $verification->note,
        ]);

        return $this->ok(new VerificationAdminResource($verification->load('club', 'requestedBy')), __('Verification rejected.'));
    }
}
