<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToast } from 'primevue/usetoast';
import PageHeader from '@admin/components/PageHeader.vue';
import { marketplaceApi } from '@admin/api/marketplace';

const { t } = useI18n();
const toast = useToast();

const STATUSES = ['pending_review', 'pending_payment', 'published', 'rejected', 'expired', 'suspended'];
const rows = ref([]);
const loading = ref(false);
const statusFilter = ref('pending_review');
const detail = ref(null);
const detailVisible = ref(false);
const rejectVisible = ref(false);
const rejectReason = ref('');
const busy = ref(false);

function toastErr(e) { toast.add({ severity: 'error', summary: t('common.actions'), detail: e?.response?.data?.message || 'Error', life: 4000 }); }
function statusSeverity(s) { return { published: 'success', rejected: 'danger', pending_review: 'warn', pending_payment: 'info' }[s] || 'secondary'; }

async function load() {
    loading.value = true;
    try {
        const params = { per_page: 30 };
        if (statusFilter.value) params['filter[status]'] = statusFilter.value;
        const { data } = await marketplaceApi.listings(params);
        rows.value = data.data;
    } catch (e) { toastErr(e); } finally { loading.value = false; }
}
async function openDetail(row) {
    try { const { data } = await marketplaceApi.listing(row.id); detail.value = data.data; detailVisible.value = true; }
    catch (e) { toastErr(e); }
}
async function approve(row) {
    busy.value = true;
    try { await marketplaceApi.approveListing(row.id); toast.add({ severity: 'success', summary: t('marketplace.approved'), life: 2500 }); detailVisible.value = false; await load(); }
    catch (e) { toastErr(e); } finally { busy.value = false; }
}
function openReject(row) { detail.value = row; rejectReason.value = ''; rejectVisible.value = true; }
async function reject() {
    busy.value = true;
    try { await marketplaceApi.rejectListing(detail.value.id, rejectReason.value); toast.add({ severity: 'success', summary: t('marketplace.rejected'), life: 2500 }); rejectVisible.value = false; detailVisible.value = false; await load(); }
    catch (e) { toastErr(e); } finally { busy.value = false; }
}
async function feature(row) {
    try { await marketplaceApi.featureListing(row.id); toast.add({ severity: 'success', summary: t('marketplace.featured'), life: 2000 }); await load(); }
    catch (e) { toastErr(e); }
}
onMounted(load);
</script>

<template>
    <div>
        <PageHeader :title="t('marketplace.title')" :subtitle="t('marketplace.subtitle')" icon="pi pi-inbox" />

        <div class="rounded-2xl border border-surface-200 bg-surface-0 dark:border-surface-800 dark:bg-surface-900">
            <div class="border-b border-surface-200 p-4 dark:border-surface-800">
                <Select v-model="statusFilter" :options="STATUSES" :placeholder="t('common.all')" show-clear class="w-56" @change="load" />
            </div>
            <DataTable :value="rows" :loading="loading" data-key="id" class="text-sm">
                <template #empty><div class="py-8 text-center text-surface-500">{{ t('common.noData') }}</div></template>
                <Column :header="t('marketplace.listing')">
                    <template #body="{ data }">
                        <p class="font-medium">{{ data.title_ar }}</p>
                        <p class="text-xs text-surface-500">{{ data.full_name }} · {{ data.category?.name }} · {{ data.store?.name }}</p>
                    </template>
                </Column>
                <Column :header="t('marketplace.payment')">
                    <template #body="{ data }">
                        <Tag v-if="data.category?.is_free" :value="t('marketplace.free')" severity="secondary" />
                        <Tag v-else-if="data.payment" :value="data.payment.status" :severity="data.payment.status === 'paid' ? 'success' : 'warn'" />
                        <span v-else class="text-surface-400">—</span>
                    </template>
                </Column>
                <Column :header="t('common.status')">
                    <template #body="{ data }"><Tag :value="data.status" :severity="statusSeverity(data.status)" /></template>
                </Column>
                <Column :header="t('common.actions')" :style="{ width: '14rem' }">
                    <template #body="{ data }">
                        <Button icon="pi pi-eye" text rounded size="small" severity="secondary" @click="openDetail(data)" />
                        <Button v-if="data.status === 'pending_review'" :label="t('common.approve')" size="small" text severity="success" @click="approve(data)" />
                        <Button v-if="data.status === 'pending_review'" :label="t('common.reject')" size="small" text severity="danger" @click="openReject(data)" />
                        <Button v-if="data.status === 'published'" icon="pi pi-star" text rounded size="small" severity="warn" v-tooltip.bottom="t('marketplace.feature')" @click="feature(data)" />
                    </template>
                </Column>
            </DataTable>
        </div>

        <!-- Detail -->
        <Dialog v-model:visible="detailVisible" modal :header="t('marketplace.viewDetails')" :style="{ width: '42rem' }">
            <div v-if="detail" class="flex flex-col gap-3 pt-2 text-sm">
                <div class="flex items-start gap-4">
                    <img v-if="detail.photo_path" :src="detail.photo_path" class="size-20 rounded-lg object-cover" alt="" />
                    <div>
                        <h3 class="text-lg font-semibold">{{ detail.title_ar }}</h3>
                        <p class="text-surface-500">{{ detail.full_name }} · {{ detail.category?.name }}</p>
                        <p class="text-surface-500">{{ detail.governorate }} {{ detail.city }} · {{ detail.age }}</p>
                    </div>
                </div>
                <div class="grid grid-cols-3 gap-2 rounded-lg bg-surface-50 p-3 dark:bg-surface-800">
                    <div><span class="text-surface-500">{{ t('common.phone') }}:</span> <span dir="ltr">{{ detail.contact?.phone || '—' }}</span></div>
                    <div><span class="text-surface-500">WhatsApp:</span> <span dir="ltr">{{ detail.contact?.whatsapp || '—' }}</span></div>
                    <div><span class="text-surface-500">{{ t('common.email') }}:</span> <span dir="ltr">{{ detail.contact?.email || '—' }}</span></div>
                </div>
                <div v-if="detail.attributes && Object.keys(detail.attributes).length">
                    <p class="mb-1 font-medium">{{ t('marketplace.attributes') }}</p>
                    <ul class="grid grid-cols-2 gap-1 text-xs">
                        <li v-for="(v, k) in detail.attributes" :key="k"><span class="text-surface-500">{{ k }}:</span> {{ v }}</li>
                    </ul>
                </div>
                <div v-if="detail.media?.length" class="flex flex-wrap gap-2">
                    <img v-for="m in detail.media" :key="m.id" :src="m.url" class="size-16 rounded object-cover" alt="" />
                </div>
                <p v-if="detail.rejection_reason" class="text-rose-500">{{ detail.rejection_reason }}</p>
            </div>
            <template #footer>
                <Button :label="t('common.back')" text severity="secondary" @click="detailVisible = false" />
                <template v-if="detail?.status === 'pending_review'">
                    <Button :label="t('common.reject')" severity="danger" outlined @click="openReject(detail)" />
                    <Button :label="t('common.approve')" icon="pi pi-check" :loading="busy" @click="approve(detail)" />
                </template>
            </template>
        </Dialog>

        <!-- Reject reason -->
        <Dialog v-model:visible="rejectVisible" modal :header="t('common.reject')" :style="{ width: '28rem' }">
            <div class="pt-2">
                <label class="mb-1 block text-sm font-medium">{{ t('marketplace.rejectReason') }}</label>
                <Textarea v-model="rejectReason" rows="3" class="w-full" />
            </div>
            <template #footer>
                <Button :label="t('common.cancel')" text severity="secondary" @click="rejectVisible = false" />
                <Button :label="t('common.reject')" severity="danger" :loading="busy" :disabled="!rejectReason" @click="reject" />
            </template>
        </Dialog>
    </div>
</template>
