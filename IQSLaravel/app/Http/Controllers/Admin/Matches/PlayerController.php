<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Concerns\HandlesImageUploads;
use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Matches\PlayerRequest;
use App\Http\Resources\Admin\PlayerAdminResource;
use App\Models\Player;
use App\Support\Enums\Source;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Spatie\QueryBuilder\AllowedFilter;
use Spatie\QueryBuilder\QueryBuilder;

class PlayerController extends Controller
{
    use HandlesImageUploads;

    public function upload(Request $request): JsonResponse
    {
        return $this->uploadImage($request, 'players');
    }

    public function index(Request $request): JsonResponse
    {
        $players = QueryBuilder::for(Player::class)
            ->allowedFilters([
                AllowedFilter::exact('source'),
                AllowedFilter::callback('search', fn ($q, $v) => $q->where(fn ($w) => $w->where('name_en', 'like', "%{$v}%")->orWhere('name_ar', 'like', "%{$v}%"))),
            ])
            ->allowedSorts(['name_en', 'created_at'])
            ->defaultSort('name_en')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(PlayerAdminResource::collection($players));
    }

    public function store(PlayerRequest $request): JsonResponse
    {
        $player = Player::create(array_merge($request->validated(), ['source' => Source::Manual]));

        return $this->created(new PlayerAdminResource($player), __('Player created.'));
    }

    public function show(Player $player): JsonResponse
    {
        return $this->ok(new PlayerAdminResource($player));
    }

    public function update(PlayerRequest $request, Player $player): JsonResponse
    {
        $player->update($request->validated());

        return $this->ok(new PlayerAdminResource($player), __('Player updated.'));
    }

    public function destroy(Player $player): JsonResponse
    {
        $player->delete();

        return $this->noContentMessage(__('Player deleted.'));
    }
}
