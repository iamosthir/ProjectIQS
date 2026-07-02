<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\AppVersion;
use App\Models\Setting;
use App\Support\Governorates;
use App\Support\Localize;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AppConfigController extends Controller
{
    /**
     * Version gate + public settings/feature flags (§8.2). Public (no auth).
     */
    public function config(Request $request): JsonResponse
    {
        $platform = $request->string('platform', 'android')->value();
        $current = $request->query('version');

        $latest = AppVersion::query()
            ->where('platform', $platform)
            ->where('is_active', true)
            ->orderByDesc('build_number')
            ->first();

        $version = null;

        if ($latest !== null) {
            $updateAvailable = $current !== null && version_compare((string) $current, $latest->version, '<');
            $forceUpdate = $current !== null && version_compare((string) $current, $latest->min_supported_version, '<');

            if ($latest->is_force_update && $updateAvailable) {
                $forceUpdate = true;
            }

            $version = [
                'latest' => $latest->version,
                'min_supported' => $latest->min_supported_version,
                'update_available' => $updateAvailable,
                'force_update' => $forceUpdate,
                'store_url' => $latest->store_url,
                'changelog' => Localize::pick($latest->changelog_ar, $latest->changelog_en),
            ];
        }

        return $this->ok([
            'version' => $version,
            'settings' => Setting::publicValues(),
        ]);
    }

    /**
     * Static Iraqi governorate list for dropdowns (§8.2). Public.
     */
    public function governorates(): JsonResponse
    {
        return $this->ok(Governorates::localized(app()->getLocale()));
    }
}
