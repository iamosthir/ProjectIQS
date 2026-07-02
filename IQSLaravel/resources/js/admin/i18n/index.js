import { createI18n } from 'vue-i18n';
import en from './locales/en';
import ar from './locales/ar';

export const SUPPORTED_LOCALES = ['ar', 'en'];
export const DEFAULT_LOCALE = 'ar';

export function getStoredLocale() {
    try {
        const stored = localStorage.getItem('iqs.locale');
        if (stored && SUPPORTED_LOCALES.includes(stored)) {
            return stored;
        }
    } catch (e) {
        /* ignore */
    }
    return DEFAULT_LOCALE;
}

export const i18n = createI18n({
    legacy: false,
    globalInjection: true,
    locale: getStoredLocale(),
    fallbackLocale: 'en',
    messages: { en, ar },
});

export default i18n;
