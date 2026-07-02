<script setup>
import { watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { usePrimeVue } from 'primevue/config';
import { storeToRefs } from 'pinia';
import { useUiStore } from '@admin/stores/ui';
import { primeLocaleFor } from '@admin/i18n/primevue-locales';

const ui = useUiStore();
const { locale: uiLocale, isRtl } = storeToRefs(ui);
const { locale: i18nLocale } = useI18n();
const primevue = usePrimeVue();

function applyLocale(loc) {
    i18nLocale.value = loc;
    primevue.config.locale = primeLocaleFor(loc);
}

applyLocale(ui.locale);
watch(uiLocale, applyLocale);
</script>

<template>
    <RouterView />
    <Toast :position="isRtl ? 'top-left' : 'top-right'" />
    <ConfirmDialog />
    <ConfirmPopup />
</template>
