<script setup>
import { computed } from 'vue';

const props = defineProps({
    title: { type: String, required: true },
    value: { type: [String, Number], required: true },
    icon: { type: String, default: 'pi pi-chart-bar' },
    /** Percentage change; positive = up, negative = down. */
    trend: { type: Number, default: null },
    trendLabel: { type: String, default: '' },
    /** Tailwind color family for the icon tile. */
    color: { type: String, default: 'emerald' },
});

const tileClass = computed(
    () =>
        ({
            emerald: 'bg-emerald-50 text-emerald-600 dark:bg-emerald-500/15 dark:text-emerald-400',
            blue: 'bg-blue-50 text-blue-600 dark:bg-blue-500/15 dark:text-blue-400',
            amber: 'bg-amber-50 text-amber-600 dark:bg-amber-500/15 dark:text-amber-400',
            violet: 'bg-violet-50 text-violet-600 dark:bg-violet-500/15 dark:text-violet-400',
            rose: 'bg-rose-50 text-rose-600 dark:bg-rose-500/15 dark:text-rose-400',
        })[props.color] || 'bg-emerald-50 text-emerald-600 dark:bg-emerald-500/15 dark:text-emerald-400'
);

const trendUp = computed(() => props.trend !== null && props.trend >= 0);
</script>

<template>
    <div
        class="rounded-2xl border border-surface-200 bg-surface-0 p-5 transition-shadow hover:shadow-md dark:border-surface-800 dark:bg-surface-900"
    >
        <div class="flex items-start justify-between gap-3">
            <div class="min-w-0">
                <p class="truncate text-sm font-medium text-surface-500 dark:text-surface-400">{{ title }}</p>
                <p class="mt-2 text-3xl font-bold tracking-tight text-surface-900 dark:text-surface-0">{{ value }}</p>
            </div>
            <span class="grid size-12 shrink-0 place-items-center rounded-xl" :class="tileClass">
                <i :class="icon" class="text-xl"></i>
            </span>
        </div>
        <div v-if="trend !== null" class="mt-4 flex items-center gap-2 text-xs">
            <span
                class="inline-flex items-center gap-1 rounded-full px-2 py-0.5 font-semibold"
                :class="trendUp ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-500/15 dark:text-emerald-400' : 'bg-rose-50 text-rose-700 dark:bg-rose-500/15 dark:text-rose-400'"
            >
                <i :class="trendUp ? 'pi pi-arrow-up' : 'pi pi-arrow-down'" class="text-[10px]"></i>
                {{ Math.abs(trend) }}%
            </span>
            <span class="text-surface-400 dark:text-surface-500">{{ trendLabel }}</span>
        </div>
    </div>
</template>
