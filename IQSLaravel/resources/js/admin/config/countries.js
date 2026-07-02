/**
 * Country catalog for national-team support. Codes are ISO 3166-1 alpha-2
 * (lowercase, flagcdn.com convention) plus the four UK football nations that
 * flagcdn also serves. Display names are localized at runtime via
 * Intl.DisplayNames (ar/en), so no translation table is maintained here.
 * Flags: https://flagcdn.com/{size}/{code}.png — public domain, no API key.
 */
export const COUNTRY_CODES = [
    'ad', 'ae', 'af', 'ag', 'al', 'am', 'ao', 'ar', 'at', 'au', 'az',
    'ba', 'bb', 'bd', 'be', 'bf', 'bg', 'bh', 'bi', 'bj', 'bn', 'bo', 'br', 'bs', 'bt', 'bw', 'by', 'bz',
    'ca', 'cd', 'cf', 'cg', 'ch', 'ci', 'cl', 'cm', 'cn', 'co', 'cr', 'cu', 'cv', 'cy', 'cz',
    'de', 'dj', 'dk', 'dm', 'do', 'dz', 'ec', 'ee', 'eg', 'er', 'es', 'et', 'fi', 'fj', 'fm', 'fr',
    'ga', 'gb', 'gd', 'ge', 'gh', 'gm', 'gn', 'gq', 'gr', 'gt', 'gw', 'gy',
    'hn', 'hr', 'ht', 'hu', 'id', 'ie', 'il', 'in', 'iq', 'ir', 'is', 'it',
    'jm', 'jo', 'jp', 'ke', 'kg', 'kh', 'ki', 'km', 'kn', 'kp', 'kr', 'kw', 'kz',
    'la', 'lb', 'lc', 'li', 'lk', 'lr', 'ls', 'lt', 'lu', 'lv', 'ly',
    'ma', 'mc', 'md', 'me', 'mg', 'mh', 'mk', 'ml', 'mm', 'mn', 'mr', 'mt', 'mu', 'mv', 'mw', 'mx', 'my', 'mz',
    'na', 'ne', 'ng', 'ni', 'nl', 'no', 'np', 'nr', 'nz', 'om',
    'pa', 'pe', 'pg', 'ph', 'pk', 'pl', 'ps', 'pt', 'pw', 'py', 'qa',
    'ro', 'rs', 'ru', 'rw', 'sa', 'sb', 'sc', 'sd', 'se', 'sg', 'si', 'sk', 'sl', 'sm', 'sn', 'so', 'sr', 'ss', 'st', 'sv', 'sy', 'sz',
    'td', 'tg', 'th', 'tj', 'tl', 'tm', 'tn', 'to', 'tr', 'tt', 'tv', 'tw', 'tz',
    'ua', 'ug', 'us', 'uy', 'uz', 'vc', 've', 'vn', 'vu', 'ws', 'ye', 'za', 'zm', 'zw',
];

/** Football nations without a plain ISO alpha-2 code (flagcdn serves them). */
const FOOTBALL_EXTRAS = [
    { code: 'gb-eng', en: 'England', ar: 'إنجلترا' },
    { code: 'gb-sct', en: 'Scotland', ar: 'اسكتلندا' },
    { code: 'gb-wls', en: 'Wales', ar: 'ويلز' },
    { code: 'gb-nir', en: 'Northern Ireland', ar: 'أيرلندا الشمالية' },
    { code: 'xk', en: 'Kosovo', ar: 'كوسوفو' },
];

/** flagcdn PNG URL for a country code (sizes: w80/w160/w320/w640…). */
export function flagUrl(code, size = 'w320') {
    return `https://flagcdn.com/${size}/${String(code).toLowerCase()}.png`;
}

function displayNames(locale) {
    try {
        return new Intl.DisplayNames([locale], { type: 'region' });
    } catch {
        return null;
    }
}

/**
 * Options for a country Select: [{ code, en, label, flag }] where `en` is the
 * canonical English name stored in the DB (`teams.country_name`) and `label`
 * is localized to the given UI locale. Sorted by label.
 */
export function countryOptions(locale = 'ar') {
    const local = displayNames(locale);
    const english = displayNames('en');

    const options = COUNTRY_CODES.map((code) => {
        const region = code.toUpperCase();
        const en = english?.of(region) || region;
        const label = local?.of(region) || en;
        return { code, en, label, flag: flagUrl(code, 'w80') };
    });

    for (const x of FOOTBALL_EXTRAS) {
        options.push({ code: x.code, en: x.en, label: locale === 'ar' ? x.ar : x.en, flag: flagUrl(x.code, 'w80') });
    }

    return options.sort((a, b) => a.label.localeCompare(b.label, locale));
}

/** Best-effort reverse lookup: stored English country_name → option. */
export function findByEnglishName(options, name) {
    if (!name) return null;
    const n = String(name).trim().toLowerCase();
    return options.find((o) => o.en.toLowerCase() === n) || null;
}
