<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import PageHeader from '@admin/components/PageHeader.vue';
import ImageUploadField from '@admin/components/ImageUploadField.vue';
import { bannersApi } from '@admin/api/content';
import { useFormErrors } from '@admin/composables/useFormErrors';

const { t } = useI18n();
const toast = useToast();
const confirm = useConfirm();
const { reset: resetErrors, setFrom, first } = useFormErrors();

const PLACEMENTS = ['home_top', 'home_middle', 'marketplace_top'];
const ACTION_TYPES = ['none', 'url', 'fixture', 'listing', 'club', 'fan_group'];

const banners = ref([]);
const loading = ref(false);
const dialog = ref(false);
const saving = ref(false);
const form = ref(emptyForm());

const placementOptions = computed(() =>
    PLACEMENTS.map((value) => ({ value, label: t(`banners.placements.${value}`) })),
);
const actionOptions = computed(() =>
    ACTION_TYPES.map((value) => ({ value, label: t(`banners.actions.${value}`) })),
);

function emptyForm() {
    return {
        id: null, title_ar: '', title_en: '', image_path: '',
        action_type: 'none', action_value: '', placement: 'home_top',
        position: 0, is_active: true, starts_at: null, ends_at: null,
    };
}

function toastError(e) {
    toast.add({ severity: 'error', summary: t('common.actions'), detail: e?.response?.data?.message || 'Error', life: 4000 });
}

async function load() {
    loading.value = true;
    try {
        const { data } = await bannersApi.list({ per_page: 50 });
        banners.value = data.data;
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
    form.value = {
        ...row,
        starts_at: row.starts_at ? new Date(row.starts_at) : null,
        ends_at: row.ends_at ? new Date(row.ends_at) : null,
    };
    dialog.value = true;
}
async function save() {
    saving.value = true;
    resetErrors();
    try {
        const payload = { ...form.value };
        if (payload.starts_at instanceof Date) {
            payload.starts_at = payload.starts_at.toISOString();
        }
        if (payload.ends_at instanceof Date) {
            payload.ends_at = payload.ends_at.toISOString();
        }
        if (form.value.id) {
            await bannersApi.update(form.value.id, payload);
        } else {
            await bannersApi.create(payload);
        }
        toast.add({ severity: 'success', summary: t('banners.savedOk'), life: 2500 });
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
        message: t('banners.deleteConfirm'),
        header: t('common.delete'),
        icon: 'pi pi-exclamation-triangle',
        rejectLabel: t('common.cancel'),
        acceptLabel: t('common.delete'),
        acceptClass: 'p-button-danger',
        accept: async () => {
            try {
                await bannersApi.remove(row.id);
                toast.add({ severity: 'success', summary: t('banners.deletedOk'), life: 2500 });
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
        <PageHeader :title="t('banners.title')" :subtitle="t('banners.subtitle')" icon="pi pi-image">
            <template #actions>
                <Button :label="t('banners.newBanner')" icon="pi pi-plus" @click="openCreate" />
            </template>
        </PageHeader>

        <div class="rounded-2xl border border-surface-200 bg-surface-0 dark:border-surface-800 dark:bg-surface-900">
            <DataTable :value="banners" :loading="loading" data-key="id" class="text-sm" removable-sort>
                <template #empty>
                    <div class="py-8 text-center text-surface-500">{{ t('common.noData') }}</div>
                </template>
                <Column :header="t('banners.titleAr')">
                    <template #body="{ data }">
                        <span class="font-medium">{{ data.title_ar || data.title_en || '—' }}</span>
                    </template>
                </Column>
                <Column :header="t('banners.placement')">
                    <template #body="{ data }">
                        <Tag :value="t(`banners.placements.${data.placement}`)" severity="secondary" />
                    </template>
                </Column>
                <Column :header="t('banners.actionType')">
                    <template #body="{ data }">
                        {{ t(`banners.actions.${data.action_type}`) }}
                    </template>
                </Column>
                <Column :header="t('banners.position')" field="position" sortable />
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

        <Dialog v-model:visible="dialog" modal :header="form.id ? t('banners.editBanner') : t('banners.newBanner')" :style="{ width: '34rem' }">
            <div class="flex flex-col gap-4 pt-2">
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('banners.titleAr') }}</label>
                        <InputText v-model="form.title_ar" class="w-full" :invalid="!!first('title_ar')" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('banners.titleEn') }}</label>
                        <InputText v-model="form.title_en" class="w-full" dir="ltr" :invalid="!!first('title_en')" />
                    </div>
                </div>
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('banners.image') }}</label>
                    <ImageUploadField v-model="form.image_path" endpoint="/banners/upload" :error="first('image_path')" />
                </div>
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('banners.placement') }}</label>
                        <Select v-model="form.placement" :options="placementOptions" option-label="label" option-value="value" class="w-full" :invalid="!!first('placement')" />
                        <Message v-if="first('placement')" severity="error" size="small" variant="simple">{{ first('placement') }}</Message>
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('banners.position') }}</label>
                        <InputNumber v-model="form.position" class="w-full" :use-grouping="false" :min="0" />
                    </div>
                </div>
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('banners.actionType') }}</label>
                        <Select v-model="form.action_type" :options="actionOptions" option-label="label" option-value="value" class="w-full" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('banners.actionValue') }}</label>
                        <InputText v-model="form.action_value" class="w-full" dir="ltr" :disabled="form.action_type === 'none'" :invalid="!!first('action_value')" />
                    </div>
                </div>
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('banners.startsAt') }}</label>
                        <DatePicker v-model="form.starts_at" show-time hour-format="24" class="w-full" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('banners.endsAt') }}</label>
                        <DatePicker v-model="form.ends_at" show-time hour-format="24" class="w-full" :invalid="!!first('ends_at')" />
                        <Message v-if="first('ends_at')" severity="error" size="small" variant="simple">{{ first('ends_at') }}</Message>
                    </div>
                </div>
                <label class="flex items-center gap-2 text-sm">
                    <ToggleSwitch v-model="form.is_active" /> {{ t('common.active') }}
                </label>
            </div>
            <template #footer>
                <Button :label="t('common.cancel')" text severity="secondary" @click="dialog = false" />
                <Button :label="t('common.save')" icon="pi pi-check" :loading="saving" @click="save" />
            </template>
        </Dialog>
    </div>
</template>
