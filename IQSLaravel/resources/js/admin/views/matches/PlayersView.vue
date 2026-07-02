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

const rows = ref([]);
const loading = ref(false);
const search = ref('');
const dialog = ref(false);
const saving = ref(false);
const form = ref(empty());

function empty() {
    return { id: null, name_ar: '', name_en: '', firstname: '', lastname: '', position: '', nationality: 'Iraq', height: '', weight: '', photo_path: '', is_injured: false };
}
function toastErr(e) { toast.add({ severity: 'error', summary: t('common.actions'), detail: e?.response?.data?.message || 'Error', life: 4000 }); }
async function load() {
    loading.value = true;
    try { const { data } = await matchesApi.players({ 'filter[search]': search.value || undefined, per_page: 50 }); rows.value = data.data; }
    catch (e) { toastErr(e); } finally { loading.value = false; }
}
function openCreate() { reset(); form.value = empty(); dialog.value = true; }
function openEdit(r) { reset(); form.value = { ...empty(), ...r }; dialog.value = true; }
async function save() {
    saving.value = true; reset();
    try {
        if (form.value.id) await matchesApi.updatePlayer(form.value.id, form.value);
        else await matchesApi.createPlayer(form.value);
        toast.add({ severity: 'success', summary: t('common.save'), life: 2500 });
        dialog.value = false; await load();
    } catch (e) { if (!setFrom(e)) toastErr(e); } finally { saving.value = false; }
}
function del(r) {
    confirm.require({
        message: t('matches.deletePlayerConfirm'), header: t('common.delete'), icon: 'pi pi-exclamation-triangle',
        rejectLabel: t('common.cancel'), acceptLabel: t('common.delete'), acceptClass: 'p-button-danger',
        accept: async () => { try { await matchesApi.deletePlayer(r.id); await load(); } catch (e) { toastErr(e); } },
    });
}
onMounted(load);
</script>

<template>
    <div>
        <PageHeader :title="t('matches.players')" :subtitle="t('matches.playersSubtitle')" icon="pi pi-users">
            <template #actions><Button :label="t('matches.newPlayer')" icon="pi pi-plus" @click="openCreate" /></template>
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
                <Column :header="t('matches.position')" field="position" />
                <Column :header="t('matches.nationality')" field="nationality" />
                <Column :header="t('common.status')">
                    <template #body="{ data }"><Tag v-if="data.is_injured" :value="t('matches.injured')" severity="danger" /><span v-else class="text-surface-400">—</span></template>
                </Column>
                <Column :header="t('common.actions')" :style="{ width: '7rem' }">
                    <template #body="{ data }">
                        <Button icon="pi pi-pencil" text rounded size="small" severity="secondary" @click="openEdit(data)" />
                        <Button icon="pi pi-trash" text rounded size="small" severity="danger" @click="del(data)" />
                    </template>
                </Column>
            </DataTable>
        </div>

        <Dialog v-model:visible="dialog" modal :header="form.id ? t('matches.editPlayer') : t('matches.newPlayer')" :style="{ width: '34rem' }">
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
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.position') }}</label>
                        <InputText v-model="form.position" class="w-full" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.nationality') }}</label>
                        <InputText v-model="form.nationality" class="w-full" />
                    </div>
                </div>
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.height') }}</label>
                        <InputText v-model="form.height" class="w-full" dir="ltr" placeholder="180 cm" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.weight') }}</label>
                        <InputText v-model="form.weight" class="w-full" dir="ltr" placeholder="75 kg" />
                    </div>
                </div>
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('common.photo') }}</label>
                    <ImageUploadField v-model="form.photo_path" endpoint="/players/upload" :error="first('photo_path')" />
                </div>
                <label class="flex items-center gap-2 text-sm"><ToggleSwitch v-model="form.is_injured" /> {{ t('matches.injured') }}</label>
            </div>
            <template #footer>
                <Button :label="t('common.cancel')" text severity="secondary" @click="dialog = false" />
                <Button :label="t('common.save')" icon="pi pi-check" :loading="saving" @click="save" />
            </template>
        </Dialog>
    </div>
</template>
