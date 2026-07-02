<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import PageHeader from '@admin/components/PageHeader.vue';
import ImageUploadField from '@admin/components/ImageUploadField.vue';
import { matchesApi } from '@admin/api/matches';
import { countryOptions, findByEnglishName, flagUrl } from '@admin/config/countries';
import { useFormErrors } from '@admin/composables/useFormErrors';

const { t, locale } = useI18n();
const toast = useToast();
const confirm = useConfirm();
const { reset, setFrom, first } = useFormErrors();

const rows = ref([]);
const loading = ref(false);
const search = ref('');
const dialog = ref(false);
const saving = ref(false);
const form = ref(empty());

// Country picker (localized names + flagcdn thumbnails). `country` is a
// UI-only field; saving maps it to the stored English `country_name`.
const countries = computed(() => countryOptions(locale.value));
const country = ref(null);

function empty() {
    return { id: null, name_ar: '', name_en: '', short_code: '', country_name: 'Iraq', founded_year: null, is_national: false, logo_path: '', is_active: true };
}
function toastErr(e) { toast.add({ severity: 'error', summary: t('common.actions'), detail: e?.response?.data?.message || 'Error', life: 4000 }); }
function logoUrl(p) { return /^https?:\/\//.test(p) ? p : `/storage/${p}`; }
async function load() {
    loading.value = true;
    try { const { data } = await matchesApi.teams({ 'filter[search]': search.value || undefined, per_page: 50 }); rows.value = data.data; }
    catch (e) { toastErr(e); } finally { loading.value = false; }
}
function onCountryChange(opt) {
    form.value.country_name = opt?.en || '';
    // National teams get the country flag automatically when no logo is set.
    if (opt && form.value.is_national && !form.value.logo_path) useCountryFlag();
}
function useCountryFlag() {
    if (country.value) form.value.logo_path = flagUrl(country.value.code);
}
function openCreate() {
    reset();
    form.value = empty();
    country.value = findByEnglishName(countries.value, form.value.country_name);
    dialog.value = true;
}
function openEdit(r) {
    reset();
    form.value = { ...empty(), ...r };
    country.value = findByEnglishName(countries.value, r.country_name);
    dialog.value = true;
}
async function save() {
    saving.value = true; reset();
    try {
        if (form.value.id) await matchesApi.updateTeam(form.value.id, form.value);
        else await matchesApi.createTeam(form.value);
        toast.add({ severity: 'success', summary: t('common.save'), life: 2500 });
        dialog.value = false; await load();
    } catch (e) { if (!setFrom(e)) toastErr(e); } finally { saving.value = false; }
}
async function toggleLock(r) { try { await matchesApi.toggleTeamLock(r.id); await load(); } catch (e) { toastErr(e); } }
function del(r) {
    confirm.require({
        message: t('matches.deleteTeamConfirm'), header: t('common.delete'), icon: 'pi pi-exclamation-triangle',
        rejectLabel: t('common.cancel'), acceptLabel: t('common.delete'), acceptClass: 'p-button-danger',
        accept: async () => { try { await matchesApi.deleteTeam(r.id); await load(); } catch (e) { toastErr(e); } },
    });
}
onMounted(load);
</script>

<template>
    <div>
        <PageHeader :title="t('matches.teams')" :subtitle="t('matches.teamsSubtitle')" icon="pi pi-shield">
            <template #actions><Button :label="t('matches.newTeam')" icon="pi pi-plus" @click="openCreate" /></template>
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
                        <div class="flex items-center gap-3">
                            <img v-if="data.logo_path" :src="logoUrl(data.logo_path)" alt="" class="h-8 w-8 rounded-full object-cover" />
                            <div>
                                <p class="font-medium text-surface-800 dark:text-surface-100">{{ data.name_ar }}</p>
                                <p class="text-xs text-surface-500" dir="ltr">{{ data.name_en }}</p>
                            </div>
                        </div>
                    </template>
                </Column>
                <Column :header="t('matches.shortCode')" field="short_code" />
                <Column :header="t('fixtures.source')">
                    <template #body="{ data }">
                        <Tag :value="data.source" :severity="data.source === 'manual' ? 'info' : 'secondary'" />
                        <Tag v-if="data.is_national" value="NT" severity="contrast" class="ms-1" />
                        <Tag v-if="data.is_locked" value="locked" severity="warn" class="ms-1" />
                    </template>
                </Column>
                <Column :header="t('common.actions')" :style="{ width: '9rem' }">
                    <template #body="{ data }">
                        <Button v-if="data.source === 'api_football'" :icon="data.is_locked ? 'pi pi-lock' : 'pi pi-lock-open'" text rounded size="small" severity="warn" @click="toggleLock(data)" />
                        <Button icon="pi pi-pencil" text rounded size="small" severity="secondary" @click="openEdit(data)" />
                        <Button icon="pi pi-trash" text rounded size="small" severity="danger" @click="del(data)" />
                    </template>
                </Column>
            </DataTable>
        </div>

        <Dialog v-model:visible="dialog" modal :header="form.id ? t('matches.editTeam') : t('matches.newTeam')" :style="{ width: '32rem' }">
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
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.shortCode') }}</label>
                        <InputText v-model="form.short_code" class="w-full" dir="ltr" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.foundedYear') }}</label>
                        <InputNumber v-model="form.founded_year" class="w-full" :use-grouping="false" />
                    </div>
                </div>
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('matches.country') }}</label>
                    <Select v-model="country" :options="countries" option-label="label" filter reset-filter-on-hide :placeholder="t('matches.selectCountry')" class="w-full" @change="(e) => onCountryChange(e.value)">
                        <template #option="{ option }">
                            <div class="flex items-center gap-2">
                                <img :src="option.flag" alt="" class="h-4 w-6 rounded-sm object-cover" />
                                <span>{{ option.label }}</span>
                            </div>
                        </template>
                        <template #value="{ value, placeholder }">
                            <div v-if="value" class="flex items-center gap-2">
                                <img :src="value.flag" alt="" class="h-4 w-6 rounded-sm object-cover" />
                                <span>{{ value.label }}</span>
                            </div>
                            <span v-else>{{ placeholder }}</span>
                        </template>
                    </Select>
                </div>
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('common.logo') }}</label>
                    <ImageUploadField v-model="form.logo_path" endpoint="/teams/upload" :error="first('logo_path')" />
                    <Button v-if="country" :label="t('matches.useCountryFlag')" icon="pi pi-flag" text size="small" class="mt-1" @click="useCountryFlag" />
                </div>
                <div class="flex gap-4">
                    <label class="flex items-center gap-2 text-sm"><ToggleSwitch v-model="form.is_national" /> {{ t('matches.nationalTeam') }}</label>
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
