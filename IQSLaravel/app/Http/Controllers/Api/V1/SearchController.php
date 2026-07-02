<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Club;
use App\Models\FanGroup;
use App\Models\Listing;
use App\Models\Player;
use App\Models\Team;
use App\Support\Enums\ListingStatus;
use App\Support\Localize;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;

/**
 * Global search across teams, players, clubs, fan groups and listings, in a
 * single typed result shape (§8.2).
 */
class SearchController extends Controller
{
    public function search(Request $request): JsonResponse
    {
        $q = trim((string) $request->query('q', ''));

        if (mb_strlen($q) < 2) {
            return $this->ok(['query' => $q, 'results' => []]);
        }

        $type = $request->query('type');
        $like = '%'.$q.'%';
        $limit = 8;
        $results = new Collection;
        $want = fn (string $t): bool => $type === null || $type === $t;

        if ($want('team')) {
            Team::query()->where($this->bilingual($like, 'name_ar', 'name_en'))->limit($limit)->get()
                ->each(fn (Team $x) => $results->push($this->item('team', $x->id, Localize::pick($x->name_ar, $x->name_en), $x->country_name, $x->logo_path)));
        }
        if ($want('player')) {
            Player::query()->where($this->bilingual($like, 'name_ar', 'name_en'))->limit($limit)->get()
                ->each(fn (Player $x) => $results->push($this->item('player', $x->id, Localize::pick($x->name_ar, $x->name_en), $x->position, $x->photo_path)));
        }
        if ($want('club')) {
            Club::query()->where('is_active', true)->where($this->bilingual($like, 'name_ar', 'name_en'))->limit($limit)->get()
                ->each(fn (Club $x) => $results->push($this->item('club', $x->id, Localize::pick($x->name_ar, $x->name_en), $x->governorate, $x->logo_path)));
        }
        if ($want('fan_group')) {
            FanGroup::query()->where('is_active', true)->where($this->bilingual($like, 'name_ar', 'name_en'))->limit($limit)->get()
                ->each(fn (FanGroup $x) => $results->push($this->item('fan_group', $x->id, Localize::pick($x->name_ar, $x->name_en), $x->governorate, $x->group_logo_path)));
        }
        if ($want('listing')) {
            Listing::query()->where('status', ListingStatus::Published->value)
                ->where(fn ($w) => $w->where('title_ar', 'like', $like)->orWhere('title_en', 'like', $like)->orWhere('full_name', 'like', $like))
                ->limit($limit)->get()
                ->each(fn (Listing $x) => $results->push($this->item('listing', $x->id, Localize::pick($x->title_ar, $x->title_en), $x->governorate, $x->photo_path)));
        }

        return $this->ok(['query' => $q, 'results' => $results->values()]);
    }

    /**
     * @return \Closure
     */
    protected function bilingual(string $like, string $ar, string $en): \Closure
    {
        return fn ($w) => $w->where($ar, 'like', $like)->orWhere($en, 'like', $like);
    }

    /**
     * @return array<string, mixed>
     */
    protected function item(string $type, int $id, ?string $title, ?string $subtitle, ?string $image): array
    {
        return ['type' => $type, 'id' => $id, 'title' => $title, 'subtitle' => $subtitle, 'image' => $image];
    }
}
