<?php

namespace App\Services\Clubs;

use App\Models\Club;
use App\Models\ClubBoardMember;
use App\Models\ClubCaptain;
use App\Models\ClubCompetition;
use App\Models\ClubStaff;
use App\Models\ClubTitle;
use App\Support\Enums\ClubCompetitionStatus;
use App\Support\Enums\ClubStaffType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Validation\Rule;

/**
 * Shared CRUD for a club's nested content (board / staff / titles / captains /
 * competitions). Used by both the club-admin (my-club) and admin controllers.
 */
class ClubContentService
{
    /**
     * type → [model, relation] map.
     *
     * @var array<string, array{model: class-string<Model>, relation: string}>
     */
    public const TYPES = [
        'board' => ['model' => ClubBoardMember::class, 'relation' => 'boardMembers'],
        'staff' => ['model' => ClubStaff::class, 'relation' => 'staff'],
        'titles' => ['model' => ClubTitle::class, 'relation' => 'titles'],
        'captains' => ['model' => ClubCaptain::class, 'relation' => 'captains'],
        'competitions' => ['model' => ClubCompetition::class, 'relation' => 'competitions'],
    ];

    public static function isValidType(string $type): bool
    {
        return isset(self::TYPES[$type]);
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function create(Club $club, string $type, array $data): Model
    {
        $relation = self::TYPES[$type]['relation'];

        return $club->{$relation}()->create($data);
    }

    public function find(Club $club, string $type, int $id): Model
    {
        $model = self::TYPES[$type]['model'];

        return $model::where('club_id', $club->id)->findOrFail($id);
    }

    /**
     * Validation rules per child type.
     *
     * @return array<string, mixed>
     */
    public static function rules(string $type, bool $create): array
    {
        $r = $create ? 'required' : 'sometimes';

        return match ($type) {
            'board' => [
                'name_ar' => [$r, 'string', 'max:255'], 'name_en' => [$r, 'string', 'max:255'],
                'position_ar' => [$r, 'string', 'max:255'], 'position_en' => [$r, 'string', 'max:255'],
                'parent_id' => ['nullable', 'integer'], 'photo_path' => ['nullable', 'string', 'max:2048'],
                'display_order' => ['sometimes', 'integer'], 'is_active' => ['sometimes', 'boolean'],
            ],
            'staff' => [
                'name_ar' => [$r, 'string', 'max:255'], 'name_en' => [$r, 'string', 'max:255'],
                'role_ar' => [$r, 'string', 'max:255'], 'role_en' => [$r, 'string', 'max:255'],
                'type' => [$r, Rule::enum(ClubStaffType::class)], 'photo_path' => ['nullable', 'string', 'max:2048'],
                'bio' => ['nullable', 'string'], 'display_order' => ['sometimes', 'integer'],
            ],
            'titles' => [
                'title_ar' => [$r, 'string', 'max:255'], 'title_en' => [$r, 'string', 'max:255'],
                'competition_ar' => ['nullable', 'string', 'max:255'], 'competition_en' => ['nullable', 'string', 'max:255'],
                'season' => ['nullable', 'string', 'max:50'], 'year' => ['nullable', 'integer'],
                'count' => ['nullable', 'integer', 'min:0'], 'image_path' => ['nullable', 'string', 'max:2048'],
                'display_order' => ['sometimes', 'integer'],
            ],
            'captains' => [
                'name_ar' => [$r, 'string', 'max:255'], 'name_en' => [$r, 'string', 'max:255'],
                'photo_path' => ['nullable', 'string', 'max:2048'], 'period_from' => ['nullable', 'integer'],
                'period_to' => ['nullable', 'integer'], 'description' => ['nullable', 'string'],
                'display_order' => ['sometimes', 'integer'],
            ],
            'competitions' => [
                'league_id' => ['nullable', 'integer', 'exists:leagues,id'],
                'name_ar' => ['nullable', 'string', 'max:255'], 'name_en' => ['nullable', 'string', 'max:255'],
                'season' => ['nullable', 'string', 'max:50'], 'status' => ['sometimes', Rule::enum(ClubCompetitionStatus::class)],
                'display_order' => ['sometimes', 'integer'],
            ],
            default => [],
        };
    }
}
