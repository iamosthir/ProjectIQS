<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import PageHeader from '@admin/components/PageHeader.vue';
import { fanGroupsApi } from '@admin/api/fanGroups';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const toast = useToast();
const confirm = useConfirm();

const id = Number(route.params.id);
const group = ref(null);
const loading = ref(false);
const dialog = ref(false);
const mode = ref('media');
const form = ref({});
const saving = ref(false);

function toastErr(e) { toast.add({ severity: 'error', summary: t('common.actions'), detail: e?.response?.data?.message || 'Error', life: 4000 }); }

async function load() {
    loading.value = true;
    try { const { data } = await fanGroupsApi.get(id); group.value = data.data; }
    catch (e) { toastErr(e); } finally { loading.value = false; }
}
function openAdd(m) { mode.value = m; form.value = m === 'media' ? { type: 'image', path: '', title: '' } : (m === 'chants' ? { title_ar: '', video_path: '', lyrics: '' } : { title_ar: '', path: '', mime_type: '' }); dialog.value = true; }
async function save() {
    saving.value = true;
    try {
        if (mode.value === 'media') await fanGroupsApi.addMedia(id, form.value);
        else if (mode.value === 'chants') await fanGroupsApi.addChant(id, form.value);
        else await fanGroupsApi.addDocument(id, form.value);
        toast.add({ severity: 'success', summary: t('common.save'), life: 2000 });
        dialog.value = false; await load();
    } catch (e) { toastErr(e); } finally { saving.value = false; }
}
function del(m, row) {
    const fn = m === 'media' ? fanGroupsApi.removeMedia : (m === 'chants' ? fanGroupsApi.removeChant : fanGroupsApi.removeDocument);
    confirm.require({
        message: t('common.delete') + '?', header: t('common.delete'), icon: 'pi pi-trash',
        rejectLabel: t('common.cancel'), acceptLabel: t('common.delete'), acceptClass: 'p-button-danger',
        accept: async () => { try { await fn(id, row.id); await load(); } catch (e) { toastErr(e); } },
    });
}
onMounted(load);
</script>

<template>
    <div>
        <PageHeader :title="group ? group.name_ar : t('fanGroups.archives')" :subtitle="t('fanGroups.archivesSubtitle')" icon="pi pi-images">
            <template #actions><Button :label="t('common.back')" icon="pi pi-arrow-right" text severity="secondary" @click="router.push({ name: 'fan-groups' })" /></template>
        </PageHeader>

        <div v-if="group">
            <Tabs value="media">
                <TabList>
                    <Tab value="media">{{ t('fanGroups.media') }}</Tab>
                    <Tab value="chants">{{ t('fanGroups.chants') }}</Tab>
                    <Tab value="documents">{{ t('fanGroups.documents') }}</Tab>
                </TabList>
                <TabPanels>
                    <TabPanel value="media">
                        <div class="mb-3 flex items-center justify-between">
                            <p class="text-sm text-surface-500">{{ t('fanGroups.mediaLimits') }}</p>
                            <Button :label="t('common.add')" icon="pi pi-plus" size="small" @click="openAdd('media')" />
                        </div>
                        <DataTable :value="group.media || []" data-key="id" class="text-sm">
                            <template #empty><div class="py-6 text-center text-surface-500">{{ t('common.noData') }}</div></template>
                            <Column :header="t('matches.type')"><template #body="{ data }"><Tag :value="data.type" severity="secondary" /></template></Column>
                            <Column :header="t('common.name')" field="title" />
                            <Column field="path" header="Path" />
                            <Column :style="{ width: '4rem' }"><template #body="{ data }"><Button icon="pi pi-trash" text rounded size="small" severity="danger" @click="del('media', data)" /></template></Column>
                        </DataTable>
                    </TabPanel>

                    <TabPanel value="chants">
                        <div class="mb-3 flex items-center justify-between">
                            <p class="text-sm text-surface-500">{{ t('fanGroups.chantsLimit') }}</p>
                            <Button :label="t('common.add')" icon="pi pi-plus" size="small" @click="openAdd('chants')" />
                        </div>
                        <DataTable :value="group.chants || []" data-key="id" class="text-sm">
                            <template #empty><div class="py-6 text-center text-surface-500">{{ t('common.noData') }}</div></template>
                            <Column :header="t('common.name')" field="title_ar" />
                            <Column field="video_path" header="Video" />
                            <Column :style="{ width: '4rem' }"><template #body="{ data }"><Button icon="pi pi-trash" text rounded size="small" severity="danger" @click="del('chants', data)" /></template></Column>
                        </DataTable>
                    </TabPanel>

                    <TabPanel value="documents">
                        <div class="mb-3 flex justify-end">
                            <Button :label="t('common.add')" icon="pi pi-plus" size="small" @click="openAdd('documents')" />
                        </div>
                        <DataTable :value="group.documents || []" data-key="id" class="text-sm">
                            <template #empty><div class="py-6 text-center text-surface-500">{{ t('common.noData') }}</div></template>
                            <Column :header="t('common.name')" field="title_ar" />
                            <Column field="path" header="Path" />
                            <Column :style="{ width: '4rem' }"><template #body="{ data }"><Button icon="pi pi-trash" text rounded size="small" severity="danger" @click="del('documents', data)" /></template></Column>
                        </DataTable>
                    </TabPanel>
                </TabPanels>
            </Tabs>
        </div>

        <Dialog v-model:visible="dialog" modal :header="t('common.add')" :style="{ width: '30rem' }">
            <div class="flex flex-col gap-3 pt-2">
                <template v-if="mode === 'media'">
                    <Select v-model="form.type" :options="['image', 'video']" class="w-full" />
                    <InputText v-model="form.path" placeholder="Path / URL" class="w-full" dir="ltr" />
                    <InputText v-model="form.title" :placeholder="t('common.name')" class="w-full" />
                </template>
                <template v-else-if="mode === 'chants'">
                    <InputText v-model="form.title_ar" :placeholder="t('matches.nameAr')" class="w-full" />
                    <InputText v-model="form.video_path" placeholder="Video URL" class="w-full" dir="ltr" />
                    <Textarea v-model="form.lyrics" :placeholder="t('fanGroups.lyrics')" rows="3" class="w-full" auto-resize />
                </template>
                <template v-else>
                    <InputText v-model="form.title_ar" :placeholder="t('matches.nameAr')" class="w-full" />
                    <InputText v-model="form.path" placeholder="Path / URL" class="w-full" dir="ltr" />
                </template>
            </div>
            <template #footer>
                <Button :label="t('common.cancel')" text severity="secondary" @click="dialog = false" />
                <Button :label="t('common.save')" icon="pi pi-check" :loading="saving" @click="save" />
            </template>
        </Dialog>
    </div>
</template>
