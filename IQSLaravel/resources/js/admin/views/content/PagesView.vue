<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import PageHeader from '@admin/components/PageHeader.vue';
import { pagesApi } from '@admin/api/content';
import { useFormErrors } from '@admin/composables/useFormErrors';

const { t } = useI18n();
const toast = useToast();
const confirm = useConfirm();
const { reset: resetErrors, setFrom, first } = useFormErrors();

const pages = ref([]);
const loading = ref(false);
const dialog = ref(false);
const saving = ref(false);
const form = ref(emptyForm());

function emptyForm() {
    return {
        id: null, slug: '', title_ar: '', title_en: '',
        content_ar: '', content_en: '', is_active: true,
    };
}

function toastError(e) {
    toast.add({ severity: 'error', summary: t('common.actions'), detail: e?.response?.data?.message || 'Error', life: 4000 });
}

async function load() {
    loading.value = true;
    try {
        const { data } = await pagesApi.list({ per_page: 50 });
        pages.value = data.data;
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
    form.value = { ...row };
    dialog.value = true;
}
async function save() {
    saving.value = true;
    resetErrors();
    try {
        if (form.value.id) {
            await pagesApi.update(form.value.id, form.value);
        } else {
            await pagesApi.create(form.value);
        }
        toast.add({ severity: 'success', summary: t('pages.savedOk'), life: 2500 });
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
        message: t('pages.deleteConfirm'),
        header: t('common.delete'),
        icon: 'pi pi-exclamation-triangle',
        rejectLabel: t('common.cancel'),
        acceptLabel: t('common.delete'),
        acceptClass: 'p-button-danger',
        accept: async () => {
            try {
                await pagesApi.remove(row.id);
                toast.add({ severity: 'success', summary: t('pages.deletedOk'), life: 2500 });
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
        <PageHeader :title="t('pages.title')" :subtitle="t('pages.subtitle')" icon="pi pi-file-edit">
            <template #actions>
                <Button :label="t('pages.newPage')" icon="pi pi-plus" @click="openCreate" />
            </template>
        </PageHeader>

        <div class="rounded-2xl border border-surface-200 bg-surface-0 dark:border-surface-800 dark:bg-surface-900">
            <DataTable :value="pages" :loading="loading" data-key="id" class="text-sm" removable-sort>
                <template #empty>
                    <div class="py-8 text-center text-surface-500">{{ t('common.noData') }}</div>
                </template>
                <Column :header="t('pages.slug')" field="slug" sortable>
                    <template #body="{ data }">
                        <code class="text-xs" dir="ltr">{{ data.slug }}</code>
                    </template>
                </Column>
                <Column :header="t('pages.titleAr')" field="title_ar" />
                <Column :header="t('pages.titleEn')">
                    <template #body="{ data }">
                        <span dir="ltr">{{ data.title_en }}</span>
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

        <Dialog v-model:visible="dialog" modal :header="form.id ? t('pages.editPage') : t('pages.newPage')" :style="{ width: '40rem' }">
            <div class="flex flex-col gap-4 pt-2">
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('pages.slug') }}</label>
                    <InputText v-model="form.slug" class="w-full" dir="ltr" :invalid="!!first('slug')" />
                    <Message v-if="first('slug')" severity="error" size="small" variant="simple">{{ first('slug') }}</Message>
                </div>
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('pages.titleAr') }}</label>
                        <InputText v-model="form.title_ar" class="w-full" :invalid="!!first('title_ar')" />
                        <Message v-if="first('title_ar')" severity="error" size="small" variant="simple">{{ first('title_ar') }}</Message>
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('pages.titleEn') }}</label>
                        <InputText v-model="form.title_en" class="w-full" dir="ltr" :invalid="!!first('title_en')" />
                        <Message v-if="first('title_en')" severity="error" size="small" variant="simple">{{ first('title_en') }}</Message>
                    </div>
                </div>
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('pages.contentAr') }}</label>
                    <Textarea v-model="form.content_ar" rows="5" auto-resize class="w-full" :invalid="!!first('content_ar')" />
                    <Message v-if="first('content_ar')" severity="error" size="small" variant="simple">{{ first('content_ar') }}</Message>
                </div>
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('pages.contentEn') }}</label>
                    <Textarea v-model="form.content_en" rows="5" auto-resize class="w-full" dir="ltr" :invalid="!!first('content_en')" />
                    <Message v-if="first('content_en')" severity="error" size="small" variant="simple">{{ first('content_en') }}</Message>
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
