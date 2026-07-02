<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import PageHeader from '@admin/components/PageHeader.vue';
import ImageUploadField from '@admin/components/ImageUploadField.vue';
import { clubsApi } from '@admin/api/clubs';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const toast = useToast();
const confirm = useConfirm();

const id = Number(route.params.id);
const club = ref(null);
const loading = ref(false);

// type → field definitions (rendered dynamically in the dialog).
const TYPES = {
    board: { titleKey: 'clubs.board', listKey: 'board', fields: [['name_ar', 'text'], ['name_en', 'text'], ['position_ar', 'text'], ['position_en', 'text']], cols: ['name_ar', 'position_en'] },
    staff: { titleKey: 'clubs.staff', listKey: 'staff', fields: [['name_ar', 'text'], ['name_en', 'text'], ['role_ar', 'text'], ['role_en', 'text'], ['type', 'select', ['coaching', 'technical', 'medical', 'admin']]], cols: ['name_ar', 'type'] },
    titles: { titleKey: 'clubs.titles', listKey: 'titles', fields: [['title_ar', 'text'], ['title_en', 'text'], ['season', 'text'], ['year', 'number'], ['count', 'number']], cols: ['title_ar', 'year'] },
    captains: { titleKey: 'clubs.captains', listKey: 'captains', fields: [['name_ar', 'text'], ['name_en', 'text'], ['period_from', 'number'], ['period_to', 'number']], cols: ['name_ar', 'period_from'] },
    competitions: { titleKey: 'clubs.competitions', listKey: 'competitions', fields: [['name_ar', 'text'], ['name_en', 'text'], ['season', 'text'], ['status', 'select', ['active', 'past']]], cols: ['name_en', 'status'] },
};

const dialog = ref(false);
const activeType = ref('board');
const form = ref({});
const editingId = ref(null);
const saving = ref(false);

// News
const newsDialog = ref(false);
const newsForm = ref(emptyNews());
function emptyNews() { return { id: null, title_ar: '', title_en: '', excerpt_ar: '', content_ar: '', content_en: '', cover_path: '', is_published: true }; }

function toastErr(e) { toast.add({ severity: 'error', summary: t('common.actions'), detail: e?.response?.data?.message || 'Error', life: 4000 }); }
const def = computed(() => TYPES[activeType.value]);

async function load() {
    loading.value = true;
    try { const { data } = await clubsApi.get(id); club.value = data.data; }
    catch (e) { toastErr(e); } finally { loading.value = false; }
}
function openAdd(type) { activeType.value = type; editingId.value = null; form.value = {}; dialog.value = true; }
function openEdit(type, row) { activeType.value = type; editingId.value = row.id; form.value = { ...row }; dialog.value = true; }
async function save() {
    saving.value = true;
    try {
        if (editingId.value) await clubsApi.updateChild(id, activeType.value, editingId.value, form.value);
        else await clubsApi.addChild(id, activeType.value, form.value);
        toast.add({ severity: 'success', summary: t('common.save'), life: 2000 });
        dialog.value = false; await load();
    } catch (e) { toastErr(e); } finally { saving.value = false; }
}
function del(type, row) {
    confirm.require({
        message: t('common.delete') + '?', header: t('common.delete'), icon: 'pi pi-trash',
        rejectLabel: t('common.cancel'), acceptLabel: t('common.delete'), acceptClass: 'p-button-danger',
        accept: async () => { try { await clubsApi.removeChild(id, type, row.id); await load(); } catch (e) { toastErr(e); } },
    });
}

function openNews(row = null) { newsForm.value = row ? { ...row } : emptyNews(); newsDialog.value = true; }
async function saveNews() {
    saving.value = true;
    try {
        if (newsForm.value.id) await clubsApi.updateNews(id, newsForm.value.id, newsForm.value);
        else await clubsApi.addNews(id, newsForm.value);
        toast.add({ severity: 'success', summary: t('common.save'), life: 2000 });
        newsDialog.value = false; await load();
    } catch (e) { toastErr(e); } finally { saving.value = false; }
}
function delNews(row) {
    confirm.require({
        message: t('common.delete') + '?', header: t('common.delete'), icon: 'pi pi-trash',
        rejectLabel: t('common.cancel'), acceptLabel: t('common.delete'), acceptClass: 'p-button-danger',
        accept: async () => { try { await clubsApi.removeNews(id, row.id); await load(); } catch (e) { toastErr(e); } },
    });
}
onMounted(load);
</script>

<template>
    <div>
        <PageHeader :title="club ? club.name_ar : t('clubs.content')" :subtitle="t('clubs.contentSubtitle')" icon="pi pi-sitemap">
            <template #actions><Button :label="t('common.back')" icon="pi pi-arrow-right" text severity="secondary" @click="router.push({ name: 'clubs' })" /></template>
        </PageHeader>

        <div v-if="club">
            <Tabs value="board">
                <TabList>
                    <Tab v-for="(d, key) in TYPES" :key="key" :value="key">{{ t(d.titleKey) }}</Tab>
                    <Tab value="news">{{ t('clubs.news') }}</Tab>
                </TabList>
                <TabPanels>
                    <TabPanel v-for="(d, key) in TYPES" :key="key" :value="key">
                        <div class="mb-3 flex justify-end">
                            <Button :label="t('common.add')" icon="pi pi-plus" size="small" @click="openAdd(key)" />
                        </div>
                        <DataTable :value="club[d.listKey] || []" data-key="id" class="text-sm">
                            <template #empty><div class="py-6 text-center text-surface-500">{{ t('common.noData') }}</div></template>
                            <Column v-for="col in d.cols" :key="col" :header="col" :field="col" />
                            <Column :style="{ width: '6rem' }">
                                <template #body="{ data }">
                                    <Button icon="pi pi-pencil" text rounded size="small" severity="secondary" @click="openEdit(key, data)" />
                                    <Button icon="pi pi-trash" text rounded size="small" severity="danger" @click="del(key, data)" />
                                </template>
                            </Column>
                        </DataTable>
                    </TabPanel>

                    <TabPanel value="news">
                        <div class="mb-3 flex justify-end">
                            <Button :label="t('common.add')" icon="pi pi-plus" size="small" @click="openNews()" />
                        </div>
                        <DataTable :value="club.news || []" data-key="id" class="text-sm">
                            <template #empty><div class="py-6 text-center text-surface-500">{{ t('common.noData') }}</div></template>
                            <Column :header="t('common.name')" field="title_ar" />
                            <Column :header="t('common.status')">
                                <template #body="{ data }"><Tag :value="data.is_published ? t('marketplace.published') : t('placeholder.badge')" :severity="data.is_published ? 'success' : 'secondary'" /></template>
                            </Column>
                            <Column :style="{ width: '6rem' }">
                                <template #body="{ data }">
                                    <Button icon="pi pi-pencil" text rounded size="small" severity="secondary" @click="openNews(data)" />
                                    <Button icon="pi pi-trash" text rounded size="small" severity="danger" @click="delNews(data)" />
                                </template>
                            </Column>
                        </DataTable>
                    </TabPanel>
                </TabPanels>
            </Tabs>
        </div>

        <!-- Generic child dialog -->
        <Dialog v-model:visible="dialog" modal :header="t(def.titleKey)" :style="{ width: '32rem' }">
            <div class="flex flex-col gap-3 pt-2">
                <div v-for="f in def.fields" :key="f[0]">
                    <label class="mb-1 block text-sm font-medium">{{ f[0] }}</label>
                    <Select v-if="f[1] === 'select'" v-model="form[f[0]]" :options="f[2]" class="w-full" />
                    <InputNumber v-else-if="f[1] === 'number'" v-model="form[f[0]]" class="w-full" :use-grouping="false" />
                    <InputText v-else v-model="form[f[0]]" class="w-full" :dir="f[0].endsWith('_en') ? 'ltr' : 'rtl'" />
                </div>
            </div>
            <template #footer>
                <Button :label="t('common.cancel')" text severity="secondary" @click="dialog = false" />
                <Button :label="t('common.save')" icon="pi pi-check" :loading="saving" @click="save" />
            </template>
        </Dialog>

        <!-- News dialog -->
        <Dialog v-model:visible="newsDialog" modal :header="t('clubs.news')" :style="{ width: '40rem' }">
            <div class="flex flex-col gap-3 pt-2">
                <div class="grid grid-cols-2 gap-3">
                    <InputText v-model="newsForm.title_ar" :placeholder="t('matches.nameAr')" class="w-full" />
                    <InputText v-model="newsForm.title_en" :placeholder="t('matches.nameEn')" class="w-full" dir="ltr" />
                </div>
                <Textarea v-model="newsForm.excerpt_ar" :placeholder="t('clubs.excerpt')" rows="2" class="w-full" auto-resize />
                <Textarea v-model="newsForm.content_ar" :placeholder="t('clubs.contentBody')" rows="4" class="w-full" auto-resize />
                <ImageUploadField v-model="newsForm.cover_path" endpoint="/clubs/upload" :label="t('common.cover')" />
                <label class="flex items-center gap-2 text-sm"><ToggleSwitch v-model="newsForm.is_published" /> {{ t('clubs.published') }}</label>
            </div>
            <template #footer>
                <Button :label="t('common.cancel')" text severity="secondary" @click="newsDialog = false" />
                <Button :label="t('common.save')" icon="pi pi-check" :loading="saving" @click="saveNews" />
            </template>
        </Dialog>
    </div>
</template>
