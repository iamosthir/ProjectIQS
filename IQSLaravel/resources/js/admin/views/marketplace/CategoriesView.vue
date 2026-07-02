<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import PageHeader from '@admin/components/PageHeader.vue';
import ImageUploadField from '@admin/components/ImageUploadField.vue';
import { marketplaceApi } from '@admin/api/marketplace';
import { useFormErrors } from '@admin/composables/useFormErrors';

const { t } = useI18n();
const toast = useToast();
const confirm = useConfirm();
const { reset, setFrom, first } = useFormErrors();

const CURRENCIES = ['IQD', 'USD'];
const rows = ref([]);
const loading = ref(false);
const dialog = ref(false);
const saving = ref(false);
const form = ref(empty());
const schemaText = ref('');

function empty() {
    return { id: null, key: '', parent_id: null, name_ar: '', name_en: '', icon_path: '', base_price: 25000, currency: 'IQD', is_free: false, requires_contact_button: true, listing_duration_days: 30, is_active: true };
}
function toastErr(e) { toast.add({ severity: 'error', summary: t('common.actions'), detail: e?.response?.data?.message || 'Error', life: 4000 }); }
const parentOptions = computed(() => [{ id: null, label: '—' }, ...rows.value.map((c) => ({ id: c.id, label: c.name_en || c.name_ar }))]);

async function load() {
    loading.value = true;
    try { const { data } = await marketplaceApi.categories(); rows.value = data.data; }
    catch (e) { toastErr(e); } finally { loading.value = false; }
}
function openCreate() { reset(); form.value = empty(); schemaText.value = '{\n  "fields": [],\n  "media": { "image": 6, "video": 1, "document": 1 }\n}'; dialog.value = true; }
function openEdit(r) { reset(); form.value = { ...empty(), ...r }; schemaText.value = JSON.stringify(r.field_schema ?? {}, null, 2); dialog.value = true; }
async function save() {
    saving.value = true; reset();
    try {
        const payload = { ...form.value };
        try { payload.field_schema = schemaText.value ? JSON.parse(schemaText.value) : null; }
        catch { toast.add({ severity: 'warn', summary: t('marketplace.invalidSchema'), life: 3000 }); saving.value = false; return; }
        if (form.value.id) await marketplaceApi.updateCategory(form.value.id, payload);
        else await marketplaceApi.createCategory(payload);
        toast.add({ severity: 'success', summary: t('common.save'), life: 2500 });
        dialog.value = false; await load();
    } catch (e) { if (!setFrom(e)) toastErr(e); } finally { saving.value = false; }
}
function del(r) {
    confirm.require({
        message: t('marketplace.deleteCategoryConfirm'), header: t('common.delete'), icon: 'pi pi-exclamation-triangle',
        rejectLabel: t('common.cancel'), acceptLabel: t('common.delete'), acceptClass: 'p-button-danger',
        accept: async () => { try { await marketplaceApi.deleteCategory(r.id); await load(); } catch (e) { toastErr(e); } },
    });
}
onMounted(load);
</script>

<template>
    <div>
        <PageHeader :title="t('marketplace.categories')" :subtitle="t('marketplace.categoriesSubtitle')" icon="pi pi-tags">
            <template #actions><Button :label="t('marketplace.newCategory')" icon="pi pi-plus" @click="openCreate" /></template>
        </PageHeader>

        <div class="rounded-2xl border border-surface-200 bg-surface-0 dark:border-surface-800 dark:bg-surface-900">
            <DataTable :value="rows" :loading="loading" data-key="id" class="text-sm" row-group-mode="none">
                <template #empty><div class="py-8 text-center text-surface-500">{{ t('common.noData') }}</div></template>
                <Column :header="t('common.name')">
                    <template #body="{ data }">
                        <span :class="data.parent_id && 'ms-4'">{{ data.name_ar }}</span>
                        <span class="block text-xs text-surface-500" dir="ltr">{{ data.key }}</span>
                    </template>
                </Column>
                <Column :header="t('marketplace.price')">
                    <template #body="{ data }">
                        <span v-if="data.is_free" class="text-emerald-600">{{ t('marketplace.free') }}</span>
                        <span v-else dir="ltr">{{ Number(data.base_price).toLocaleString() }} {{ data.currency }}</span>
                    </template>
                </Column>
                <Column :header="t('marketplace.contactMode')">
                    <template #body="{ data }"><Tag :value="data.requires_contact_button ? t('marketplace.contact') : t('marketplace.commission')" severity="secondary" /></template>
                </Column>
                <Column :header="t('marketplace.listings')" field="listings_count" />
                <Column :header="t('common.status')">
                    <template #body="{ data }"><Tag :value="data.is_active ? t('common.active') : t('common.inactive')" :severity="data.is_active ? 'success' : 'secondary'" /></template>
                </Column>
                <Column :header="t('common.actions')" :style="{ width: '7rem' }">
                    <template #body="{ data }">
                        <Button icon="pi pi-pencil" text rounded size="small" severity="secondary" @click="openEdit(data)" />
                        <Button icon="pi pi-trash" text rounded size="small" severity="danger" @click="del(data)" />
                    </template>
                </Column>
            </DataTable>
        </div>

        <Dialog v-model:visible="dialog" modal :header="form.id ? t('marketplace.editCategory') : t('marketplace.newCategory')" :style="{ width: '40rem' }">
            <div class="flex flex-col gap-4 pt-2">
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('marketplace.key') }}</label>
                        <InputText v-model="form.key" class="w-full" dir="ltr" :invalid="!!first('key')" />
                        <Message v-if="first('key')" severity="error" size="small" variant="simple">{{ first('key') }}</Message>
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('marketplace.parent') }}</label>
                        <Select v-model="form.parent_id" :options="parentOptions" option-label="label" option-value="id" class="w-full" />
                    </div>
                </div>
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.nameAr') }}</label>
                        <InputText v-model="form.name_ar" class="w-full" :invalid="!!first('name_ar')" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.nameEn') }}</label>
                        <InputText v-model="form.name_en" class="w-full" dir="ltr" :invalid="!!first('name_en')" />
                    </div>
                </div>
                <div>
                    <ImageUploadField v-model="form.icon_path" endpoint="/marketplace/categories/upload" :label="t('common.icon')" :error="first('icon_path')" />
                </div>
                <div class="grid grid-cols-3 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('marketplace.price') }}</label>
                        <InputNumber v-model="form.base_price" class="w-full" :min="0" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('payments.amount') }}</label>
                        <Select v-model="form.currency" :options="CURRENCIES" class="w-full" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('marketplace.durationDays') }}</label>
                        <InputNumber v-model="form.listing_duration_days" class="w-full" :min="1" />
                    </div>
                </div>
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('marketplace.fieldSchema') }}</label>
                    <Textarea v-model="schemaText" rows="6" class="w-full font-mono text-xs" dir="ltr" />
                </div>
                <div class="flex flex-wrap gap-4">
                    <label class="flex items-center gap-2 text-sm"><ToggleSwitch v-model="form.is_free" /> {{ t('marketplace.free') }}</label>
                    <label class="flex items-center gap-2 text-sm"><ToggleSwitch v-model="form.requires_contact_button" /> {{ t('marketplace.showContactBtn') }}</label>
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
