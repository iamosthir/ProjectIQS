<script setup>
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';

const { t } = useI18n();
const router = useRouter();
</script>

<template>
    <div class="flex h-full flex-col items-center justify-center bg-surface-50 p-6 text-center dark:bg-surface-950">
        <p class="text-7xl font-black tracking-tight text-emerald-500">404</p>
        <h1 class="mt-4 text-2xl font-bold text-surface-900 dark:text-surface-0">{{ t('notFound.title') }}</h1>
        <p class="mt-2 max-w-md text-surface-500 dark:text-surface-400">{{ t('notFound.description') }}</p>
        <Button :label="t('notFound.goHome')" icon="pi pi-home" class="mt-6" @click="router.push({ name: 'dashboard' })" />
    </div>
</template>
