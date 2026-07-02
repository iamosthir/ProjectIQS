<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToast } from 'primevue/usetoast';
import PageHeader from '@admin/components/PageHeader.vue';
import { matchesApi } from '@admin/api/matches';

const { t } = useI18n();
const toast = useToast();

const iraqiOnly = ref(true);
const league = ref(null);
const season = ref(2025);
const busy = ref('');
const logs = ref([]);
const loadingLogs = ref(false);

function toastErr(e) { toast.add({ severity: 'error', summary: t('matches.syncConsole'), detail: e?.response?.data?.message || 'Error', life: 5000 }); }
function ok(res) { toast.add({ severity: 'success', summary: t('matches.syncDone'), detail: t('matches.processed', { n: res?.data?.data?.processed ?? 0 }), life: 3000 }); }

async function run(key, fn) {
    busy.value = key;
    try { ok(await fn()); await loadLogs(); }
    catch (e) { toastErr(e); }
    finally { busy.value = ''; }
}
const needsLeague = () => {
    if (!league.value || !season.value) { toastErr({ response: { data: { message: t('matches.leagueSeasonRequired') } } }); return false; }
    return true;
};

async function loadLogs() {
    loadingLogs.value = true;
    try { const { data } = await matchesApi.syncLogs({ per_page: 30 }); logs.value = data.data; }
    catch (e) { toastErr(e); } finally { loadingLogs.value = false; }
}

onMounted(loadLogs);
</script>

<template>
    <div>
        <PageHeader :title="t('matches.syncConsole')" :subtitle="t('matches.syncConsoleSubtitle')" icon="pi pi-sync" />

        <div class="grid gap-4 lg:grid-cols-2">
            <!-- Leagues -->
            <div class="rounded-2xl border border-surface-200 bg-surface-0 p-4 dark:border-surface-800 dark:bg-surface-900">
                <h3 class="mb-3 font-semibold">{{ t('matches.syncLeagues') }}</h3>
                <label class="mb-3 flex items-center gap-2 text-sm"><ToggleSwitch v-model="iraqiOnly" /> {{ t('matches.iraqiOnly') }}</label>
                <Button :label="t('matches.runSync')" icon="pi pi-play" :loading="busy === 'leagues'" @click="run('leagues', () => matchesApi.syncLeagues({ iraqi: iraqiOnly }))" />
            </div>

            <!-- Per-league syncs -->
            <div class="rounded-2xl border border-surface-200 bg-surface-0 p-4 dark:border-surface-800 dark:bg-surface-900">
                <h3 class="mb-3 font-semibold">{{ t('matches.syncByLeague') }}</h3>
                <div class="mb-3 grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-xs text-surface-500">{{ t('matches.apiLeagueId') }}</label>
                        <InputNumber v-model="league" class="w-full" :use-grouping="false" />
                    </div>
                    <div>
                        <label class="mb-1 block text-xs text-surface-500">{{ t('matches.season') }}</label>
                        <InputNumber v-model="season" class="w-full" :use-grouping="false" />
                    </div>
                </div>
                <div class="flex flex-wrap gap-2">
                    <Button :label="t('matches.teams')" icon="pi pi-shield" size="small" outlined :loading="busy === 'teams'" @click="needsLeague() && run('teams', () => matchesApi.syncTeams({ league, season }))" />
                    <Button :label="t('fixtures.title')" icon="pi pi-calendar" size="small" outlined :loading="busy === 'fixtures'" @click="needsLeague() && run('fixtures', () => matchesApi.syncFixtures({ league, season }))" />
                    <Button :label="t('matches.standings')" icon="pi pi-list" size="small" outlined :loading="busy === 'standings'" @click="needsLeague() && run('standings', () => matchesApi.syncStandings({ league, season }))" />
                    <Button :label="t('matches.topScorers')" icon="pi pi-star" size="small" outlined :loading="busy === 'scorers'" @click="needsLeague() && run('scorers', () => matchesApi.syncTopScorers({ league, season }))" />
                </div>
            </div>
        </div>

        <div class="mt-4 rounded-2xl border border-surface-200 bg-surface-0 dark:border-surface-800 dark:bg-surface-900">
            <div class="flex items-center justify-between border-b border-surface-200 p-4 dark:border-surface-800">
                <h3 class="font-semibold">{{ t('matches.syncLogs') }}</h3>
                <Button icon="pi pi-refresh" text rounded severity="secondary" :loading="loadingLogs" @click="loadLogs" />
            </div>
            <DataTable :value="logs" :loading="loadingLogs" data-key="id" class="text-sm" paginator :rows="10">
                <template #empty><div class="py-6 text-center text-surface-500">{{ t('common.noData') }}</div></template>
                <Column :header="t('matches.endpoint')" field="endpoint" />
                <Column :header="t('common.status')">
                    <template #body="{ data }"><Tag :value="data.status" :severity="data.status === 'success' ? 'success' : (data.status === 'rate_limited' ? 'warn' : 'danger')" /></template>
                </Column>
                <Column :header="t('matches.records')" field="records_processed" />
                <Column :header="t('matches.remaining')" field="requests_remaining" />
                <Column :header="t('matches.duration')">
                    <template #body="{ data }"><span dir="ltr">{{ data.duration_ms }} ms</span></template>
                </Column>
                <Column :header="t('common.date')">
                    <template #body="{ data }"><span dir="ltr">{{ data.created_at ? new Date(data.created_at).toLocaleString() : '' }}</span></template>
                </Column>
            </DataTable>
        </div>
    </div>
</template>
