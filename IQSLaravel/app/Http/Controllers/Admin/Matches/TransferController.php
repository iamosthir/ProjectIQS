<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Matches\TransferRequest;
use App\Models\Transfer;
use App\Support\Enums\Source;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TransferController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $transfers = Transfer::query()
            ->with(['player', 'teamIn', 'teamOut'])
            ->when($request->filled('player_id'), fn ($q) => $q->where('player_id', $request->integer('player_id')))
            ->when($request->filled('team_id'), function ($q) use ($request) {
                $teamId = $request->integer('team_id');
                $q->where(fn ($w) => $w->where('team_in_id', $teamId)->orWhere('team_out_id', $teamId));
            })
            ->orderByDesc('transfer_date')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok($transfers);
    }

    public function store(TransferRequest $request): JsonResponse
    {
        $transfer = Transfer::create(array_merge($request->validated(), ['source' => Source::Manual]));

        return $this->created($transfer->load(['player', 'teamIn', 'teamOut']), __('Transfer created.'));
    }

    public function show(Transfer $transfer): JsonResponse
    {
        return $this->ok($transfer->load(['player', 'teamIn', 'teamOut']));
    }

    public function update(TransferRequest $request, Transfer $transfer): JsonResponse
    {
        $transfer->update($request->validated());

        return $this->ok($transfer->load(['player', 'teamIn', 'teamOut']), __('Transfer updated.'));
    }

    public function destroy(Transfer $transfer): JsonResponse
    {
        $transfer->delete();

        return $this->noContentMessage(__('Transfer deleted.'));
    }
}
