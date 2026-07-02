<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToast } from 'primevue/usetoast';
import PageHeader from '@admin/components/PageHeader.vue';
import { notificationsApi } from '@admin/api/notifications';
import { useFormErrors } from '@admin/composables/useFormErrors';

const { t } = useI18n();
const toast = useToast();
const { reset, setFrom, first } = useFormErrors();

const meta = ref({ targets: [], types: [], action_types: [], clubs: [], governorates: [] });
const form = ref(empty());
const sending = ref(false);
const batches = ref([]);
const loadingBatches = ref(false);
const detail = ref(null);
const detailVisible = ref(false);

function empty() {
    return { title_ar: '', title_en: '', body_ar: '', body_en: '', target: 'all', target_value: {}, type: 'general', action_type: 'none', action_value: '', customIds: '' };
}
function toastErr(e) { toast.add({ severity: 'error', summary: t('notifications.title'), detail: e?.response?.data?.message || 'Error', life: 4000 }); }
const clubOptions = computed(() => meta.value.clubs.map((c) => ({ id: c.id, label: c.name_ar || c.name_en })));

async function loadMeta() { try { const { data } = await notificationsApi.compose(); meta.value = data.data; } catch (e) { toastErr(e); } }
async function loadBatches() {
    loadingBatches.value = true;
    try { const { data } = await notificationsApi.batches({ per_page: 30 }); batches.value = data.data; }
    catch (e) { toastErr(e); } finally { loadingBatches.value = false; }
}
async function send() {
    sending.value = true; reset();
    try {
        const payload = { title_ar: form.value.title_ar, title_en: form.value.title_en, body_ar: form.value.body_ar, body_en: form.value.body_en, target: form.value.target, type: form.value.type, action_type: form.value.action_type, action_value: form.value.action_value || null };
        if (form.value.target === 'club_supporters') payload.target_value = { club_id: form.value.target_value.club_id };
        else if (form.value.target === 'governorate') payload.target_value = { governorate: form.value.target_value.governorate };
        else if (form.value.target === 'custom') payload.target_value = { user_ids: String(form.value.customIds).split(',').map((s) => parseInt(s.trim())).filter(Boolean) };
        await notificationsApi.send(payload);
        toast.add({ severity: 'success', summary: t('notifications.queued'), life: 3000 });
        form.value = empty();
        await loadBatches();
    } catch (e) { if (!setFrom(e)) toastErr(e); } finally { sending.value = false; }
}
function statusSeverity(s) { return { sent: 'success', failed: 'danger', sending: 'warn', queued: 'info' }[s] || 'secondary'; }

onMounted(() => { loadMeta(); loadBatches(); });
</script>

<template>
    <div>
        <PageHeader :title="t('notifications.title')" :subtitle="t('notifications.subtitle')" icon="pi pi-bell" />

        <Tabs value="compose">
            <TabList>
                <Tab value="compose">{{ t('notifications.compose') }}</Tab>
                <Tab value="history">{{ t('notifications.history') }}</Tab>
            </TabList>
            <TabPanels>
                <TabPanel value="compose">
                    <div class="max-w-2xl rounded-2xl border border-surface-200 bg-surface-0 p-5 dark:border-surface-800 dark:bg-surface-900">
                        <div class="grid grid-cols-2 gap-3">
                            <div>
                                <label class="mb-1 block text-sm font-medium">{{ t('matches.nameAr') }}</label>
                                <InputText v-model="form.title_ar" class="w-full" :invalid="!!first('title_ar')" />
                                <Message v-if="first('title_ar')" severity="error" size="small" variant="simple">{{ first('title_ar') }}</Message>
                            </div>
                            <div>
                                <label class="mb-1 block text-sm font-medium">{{ t('matches.nameEn') }}</label>
                                <InputText v-model="form.title_en" class="w-full" dir="ltr" :invalid="!!first('title_en')" />
                            </div>
                        </div>
                        <div class="mt-3 grid grid-cols-2 gap-3">
                            <Textarea v-model="form.body_ar" :placeholder="t('notifications.bodyAr')" rows="3" class="w-full" auto-resize :invalid="!!first('body_ar')" />
                            <Textarea v-model="form.body_en" :placeholder="t('notifications.bodyEn')" rows="3" class="w-full" dir="ltr" auto-resize />
                        </div>
                        <div class="mt-3">
                            <label class="mb-1 block text-sm font-medium">{{ t('notifications.target') }}</label>
                            <SelectButton v-model="form.target" :options="meta.targets" :allow-empty="false" />
                        </div>
                        <div v-if="form.target === 'club_supporters'" class="mt-3">
                            <label class="mb-1 block text-sm font-medium">{{ t('nav.clubs') }}</label>
                            <Select v-model="form.target_value.club_id" :options="clubOptions" option-label="label" option-value="id" filter class="w-full" :invalid="!!first('target_value.club_id')" />
                        </div>
                        <div v-if="form.target === 'governorate'" class="mt-3">
                            <label class="mb-1 block text-sm font-medium">{{ t('users.governorate') }}</label>
                            <Select v-model="form.target_value.governorate" :options="meta.governorates" editable filter class="w-full" :invalid="!!first('target_value.governorate')" />
                        </div>
                        <div v-if="form.target === 'custom'" class="mt-3">
                            <label class="mb-1 block text-sm font-medium">{{ t('notifications.userIds') }}</label>
                            <InputText v-model="form.customIds" class="w-full" dir="ltr" placeholder="1, 2, 3" />
                        </div>
                        <div class="mt-3 grid grid-cols-3 gap-3">
                            <div>
                                <label class="mb-1 block text-sm font-medium">{{ t('matches.type') }}</label>
                                <Select v-model="form.type" :options="meta.types" class="w-full" />
                            </div>
                            <div>
                                <label class="mb-1 block text-sm font-medium">{{ t('notifications.action') }}</label>
                                <Select v-model="form.action_type" :options="meta.action_types" class="w-full" />
                            </div>
                            <div>
                                <label class="mb-1 block text-sm font-medium">{{ t('notifications.actionValue') }}</label>
                                <InputText v-model="form.action_value" class="w-full" dir="ltr" />
                            </div>
                        </div>
                        <div class="mt-5 flex justify-end">
                            <Button :label="t('notifications.send')" icon="pi pi-send" :loading="sending" @click="send" />
                        </div>
                    </div>
                </TabPanel>

                <TabPanel value="history">
                    <div class="rounded-2xl border border-surface-200 bg-surface-0 dark:border-surface-800 dark:bg-surface-900">
                        <DataTable :value="batches" :loading="loadingBatches" data-key="id" class="text-sm">
                            <template #empty><div class="py-8 text-center text-surface-500">{{ t('common.noData') }}</div></template>
                            <Column :header="t('common.name')">
                                <template #body="{ data }">
                                    <p class="font-medium">{{ data.title_ar }}</p>
                                    <p class="text-xs text-surface-500">{{ data.target }}</p>
                                </template>
                            </Column>
                            <Column :header="t('notifications.recipients')" field="total_recipients" />
                            <Column :header="t('notifications.sent')">
                                <template #body="{ data }"><span class="text-emerald-600">{{ data.sent_count }}</span> / <span class="text-rose-500">{{ data.failed_count }}</span></template>
                            </Column>
                            <Column :header="t('common.status')">
                                <template #body="{ data }"><Tag :value="data.status" :severity="statusSeverity(data.status)" /></template>
                            </Column>
                            <Column :header="t('common.date')">
                                <template #body="{ data }"><span dir="ltr">{{ data.created_at ? new Date(data.created_at).toLocaleString() : '' }}</span></template>
                            </Column>
                        </DataTable>
                    </div>
                </TabPanel>
            </TabPanels>
        </Tabs>
    </div>
</template>
