/**
 * Sidebar navigation definition.
 *
 * Pure data shared by the sidebar. Each `item.name` matches a Vue Router
 * route name (see router/index.js). `permission` (when set) gates visibility
 * via useCan(); the server still enforces authorization.
 */
export const navigation = [
    {
        key: 'main',
        items: [
            { name: 'dashboard', labelKey: 'nav.dashboard', icon: 'pi pi-objects-column' },
        ],
    },
    {
        key: 'matchCenter',
        labelKey: 'nav.matchCenter',
        items: [
            { name: 'fixtures', labelKey: 'nav.fixtures', icon: 'pi pi-calendar', permission: 'manage matches' },
            { name: 'leagues', labelKey: 'nav.leagues', icon: 'pi pi-trophy', permission: 'manage matches' },
            { name: 'teams', labelKey: 'nav.teams', icon: 'pi pi-shield', permission: 'manage matches' },
            { name: 'players', labelKey: 'nav.players', icon: 'pi pi-users', permission: 'manage matches' },
            { name: 'comments-moderation', labelKey: 'nav.commentsModeration', icon: 'pi pi-comments', permission: 'moderate comments' },
            { name: 'sync-console', labelKey: 'nav.syncConsole', icon: 'pi pi-sync', permission: 'sync matches' },
        ],
    },
    {
        key: 'marketplace',
        labelKey: 'nav.marketplace',
        items: [
            { name: 'listings-review', labelKey: 'nav.listingsReview', icon: 'pi pi-inbox', permission: 'approve listings', badgeKey: 'pendingListings' },
            { name: 'categories', labelKey: 'nav.categories', icon: 'pi pi-tags', permission: 'manage marketplace' },
            { name: 'stores', labelKey: 'nav.stores', icon: 'pi pi-building', permission: 'manage marketplace' },
        ],
    },
    {
        key: 'community',
        labelKey: 'nav.community',
        items: [
            { name: 'clubs', labelKey: 'nav.clubs', icon: 'pi pi-flag', permission: 'manage clubs' },
            { name: 'club-verifications', labelKey: 'clubs.verifications', icon: 'pi pi-verified', permission: 'manage clubs' },
            { name: 'fan-groups', labelKey: 'nav.fanGroups', icon: 'pi pi-megaphone', permission: 'manage fan-groups' },
            { name: 'fan-group-verifications', labelKey: 'fanGroups.verifications', icon: 'pi pi-verified', permission: 'manage fan-groups' },
        ],
    },
    {
        key: 'people',
        labelKey: 'nav.people',
        items: [
            { name: 'users', labelKey: 'nav.users', icon: 'pi pi-user', permission: 'manage users' },
            { name: 'admins', labelKey: 'nav.adminsRoles', icon: 'pi pi-id-card', permission: 'manage admins' },
        ],
    },
    {
        key: 'operations',
        labelKey: 'nav.operations',
        items: [
            { name: 'payments', labelKey: 'nav.payments', icon: 'pi pi-wallet', permission: 'manage payments' },
            { name: 'notifications', labelKey: 'nav.notifications', icon: 'pi pi-bell', permission: 'send notifications' },
        ],
    },
    {
        key: 'content',
        labelKey: 'nav.content',
        items: [
            { name: 'banners', labelKey: 'nav.banners', icon: 'pi pi-image', permission: 'manage banners' },
            { name: 'pages', labelKey: 'nav.pages', icon: 'pi pi-file-edit', permission: 'manage settings' },
            { name: 'app-versions', labelKey: 'nav.appVersions', icon: 'pi pi-mobile', permission: 'manage settings' },
            { name: 'settings', labelKey: 'nav.settings', icon: 'pi pi-cog', permission: 'manage settings' },
        ],
    },
];

export default navigation;
