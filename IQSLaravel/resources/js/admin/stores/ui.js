import { defineStore } from 'pinia';

const THEME_KEY = 'iqs.theme';
const LOCALE_KEY = 'iqs.locale';
const SIDEBAR_KEY = 'iqs.sidebarCollapsed';

function readStorage(key, fallback) {
    try {
        const v = localStorage.getItem(key);
        return v === null ? fallback : v;
    } catch (e) {
        return fallback;
    }
}

function writeStorage(key, value) {
    try {
        localStorage.setItem(key, value);
    } catch (e) {
        /* ignore */
    }
}

/**
 * Global UI state: theme (light/dark), locale + text direction, and the
 * sidebar/drawer state. The store owns the DOM side-effects (dark class,
 * dir, lang) so toggles stay in sync with the pre-paint script in the shell.
 */
export const useUiStore = defineStore('ui', {
    state: () => ({
        theme: readStorage(THEME_KEY, 'light') === 'dark' ? 'dark' : 'light',
        locale: readStorage(LOCALE_KEY, 'ar'),
        sidebarCollapsed: readStorage(SIDEBAR_KEY, '0') === '1',
        mobileNavOpen: false,
    }),

    getters: {
        isDark: (state) => state.theme === 'dark',
        isRtl: (state) => state.locale === 'ar',
        direction: (state) => (state.locale === 'ar' ? 'rtl' : 'ltr'),
    },

    actions: {
        /** Sync the DOM to the current state (called once on app start). */
        applyToDocument() {
            const el = document.documentElement;
            el.classList.toggle('dark', this.theme === 'dark');
            el.setAttribute('lang', this.locale);
            el.setAttribute('dir', this.direction);
        },

        setTheme(theme) {
            this.theme = theme === 'dark' ? 'dark' : 'light';
            writeStorage(THEME_KEY, this.theme);
            document.documentElement.classList.toggle('dark', this.theme === 'dark');
        },

        toggleTheme() {
            this.setTheme(this.theme === 'dark' ? 'light' : 'dark');
        },

        setLocale(locale) {
            this.locale = locale === 'en' ? 'en' : 'ar';
            writeStorage(LOCALE_KEY, this.locale);
            const el = document.documentElement;
            el.setAttribute('lang', this.locale);
            el.setAttribute('dir', this.direction);
        },

        toggleLocale() {
            this.setLocale(this.locale === 'ar' ? 'en' : 'ar');
        },

        toggleSidebar() {
            this.sidebarCollapsed = !this.sidebarCollapsed;
            writeStorage(SIDEBAR_KEY, this.sidebarCollapsed ? '1' : '0');
        },

        openMobileNav() {
            this.mobileNavOpen = true;
        },

        closeMobileNav() {
            this.mobileNavOpen = false;
        },
    },
});

export default useUiStore;
