<script setup>
import { watch } from 'vue';
import { storeToRefs } from 'pinia';
import { useMediaQuery } from '@vueuse/core';
import { useUiStore } from '@admin/stores/ui';
import AppSidebar from '@admin/components/AppSidebar.vue';
import AppTopbar from '@admin/components/AppTopbar.vue';
import AppFooter from '@admin/components/AppFooter.vue';

const ui = useUiStore();
const { sidebarCollapsed, mobileNavOpen, isRtl } = storeToRefs(ui);

// Close the mobile drawer if the viewport grows to desktop while it's open.
const isDesktop = useMediaQuery('(min-width: 1024px)');
watch(isDesktop, (desktop) => {
    if (desktop) {
        ui.closeMobileNav();
    }
});
</script>

<template>
    <div class="flex h-full overflow-hidden bg-surface-50 dark:bg-surface-950">
        <!-- Desktop sidebar -->
        <aside
            class="hidden shrink-0 border-e border-surface-200 dark:border-surface-800 transition-[width] duration-200 ease-in-out lg:block"
            :class="sidebarCollapsed ? 'w-20' : 'w-72'"
        >
            <AppSidebar :collapsed="sidebarCollapsed" />
        </aside>

        <!-- Main column -->
        <div class="flex min-w-0 flex-1 flex-col">
            <AppTopbar />
            <main class="flex-1 overflow-y-auto">
                <div class="mx-auto flex min-h-full max-w-[1600px] flex-col">
                    <div class="flex-1 p-4 lg:p-6">
                        <RouterView v-slot="{ Component }">
                            <transition name="fade" mode="out-in">
                                <component :is="Component" />
                            </transition>
                        </RouterView>
                    </div>
                    <AppFooter />
                </div>
            </main>
        </div>

        <!-- Mobile drawer -->
        <Drawer
            v-model:visible="mobileNavOpen"
            :position="isRtl ? 'right' : 'left'"
            :modal="true"
            :style="{ width: '18rem' }"
        >
            <template #container>
                <AppSidebar :mobile="true" @navigate="ui.closeMobileNav()" />
            </template>
        </Drawer>
    </div>
</template>
