import { defineStore } from 'pinia';
import { authApi } from '@admin/api/auth';

/**
 * DEMO_MODE keeps the panel usable before the admin backend exists: any
 * credentials sign in as a super-admin. Flip to `false` once
 * `/admin/api/v1/{login,logout,me}` are implemented in web.php.
 */
const DEMO_MODE = false;
const DEMO_KEY = 'iqs.demoAuth';

const DEMO_ADMIN = {
    id: 1,
    name: 'مدير النظام',
    name_en: 'System Admin',
    email: 'admin@iqs.app',
    avatar: null,
    roles: ['super-admin'],
};

export const useAuthStore = defineStore('auth', {
    state: () => ({
        admin: null,
        permissions: [],
        roles: [],
        initialized: false,
        loading: false,
    }),

    getters: {
        isAuthenticated: (state) => state.admin !== null,
        isSuperAdmin: (state) => state.roles.includes('super-admin'),
        displayName: (state) => state.admin?.name || state.admin?.email || '',
        initials: (state) => {
            const name = state.admin?.name_en || state.admin?.name || '';
            return name
                .split(' ')
                .filter(Boolean)
                .slice(0, 2)
                .map((p) => p[0])
                .join('')
                .toUpperCase();
        },
    },

    actions: {
        async login(credentials) {
            this.loading = true;
            try {
                if (DEMO_MODE) {
                    await new Promise((r) => setTimeout(r, 450));
                    this._setSession(DEMO_ADMIN, ['super-admin'], []);
                    try {
                        localStorage.setItem(DEMO_KEY, '1');
                    } catch (e) {
                        /* ignore */
                    }
                    return true;
                }
                await authApi.login(credentials);
                await this.fetchMe();
                return true;
            } finally {
                this.loading = false;
            }
        },

        async fetchMe() {
            if (DEMO_MODE) {
                const flagged = (() => {
                    try {
                        return localStorage.getItem(DEMO_KEY) === '1';
                    } catch (e) {
                        return false;
                    }
                })();
                if (flagged) {
                    this._setSession(DEMO_ADMIN, ['super-admin'], []);
                }
                this.initialized = true;
                return this.isAuthenticated;
            }

            try {
                const { data } = await authApi.me();
                const payload = data?.data ?? data;
                this._setSession(payload.admin ?? payload, payload.roles ?? [], payload.permissions ?? []);
            } catch (e) {
                this._clearSession();
            } finally {
                this.initialized = true;
            }
            return this.isAuthenticated;
        },

        async logout() {
            try {
                if (!DEMO_MODE) {
                    await authApi.logout();
                }
            } catch (e) {
                /* ignore network errors on logout */
            } finally {
                try {
                    localStorage.removeItem(DEMO_KEY);
                } catch (e) {
                    /* ignore */
                }
                this._clearSession();
            }
        },

        _setSession(admin, roles, permissions) {
            this.admin = admin;
            this.roles = roles ?? [];
            this.permissions = permissions ?? [];
        },

        _clearSession() {
            this.admin = null;
            this.roles = [];
            this.permissions = [];
        },
    },
});

export default useAuthStore;
