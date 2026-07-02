<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import PageHeader from '@admin/components/PageHeader.vue';
import { settingsApi } from '@admin/api/settings';
import { useFormErrors } from '@admin/composables/useFormErrors';

const { t } = useI18n();
const toast = useToast();
const confirm = useConfirm();
const { reset: resetErrors, setFrom, first } = useFormErrors();

const TYPES = ['string', 'integer', 'boolean', 'json'];

const settings = ref([]);
const loading = ref(false);
const savingId = ref(null);
const dialog = ref(false);
const saving = ref(false);
const form = ref(emptyForm());

function emptyForm() {
    return { group: '', key: '', type: 'string', value: '', is_public: false };
}

function toastError(e) {
    toast.add({ severity: 'error', summary: t('common.actions'), detail: e?.response?.data?.message || 'Error', life: 4000 });
}

async function load() {
    loading.value = true;
    try {
        const { data } = await settingsApi.list();
        settings.value = data.data.map((s) => ({ ...s, _value: jsonAware(s) }));
    } catch (e) {
        toastError(e);
    } finally {
        loading.value = false;
    }
}

// JSON values are edited as a string in the table.
function jsonAware(s) {
    return s.type === 'json' ? JSON.stringify(s.value) : s.value;
}

async function saveRow(row) {
    savingId.value = row.id;
    try {
        const value = row.type === 'json' ? JSON.parse(row._value) : row._value;
        const { data } = await settingsApi.update(row.id, { value, is_public: row.is_public });
        Object.assign(row, data.data, { _value: jsonAware(data.data) });
        toast.add({ severity: 'success', summary: t('settings.savedOk'), life: 2500 });
    } catch (e) {
        toastError(e);
    } finally {
        savingId.value = null;
    }
}

function openCreate() {
    resetErrors();
    form.value = emptyForm();
    dialog.value = true;
}
async function create() {
    saving.value = true;
    resetErrors();
    try {
        const value = form.value.type === 'json' ? JSON.parse(form.value.value || 'null') : form.value.value;
        await settingsApi.create({ ...form.value, value });
        toast.add({ severity: 'success', summary: t('settings.savedOk'), life: 2500 });
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
        message: t('settings.deleteConfirm'),
        header: t('common.delete'),
        icon: 'pi pi-exclamation-triangle',
        rejectLabel: t('common.cancel'),
        acceptLabel: t('common.delete'),
        acceptClass: 'p-button-danger',
        accept: async () => {
            try {
                await settingsApi.remove(row.id);
                toast.add({ severity: 'success', summary: t('settings.deletedOk'), life: 2500 });
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
        <PageHeader :title="t('settings.title')" :subtitle="t('settings.subtitle')" icon="pi pi-cog">
            <template #actions>
                <Button :label="t('settings.newSetting')" icon="pi pi-plus" @click="openCreate" />
            </template>
        </PageHeader>

        <div class="rounded-2xl border border-surface-200 bg-surface-0 dark:border-surface-800 dark:bg-surface-900">
            <DataTable :value="settings" :loading="loading" data-key="id" row-group-mode="subheader" group-rows-by="group" sort-field="group" :sort-order="1" class="text-sm">
                <template #empty>
                    <div class="py-8 text-center text-surface-500">{{ t('common.noData') }}</div>
                </template>
                <template #groupheader="{ data }">
                    <span class="font-semibold uppercase tracking-wide text-emerald-600 dark:text-emerald-400">{{ data.group }}</span>
                </template>
                <Column :header="t('settings.key')" field="key" :style="{ width: '18rem' }">
                    <template #body="{ data }">
                        <span class="font-medium text-surface-800 dark:text-surface-100">{{ data.key }}</span>
                        <Tag :value="data.type" severity="secondary" class="ms-2" />
                    </template>
                </Column>
                <Column :header="t('settings.value')">
                    <template #body="{ data }">
                        <ToggleSwitch v-if="data.type === 'boolean'" v-model="data._value" />
                        <InputNumber v-else-if="data.type === 'integer'" v-model="data._value" class="w-40" :use-grouping="false" />
                        <Textarea v-else-if="data.type === 'json'" v-model="data._value" rows="1" auto-resize class="w-full font-mono text-xs" dir="ltr" />
                        <InputText v-else v-model="data._value" class="w-full" />
                    </template>
                </Column>
                <Column :header="t('settings.isPublic')" :style="{ width: '7rem' }">
                    <template #body="{ data }">
                        <ToggleSwitch v-model="data.is_public" />
                    </template>
                </Column>
                <Column :style="{ width: '6rem' }">
                    <template #body="{ data }">
                        <Button icon="pi pi-check" text rounded size="small" :loading="savingId === data.id" @click="saveRow(data)" />
                        <Button icon="pi pi-trash" text rounded size="small" severity="danger" @click="confirmDelete(data)" />
                    </template>
                </Column>
            </DataTable>
        </div>

        <Dialog v-model:visible="dialog" modal :header="t('settings.newSetting')" :style="{ width: '30rem' }">
            <div class="flex flex-col gap-4 pt-2">
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('settings.group') }}</label>
                        <InputText v-model="form.group" class="w-full" :invalid="!!first('group')" />
                        <Message v-if="first('group')" severity="error" size="small" variant="simple">{{ first('group') }}</Message>
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('settings.key') }}</label>
                        <InputText v-model="form.key" class="w-full" :invalid="!!first('key')" />
                        <Message v-if="first('key')" severity="error" size="small" variant="simple">{{ first('key') }}</Message>
                    </div>
                </div>
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('settings.type') }}</label>
                    <Select v-model="form.type" :options="TYPES" class="w-full" />
                </div>
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('settings.value') }}</label>
                    <InputText v-model="form.value" class="w-full" />
                </div>
                <label class="flex items-center gap-2 text-sm">
                    <ToggleSwitch v-model="form.is_public" /> {{ t('settings.isPublic') }}
                </label>
            </div>
            <template #footer>
                <Button :label="t('common.cancel')" text severity="secondary" @click="dialog = false" />
                <Button :label="t('common.create')" icon="pi pi-check" :loading="saving" @click="create" />
            </template>
        </Dialog>
    </div>
</template>
