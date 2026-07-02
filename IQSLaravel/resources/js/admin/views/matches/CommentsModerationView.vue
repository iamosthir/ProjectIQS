<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import PageHeader from '@admin/components/PageHeader.vue';
import { matchesApi } from '@admin/api/matches';

const { t } = useI18n();
const toast = useToast();
const confirm = useConfirm();

const rows = ref([]);
const loading = ref(false);
const search = ref('');
const hiddenFilter = ref(null);

function toastErr(e) { toast.add({ severity: 'error', summary: t('common.actions'), detail: e?.response?.data?.message || 'Error', life: 4000 }); }
async function load() {
    loading.value = true;
    try {
        const params = { per_page: 30 };
        if (search.value) params.search = search.value;
        if (hiddenFilter.value !== null) params.hidden = hiddenFilter.value;
        const { data } = await matchesApi.comments(params);
        rows.value = data.data;
    } catch (e) { toastErr(e); } finally { loading.value = false; }
}
async function toggleHide(r) {
    try { const { data } = await matchesApi.hideComment(r.id); r.is_hidden = data.data.is_hidden; }
    catch (e) { toastErr(e); }
}
function del(r) {
    confirm.require({
        message: t('matches.deleteCommentConfirm'), header: t('common.delete'), icon: 'pi pi-trash',
        rejectLabel: t('common.cancel'), acceptLabel: t('common.delete'), acceptClass: 'p-button-danger',
        accept: async () => { try { await matchesApi.deleteComment(r.id); await load(); } catch (e) { toastErr(e); } },
    });
}
const hiddenOptions = [
    { label: t('common.all'), value: null },
    { label: t('matches.visible'), value: false },
    { label: t('matches.hidden'), value: true },
];
onMounted(load);
</script>

<template>
    <div>
        <PageHeader :title="t('matches.commentsModeration')" :subtitle="t('matches.commentsModerationSubtitle')" icon="pi pi-comments" />

        <div class="rounded-2xl border border-surface-200 bg-surface-0 dark:border-surface-800 dark:bg-surface-900">
            <div class="flex flex-wrap items-center gap-3 border-b border-surface-200 p-4 dark:border-surface-800">
                <IconField class="w-full sm:max-w-xs">
                    <InputIcon class="pi pi-search" />
                    <InputText v-model="search" :placeholder="t('common.searchPlaceholder')" class="w-full" @keyup.enter="load" />
                </IconField>
                <SelectButton v-model="hiddenFilter" :options="hiddenOptions" option-label="label" option-value="value" :allow-empty="false" @change="load" />
            </div>
            <DataTable :value="rows" :loading="loading" data-key="id" class="text-sm">
                <template #empty><div class="py-8 text-center text-surface-500">{{ t('common.noData') }}</div></template>
                <Column :header="t('matches.comment')">
                    <template #body="{ data }">
                        <p :class="['text-surface-800 dark:text-surface-100', data.is_hidden && 'line-through opacity-60']">{{ data.body }}</p>
                        <p class="text-xs text-surface-500">{{ data.user?.name || data.user?.phone }} · {{ data.commentable_type }}#{{ data.commentable_id }} · {{ data.context }}</p>
                    </template>
                </Column>
                <Column :header="t('matches.likes')" field="likes_count" :style="{ width: '6rem' }" />
                <Column :header="t('common.status')" :style="{ width: '7rem' }">
                    <template #body="{ data }"><Tag :value="data.is_hidden ? t('matches.hidden') : t('matches.visible')" :severity="data.is_hidden ? 'warn' : 'success'" /></template>
                </Column>
                <Column :header="t('common.actions')" :style="{ width: '8rem' }">
                    <template #body="{ data }">
                        <Button :icon="data.is_hidden ? 'pi pi-eye' : 'pi pi-eye-slash'" text rounded size="small" severity="secondary" v-tooltip.bottom="data.is_hidden ? t('matches.unhide') : t('matches.hide')" @click="toggleHide(data)" />
                        <Button icon="pi pi-trash" text rounded size="small" severity="danger" @click="del(data)" />
                    </template>
                </Column>
            </DataTable>
        </div>
    </div>
</template>
