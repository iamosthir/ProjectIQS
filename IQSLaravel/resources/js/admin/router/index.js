import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '@admin/stores/auth';
import { useCan } from '@admin/composables/useCan';
import { i18n } from '@admin/i18n';

const AppLayout = () => import('@admin/layouts/AppLayout.vue');
const AuthLayout = () => import('@admin/layouts/AuthLayout.vue');

const routes = [
    {
        path: '/login',
        component: AuthLayout,
        children: [
            {
                path: '',
                name: 'login',
                component: () => import('@admin/views/auth/LoginView.vue'),
                meta: { public: true },
            },
        ],
    },
    {
        path: '/',
        component: AppLayout,
        children: [
            {
                path: '',
                name: 'dashboard',
                component: () => import('@admin/views/DashboardView.vue'),
                meta: { titleKey: 'nav.dashboard', icon: 'pi pi-objects-column' },
            },

            // Match Center
            {
                path: 'matches/fixtures',
                name: 'fixtures',
                component: () => import('@admin/views/matches/FixturesView.vue'),
                meta: { titleKey: 'nav.fixtures', icon: 'pi pi-calendar', permission: 'manage matches' },
            },
            {
                path: 'matches/leagues',
                name: 'leagues',
                component: () => import('@admin/views/matches/LeaguesView.vue'),
                meta: { titleKey: 'nav.leagues', icon: 'pi pi-trophy', permission: 'manage matches' },
            },
            {
                path: 'matches/teams',
                name: 'teams',
                component: () => import('@admin/views/matches/TeamsView.vue'),
                meta: { titleKey: 'nav.teams', icon: 'pi pi-shield', permission: 'manage matches' },
            },
            {
                path: 'matches/players',
                name: 'players',
                component: () => import('@admin/views/matches/PlayersView.vue'),
                meta: { titleKey: 'nav.players', icon: 'pi pi-users', permission: 'manage matches' },
            },
            {
                path: 'matches/fixtures/:id/console',
                name: 'match-console',
                component: () => import('@admin/views/matches/MatchConsoleView.vue'),
                meta: { titleKey: 'matches.matchConsole', icon: 'pi pi-sliders-h', permission: 'manage matches' },
            },
            {
                path: 'matches/comments',
                name: 'comments-moderation',
                component: () => import('@admin/views/matches/CommentsModerationView.vue'),
                meta: { titleKey: 'matches.commentsModeration', icon: 'pi pi-comments', permission: 'moderate comments' },
            },
            {
                path: 'matches/sync',
                name: 'sync-console',
                component: () => import('@admin/views/matches/SyncConsoleView.vue'),
                meta: { titleKey: 'nav.syncConsole', icon: 'pi pi-sync', permission: 'sync matches' },
            },

            // Marketplace
            {
                path: 'marketplace/listings',
                name: 'listings-review',
                component: () => import('@admin/views/marketplace/ListingsReviewView.vue'),
                meta: { titleKey: 'nav.listingsReview', icon: 'pi pi-inbox', permission: 'approve listings' },
            },
            {
                path: 'marketplace/categories',
                name: 'categories',
                component: () => import('@admin/views/marketplace/CategoriesView.vue'),
                meta: { titleKey: 'nav.categories', icon: 'pi pi-tags', permission: 'manage marketplace' },
            },
            {
                path: 'marketplace/stores',
                name: 'stores',
                component: () => import('@admin/views/marketplace/StoresView.vue'),
                meta: { titleKey: 'nav.stores', icon: 'pi pi-building', permission: 'manage marketplace' },
            },

            // Community
            {
                path: 'clubs',
                name: 'clubs',
                component: () => import('@admin/views/clubs/ClubsView.vue'),
                meta: { titleKey: 'nav.clubs', icon: 'pi pi-flag', permission: 'manage clubs' },
            },
            {
                path: 'clubs/:id/content',
                name: 'club-content',
                component: () => import('@admin/views/clubs/ClubContentView.vue'),
                meta: { titleKey: 'clubs.content', icon: 'pi pi-sitemap', permission: 'manage clubs' },
            },
            {
                path: 'clubs-verifications',
                name: 'club-verifications',
                component: () => import('@admin/views/clubs/VerificationsView.vue'),
                meta: { titleKey: 'clubs.verifications', icon: 'pi pi-verified', permission: 'manage clubs' },
            },
            {
                path: 'fan-groups',
                name: 'fan-groups',
                component: () => import('@admin/views/fanGroups/FanGroupsView.vue'),
                meta: { titleKey: 'nav.fanGroups', icon: 'pi pi-megaphone', permission: 'manage fan-groups' },
            },
            {
                path: 'fan-groups/:id/content',
                name: 'fan-group-content',
                component: () => import('@admin/views/fanGroups/FanGroupContentView.vue'),
                meta: { titleKey: 'fanGroups.archives', icon: 'pi pi-images', permission: 'manage fan-groups' },
            },
            {
                path: 'fan-groups-verifications',
                name: 'fan-group-verifications',
                component: () => import('@admin/views/fanGroups/FanGroupVerificationsView.vue'),
                meta: { titleKey: 'fanGroups.verifications', icon: 'pi pi-verified', permission: 'manage fan-groups' },
            },

            // People
            {
                path: 'users',
                name: 'users',
                component: () => import('@admin/views/users/UsersView.vue'),
                meta: { titleKey: 'nav.users', icon: 'pi pi-user', permission: 'manage users' },
            },
            {
                path: 'admins',
                name: 'admins',
                component: () => import('@admin/views/admins/AdminsRolesView.vue'),
                meta: { titleKey: 'nav.adminsRoles', icon: 'pi pi-id-card', permission: 'manage admins' },
            },

            // Operations
            {
                path: 'payments',
                name: 'payments',
                component: () => import('@admin/views/operations/PaymentsView.vue'),
                meta: { titleKey: 'nav.payments', icon: 'pi pi-wallet', permission: 'manage payments' },
            },
            {
                path: 'notifications',
                name: 'notifications',
                component: () => import('@admin/views/operations/NotificationsView.vue'),
                meta: { titleKey: 'nav.notifications', icon: 'pi pi-bell', permission: 'send notifications' },
            },

            // Content
            {
                path: 'content/banners',
                name: 'banners',
                component: () => import('@admin/views/content/BannersView.vue'),
                meta: { titleKey: 'nav.banners', icon: 'pi pi-image', permission: 'manage banners' },
            },
            {
                path: 'content/pages',
                name: 'pages',
                component: () => import('@admin/views/content/PagesView.vue'),
                meta: { titleKey: 'nav.pages', icon: 'pi pi-file-edit', permission: 'manage settings' },
            },
            {
                path: 'content/app-versions',
                name: 'app-versions',
                component: () => import('@admin/views/content/AppVersionsView.vue'),
                meta: { titleKey: 'nav.appVersions', icon: 'pi pi-mobile', permission: 'manage settings' },
            },
            {
                path: 'content/settings',
                name: 'settings',
                component: () => import('@admin/views/content/SettingsView.vue'),
                meta: { titleKey: 'nav.settings', icon: 'pi pi-cog', permission: 'manage settings' },
            },
        ],
    },
    {
        path: '/:pathMatch(.*)*',
        name: 'not-found',
        component: () => import('@admin/views/NotFoundView.vue'),
        meta: { public: true },
    },
];

const router = createRouter({
    history: createWebHistory('/admin'),
    routes,
    scrollBehavior: () => ({ top: 0 }),
});

router.beforeEach(async (to) => {
    const auth = useAuthStore();
    if (!auth.initialized) {
        await auth.fetchMe();
    }

    if (to.meta.public) {
        if (to.name === 'login' && auth.isAuthenticated) {
            return { name: 'dashboard' };
        }
        return true;
    }

    if (!auth.isAuthenticated) {
        return { name: 'login', query: { redirect: to.fullPath } };
    }

    if (to.meta.permission) {
        const { can } = useCan();
        if (!can(to.meta.permission)) {
            return { name: 'dashboard' };
        }
    }

    return true;
});

router.afterEach((to) => {
    const base = i18n.global.t('common.appName');
    const title = to.meta.titleKey ? i18n.global.t(to.meta.titleKey) : '';
    document.title = title ? `${title} — ${base}` : base;
});

export default router;
