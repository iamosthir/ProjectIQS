<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Matches\CountryRequest;
use App\Models\Country;
use App\Support\Enums\Source;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CountryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $countries = Country::query()
            ->when($request->filled('search'), function ($q) use ($request) {
                $search = $request->string('search')->toString();
                $q->where(fn ($w) => $w
                    ->where('name_ar', 'like', "%{$search}%")
                    ->orWhere('name_en', 'like', "%{$search}%")
                    ->orWhere('code', 'like', "%{$search}%"));
            })
            ->orderBy('display_order')
            ->orderBy('name_en')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok($countries);
    }

    public function store(CountryRequest $request): JsonResponse
    {
        $country = Country::create(array_merge($request->validated(), ['source' => Source::Manual]));

        return $this->created($country, __('Country created.'));
    }

    public function show(Country $country): JsonResponse
    {
        return $this->ok($country);
    }

    public function update(CountryRequest $request, Country $country): JsonResponse
    {
        $country->update($request->validated());

        return $this->ok($country, __('Country updated.'));
    }

    public function destroy(Country $country): JsonResponse
    {
        $country->delete();

        return $this->noContentMessage(__('Country deleted.'));
    }
}
