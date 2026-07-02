<script setup>
import { storeToRefs } from 'pinia';
import { useI18n } from 'vue-i18n';
import { useUiStore } from '@admin/stores/ui';

defineProps({
    title: { type: String, required: true },
    subtitle: { type: String, default: '' },
    icon: { type: String, default: '' },
});

const { t } = useI18n();
const ui = useUiStore();
const { isRtl } = storeToRefs(ui);
</script>

<template>
    <div class="mb-6">
        <nav class="mb-2 flex items-center gap-2 text-xs text-surface-500 dark:text-surface-400">
            <RouterLink :to="{ name: 'dashboard' }" class="inline-flex items-center gap-1 transition-colors hover:text-emerald-600 dark:hover:text-emerald-400">
                <i class="pi pi-home text-[11px]"></i>
                <span>{{ t('nav.dashboard') }}</span>
            </RouterLink>
            <i :class="isRtl ? 'pi pi-angle-left' : 'pi pi-angle-right'" class="text-[10px]"></i>
            <span class="font-medium text-surface-600 dark:text-surface-300">{{ title }}</span>
        </nav>

        <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div class="flex items-start gap-3">
                <span
                    v-if="icon"
                    class="hidden size-11 shrink-0 place-items-center rounded-xl bg-emerald-50 text-emerald-600 dark:bg-emerald-500/15 dark:text-emerald-400 sm:grid"
                >
                    <i :class="icon" class="text-xl"></i>
                </span>
                <div class="min-w-0">
                    <h1 class="text-xl font-bold tracking-tight text-surface-900 dark:text-surface-0 sm:text-2xl">
                        {{ title }}
                    </h1>
                    <p v-if="subtitle" class="mt-1 text-sm text-surface-500 dark:text-surface-400">{{ subtitle }}</p>
                </div>
            </div>
            <div v-if="$slots.actions" class="flex shrink-0 flex-wrap items-center gap-2">
                <slot name="actions" />
            </div>
        </div>
    </div>
</template>
