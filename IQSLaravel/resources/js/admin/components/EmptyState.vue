<script setup>
defineProps({
    icon: { type: String, default: 'pi pi-inbox' },
    title: { type: String, required: true },
    message: { type: String, default: '' },
    badge: { type: String, default: '' },
});
</script>

<template>
    <div class="flex flex-col items-center justify-center rounded-2xl border border-dashed border-surface-300 bg-surface-0 px-6 py-16 text-center dark:border-surface-700 dark:bg-surface-900">
        <span class="grid size-16 place-items-center rounded-2xl bg-emerald-50 text-emerald-500 dark:bg-emerald-500/15 dark:text-emerald-400">
            <i :class="icon" class="text-3xl"></i>
        </span>
        <Tag v-if="badge" :value="badge" severity="warn" class="mt-4" rounded />
        <h3 class="mt-4 text-lg font-bold text-surface-900 dark:text-surface-0">{{ title }}</h3>
        <p v-if="message" class="mt-2 max-w-md text-sm text-surface-500 dark:text-surface-400">{{ message }}</p>
        <div v-if="$slots.default" class="mt-6">
            <slot />
        </div>
    </div>
</template>
