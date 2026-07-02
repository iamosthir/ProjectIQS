<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToast } from 'primevue/usetoast';
import PageHeader from '@admin/components/PageHeader.vue';
import { marketplaceApi } from '@admin/api/marketplace';

const { t } = useI18n();
const toast = useToast();

const rows = ref([]);
const loading = ref(false);
const search = ref('');
const statusFilter = ref(null);
const STATUSES = ['pending', 'active', 'suspended'];

function toastErr(e) { toast.add({ severity: 'error', summary: t('common.actions'), detail: e?.response?.data?.message || 'Error', life: 4000 }); }
function statusSeverity(s) { return { active: 'success', suspended: 'danger' }[s] || 'warn'; }

async function load() {
    loading.value = true;
    try {
        const params = { per_page: 30 };
        if (search.value) params['filter[search]'] = search.value;
        if (statusFilter.value) params['filter[status]'] = statusFilter.value;
        const { data } = await marketplaceApi.stores(params);
        rows.value = data.data;
    } catch (e) { toastErr(e); } finally { loading.value = false; }
}
async function act(fn, row) {
    try { await fn(row.id); toast.add({ severity: 'success', summary: t('common.save'), life: 2000 }); await load(); }
    catch (e) { toastErr(e); }
}
onMounted(load);
</script>

<template>
    <div>
        <PageHeader :title="t('marketplace.stores')" :subtitle="t('marketplace.storesSubtitle')" icon="pi pi-building" />

        <div class="rounded-2xl border border-surface-200 bg-surface-0 dark:border-surface-800 dark:bg-surface-900">
            <div class="flex flex-wrap items-center gap-3 border-b border-surface-200 p-4 dark:border-surface-800">
                <IconField class="w-full sm:max-w-xs">
                    <InputIcon class="pi pi-search" />
                    <InputText v-model="search" :placeholder="t('common.searchPlaceholder')" class="w-full" @keyup.enter="load" />
                </IconField>
                <Select v-model="statusFilter" :options="STATUSES" :placeholder="t('common.status')" show-clear class="w-44" @change="load" />
            </div>
            <DataTable :value="rows" :loading="loading" data-key="id" class="text-sm">
                <template #empty><div class="py-8 text-center text-surface-500">{{ t('common.noData') }}</div></template>
                <Column :header="t('common.name')">
                    <template #body="{ data }">
                        <p class="font-medium">{{ data.name_ar }}</p>
                        <p class="text-xs text-surface-500">{{ data.user?.name || data.user?.phone }} · {{ data.governorate }}</p>
                    </template>
                </Column>
                <Column :header="t('marketplace.listings')" field="listings_count" />
                <Column :header="t('marketplace.verified')">
                    <template #body="{ data }"><i :class="data.is_verified ? 'pi pi-verified text-emerald-500' : 'pi pi-minus text-surface-300'"></i></template>
                </Column>
                <Column :header="t('common.status')">
                    <template #body="{ data }"><Tag :value="data.status" :severity="statusSeverity(data.status)" /></template>
                </Column>
                <Column :header="t('common.actions')" :style="{ width: '13rem' }">
                    <template #body="{ data }">
                        <Button v-if="!data.is_verified" :label="t('marketplace.verify')" size="small" text severity="success" @click="act(marketplaceApi.verifyStore, data)" />
                        <Button v-if="data.status !== 'suspended'" :label="t('marketplace.suspend')" size="small" text severity="danger" @click="act(marketplaceApi.suspendStore, data)" />
                        <Button v-else :label="t('marketplace.activate')" size="small" text severity="success" @click="act(marketplaceApi.activateStore, data)" />
                    </template>
                </Column>
            </DataTable>
        </div>
    </div>
</template>
