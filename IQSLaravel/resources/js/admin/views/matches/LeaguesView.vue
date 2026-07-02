<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import PageHeader from '@admin/components/PageHeader.vue';
import ImageUploadField from '@admin/components/ImageUploadField.vue';
import { matchesApi } from '@admin/api/matches';
import { useFormErrors } from '@admin/composables/useFormErrors';

const { t } = useI18n();
const toast = useToast();
const confirm = useConfirm();
const { reset, setFrom, first } = useFormErrors();

const CATEGORIES = ['premier', 'first_div', 'second_div', 'third_div', 'nt_senior', 'nt_u21', 'nt_u19', 'nt_u17', 'nt_u16', 'nt_u14', 'other'];
const TYPES = ['league', 'cup'];

const rows = ref([]);
const loading = ref(false);
const search = ref('');
const dialog = ref(false);
const saving = ref(false);
const form = ref(empty());

function empty() {
    return { id: null, name_ar: '', name_en: '', type: 'league', category: 'premier', tier: 1, is_iraqi: true, requires_auth: true, is_featured: false, is_active: true, logo_path: '' };
}
function toastErr(e) {
    toast.add({ severity: 'error', summary: t('common.actions'), detail: e?.response?.data?.message || 'Error', life: 4000 });
}
async function load() {
    loading.value = true;
    try {
        const { data } = await matchesApi.leagues({ 'filter[search]': search.value || undefined, per_page: 50 });
        rows.value = data.data;
    } catch (e) { toastErr(e); } finally { loading.value = false; }
}
function openCreate() { reset(); form.value = empty(); dialog.value = true; }
function openEdit(r) { reset(); form.value = { ...empty(), ...r }; dialog.value = true; }
async function save() {
    saving.value = true; reset();
    try {
        if (form.value.id) await matchesApi.updateLeague(form.value.id, form.value);
        else await matchesApi.createLeague(form.value);
        toast.add({ severity: 'success', summary: t('common.save'), life: 2500 });
        dialog.value = false; await load();
    } catch (e) { if (!setFrom(e)) toastErr(e); } finally { saving.value = false; }
}
async function toggleLock(r) {
    try { await matchesApi.toggleLeagueLock(r.id); await load(); } catch (e) { toastErr(e); }
}
function del(r) {
    confirm.require({
        message: t('matches.deleteLeagueConfirm'), header: t('common.delete'), icon: 'pi pi-exclamation-triangle',
        rejectLabel: t('common.cancel'), acceptLabel: t('common.delete'), acceptClass: 'p-button-danger',
        accept: async () => { try { await matchesApi.deleteLeague(r.id); await load(); } catch (e) { toastErr(e); } },
    });
}
onMounted(load);
</script>

<template>
    <div>
        <PageHeader :title="t('matches.leagues')" :subtitle="t('matches.leaguesSubtitle')" icon="pi pi-trophy">
            <template #actions>
                <Button :label="t('matches.newLeague')" icon="pi pi-plus" @click="openCreate" />
            </template>
        </PageHeader>

        <div class="rounded-2xl border border-surface-200 bg-surface-0 dark:border-surface-800 dark:bg-surface-900">
            <div class="border-b border-surface-200 p-4 dark:border-surface-800">
                <IconField class="w-full sm:max-w-xs">
                    <InputIcon class="pi pi-search" />
                    <InputText v-model="search" :placeholder="t('common.searchPlaceholder')" class="w-full" @keyup.enter="load" />
                </IconField>
            </div>
            <DataTable :value="rows" :loading="loading" data-key="id" class="text-sm">
                <template #empty><div class="py-8 text-center text-surface-500">{{ t('common.noData') }}</div></template>
                <Column :header="t('common.name')">
                    <template #body="{ data }">
                        <p class="font-medium text-surface-800 dark:text-surface-100">{{ data.name_ar }}</p>
                        <p class="text-xs text-surface-500" dir="ltr">{{ data.name_en }}</p>
                    </template>
                </Column>
                <Column :header="t('matches.category')" field="category" />
                <Column header="Tier" field="tier" />
                <Column :header="t('fixtures.source')">
                    <template #body="{ data }">
                        <Tag :value="data.source" :severity="data.source === 'manual' ? 'info' : 'secondary'" />
                        <Tag v-if="data.is_locked" value="locked" severity="warn" class="ms-1" />
                    </template>
                </Column>
                <Column :header="t('common.status')">
                    <template #body="{ data }"><Tag :value="data.is_active ? t('common.active') : t('common.inactive')" :severity="data.is_active ? 'success' : 'secondary'" /></template>
                </Column>
                <Column :header="t('common.actions')" :style="{ width: '9rem' }">
                    <template #body="{ data }">
                        <Button v-if="data.source === 'api_football'" :icon="data.is_locked ? 'pi pi-lock' : 'pi pi-lock-open'" text rounded size="small" severity="warn" v-tooltip.bottom="t('matches.toggleLock')" @click="toggleLock(data)" />
                        <Button icon="pi pi-pencil" text rounded size="small" severity="secondary" @click="openEdit(data)" />
                        <Button icon="pi pi-trash" text rounded size="small" severity="danger" @click="del(data)" />
                    </template>
                </Column>
            </DataTable>
        </div>

        <Dialog v-model:visible="dialog" modal :header="form.id ? t('matches.editLeague') : t('matches.newLeague')" :style="{ width: '34rem' }">
            <div class="flex flex-col gap-4 pt-2">
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.nameAr') }}</label>
                        <InputText v-model="form.name_ar" class="w-full" :invalid="!!first('name_ar')" />
                        <Message v-if="first('name_ar')" severity="error" size="small" variant="simple">{{ first('name_ar') }}</Message>
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.nameEn') }}</label>
                        <InputText v-model="form.name_en" class="w-full" dir="ltr" :invalid="!!first('name_en')" />
                        <Message v-if="first('name_en')" severity="error" size="small" variant="simple">{{ first('name_en') }}</Message>
                    </div>
                </div>
                <div class="grid grid-cols-3 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.type') }}</label>
                        <Select v-model="form.type" :options="TYPES" class="w-full" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.category') }}</label>
                        <Select v-model="form.category" :options="CATEGORIES" class="w-full" filter />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">Tier</label>
                        <InputNumber v-model="form.tier" class="w-full" :min="1" :max="255" />
                    </div>
                </div>
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('common.logo') }}</label>
                    <ImageUploadField v-model="form.logo_path" endpoint="/leagues/upload" :error="first('logo_path')" />
                </div>
                <div class="flex flex-wrap gap-4">
                    <label class="flex items-center gap-2 text-sm"><ToggleSwitch v-model="form.is_iraqi" /> {{ t('matches.isIraqi') }}</label>
                    <label class="flex items-center gap-2 text-sm"><ToggleSwitch v-model="form.requires_auth" /> {{ t('matches.requiresAuth') }}</label>
                    <label class="flex items-center gap-2 text-sm"><ToggleSwitch v-model="form.is_featured" /> {{ t('matches.featured') }}</label>
                    <label class="flex items-center gap-2 text-sm"><ToggleSwitch v-model="form.is_active" /> {{ t('common.active') }}</label>
                </div>
            </div>
            <template #footer>
                <Button :label="t('common.cancel')" text severity="secondary" @click="dialog = false" />
                <Button :label="t('common.save')" icon="pi pi-check" :loading="saving" @click="save" />
            </template>
        </Dialog>
    </div>
</template>
