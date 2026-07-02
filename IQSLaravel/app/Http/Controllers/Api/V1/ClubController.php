<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ClubDetailResource;
use App\Http\Resources\ClubNewsResource;
use App\Http\Resources\ClubResource;
use App\Models\Club;
use App\Models\ClubNews;
use App\Models\Setting;
use App\Support\Enums\VerificationMethod;
use App\Support\Enums\VerificationStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ClubController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $clubs = Club::query()
            ->where('is_active', true)
            ->when($request->filled('governorate'), fn ($q) => $q->where('governorate', $request->string('governorate')))
            ->when($request->filled('q'), fn ($q) => $q->where(fn ($w) => $w
                ->where('name_ar', 'like', '%'.$request->string('q').'%')
                ->orWhere('name_en', 'like', '%'.$request->string('q').'%')))
            ->orderByDesc('is_verified')
            ->orderBy('display_order')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(ClubResource::collection($clubs));
    }

    public function show(Club $club): JsonResponse
    {
        $club->load(['boardMembers', 'staff', 'titles', 'captains', 'competitions']);

        return $this->ok(new ClubDetailResource($club));
    }

    public function news(Request $request, Club $club): JsonResponse
    {
        $news = $club->news()
            ->where('is_published', true)
            ->latest('published_at')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(ClubNewsResource::collection($news));
    }

    public function newsArticle(Club $club, ClubNews $news): JsonResponse
    {
        abort_unless($news->club_id === $club->id && $news->is_published, 404);

        $news->increment('views_count');
        $news->setAttribute('with_content', true);

        return $this->ok(new ClubNewsResource($news));
    }

    public function verifyRequest(Request $request, Club $club): JsonResponse
    {
        if (! Setting::get('clubs', 'verification_enabled', false)) {
            return $this->fail(__('Club verification is not available yet.'), null, 403);
        }

        $data = $request->validate([
            'method' => ['required', Rule::enum(VerificationMethod::class)],
            'note' => ['nullable', 'string', 'max:1000'],
        ]);

        $verification = $club->verifications()->create([
            'verifiable_type' => $request->user()->getMorphClass(),
            'verifiable_id' => $request->user()->id,
            'requested_by' => $request->user()->id,
            'method' => $data['method'],
            'note' => $data['note'] ?? null,
            'status' => VerificationStatus::Pending,
        ]);

        return $this->created([
            'id' => $verification->id,
            'status' => $verification->status->value,
        ], __('Verification request submitted.'));
    }
}
