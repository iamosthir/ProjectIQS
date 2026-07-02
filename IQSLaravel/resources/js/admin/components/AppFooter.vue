<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
const year = 2026;
const version = '0.1.0';
</script>

<template>
    <footer
        class="flex flex-col items-center justify-between gap-2 border-t border-surface-200 dark:border-surface-800 px-4 py-4 text-xs text-surface-500 dark:text-surface-400 sm:flex-row lg:px-6"
    >
        <p>{{ t('footer.rights', { year }) }}</p>
        <div class="flex items-center gap-4">
            <span>{{ t('footer.version', { version }) }}</span>
            <span class="hidden items-center gap-1.5 sm:inline-flex">
                <span class="size-2 rounded-full bg-emerald-500 animate-pulse"></span>
                {{ t('dashboard.liveNow') }}
            </span>
        </div>
    </footer>
</template>
