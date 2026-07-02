<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import PageHeader from '@admin/components/PageHeader.vue';
import { paymentsApi } from '@admin/api/payments';

const { t } = useI18n();
const toast = useToast();
const confirm = useConfirm();

const STATUSES = ['pending', 'processing', 'paid', 'failed', 'cancelled', 'refunded'];
const GATEWAYS = ['zaincash', 'fib', 'manual'];

const rows = ref([]);
const webhooks = ref([]);
const loading = ref(false);
const statusFilter = ref(null);
const gatewayFilter = ref(null);
const detail = ref(null);
const detailVisible = ref(false);

function toastErr(e) { toast.add({ severity: 'error', summary: t('common.actions'), detail: e?.response?.data?.message || 'Error', life: 4000 }); }
function statusSeverity(s) { return { paid: 'success', refunded: 'info', failed: 'danger', cancelled: 'danger', processing: 'warn' }[s] || 'secondary'; }

async function load() {
    loading.value = true;
    try {
        const params = { per_page: 30 };
        if (statusFilter.value) params['filter[status]'] = statusFilter.value;
        if (gatewayFilter.value) params['filter[gateway]'] = gatewayFilter.value;
        const { data } = await paymentsApi.list(params);
        rows.value = data.data;
    } catch (e) { toastErr(e); } finally { loading.value = false; }
}
async function loadWebhooks() {
    try { const { data } = await paymentsApi.webhooks({ per_page: 30 }); webhooks.value = data.data; }
    catch (e) { toastErr(e); }
}
async function openDetail(row) {
    try { const { data } = await paymentsApi.show(row.id); detail.value = data.data; detailVisible.value = true; }
    catch (e) { toastErr(e); }
}
function refund(row) {
    confirm.require({
        message: t('payments.refundConfirm'), header: t('payments.refund'), icon: 'pi pi-exclamation-triangle',
        rejectLabel: t('common.cancel'), acceptLabel: t('payments.refund'), acceptClass: 'p-button-danger',
        accept: async () => {
            try { await paymentsApi.refund(row.id); toast.add({ severity: 'success', summary: t('payments.refunded'), life: 2500 }); await load(); }
            catch (e) { toastErr(e); }
        },
    });
}

onMounted(() => { load(); loadWebhooks(); });
</script>

<template>
    <div>
        <PageHeader :title="t('payments.title')" :subtitle="t('payments.subtitle')" icon="pi pi-wallet" />

        <Tabs value="payments">
            <TabList>
                <Tab value="payments">{{ t('payments.title') }}</Tab>
                <Tab value="webhooks">{{ t('payments.webhooks') }}</Tab>
            </TabList>
            <TabPanels>
                <TabPanel value="payments">
                    <div class="mb-3 flex flex-wrap gap-3">
                        <Select v-model="statusFilter" :options="STATUSES" :placeholder="t('common.status')" show-clear class="w-44" @change="load" />
                        <Select v-model="gatewayFilter" :options="GATEWAYS" :placeholder="t('payments.gateway')" show-clear class="w-44" @change="load" />
                    </div>
                    <div class="rounded-2xl border border-surface-200 bg-surface-0 dark:border-surface-800 dark:bg-surface-900">
                        <DataTable :value="rows" :loading="loading" data-key="id" class="text-sm">
                            <template #empty><div class="py-8 text-center text-surface-500">{{ t('common.noData') }}</div></template>
                            <Column :header="t('payments.reference')">
                                <template #body="{ data }">
                                    <span class="font-mono text-xs" dir="ltr">{{ data.payment_number }}</span>
                                    <p class="text-xs text-surface-500">{{ data.payable.type }}#{{ data.payable.id }}</p>
                                </template>
                            </Column>
                            <Column :header="t('payments.amount')">
                                <template #body="{ data }"><span dir="ltr" class="font-medium">{{ data.amount.toLocaleString() }} {{ data.currency }}</span></template>
                            </Column>
                            <Column :header="t('payments.gateway')" field="gateway">
                                <template #body="{ data }"><Tag :value="data.gateway" severity="secondary" /></template>
                            </Column>
                            <Column :header="t('common.status')">
                                <template #body="{ data }"><Tag :value="data.status" :severity="statusSeverity(data.status)" /></template>
                            </Column>
                            <Column :header="t('common.date')">
                                <template #body="{ data }"><span dir="ltr">{{ data.created_at ? new Date(data.created_at).toLocaleString() : '' }}</span></template>
                            </Column>
                            <Column :header="t('common.actions')" :style="{ width: '9rem' }">
                                <template #body="{ data }">
                                    <Button icon="pi pi-eye" text rounded size="small" severity="secondary" @click="openDetail(data)" />
                                    <Button v-if="data.status === 'paid'" :label="t('payments.refund')" size="small" text severity="danger" @click="refund(data)" />
                                </template>
                            </Column>
                        </DataTable>
                    </div>
                </TabPanel>

                <TabPanel value="webhooks">
                    <div class="rounded-2xl border border-surface-200 bg-surface-0 dark:border-surface-800 dark:bg-surface-900">
                        <DataTable :value="webhooks" data-key="id" class="text-sm" paginator :rows="10">
                            <template #empty><div class="py-8 text-center text-surface-500">{{ t('common.noData') }}</div></template>
                            <Column :header="t('payments.gateway')" field="gateway" />
                            <Column :header="t('payments.event')" field="event_type" />
                            <Column :header="t('payments.signature')">
                                <template #body="{ data }"><Tag :value="data.signature_valid ? 'valid' : 'invalid'" :severity="data.signature_valid ? 'success' : 'danger'" /></template>
                            </Column>
                            <Column :header="t('payments.processed')">
                                <template #body="{ data }"><i :class="data.processed ? 'pi pi-check text-emerald-500' : 'pi pi-times text-surface-400'"></i></template>
                            </Column>
                            <Column :header="t('common.date')">
                                <template #body="{ data }"><span dir="ltr">{{ data.created_at ? new Date(data.created_at).toLocaleString() : '' }}</span></template>
                            </Column>
                        </DataTable>
                    </div>
                </TabPanel>
            </TabPanels>
        </Tabs>

        <Dialog v-model:visible="detailVisible" modal :header="t('payments.detail')" :style="{ width: '40rem' }">
            <div v-if="detail" class="flex flex-col gap-3 pt-2 text-sm">
                <div class="grid grid-cols-2 gap-3">
                    <div><span class="text-surface-500">{{ t('payments.reference') }}:</span> <span class="font-mono" dir="ltr">{{ detail.payment_number }}</span></div>
                    <div><span class="text-surface-500">{{ t('common.status') }}:</span> <Tag :value="detail.status" :severity="statusSeverity(detail.status)" /></div>
                    <div><span class="text-surface-500">{{ t('payments.amount') }}:</span> <span dir="ltr">{{ detail.amount.toLocaleString() }} {{ detail.currency }}</span></div>
                    <div><span class="text-surface-500">{{ t('payments.gateway') }}:</span> {{ detail.gateway }}</div>
                    <div><span class="text-surface-500">{{ t('payments.txn') }}:</span> <span dir="ltr">{{ detail.gateway_transaction_id || '—' }}</span></div>
                    <div><span class="text-surface-500">{{ t('payments.user') }}:</span> {{ detail.user?.name || detail.user?.phone }}</div>
                </div>
                <p v-if="detail.failure_reason" class="text-rose-500">{{ detail.failure_reason }}</p>
                <Divider align="left"><span class="text-xs text-surface-500">{{ t('payments.webhooks') }}</span></Divider>
                <ul class="space-y-1">
                    <li v-for="w in detail.webhooks" :key="w.id" class="flex items-center gap-2 text-xs">
                        <Tag :value="w.event_type || w.gateway" severity="secondary" />
                        <Tag :value="w.signature_valid ? 'valid' : 'invalid'" :severity="w.signature_valid ? 'success' : 'danger'" />
                        <span class="text-surface-500" dir="ltr">{{ w.created_at ? new Date(w.created_at).toLocaleString() : '' }}</span>
                    </li>
                    <li v-if="!detail.webhooks?.length" class="text-surface-400">{{ t('common.noData') }}</li>
                </ul>
            </div>
            <template #footer>
                <Button :label="t('common.back')" text severity="secondary" @click="detailVisible = false" />
                <Button v-if="detail?.status === 'paid'" :label="t('payments.refund')" severity="danger" @click="refund(detail); detailVisible = false" />
            </template>
        </Dialog>
    </div>
</template>
