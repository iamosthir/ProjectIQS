<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToast } from 'primevue/usetoast';
import PageHeader from '@admin/components/PageHeader.vue';
import { clubsApi } from '@admin/api/clubs';

const { t } = useI18n();
const toast = useToast();

const STATUSES = ['pending', 'approved', 'rejected'];
const rows = ref([]);
const loading = ref(false);
const statusFilter = ref('pending');
const rejectDialog = ref(false);
const rejectNote = ref('');
const current = ref(null);

function toastErr(e) { toast.add({ severity: 'error', summary: t('common.actions'), detail: e?.response?.data?.message || 'Error', life: 4000 }); }

async function load() {
    loading.value = true;
    try {
        const params = { per_page: 30 };
        if (statusFilter.value) params.status = statusFilter.value;
        const { data } = await clubsApi.verifications(params);
        rows.value = data.data;
    } catch (e) { toastErr(e); } finally { loading.value = false; }
}
async function approve(r) {
    try { await clubsApi.approveVerification(r.id); toast.add({ severity: 'success', summary: t('clubs.approved'), life: 2000 }); await load(); }
    catch (e) { toastErr(e); }
}
function openReject(r) { current.value = r; rejectNote.value = ''; rejectDialog.value = true; }
async function reject() {
    try { await clubsApi.rejectVerification(current.value.id, rejectNote.value); rejectDialog.value = false; await load(); }
    catch (e) { toastErr(e); }
}
onMounted(load);
</script>

<template>
    <div>
        <PageHeader :title="t('clubs.verifications')" :subtitle="t('clubs.verificationsSubtitle')" icon="pi pi-verified" />

        <div class="rounded-2xl border border-surface-200 bg-surface-0 dark:border-surface-800 dark:bg-surface-900">
            <div class="border-b border-surface-200 p-4 dark:border-surface-800">
                <Select v-model="statusFilter" :options="STATUSES" :placeholder="t('common.all')" show-clear class="w-48" @change="load" />
            </div>
            <DataTable :value="rows" :loading="loading" data-key="id" class="text-sm">
                <template #empty><div class="py-8 text-center text-surface-500">{{ t('common.noData') }}</div></template>
                <Column :header="t('clubs.title')">
                    <template #body="{ data }">
                        <p class="font-medium">{{ data.club?.name }}</p>
                        <p class="text-xs text-surface-500">{{ data.verifiable_type }}#{{ data.verifiable_id }} · {{ data.requested_by?.name || data.requested_by?.phone }}</p>
                    </template>
                </Column>
                <Column :header="t('clubs.method')" field="method" />
                <Column :header="t('common.status')">
                    <template #body="{ data }"><Tag :value="data.status" :severity="data.status === 'approved' ? 'success' : (data.status === 'rejected' ? 'danger' : 'warn')" /></template>
                </Column>
                <Column :header="t('common.actions')" :style="{ width: '12rem' }">
                    <template #body="{ data }">
                        <template v-if="data.status === 'pending'">
                            <Button :label="t('common.approve')" size="small" text severity="success" @click="approve(data)" />
                            <Button :label="t('common.reject')" size="small" text severity="danger" @click="openReject(data)" />
                        </template>
                    </template>
                </Column>
            </DataTable>
        </div>

        <Dialog v-model:visible="rejectDialog" modal :header="t('common.reject')" :style="{ width: '28rem' }">
            <div class="pt-2">
                <label class="mb-1 block text-sm font-medium">{{ t('marketplace.rejectReason') }}</label>
                <Textarea v-model="rejectNote" rows="3" class="w-full" />
            </div>
            <template #footer>
                <Button :label="t('common.cancel')" text severity="secondary" @click="rejectDialog = false" />
                <Button :label="t('common.reject')" severity="danger" @click="reject" />
            </template>
        </Dialog>
    </div>
</template>
