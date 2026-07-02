<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import PageHeader from '@admin/components/PageHeader.vue';
import { appVersionsApi } from '@admin/api/appVersions';
import { useFormErrors } from '@admin/composables/useFormErrors';

const { t } = useI18n();
const toast = useToast();
const confirm = useConfirm();
const { reset: resetErrors, setFrom, first } = useFormErrors();

const PLATFORMS = ['android', 'ios'];

const versions = ref([]);
const loading = ref(false);
const dialog = ref(false);
const saving = ref(false);
const form = ref(emptyForm());

function emptyForm() {
    return {
        id: null, platform: 'android', version: '', build_number: 1, min_supported_version: '',
        is_force_update: false, is_active: true, store_url: '', changelog_ar: '', changelog_en: '', released_at: null,
    };
}

function toastError(e) {
    toast.add({ severity: 'error', summary: t('common.actions'), detail: e?.response?.data?.message || 'Error', life: 4000 });
}

async function load() {
    loading.value = true;
    try {
        const { data } = await appVersionsApi.list({ per_page: 50 });
        versions.value = data.data;
    } catch (e) {
        toastError(e);
    } finally {
        loading.value = false;
    }
}

function openCreate() {
    resetErrors();
    form.value = emptyForm();
    dialog.value = true;
}
function openEdit(row) {
    resetErrors();
    form.value = { ...row, released_at: row.released_at ? new Date(row.released_at) : null };
    dialog.value = true;
}
async function save() {
    saving.value = true;
    resetErrors();
    try {
        const payload = { ...form.value };
        if (payload.released_at instanceof Date) {
            payload.released_at = payload.released_at.toISOString();
        }
        if (form.value.id) {
            await appVersionsApi.update(form.value.id, payload);
        } else {
            await appVersionsApi.create(payload);
        }
        toast.add({ severity: 'success', summary: t('appVersions.savedOk'), life: 2500 });
        dialog.value = false;
        await load();
    } catch (e) {
        if (!setFrom(e)) toastError(e);
    } finally {
        saving.value = false;
    }
}
function confirmDelete(row) {
    confirm.require({
        message: t('appVersions.deleteConfirm'),
        header: t('common.delete'),
        icon: 'pi pi-exclamation-triangle',
        rejectLabel: t('common.cancel'),
        acceptLabel: t('common.delete'),
        acceptClass: 'p-button-danger',
        accept: async () => {
            try {
                await appVersionsApi.remove(row.id);
                toast.add({ severity: 'success', summary: t('appVersions.deletedOk'), life: 2500 });
                await load();
            } catch (e) {
                toastError(e);
            }
        },
    });
}

onMounted(load);
</script>

<template>
    <div>
        <PageHeader :title="t('appVersions.title')" :subtitle="t('appVersions.subtitle')" icon="pi pi-mobile">
            <template #actions>
                <Button :label="t('appVersions.newVersion')" icon="pi pi-plus" @click="openCreate" />
            </template>
        </PageHeader>

        <div class="rounded-2xl border border-surface-200 bg-surface-0 dark:border-surface-800 dark:bg-surface-900">
            <DataTable :value="versions" :loading="loading" data-key="id" class="text-sm" removable-sort>
                <template #empty>
                    <div class="py-8 text-center text-surface-500">{{ t('common.noData') }}</div>
                </template>
                <Column :header="t('appVersions.platform')" field="platform" sortable>
                    <template #body="{ data }">
                        <Tag :value="data.platform" :icon="data.platform === 'ios' ? 'pi pi-apple' : 'pi pi-android'" severity="secondary" />
                    </template>
                </Column>
                <Column :header="t('appVersions.version')" field="version" sortable />
                <Column :header="t('appVersions.buildNumber')" field="build_number" sortable />
                <Column :header="t('appVersions.minSupported')" field="min_supported_version" />
                <Column :header="t('appVersions.forceUpdate')">
                    <template #body="{ data }">
                        <Tag v-if="data.is_force_update" :value="t('common.yes')" severity="danger" />
                        <span v-else class="text-surface-400">{{ t('common.no') }}</span>
                    </template>
                </Column>
                <Column :header="t('common.status')">
                    <template #body="{ data }">
                        <Tag :value="data.is_active ? t('common.active') : t('common.inactive')" :severity="data.is_active ? 'success' : 'secondary'" />
                    </template>
                </Column>
                <Column :header="t('common.actions')" :style="{ width: '7rem' }">
                    <template #body="{ data }">
                        <Button icon="pi pi-pencil" text rounded size="small" severity="secondary" @click="openEdit(data)" />
                        <Button icon="pi pi-trash" text rounded size="small" severity="danger" @click="confirmDelete(data)" />
                    </template>
                </Column>
            </DataTable>
        </div>

        <Dialog v-model:visible="dialog" modal :header="form.id ? t('appVersions.editVersion') : t('appVersions.newVersion')" :style="{ width: '34rem' }">
            <div class="flex flex-col gap-4 pt-2">
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('appVersions.platform') }}</label>
                        <Select v-model="form.platform" :options="PLATFORMS" class="w-full" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('appVersions.version') }}</label>
                        <InputText v-model="form.version" class="w-full" dir="ltr" :invalid="!!first('version')" />
                        <Message v-if="first('version')" severity="error" size="small" variant="simple">{{ first('version') }}</Message>
                    </div>
                </div>
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('appVersions.buildNumber') }}</label>
                        <InputNumber v-model="form.build_number" class="w-full" :use-grouping="false" :invalid="!!first('build_number')" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('appVersions.minSupported') }}</label>
                        <InputText v-model="form.min_supported_version" class="w-full" dir="ltr" :invalid="!!first('min_supported_version')" />
                    </div>
                </div>
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('appVersions.storeUrl') }}</label>
                    <InputText v-model="form.store_url" class="w-full" dir="ltr" :invalid="!!first('store_url')" />
                    <Message v-if="first('store_url')" severity="error" size="small" variant="simple">{{ first('store_url') }}</Message>
                </div>
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('appVersions.changelogAr') }}</label>
                    <Textarea v-model="form.changelog_ar" rows="2" auto-resize class="w-full" />
                </div>
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('appVersions.changelogEn') }}</label>
                    <Textarea v-model="form.changelog_en" rows="2" auto-resize class="w-full" dir="ltr" />
                </div>
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('appVersions.releasedAt') }}</label>
                        <DatePicker v-model="form.released_at" show-time hour-format="24" class="w-full" />
                    </div>
                    <div class="flex flex-col justify-end gap-2 pb-1">
                        <label class="flex items-center gap-2 text-sm">
                            <ToggleSwitch v-model="form.is_force_update" /> {{ t('appVersions.forceUpdate') }}
                        </label>
                        <label class="flex items-center gap-2 text-sm">
                            <ToggleSwitch v-model="form.is_active" /> {{ t('common.active') }}
                        </label>
                    </div>
                </div>
            </div>
            <template #footer>
                <Button :label="t('common.cancel')" text severity="secondary" @click="dialog = false" />
                <Button :label="t('common.save')" icon="pi pi-check" :loading="saving" @click="save" />
            </template>
        </Dialog>
    </div>
</template>
