<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import PageHeader from '@admin/components/PageHeader.vue';
import ImageUploadField from '@admin/components/ImageUploadField.vue';
import { matchesApi } from '@admin/api/matches';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const toast = useToast();
const confirm = useConfirm();

const id = Number(route.params.id);
const fixture = ref(null);
const events = ref([]);
const broadcasts = ref([]);
const lineups = ref([]);
const scorers = ref([]);
const statistics = ref([]);
const news = ref([]);
const loading = ref(false);

// Event keyword presets → type/detail.
const EVENT_KEYWORDS = [
    { key: 'goal', type: 'goal', detail: 'Normal Goal', needsPlayer: true, severity: 'success' },
    { key: 'yellow', type: 'card', detail: 'Yellow Card', needsPlayer: true, severity: 'warn' },
    { key: 'red', type: 'card', detail: 'Red Card', needsPlayer: true, severity: 'danger' },
    { key: 'subst', type: 'subst', detail: 'Substitution', needsPlayer: true, severity: 'info' },
    { key: 'penalty', type: 'penalty', detail: 'Awarded', needsPlayer: true, severity: 'help' },
    { key: 'kickoff', type: 'kickoff', detail: 'Start', needsPlayer: false, severity: 'secondary' },
    { key: 'halfEnd', type: 'half_end', detail: 'First Half', needsPlayer: false, severity: 'secondary' },
    { key: 'matchEnd', type: 'match_end', detail: 'Full Time', needsPlayer: false, severity: 'contrast', closes: true },
    { key: 'cancel', type: 'match_cancelled', detail: 'Cancelled', needsPlayer: false, severity: 'danger', closes: true },
    { key: 'postpone', type: 'match_postponed', detail: 'Postponed', needsPlayer: false, severity: 'danger', closes: true },
];

// Common statistic types the editor pre-lists (admins can add custom ones).
const STAT_TYPES = [
    'Ball Possession', 'Total Shots', 'Shots on Goal', 'Shots off Goal', 'Corner Kicks',
    'Offsides', 'Fouls', 'Yellow Cards', 'Red Cards', 'Goalkeeper Saves', 'Total passes', 'Passes accurate',
];

const eventDialog = ref(false);
const eventForm = ref({});
const editingEventId = ref(null);
const eventPlayerSel = ref(null);
const eventAssistSel = ref(null);
const submitting = ref(false);

const broadcastForm = ref({ channel_name: '', commentator_name: '', stream_url: '' });
const lineupForm = ref({ team_id: null, formation: '', coach_name: '', coach_photo: '', players: [] });
const lineupDialog = ref(false);

const statForm = ref([]);
const newStatType = ref('');
const savingStats = ref(false);

const newsDialog = ref(false);
const newsForm = ref(emptyNews());
const editingNewsId = ref(null);
const savingNews = ref(false);

// Player picker options (server-searched, shared by events + lineups).
const playerOptions = ref([]);
const playerLoading = ref(false);
let playerTimer = null;

function toastErr(e) {
    toast.add({ severity: 'error', summary: t('common.error'), detail: e?.response?.data?.message || t('common.somethingWrong'), life: 4000 });
}

function storageUrl(p) {
    return /^https?:\/\//.test(p) ? p : `/storage/${p}`;
}

function emptyNews() {
    return { title_ar: '', title_en: '', excerpt_ar: '', excerpt_en: '', content_ar: '', content_en: '', cover_path: '', is_published: true };
}

const teamOptions = computed(() => fixture.value ? [
    { id: fixture.value.home_team_id, label: fixture.value.home_team?.name_ar || fixture.value.home_team?.name_en },
    { id: fixture.value.away_team_id, label: fixture.value.away_team?.name_ar || fixture.value.away_team?.name_en },
] : []);
const isClosed = computed(() => fixture.value && ['finished', 'cancelled', 'postponed'].includes(fixture.value.status_group));

async function loadAll() {
    loading.value = true;
    try {
        const [f, e, b, l, s, n] = await Promise.all([
            matchesApi.fixture(id), matchesApi.events(id), matchesApi.broadcasts(id),
            matchesApi.lineups(id), matchesApi.statistics(id), matchesApi.fixtureNews(id),
        ]);
        fixture.value = f.data.data;
        events.value = e.data.data;
        broadcasts.value = b.data.data;
        lineups.value = l.data.data;
        statistics.value = s.data.data;
        news.value = n.data.data;
        buildStatForm();
        if (fixture.value.league_id) {
            const sc = await matchesApi.topScorers(fixture.value.league_id);
            scorers.value = sc.data.data;
        }
    } catch (e) { toastErr(e); } finally { loading.value = false; }
}

// ---- Player picker (server search) -----------------------------------------
function searchPlayers(q) {
    clearTimeout(playerTimer);
    playerTimer = setTimeout(async () => {
        playerLoading.value = true;
        try {
            const { data } = await matchesApi.playerSearch(q);
            playerOptions.value = data.data.map((p) => ({
                id: p.id,
                name: p.name_ar || p.name_en,
                photo: p.photo_path || '',
                label: [p.name_ar, p.name_en].filter(Boolean).join(' · '),
            }));
        } catch (e) { /* non-blocking */ } finally { playerLoading.value = false; }
    }, 300);
}
function onPlayerFilter(e) { searchPlayers(e.value); }

// ---- Events ----------------------------------------------------------------
function openEvent(kw) {
    editingEventId.value = null;
    eventPlayerSel.value = null;
    eventAssistSel.value = null;
    eventForm.value = {
        keyword: kw, type: kw.type, detail: kw.detail, elapsed: fixture.value?.elapsed || 0,
        team_id: null, player_id: null, player_name: '', assist_player_id: null, assist_name: '',
    };
    eventDialog.value = true;
}
function openEditEvent(ev) {
    const kw = EVENT_KEYWORDS.find((k) => k.type === ev.type) || { needsPlayer: true };
    editingEventId.value = ev.id;
    eventPlayerSel.value = null;
    eventAssistSel.value = null;
    eventForm.value = {
        keyword: kw, type: ev.type, detail: ev.detail, elapsed: ev.elapsed,
        team_id: ev.team_id, player_id: ev.player_id, player_name: ev.player_name || '',
        assist_player_id: ev.assist_player_id, assist_name: ev.assist_name || '',
    };
    eventDialog.value = true;
}
function pickEventPlayer(opt) {
    if (opt) { eventForm.value.player_id = opt.id; eventForm.value.player_name = opt.name; }
    eventPlayerSel.value = null;
}
function pickEventAssist(opt) {
    if (opt) { eventForm.value.assist_player_id = opt.id; eventForm.value.assist_name = opt.name; }
    eventAssistSel.value = null;
}
async function submitEvent() {
    submitting.value = true;
    const f = eventForm.value;
    const payload = {
        type: f.type, detail: f.detail, elapsed: f.elapsed, team_id: f.team_id,
        player_id: f.player_id || null, player_name: f.player_name || null,
        assist_player_id: f.assist_player_id || null, assist_name: f.assist_name || null,
    };
    try {
        if (editingEventId.value) {
            await matchesApi.updateEvent(id, editingEventId.value, payload);
            toast.add({ severity: 'success', summary: t('matches.eventUpdated'), life: 2000 });
        } else {
            await matchesApi.addEvent(id, payload);
            toast.add({ severity: 'success', summary: t('matches.eventLogged'), life: 2000 });
        }
        eventDialog.value = false;
        await loadAll();
    } catch (e) { toastErr(e); } finally { submitting.value = false; }
}
function delEvent(ev) {
    confirm.require({
        message: t('matches.deleteEventConfirm'), header: t('common.delete'), icon: 'pi pi-trash',
        rejectLabel: t('common.cancel'), acceptLabel: t('common.delete'), acceptClass: 'p-button-danger',
        accept: async () => { try { await matchesApi.deleteEvent(id, ev.id); await loadAll(); } catch (e) { toastErr(e); } },
    });
}

// ---- Broadcasts ------------------------------------------------------------
async function addBroadcast() {
    if (!broadcastForm.value.channel_name) return;
    try {
        await matchesApi.addBroadcast(id, broadcastForm.value);
        broadcastForm.value = { channel_name: '', commentator_name: '', stream_url: '' };
        await loadAll();
    } catch (e) { toastErr(e); }
}
async function delBroadcast(b) { try { await matchesApi.deleteBroadcast(id, b.id); await loadAll(); } catch (e) { toastErr(e); } }

// ---- Lineups ---------------------------------------------------------------
function openLineup(teamId) {
    const existing = lineups.value.find((l) => l.team_id === teamId);
    lineupForm.value = existing
        ? {
            team_id: teamId, formation: existing.formation || '',
            coach_name: existing.coach_name || '', coach_photo: existing.coach_photo || '',
            players: existing.players.map((p) => ({ ...p })),
        }
        : { team_id: teamId, formation: '', coach_name: '', coach_photo: '', players: [] };
    lineupDialog.value = true;
}
function addLineupRow() {
    lineupForm.value.players.push({ player_id: null, player_name: '', photo_path: '', number: null, position: '', grid: '', is_starter: true });
}
function removeLineupRow(i) { lineupForm.value.players.splice(i, 1); }
function pickLineupPlayer(opt, row) {
    if (opt) {
        row.player_id = opt.id;
        row.player_name = opt.name;
        if (opt.photo) row.photo_path = opt.photo;
    }
    row._sel = null;
}
async function saveLineup() {
    try {
        await matchesApi.saveLineup(id, {
            team_id: lineupForm.value.team_id,
            formation: lineupForm.value.formation,
            coach_name: lineupForm.value.coach_name || null,
            coach_photo: lineupForm.value.coach_photo || null,
            players: lineupForm.value.players.map((p) => ({
                player_id: p.player_id || null,
                player_name: p.player_name,
                photo_path: p.photo_path || null,
                number: p.number,
                position: p.position,
                grid: p.grid,
                is_starter: p.is_starter ?? true,
            })),
        });
        toast.add({ severity: 'success', summary: t('matches.lineupSaved'), life: 2000 });
        lineupDialog.value = false;
        await loadAll();
    } catch (e) { toastErr(e); }
}

// ---- Statistics ------------------------------------------------------------
function buildStatForm() {
    const home = fixture.value?.home_team_id;
    const away = fixture.value?.away_team_id;
    const byType = {};
    for (const s of statistics.value) {
        byType[s.type] = byType[s.type] || { type: s.type, home: '', away: '' };
        if (s.team_id === home) byType[s.type].home = s.value ?? '';
        else if (s.team_id === away) byType[s.type].away = s.value ?? '';
    }
    const rows = STAT_TYPES.map((type) => byType[type] || { type, home: '', away: '' });
    for (const type of Object.keys(byType)) {
        if (!STAT_TYPES.includes(type)) rows.push(byType[type]);
    }
    statForm.value = rows;
}
function addStatRow() {
    const type = newStatType.value.trim();
    if (!type || statForm.value.some((r) => r.type === type)) return;
    statForm.value.push({ type, home: '', away: '' });
    newStatType.value = '';
}
async function saveStats() {
    const home = fixture.value.home_team_id;
    const away = fixture.value.away_team_id;
    const payload = [];
    let order = 0;
    for (const r of statForm.value) {
        const type = (r.type || '').trim();
        if (!type) continue;
        if (r.home !== '' && r.home != null) payload.push({ team_id: home, type, value: String(r.home), display_order: order });
        if (r.away !== '' && r.away != null) payload.push({ team_id: away, type, value: String(r.away), display_order: order });
        order += 1;
    }
    savingStats.value = true;
    try {
        const { data } = await matchesApi.saveStatistics(id, { statistics: payload });
        statistics.value = data.data;
        buildStatForm();
        toast.add({ severity: 'success', summary: t('matches.statisticsSaved'), life: 2000 });
    } catch (e) { toastErr(e); } finally { savingStats.value = false; }
}

// ---- News ------------------------------------------------------------------
function openNewsCreate() { editingNewsId.value = null; newsForm.value = emptyNews(); newsDialog.value = true; }
function openNewsEdit(n) {
    editingNewsId.value = n.id;
    newsForm.value = {
        title_ar: n.title_ar || '', title_en: n.title_en || '', excerpt_ar: n.excerpt_ar || '', excerpt_en: n.excerpt_en || '',
        content_ar: n.content_ar || '', content_en: n.content_en || '', cover_path: n.cover_path || '', is_published: !!n.is_published,
    };
    newsDialog.value = true;
}
async function saveNews() {
    savingNews.value = true;
    try {
        if (editingNewsId.value) await matchesApi.updateNews(id, editingNewsId.value, newsForm.value);
        else await matchesApi.createNews(id, newsForm.value);
        toast.add({ severity: 'success', summary: t('matches.newsSaved'), life: 2000 });
        newsDialog.value = false;
        await loadAll();
    } catch (e) { toastErr(e); } finally { savingNews.value = false; }
}
function delNews(n) {
    confirm.require({
        message: t('matches.deleteNewsConfirm'), header: t('common.delete'), icon: 'pi pi-trash',
        rejectLabel: t('common.cancel'), acceptLabel: t('common.delete'), acceptClass: 'p-button-danger',
        accept: async () => { try { await matchesApi.deleteNews(id, n.id); await loadAll(); } catch (e) { toastErr(e); } },
    });
}

onMounted(async () => {
    await loadAll();
    searchPlayers('');
});
</script>

<template>
    <div>
        <PageHeader :title="t('matches.matchConsole')" :subtitle="fixture ? `${fixture.home_team?.name_ar} ${fixture.score?.home_goals ?? '-'} : ${fixture.score?.away_goals ?? '-'} ${fixture.away_team?.name_ar}` : ''" icon="pi pi-sliders-h">
            <template #actions>
                <Tag v-if="fixture" :value="fixture.status_group" :severity="isClosed ? 'secondary' : 'danger'" />
                <Button :label="t('common.back')" icon="pi pi-arrow-right" text severity="secondary" @click="router.push({ name: 'fixtures' })" />
            </template>
        </PageHeader>

        <div v-if="fixture">
            <Tabs value="events">
                <TabList>
                    <Tab value="events">{{ t('matches.events') }}</Tab>
                    <Tab value="lineups">{{ t('matches.lineups') }}</Tab>
                    <Tab value="statistics">{{ t('matches.statistics') }}</Tab>
                    <Tab value="news">{{ t('matches.news') }}</Tab>
                    <Tab value="details">{{ t('matches.detailsTab') }}</Tab>
                    <Tab value="scorers">{{ t('matches.topScorers') }}</Tab>
                </TabList>
                <TabPanels>
                    <!-- Events -->
                    <TabPanel value="events">
                        <Message v-if="isClosed" severity="warn" class="mb-3">{{ t('matches.consoleClosed') }}</Message>
                        <div class="mb-4 flex flex-wrap gap-2">
                            <Button v-for="kw in EVENT_KEYWORDS" :key="kw.key" :label="t(`matches.kw.${kw.key}`)" :severity="kw.severity" size="small" outlined :disabled="isClosed" @click="openEvent(kw)" />
                        </div>
                        <div class="rounded-2xl border border-surface-200 dark:border-surface-800">
                            <DataTable :value="events" data-key="id" class="text-sm">
                                <template #empty><div class="py-6 text-center text-surface-500">{{ t('matches.noEvents') }}</div></template>
                                <Column :header="t('matches.minute')" :style="{ width: '5rem' }">
                                    <template #body="{ data }"><span class="font-semibold" dir="ltr">{{ data.elapsed }}'</span></template>
                                </Column>
                                <Column :header="t('matches.type')">
                                    <template #body="{ data }"><Tag :value="data.type" severity="secondary" /> <span class="ms-2 text-surface-600 dark:text-surface-300">{{ data.detail }}</span></template>
                                </Column>
                                <Column :header="t('matches.player')" field="player_name" />
                                <Column :style="{ width: '6rem' }">
                                    <template #body="{ data }">
                                        <Button icon="pi pi-pencil" text rounded size="small" severity="secondary" @click="openEditEvent(data)" />
                                        <Button icon="pi pi-trash" text rounded size="small" severity="danger" @click="delEvent(data)" />
                                    </template>
                                </Column>
                            </DataTable>
                        </div>
                    </TabPanel>

                    <!-- Lineups -->
                    <TabPanel value="lineups">
                        <div class="grid gap-4 sm:grid-cols-2">
                            <div v-for="team in teamOptions" :key="team.id" class="rounded-2xl border border-surface-200 p-4 dark:border-surface-800">
                                <div class="mb-3 flex items-center justify-between">
                                    <h3 class="font-semibold">{{ team.label }}</h3>
                                    <Button :label="t('matches.editLineup')" icon="pi pi-pencil" size="small" outlined @click="openLineup(team.id)" />
                                </div>
                                <template v-for="l in lineups.filter((x) => x.team_id === team.id)" :key="l.id">
                                    <p class="mb-2 text-sm text-surface-500">{{ t('matches.formation') }}: <span class="font-medium">{{ l.formation || '—' }}</span></p>
                                    <p v-if="l.coach_name" class="mb-2 flex items-center gap-2 text-sm text-surface-500">
                                        <img v-if="l.coach_photo" :src="storageUrl(l.coach_photo)" alt="" class="h-6 w-6 rounded-full object-cover" />
                                        {{ t('matches.coach') }}: <span class="font-medium">{{ l.coach_name }}</span>
                                    </p>
                                    <ul class="space-y-1 text-sm">
                                        <li v-for="p in l.players" :key="p.id" class="flex items-center gap-2">
                                            <span class="inline-block w-6 text-center text-xs text-surface-500">{{ p.number }}</span>
                                            <img v-if="p.photo_path" :src="storageUrl(p.photo_path)" alt="" class="h-6 w-6 rounded-full object-cover" />
                                            <span>{{ p.player_name }}</span>
                                            <Tag v-if="!p.is_starter" value="sub" severity="secondary" class="ms-auto" />
                                        </li>
                                    </ul>
                                </template>
                            </div>
                        </div>
                    </TabPanel>

                    <!-- Statistics -->
                    <TabPanel value="statistics">
                        <div class="mb-3 flex flex-wrap items-center justify-between gap-2">
                            <p class="text-sm text-surface-500">{{ t('matches.statisticsHint') }}</p>
                            <Button :label="t('matches.saveStatistics')" icon="pi pi-check" :loading="savingStats" @click="saveStats" />
                        </div>
                        <div class="rounded-2xl border border-surface-200 dark:border-surface-800">
                            <DataTable :value="statForm" class="text-sm">
                                <Column :header="teamOptions[0]?.label || t('matches.home')" :style="{ width: '9rem' }">
                                    <template #body="{ data }"><InputText v-model="data.home" class="w-full text-center" dir="ltr" /></template>
                                </Column>
                                <Column :header="t('matches.statType')">
                                    <template #body="{ data }"><span class="font-medium">{{ data.type }}</span></template>
                                </Column>
                                <Column :header="teamOptions[1]?.label || t('matches.away')" :style="{ width: '9rem' }">
                                    <template #body="{ data }"><InputText v-model="data.away" class="w-full text-center" dir="ltr" /></template>
                                </Column>
                            </DataTable>
                            <div class="flex items-center gap-2 border-t border-surface-200 p-3 dark:border-surface-800">
                                <InputText v-model="newStatType" :placeholder="t('matches.customStat')" class="w-64" @keyup.enter="addStatRow" />
                                <Button :label="t('matches.addStat')" icon="pi pi-plus" text size="small" @click="addStatRow" />
                            </div>
                        </div>
                    </TabPanel>

                    <!-- News -->
                    <TabPanel value="news">
                        <div class="mb-4">
                            <Button :label="t('matches.addNews')" icon="pi pi-plus" @click="openNewsCreate" />
                        </div>
                        <div class="rounded-2xl border border-surface-200 dark:border-surface-800">
                            <DataTable :value="news" data-key="id" class="text-sm">
                                <template #empty><div class="py-6 text-center text-surface-500">{{ t('common.noData') }}</div></template>
                                <Column :header="t('matches.titleAr')">
                                    <template #body="{ data }">
                                        <p class="font-medium">{{ data.title_ar }}</p>
                                        <p v-if="data.title_en" class="text-xs text-surface-500" dir="ltr">{{ data.title_en }}</p>
                                    </template>
                                </Column>
                                <Column :header="t('matches.published')" :style="{ width: '8rem' }">
                                    <template #body="{ data }"><Tag :value="data.is_published ? t('matches.published') : '—'" :severity="data.is_published ? 'success' : 'secondary'" /></template>
                                </Column>
                                <Column :style="{ width: '6rem' }">
                                    <template #body="{ data }">
                                        <Button icon="pi pi-pencil" text rounded size="small" severity="secondary" @click="openNewsEdit(data)" />
                                        <Button icon="pi pi-trash" text rounded size="small" severity="danger" @click="delNews(data)" />
                                    </template>
                                </Column>
                            </DataTable>
                        </div>
                    </TabPanel>

                    <!-- Details / Broadcasts -->
                    <TabPanel value="details">
                        <div class="rounded-2xl border border-surface-200 p-4 dark:border-surface-800">
                            <h3 class="mb-3 font-semibold">{{ t('matches.broadcasts') }}</h3>
                            <div class="mb-4 flex flex-wrap items-end gap-2">
                                <InputText v-model="broadcastForm.channel_name" :placeholder="t('matches.channel')" class="w-48" />
                                <InputText v-model="broadcastForm.commentator_name" :placeholder="t('matches.commentator')" class="w-48" />
                                <InputText v-model="broadcastForm.stream_url" :placeholder="t('matches.streamUrl')" class="w-64" dir="ltr" />
                                <Button :label="t('common.add')" icon="pi pi-plus" @click="addBroadcast" />
                            </div>
                            <ul class="space-y-2">
                                <li v-for="b in broadcasts" :key="b.id" class="flex items-center gap-3 rounded-lg bg-surface-50 px-3 py-2 text-sm dark:bg-surface-800">
                                    <i class="pi pi-desktop text-surface-400"></i>
                                    <span class="font-medium">{{ b.channel_name }}</span>
                                    <span class="text-surface-500">{{ b.commentator_name }}</span>
                                    <Button icon="pi pi-times" text rounded size="small" severity="danger" class="ms-auto" @click="delBroadcast(b)" />
                                </li>
                            </ul>
                        </div>
                    </TabPanel>

                    <!-- Top scorers (league) -->
                    <TabPanel value="scorers">
                        <DataTable :value="scorers" data-key="id" class="text-sm">
                            <template #empty><div class="py-6 text-center text-surface-500">{{ t('common.noData') }}</div></template>
                            <Column :header="t('matches.rank')" field="rank" :style="{ width: '5rem' }" />
                            <Column :header="t('matches.player')" field="player_name" />
                            <Column :header="t('matches.team')" field="team_name" />
                            <Column :header="t('matches.goals')" field="goals" />
                        </DataTable>
                    </TabPanel>
                </TabPanels>
            </Tabs>
        </div>

        <!-- Event dialog -->
        <Dialog v-model:visible="eventDialog" modal :header="editingEventId ? t('matches.editEvent') : t('matches.logEvent')" :style="{ width: '30rem' }">
            <div class="flex flex-col gap-4 pt-2">
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.minute') }}</label>
                        <InputNumber v-model="eventForm.elapsed" class="w-full" :min="0" :max="130" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.team') }}</label>
                        <Select v-model="eventForm.team_id" :options="teamOptions" option-label="label" option-value="id" class="w-full" show-clear />
                    </div>
                </div>
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('matches.detail') }}</label>
                    <InputText v-model="eventForm.detail" class="w-full" />
                </div>
                <div v-if="eventForm.keyword?.needsPlayer" class="flex flex-col gap-2">
                    <label class="text-sm font-medium">{{ t('matches.player') }}</label>
                    <Select v-model="eventPlayerSel" :options="playerOptions" option-label="label" :placeholder="t('matches.selectPlayer')" :loading="playerLoading" filter reset-filter-on-hide :show-clear="false" class="w-full" @filter="onPlayerFilter" @change="(e) => pickEventPlayer(e.value)" />
                    <InputText v-model="eventForm.player_name" :placeholder="t('matches.playerName')" class="w-full" />
                    <label class="mt-1 text-sm font-medium">{{ t('matches.assist') }}</label>
                    <Select v-model="eventAssistSel" :options="playerOptions" option-label="label" :placeholder="t('matches.selectPlayer')" :loading="playerLoading" filter reset-filter-on-hide :show-clear="false" class="w-full" @filter="onPlayerFilter" @change="(e) => pickEventAssist(e.value)" />
                    <InputText v-model="eventForm.assist_name" :placeholder="t('matches.assist')" class="w-full" />
                </div>
            </div>
            <template #footer>
                <Button :label="t('common.cancel')" text severity="secondary" @click="eventDialog = false" />
                <Button :label="editingEventId ? t('common.save') : t('matches.logEvent')" icon="pi pi-check" :loading="submitting" @click="submitEvent" />
            </template>
        </Dialog>

        <!-- Lineup dialog -->
        <Dialog v-model:visible="lineupDialog" modal :header="t('matches.editLineup')" :style="{ width: '46rem' }">
            <div class="flex flex-col gap-3 pt-2">
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.formation') }}</label>
                        <InputText v-model="lineupForm.formation" class="w-full" dir="ltr" placeholder="4-3-3" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.coachName') }}</label>
                        <InputText v-model="lineupForm.coach_name" class="w-full" />
                    </div>
                </div>
                <ImageUploadField v-model="lineupForm.coach_photo" endpoint="/lineups/upload" :label="t('matches.coachPhoto')" />
                <div class="max-h-96 overflow-y-auto">
                    <div v-for="(p, i) in lineupForm.players" :key="i" class="mb-3 rounded-xl border border-surface-200 p-3 dark:border-surface-800">
                        <div class="mb-2 grid grid-cols-12 items-center gap-2">
                            <InputText v-model="p.player_name" :placeholder="t('matches.playerName')" class="col-span-5" />
                            <InputNumber v-model="p.number" :placeholder="t('matches.number')" class="col-span-2" :use-grouping="false" />
                            <InputText v-model="p.position" placeholder="G/D/M/F" class="col-span-2" />
                            <InputText v-model="p.grid" placeholder="1:1" class="col-span-2" dir="ltr" />
                            <Button icon="pi pi-times" text rounded size="small" severity="danger" class="col-span-1" @click="removeLineupRow(i)" />
                        </div>
                        <div class="grid grid-cols-12 items-center gap-2">
                            <Select v-model="p._sel" :options="playerOptions" option-label="label" :placeholder="t('matches.selectPlayer')" :loading="playerLoading" filter reset-filter-on-hide :show-clear="false" class="col-span-5" @filter="onPlayerFilter" @change="(e) => pickLineupPlayer(e.value, p)" />
                            <div class="col-span-5">
                                <ImageUploadField v-model="p.photo_path" endpoint="/lineups/upload" />
                            </div>
                            <label class="col-span-2 flex items-center gap-1 text-xs"><Checkbox v-model="p.is_starter" :binary="true" />{{ t('matches.starter') }}</label>
                        </div>
                    </div>
                </div>
                <Button :label="t('matches.addPlayer')" icon="pi pi-plus" text size="small" @click="addLineupRow" />
            </div>
            <template #footer>
                <Button :label="t('common.cancel')" text severity="secondary" @click="lineupDialog = false" />
                <Button :label="t('common.save')" icon="pi pi-check" @click="saveLineup" />
            </template>
        </Dialog>

        <!-- News dialog -->
        <Dialog v-model:visible="newsDialog" modal :header="editingNewsId ? t('matches.editNews') : t('matches.addNews')" :style="{ width: '44rem' }">
            <div class="flex flex-col gap-4 pt-2">
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.titleAr') }}</label>
                        <InputText v-model="newsForm.title_ar" class="w-full" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.titleEn') }}</label>
                        <InputText v-model="newsForm.title_en" class="w-full" dir="ltr" />
                    </div>
                </div>
                <ImageUploadField v-model="newsForm.cover_path" endpoint="/fixture-news/upload" :label="t('matches.cover')" />
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.excerptAr') }}</label>
                        <Textarea v-model="newsForm.excerpt_ar" rows="2" class="w-full" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.excerptEn') }}</label>
                        <Textarea v-model="newsForm.excerpt_en" rows="2" class="w-full" dir="ltr" />
                    </div>
                </div>
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.contentAr') }}</label>
                        <Textarea v-model="newsForm.content_ar" rows="4" class="w-full" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.contentEn') }}</label>
                        <Textarea v-model="newsForm.content_en" rows="4" class="w-full" dir="ltr" />
                    </div>
                </div>
                <label class="flex items-center gap-2 text-sm"><ToggleSwitch v-model="newsForm.is_published" />{{ t('matches.published') }}</label>
            </div>
            <template #footer>
                <Button :label="t('common.cancel')" text severity="secondary" @click="newsDialog = false" />
                <Button :label="t('common.save')" icon="pi pi-check" :loading="savingNews" @click="saveNews" />
            </template>
        </Dialog>
    </div>
</template>
