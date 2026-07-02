<script setup>
import { useI18n } from 'vue-i18n';

defineProps({
    /** Show only the icon mark (collapsed sidebar). */
    markOnly: { type: Boolean, default: false },
});

const { t } = useI18n();
</script>

<template>
    <div class="flex items-center gap-3 select-none">
        <span
            class="grid place-items-center rounded-xl text-white shadow-sm shadow-emerald-500/30 size-10 shrink-0 bg-gradient-to-br from-emerald-400 via-emerald-500 to-emerald-700"
        >
            <svg viewBox="0 0 32 32" class="size-6" fill="none" aria-hidden="true">
                <circle cx="16" cy="16" r="11" stroke="currentColor" stroke-width="2" />
                <path d="M16 9.6l4.3 3.12-1.64 5.05h-5.32L11.7 12.72z" fill="currentColor" />
                <path
                    d="M16 9.6V6M20.3 12.72l3.4-1.1M18.66 17.77l2.05 2.86M13.34 17.77l-2.05 2.86M11.7 12.72l-3.4-1.1"
                    stroke="currentColor"
                    stroke-width="1.7"
                    stroke-linecap="round"
                />
            </svg>
        </span>
        <transition name="fade">
            <div v-if="!markOnly" class="flex flex-col leading-tight min-w-0">
                <span class="text-base font-extrabold tracking-tight text-surface-900 dark:text-surface-0">
                    IQS
                </span>
                <span class="text-[11px] font-medium text-surface-500 dark:text-surface-400 truncate">
                    {{ t('common.appNameFull') }}
                </span>
            </div>
        </transition>
    </div>
</template>
