<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { storeToRefs } from 'pinia';
import { useUiStore } from '@admin/stores/ui';
import { useAuthStore } from '@admin/stores/auth';

const { t, locale } = useI18n();
const router = useRouter();
const ui = useUiStore();
const auth = useAuthStore();
const { isDark, isRtl } = storeToRefs(ui);

const notifMenu = ref();
const userMenu = ref();
const userMenuOpen = ref(false);

const notifications = computed(() =>
    isRtl.value
        ? [
              { icon: 'pi pi-wallet', title: 'دفعة جديدة', text: 'تم استلام دفعة بقيمة ٢٥٬٠٠٠ د.ع', time: 'قبل ٥ د' },
              { icon: 'pi pi-inbox', title: 'إعلان بانتظار المراجعة', text: 'إعلان جديد في فئة المدربين', time: 'قبل ٢٠ د' },
              { icon: 'pi pi-flag', title: 'طلب توثيق نادٍ', text: 'نادي الزوراء يطلب التوثيق', time: 'قبل ساعة' },
          ]
        : [
              { icon: 'pi pi-wallet', title: 'New payment', text: 'Received a payment of 25,000 IQD', time: '5m ago' },
              { icon: 'pi pi-inbox', title: 'Listing awaiting review', text: 'New listing in Coaches category', time: '20m ago' },
              { icon: 'pi pi-flag', title: 'Club verification request', text: 'Al-Zawraa requested verification', time: '1h ago' },
          ]
);

const userMenuItems = computed(() => [
    { label: t('topbar.viewProfile'), icon: 'pi pi-user' },
    { label: t('topbar.accountSettings'), icon: 'pi pi-cog', command: () => router.push({ name: 'settings' }) },
    { separator: true },
    { label: t('topbar.signOut'), icon: 'pi pi-sign-out', command: () => onLogout() },
]);

async function onLogout() {
    await auth.logout();
    router.push({ name: 'login' });
}
</script>

<template>
    <header
        class="sticky top-0 z-30 flex h-16 items-center gap-2 border-b border-surface-200 dark:border-surface-800 bg-surface-0/85 dark:bg-surface-900/85 px-3 backdrop-blur lg:px-5"
    >
        <!-- Mobile: open drawer.
             NOTE: the responsive toggles below live on a plain wrapper, not on
             the PrimeVue component itself. PrimeVue's component CSS is unlayered
             (cssLayer: false) and so beats Tailwind's layered `@layer utilities`,
             which means `hidden`/`lg:*` display utilities are *ignored* when put
             directly on a `<Button>`/`<IconField>` root. Wrapping in a bare
             element keeps the responsive visibility reliable. `shrink-0` stops
             the menu icon from being squeezed to 0px when the row is tight. -->
        <div class="shrink-0 lg:hidden">
            <Button
                type="button"
                icon="pi pi-bars"
                text
                rounded
                severity="secondary"
                :aria-label="t('topbar.openMenu')"
                @click="ui.openMobileNav()"
            />
        </div>
        <!-- Desktop: collapse rail -->
        <div class="hidden shrink-0 lg:block">
            <Button
                type="button"
                icon="pi pi-bars"
                text
                rounded
                severity="secondary"
                v-tooltip.bottom="t('topbar.collapseSidebar')"
                :aria-label="t('topbar.collapseSidebar')"
                @click="ui.toggleSidebar()"
            />
        </div>

        <!-- Search (tablet/desktop only) -->
        <div class="ms-1 hidden md:block">
            <IconField>
                <InputIcon class="pi pi-search" />
                <InputText :placeholder="t('topbar.search')" :aria-label="t('topbar.search')" class="w-64 lg:w-80" />
            </IconField>
        </div>

        <div class="ms-auto flex items-center gap-1">
            <!-- Language -->
            <Button
                type="button"
                text
                rounded
                severity="secondary"
                class="font-semibold"
                :label="isRtl ? 'EN' : 'ع'"
                icon="pi pi-globe"
                v-tooltip.bottom="t('topbar.toggleLanguage')"
                :aria-label="t('topbar.toggleLanguage')"
                @click="ui.toggleLocale()"
            />

            <!-- Theme -->
            <Button
                type="button"
                text
                rounded
                severity="secondary"
                :icon="isDark ? 'pi pi-sun' : 'pi pi-moon'"
                v-tooltip.bottom="isDark ? t('topbar.lightMode') : t('topbar.darkMode')"
                :aria-label="t('topbar.toggleTheme')"
                @click="ui.toggleTheme()"
            />

            <!-- Notifications -->
            <OverlayBadge value="3" severity="danger">
                <Button
                    type="button"
                    icon="pi pi-bell"
                    text
                    rounded
                    severity="secondary"
                    v-tooltip.bottom="t('topbar.notifications')"
                    :aria-label="t('topbar.notifications')"
                    @click="notifMenu.toggle($event)"
                />
            </OverlayBadge>
            <Menu ref="notifMenu" :model="notifications" popup>
                <template #start>
                    <div class="px-3 py-2 border-b border-surface-200 dark:border-surface-700">
                        <p class="text-sm font-semibold text-surface-800 dark:text-surface-100">
                            {{ t('topbar.notifications') }}
                        </p>
                    </div>
                </template>
                <template #item="{ item }">
                    <div class="flex w-72 items-start gap-3 px-3 py-2.5">
                        <span class="grid size-9 shrink-0 place-items-center rounded-lg bg-emerald-50 dark:bg-emerald-500/15 text-emerald-600 dark:text-emerald-400">
                            <i :class="item.icon"></i>
                        </span>
                        <div class="min-w-0 flex-1">
                            <p class="truncate text-sm font-medium text-surface-800 dark:text-surface-100">{{ item.title }}</p>
                            <p class="truncate text-xs text-surface-500 dark:text-surface-400">{{ item.text }}</p>
                        </div>
                        <span class="shrink-0 text-[11px] text-surface-500 dark:text-surface-400">{{ item.time }}</span>
                    </div>
                </template>
                <template #end>
                    <div class="border-t border-surface-200 dark:border-surface-700 p-2">
                        <Button :label="t('common.viewAll')" text size="small" class="w-full" @click="router.push({ name: 'notifications' })" />
                    </div>
                </template>
            </Menu>

            <!-- User -->
            <button
                type="button"
                class="ms-1 flex items-center gap-2 rounded-full p-1 transition-colors hover:bg-surface-100 dark:hover:bg-surface-800 outline-none focus-visible:ring-2 focus-visible:ring-emerald-500/50"
                :aria-label="auth.displayName || t('topbar.account')"
                aria-haspopup="menu"
                :aria-expanded="userMenuOpen"
                @click="userMenu.toggle($event)"
            >
                <Avatar :label="auth.initials || 'A'" shape="circle" class="bg-emerald-500! text-white! font-semibold" />
                <span class="hidden text-start sm:block">
                    <span class="block text-sm font-semibold leading-tight text-surface-800 dark:text-surface-100">{{ auth.displayName }}</span>
                    <span class="block text-[11px] leading-tight text-surface-500 dark:text-surface-400">{{ auth.roles[0] }}</span>
                </span>
                <span class="hidden sm:block">
                    <i class="pi pi-angle-down text-surface-400" aria-hidden="true"></i>
                </span>
            </button>
            <Menu ref="userMenu" :model="userMenuItems" popup @show="userMenuOpen = true" @hide="userMenuOpen = false" />
        </div>
    </header>
</template>
