<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { storeToRefs } from 'pinia';
import navigation from '@admin/config/navigation';
import { useCan } from '@admin/composables/useCan';
import { useUiStore } from '@admin/stores/ui';
import AppLogo from './AppLogo.vue';

const props = defineProps({
    /** Desktop icon-rail mode. */
    collapsed: { type: Boolean, default: false },
    /** Rendered inside the mobile drawer (always expanded). */
    mobile: { type: Boolean, default: false },
});

const emit = defineEmits(['navigate']);

const { t } = useI18n();
const { can } = useCan();
const ui = useUiStore();
const { isRtl } = storeToRefs(ui);

/** Demo badge counts; replace with live store data later. */
const SAMPLE_BADGES = { pendingListings: 12 };

const isCollapsed = computed(() => props.collapsed && !props.mobile);

const sections = computed(() =>
    navigation
        .map((section) => ({
            ...section,
            items: section.items.filter((item) => can(item.permission)),
        }))
        .filter((section) => section.items.length > 0)
);

const tooltip = (label) => ({
    value: label,
    disabled: !isCollapsed.value,
    position: isRtl.value ? 'left' : 'right',
});

function onNavigate() {
    emit('navigate');
}
</script>

<template>
    <div class="flex h-full flex-col bg-surface-0 dark:bg-surface-900">
        <!-- Brand -->
        <div
            class="flex h-16 items-center border-b border-surface-200 dark:border-surface-800 px-4 shrink-0"
            :class="isCollapsed ? 'justify-center' : ''"
        >
            <AppLogo :mark-only="isCollapsed" />
        </div>

        <!-- Navigation -->
        <nav class="flex-1 overflow-y-auto px-3 py-4 space-y-6">
            <div v-for="section in sections" :key="section.key">
                <p
                    v-if="section.labelKey && !isCollapsed"
                    class="px-3 pb-2 text-[11px] font-semibold uppercase tracking-wider text-surface-400 dark:text-surface-500"
                >
                    {{ t(section.labelKey) }}
                </p>
                <div v-else-if="section.labelKey && isCollapsed" class="mx-3 mb-2 border-t border-surface-200 dark:border-surface-800"></div>

                <ul class="space-y-1">
                    <li v-for="item in section.items" :key="item.name">
                        <RouterLink :to="{ name: item.name }" custom v-slot="{ href, navigate, isExactActive }">
                            <a
                                :href="href"
                                v-tooltip="tooltip(t(item.labelKey))"
                                class="group relative flex items-center rounded-lg px-3 py-2.5 text-sm font-medium transition-colors outline-none focus-visible:ring-2 focus-visible:ring-emerald-500/50"
                                :class="[
                                    isCollapsed ? 'justify-center' : 'gap-3',
                                    isExactActive
                                        ? 'bg-emerald-50 dark:bg-emerald-500/15 text-emerald-700 dark:text-emerald-300 font-semibold'
                                        : 'text-surface-600 dark:text-surface-300 hover:bg-surface-100 dark:hover:bg-surface-800 hover:text-surface-900 dark:hover:text-surface-0',
                                ]"
                                @click="
                                    (e) => {
                                        navigate(e);
                                        onNavigate();
                                    }
                                "
                            >
                                <span
                                    v-if="isExactActive"
                                    class="absolute inset-y-1.5 start-0 w-1 rounded-e-full bg-emerald-500"
                                ></span>
                                <i :class="[item.icon, 'text-[1.15rem] shrink-0']"></i>
                                <template v-if="!isCollapsed">
                                    <span class="truncate">{{ t(item.labelKey) }}</span>
                                    <Badge
                                        v-if="item.badgeKey && SAMPLE_BADGES[item.badgeKey]"
                                        :value="SAMPLE_BADGES[item.badgeKey]"
                                        severity="danger"
                                        class="ms-auto"
                                    />
                                </template>
                                <Badge
                                    v-else-if="item.badgeKey && SAMPLE_BADGES[item.badgeKey]"
                                    :value="SAMPLE_BADGES[item.badgeKey]"
                                    severity="danger"
                                    class="absolute -top-0.5 end-1 scale-75"
                                />
                            </a>
                        </RouterLink>
                    </li>
                </ul>
            </div>
        </nav>

        <!-- Footer card -->
        <div v-if="!isCollapsed" class="border-t border-surface-200 dark:border-surface-800 p-3 shrink-0">
            <div class="rounded-xl bg-surface-50 dark:bg-surface-800/60 p-3 text-center">
                <p class="text-xs font-semibold text-surface-700 dark:text-surface-200">IQS Control Panel</p>
                <p class="mt-0.5 text-[11px] text-surface-400 dark:text-surface-500">v0.1.0 · 2026</p>
            </div>
        </div>
    </div>
</template>
