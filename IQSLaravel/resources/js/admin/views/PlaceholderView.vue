<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import PageHeader from '@admin/components/PageHeader.vue';
import EmptyState from '@admin/components/EmptyState.vue';

const route = useRoute();
const { t } = useI18n();

const title = computed(() => t(route.meta.titleKey));
const icon = computed(() => route.meta.icon || 'pi pi-clock');
</script>

<template>
    <div>
        <PageHeader :title="title" :icon="icon" />
        <EmptyState
            :icon="icon"
            :title="title"
            :message="t('placeholder.description')"
            :badge="t('placeholder.badge')"
        />
    </div>
</template>
