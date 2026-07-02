<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Resolves the active locale from the `Accept-Language` header (Arabic-first).
 * Only the configured supported locales are honoured; anything else falls back
 * to the app default. See §0.6 of the backend plan.
 */
class SetLocale
{
    /**
     * @var list<string>
     */
    protected array $supported = ['ar', 'en'];

    public function handle(Request $request, Closure $next): Response
    {
        $locale = $request->getPreferredLanguage($this->supported)
            ?? config('app.locale');

        // getPreferredLanguage may hand back a region variant (e.g. "en_US").
        $locale = substr((string) $locale, 0, 2);

        if (in_array($locale, $this->supported, true)) {
            app()->setLocale($locale);
        }

        return $next($request);
    }
}
