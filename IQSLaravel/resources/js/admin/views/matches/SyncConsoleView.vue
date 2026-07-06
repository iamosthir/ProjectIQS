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

const auto = ref({ seasons: [], budget_remaining: null, live_poll_seconds: 30 });
const loadingAuto = ref(false);
const apiLeagues = ref([]);
const leaguePick = ref(null);
const seasonOptions = ref([]);
const seasonPick = ref(null);
const togglingAuto = ref(false);

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

async function loadAuto() {
    loadingAuto.value = true;
    try { const { data } = await matchesApi.syncAutoStatus(); auto.value = data.data; }
    catch (e) { toastErr(e); } finally { loadingAuto.value = false; }
}

async function loadApiLeagues(search = '') {
    try {
        const params = { 'filter[source]': 'api_football', per_page: 50, sort: 'name_en' };
        if (search) params['filter[search]'] = search;
        const { data } = await matchesApi.leagues(params);
        apiLeagues.value = data.data;
    } catch (e) { toastErr(e); }
}

async function onLeaguePicked() {
    seasonPick.value = null;
    seasonOptions.value = [];
    if (!leaguePick.value) return;
    try { const { data } = await matchesApi.seasons({ league_id: leaguePick.value }); seasonOptions.value = data.data; }
    catch (e) { toastErr(e); }
}

async function toggleAuto(seasonId, enabled) {
    togglingAuto.value = true;
    try {
        const { data } = await matchesApi.toggleSeasonAutoSync(seasonId, { enabled });
        toast.add({ severity: 'success', summary: t('matches.autoSync'), detail: data?.message || t('matches.syncDone'), life: 4000 });
        if (enabled) { seasonPick.value = null; }
        await loadAuto();
    } catch (e) { toastErr(e); }
    finally { togglingAuto.value = false; }
}

function fmtTime(v) { return v ? new Date(v).toLocaleString() : '—'; }

onMounted(() => { loadLogs(); loadAuto(); loadApiLeagues(); });
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

        <!-- Auto-sync subscriptions -->
        <div class="mt-4 rounded-2xl border border-surface-200 bg-surface-0 dark:border-surface-800 dark:bg-surface-900">
            <div class="flex flex-wrap items-center justify-between gap-2 border-b border-surface-200 p-4 dark:border-surface-800">
                <div>
                    <h3 class="font-semibold">{{ t('matches.autoSync') }}</h3>
                    <p class="mt-1 text-xs text-surface-500">{{ t('matches.autoSyncHint') }}</p>
                </div>
                <div class="flex items-center gap-3">
                    <Tag v-if="auto.budget_remaining !== null" icon="pi pi-gauge" severity="secondary" :value="t('matches.budgetRemaining', { n: auto.budget_remaining })" />
                    <Button icon="pi pi-refresh" text rounded severity="secondary" :loading="loadingAuto" @click="loadAuto" />
                </div>
            </div>

            <div class="flex flex-wrap items-end gap-3 border-b border-surface-200 p-4 dark:border-surface-800">
                <div class="min-w-64">
                    <label class="mb-1 block text-xs text-surface-500">{{ t('matches.league') }}</label>
                    <Select
                        v-model="leaguePick" :options="apiLeagues" option-value="id" filter class="w-full"
                        :option-label="(l) => `${l.name_ar} (${l.country_name || ''} #${l.external_id})`"
                        :placeholder="t('matches.pickLeague')"
                        @change="onLeaguePicked" @filter="(e) => loadApiLeagues(e.value)" />
                </div>
                <div class="min-w-40">
                    <label class="mb-1 block text-xs text-surface-500">{{ t('matches.season') }}</label>
                    <Select
                        v-model="seasonPick" :options="seasonOptions" option-value="id" class="w-full"
                        :option-label="(s) => s.label || String(s.year)"
                        :placeholder="t('matches.pickSeason')" :disabled="!leaguePick" />
                </div>
                <Button :label="t('matches.enableAutoSync')" icon="pi pi-bolt" :disabled="!seasonPick" :loading="togglingAuto" @click="toggleAuto(seasonPick, true)" />
            </div>

            <DataTable :value="auto.seasons" :loading="loadingAuto" data-key="id" class="text-sm">
                <template #empty><div class="py-6 text-center text-surface-500">{{ t('matches.autoSyncEmpty') }}</div></template>
                <Column :header="t('matches.league')">
                    <template #body="{ data }">
                        <p class="font-medium text-surface-800 dark:text-surface-100">{{ data.league?.name_ar }}</p>
                        <p class="text-xs text-surface-500">{{ data.league?.country_name }} <span dir="ltr">#{{ data.league?.external_id }}</span></p>
                    </template>
                </Column>
                <Column :header="t('matches.season')">
                    <template #body="{ data }"><span dir="ltr">{{ data.label || data.year }}</span></template>
                </Column>
                <Column :header="t('matches.lastFixturesSync')">
                    <template #body="{ data }"><span dir="ltr">{{ fmtTime(data.fixtures_synced_at) }}</span></template>
                </Column>
                <Column :header="t('matches.lastStandingsSync')">
                    <template #body="{ data }"><span dir="ltr">{{ fmtTime(data.standings_synced_at) }}</span></template>
                </Column>
                <Column :header="t('matches.lastScorersSync')">
                    <template #body="{ data }"><span dir="ltr">{{ fmtTime(data.top_scorers_synced_at) }}</span></template>
                </Column>
                <Column>
                    <template #body="{ data }">
                        <Button :label="t('matches.disableAutoSync')" icon="pi pi-pause" size="small" severity="danger" outlined :loading="togglingAuto" @click="toggleAuto(data.id, false)" />
                    </template>
                </Column>
            </DataTable>
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
