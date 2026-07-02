<?php

namespace App\Http\Resources;

use App\Models\Club;
use App\Support\Localize;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Full club page — profile + org-chart board (parent_id) + staff/titles/
 * captains/competitions (§4.2/§4.4).
 *
 * @mixin Club
 */
class ClubDetailResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return array_merge((new ClubResource($this->resource))->toArray($request), [
            'description' => Localize::pick($this->description_ar, $this->description_en),
            'location' => [
                'address' => $this->address,
                'latitude' => $this->latitude,
                'longitude' => $this->longitude,
            ],
            'contact' => [
                'phone' => $this->phone,
                'email' => $this->email,
                'website' => $this->website,
                'facebook' => $this->facebook,
                'instagram' => $this->instagram,
                'twitter' => $this->twitter,
            ],
            'board' => $this->whenLoaded('boardMembers', fn () => $this->boardMembers->map(fn ($m) => [
                'id' => $m->id,
                'parent_id' => $m->parent_id,
                'name' => Localize::pick($m->name_ar, $m->name_en),
                'position' => Localize::pick($m->position_ar, $m->position_en),
                'photo' => $m->photo_path,
                'display_order' => $m->display_order,
            ])),
            'staff' => $this->whenLoaded('staff', fn () => $this->staff->map(fn ($s) => [
                'id' => $s->id,
                'name' => Localize::pick($s->name_ar, $s->name_en),
                'role' => Localize::pick($s->role_ar, $s->role_en),
                'type' => $s->type?->value,
                'photo' => $s->photo_path,
                'bio' => $s->bio,
            ])),
            'titles' => $this->whenLoaded('titles', fn () => $this->titles->map(fn ($t) => [
                'id' => $t->id,
                'title' => Localize::pick($t->title_ar, $t->title_en),
                'competition' => Localize::pick($t->competition_ar, $t->competition_en),
                'season' => $t->season,
                'year' => $t->year,
                'count' => $t->count,
                'image' => $t->image_path,
            ])),
            'captains' => $this->whenLoaded('captains', fn () => $this->captains->map(fn ($c) => [
                'id' => $c->id,
                'name' => Localize::pick($c->name_ar, $c->name_en),
                'photo' => $c->photo_path,
                'period_from' => $c->period_from,
                'period_to' => $c->period_to,
                'description' => $c->description,
            ])),
            'competitions' => $this->whenLoaded('competitions', fn () => $this->competitions->map(fn ($c) => [
                'id' => $c->id,
                'name' => Localize::pick($c->name_ar, $c->name_en),
                'season' => $c->season,
                'status' => $c->status?->value,
                'league_id' => $c->league_id,
            ])),
        ]);
    }
}
