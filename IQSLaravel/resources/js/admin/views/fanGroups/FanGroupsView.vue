<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import PageHeader from '@admin/components/PageHeader.vue';
import ImageUploadField from '@admin/components/ImageUploadField.vue';
import { fanGroupsApi } from '@admin/api/fanGroups';
import { clubsApi } from '@admin/api/clubs';
import { useFormErrors } from '@admin/composables/useFormErrors';

const { t } = useI18n();
const router = useRouter();
const toast = useToast();
const confirm = useConfirm();
const { reset, setFrom, first } = useFormErrors();

const STATUSES = ['pending', 'active', 'suspended'];
const rows = ref([]);
const clubs = ref([]);
const loading = ref(false);
const search = ref('');
const dialog = ref(false);
const saving = ref(false);
const form = ref(empty());

function empty() {
    return { id: null, name_ar: '', name_en: '', club_id: null, governorate: '', city: '', founded_year: null, managed_by: null, group_logo_path: '', club_logo_path: '', cover_path: '', description_ar: '', description_en: '', phone: '', facebook: '', instagram: '', is_official: false, status: 'active', is_active: true };
}
function toastErr(e) { toast.add({ severity: 'error', summary: t('common.actions'), detail: e?.response?.data?.message || 'Error', life: 4000 }); }
const clubOptions = computed(() => [{ id: null, label: '—' }, ...clubs.value.map((c) => ({ id: c.id, label: c.name_ar || c.name_en }))]);

async function load() {
    loading.value = true;
    try { const { data } = await fanGroupsApi.list({ 'filter[search]': search.value || undefined, per_page: 50 }); rows.value = data.data; }
    catch (e) { toastErr(e); } finally { loading.value = false; }
}
async function loadClubs() { try { const { data } = await clubsApi.list({ per_page: 100 }); clubs.value = data.data; } catch { /* ignore */ } }
function openCreate() { reset(); form.value = empty(); dialog.value = true; }
function openEdit(r) { reset(); form.value = { ...empty(), ...r }; dialog.value = true; }
async function save() {
    saving.value = true; reset();
    try {
        if (form.value.id) await fanGroupsApi.update(form.value.id, form.value);
        else await fanGroupsApi.create(form.value);
        toast.add({ severity: 'success', summary: t('common.save'), life: 2500 });
        dialog.value = false; await load();
    } catch (e) { if (!setFrom(e)) toastErr(e); } finally { saving.value = false; }
}
async function verify(r) { try { await fanGroupsApi.verify(r.id); await load(); } catch (e) { toastErr(e); } }
function del(r) {
    confirm.require({
        message: t('fanGroups.deleteConfirm'), header: t('common.delete'), icon: 'pi pi-exclamation-triangle',
        rejectLabel: t('common.cancel'), acceptLabel: t('common.delete'), acceptClass: 'p-button-danger',
        accept: async () => { try { await fanGroupsApi.remove(r.id); await load(); } catch (e) { toastErr(e); } },
    });
}
function openContent(r) { router.push({ name: 'fan-group-content', params: { id: r.id } }); }
onMounted(() => { load(); loadClubs(); });
</script>

<template>
    <div>
        <PageHeader :title="t('fanGroups.title')" :subtitle="t('fanGroups.subtitle')" icon="pi pi-megaphone">
            <template #actions><Button :label="t('fanGroups.newGroup')" icon="pi pi-plus" @click="openCreate" /></template>
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
                        <p class="font-medium">{{ data.name_ar }}</p>
                        <p class="text-xs text-surface-500">{{ data.governorate }} · {{ data.media_count }} {{ t('fanGroups.media') }} · {{ data.chants_count }} {{ t('fanGroups.chants') }}</p>
                    </template>
                </Column>
                <Column :header="t('fanGroups.official')">
                    <template #body="{ data }"><Tag v-if="data.is_official" :value="t('fanGroups.official')" severity="contrast" /><span v-else class="text-surface-300">—</span></template>
                </Column>
                <Column :header="t('clubs.verified')">
                    <template #body="{ data }"><i :class="data.is_verified ? 'pi pi-verified text-emerald-500' : 'pi pi-minus text-surface-300'"></i></template>
                </Column>
                <Column :header="t('common.actions')" :style="{ width: '14rem' }">
                    <template #body="{ data }">
                        <Button :label="t('fanGroups.archives')" icon="pi pi-images" size="small" outlined @click="openContent(data)" />
                        <Button v-if="!data.is_verified" icon="pi pi-verified" text rounded size="small" severity="success" v-tooltip.bottom="t('clubs.verify')" @click="verify(data)" />
                        <Button icon="pi pi-pencil" text rounded size="small" severity="secondary" @click="openEdit(data)" />
                        <Button icon="pi pi-trash" text rounded size="small" severity="danger" @click="del(data)" />
                    </template>
                </Column>
            </DataTable>
        </div>

        <Dialog v-model:visible="dialog" modal :header="form.id ? t('fanGroups.editGroup') : t('fanGroups.newGroup')" :style="{ width: '40rem' }">
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
                    </div>
                </div>
                <div class="grid grid-cols-3 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('fanGroups.affiliatedClub') }}</label>
                        <Select v-model="form.club_id" :options="clubOptions" option-label="label" option-value="id" filter class="w-full" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('users.governorate') }}</label>
                        <InputText v-model="form.governorate" class="w-full" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('clubs.foundedYear') }}</label>
                        <InputNumber v-model="form.founded_year" class="w-full" :use-grouping="false" />
                    </div>
                </div>
                <div class="grid grid-cols-3 gap-3">
                    <InputNumber v-model="form.managed_by" :placeholder="t('clubs.managerUserId')" class="w-full" :use-grouping="false" />
                    <InputText v-model="form.phone" :placeholder="t('common.phone')" class="w-full" dir="ltr" />
                    <InputText v-model="form.facebook" placeholder="Facebook" class="w-full" dir="ltr" />
                </div>
                <div class="grid grid-cols-3 gap-3">
                    <ImageUploadField v-model="form.group_logo_path" endpoint="/fan-groups/upload" :label="t('common.groupLogo')" :error="first('group_logo_path')" />
                    <ImageUploadField v-model="form.club_logo_path" endpoint="/fan-groups/upload" :label="t('common.clubLogo')" :error="first('club_logo_path')" />
                    <ImageUploadField v-model="form.cover_path" endpoint="/fan-groups/upload" :label="t('common.cover')" :error="first('cover_path')" />
                </div>
                <div class="flex flex-wrap gap-4">
                    <label class="flex items-center gap-2 text-sm"><ToggleSwitch v-model="form.is_official" /> {{ t('fanGroups.official') }}</label>
                    <div class="flex items-center gap-2">
                        <span class="text-sm">{{ t('common.status') }}:</span>
                        <Select v-model="form.status" :options="STATUSES" class="w-40" />
                    </div>
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
