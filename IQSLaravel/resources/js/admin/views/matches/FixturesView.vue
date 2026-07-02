<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import PageHeader from '@admin/components/PageHeader.vue';
import { matchesApi } from '@admin/api/matches';
import { useFormErrors } from '@admin/composables/useFormErrors';

const { t } = useI18n();
const router = useRouter();
const toast = useToast();
const confirm = useConfirm();
const { reset, setFrom, first } = useFormErrors();

const STATUSES = ['scheduled', 'live', 'finished', 'postponed', 'cancelled'];

const rows = ref([]);
const leagues = ref([]);
const teams = ref([]);
const loading = ref(false);
const statusFilter = ref(null);
const dialog = ref(false);
const saving = ref(false);
const form = ref(empty());

function empty() {
    return {
        id: null, league_id: null, home_team_id: null, away_team_id: null, venue_id: null, round: '',
        match_datetime: null, status_group: 'scheduled', referee: '', referee_assistant_1: '', referee_assistant_2: '',
        referee_fourth_official: '', supervisor: '', home_goals: null, away_goals: null, is_featured: false,
    };
}
function toastErr(e) { toast.add({ severity: 'error', summary: t('common.actions'), detail: e?.response?.data?.message || 'Error', life: 4000 }); }

function logoUrl(p) { return /^https?:\/\//.test(p) ? p : `/storage/${p}`; }

async function load() {
    loading.value = true;
    try {
        const params = { per_page: 50 };
        if (statusFilter.value) params['filter[status_group]'] = statusFilter.value;
        const { data } = await matchesApi.fixtures(params);
        rows.value = data.data;
    } catch (e) { toastErr(e); } finally { loading.value = false; }
}

// Team picker: server-side search (the API caps pages at 50 rows, so the old
// bulk fetch silently hid every team past the first 50). Labels join AR + EN
// so the dropdown's client filter matches whichever the admin typed; selected
// ids are kept visible via a small cache even when outside the current page.
const teamCache = ref({});
let teamTimer = null;

function teamOption(x) {
    return { id: x.id, label: [x.name_ar, x.name_en].filter(Boolean).join(' · ') };
}
async function searchTeams(q) {
    try {
        const { data } = await matchesApi.teams({ 'filter[search]': q || undefined, per_page: 50 });
        const opts = data.data.map(teamOption);
        opts.forEach((o) => { teamCache.value[o.id] = o; });
        for (const id of [form.value.home_team_id, form.value.away_team_id]) {
            if (id && !opts.some((o) => o.id === id) && teamCache.value[id]) opts.push(teamCache.value[id]);
        }
        teams.value = opts;
    } catch (e) { /* non-blocking */ }
}
function onTeamFilter(e) {
    clearTimeout(teamTimer);
    teamTimer = setTimeout(() => searchTeams(e.value), 300);
}

async function loadRefs() {
    try {
        const [l] = await Promise.all([matchesApi.leagues({ per_page: 50 }), searchTeams('')]);
        leagues.value = l.data.data;
    } catch (e) { toastErr(e); }
}
const leagueOptions = computed(() => leagues.value.map((l) => ({ id: l.id, label: l.name_ar || l.name_en })));

function openCreate() { reset(); form.value = empty(); dialog.value = true; }
function openEdit(r) {
    reset();
    // Seed the picker cache so the fixture's teams stay visible/labelled even
    // when they fall outside the current search page.
    if (r.home_team) teamCache.value[r.home_team_id] = teamOption(r.home_team);
    if (r.away_team) teamCache.value[r.away_team_id] = teamOption(r.away_team);
    form.value = {
        id: r.id, league_id: r.league_id, home_team_id: r.home_team_id, away_team_id: r.away_team_id, venue_id: r.venue_id,
        round: r.round, match_datetime: r.match_datetime ? new Date(r.match_datetime) : null, status_group: r.status_group,
        referee: r.officials?.referee, referee_assistant_1: r.officials?.assistant_1, referee_assistant_2: r.officials?.assistant_2,
        referee_fourth_official: r.officials?.fourth_official, supervisor: r.officials?.supervisor,
        home_goals: r.score?.home_goals, away_goals: r.score?.away_goals, is_featured: r.is_featured,
    };
    searchTeams('');
    dialog.value = true;
}
async function save() {
    saving.value = true; reset();
    try {
        const payload = { ...form.value };
        if (payload.match_datetime instanceof Date) payload.match_datetime = payload.match_datetime.toISOString();
        if (form.value.id) await matchesApi.updateFixture(form.value.id, payload);
        else await matchesApi.createFixture(payload);
        toast.add({ severity: 'success', summary: t('common.save'), life: 2500 });
        dialog.value = false; await load();
    } catch (e) { if (!setFrom(e)) toastErr(e); } finally { saving.value = false; }
}
function del(r) {
    confirm.require({
        message: t('matches.deleteFixtureConfirm'), header: t('common.delete'), icon: 'pi pi-exclamation-triangle',
        rejectLabel: t('common.cancel'), acceptLabel: t('common.delete'), acceptClass: 'p-button-danger',
        accept: async () => { try { await matchesApi.deleteFixture(r.id); await load(); } catch (e) { toastErr(e); } },
    });
}
function openConsole(r) { router.push({ name: 'match-console', params: { id: r.id } }); }
function statusSeverity(s) { return { live: 'danger', finished: 'secondary', scheduled: 'info' }[s] || 'warn'; }

onMounted(() => { loadRefs(); load(); });
</script>

<template>
    <div>
        <PageHeader :title="t('fixtures.title')" :subtitle="t('fixtures.subtitle')" icon="pi pi-calendar">
            <template #actions><Button :label="t('fixtures.addFixture')" icon="pi pi-plus" @click="openCreate" /></template>
        </PageHeader>

        <div class="rounded-2xl border border-surface-200 bg-surface-0 dark:border-surface-800 dark:bg-surface-900">
            <div class="flex flex-wrap items-center gap-3 border-b border-surface-200 p-4 dark:border-surface-800">
                <Select v-model="statusFilter" :options="STATUSES" :placeholder="t('fixtures.statusAll')" show-clear class="w-48" @change="load" />
            </div>
            <DataTable :value="rows" :loading="loading" data-key="id" class="text-sm">
                <template #empty><div class="py-8 text-center text-surface-500">{{ t('common.noData') }}</div></template>
                <Column :header="t('fixtures.match')">
                    <template #body="{ data }">
                        <div class="flex items-center gap-2">
                            <img v-if="data.home_team?.logo" :src="logoUrl(data.home_team.logo)" alt="" class="h-6 w-6 rounded-full object-cover" />
                            <span class="font-medium">{{ data.home_team?.name_ar || data.home_team?.name_en }}</span>
                            <span class="text-surface-400" dir="ltr">
                                {{ data.score?.home_goals ?? '-' }} : {{ data.score?.away_goals ?? '-' }}
                            </span>
                            <span class="font-medium">{{ data.away_team?.name_ar || data.away_team?.name_en }}</span>
                            <img v-if="data.away_team?.logo" :src="logoUrl(data.away_team.logo)" alt="" class="h-6 w-6 rounded-full object-cover" />
                        </div>
                        <p class="text-xs text-surface-500">{{ data.league?.name }} · {{ data.round }}</p>
                    </template>
                </Column>
                <Column :header="t('fixtures.kickoff')">
                    <template #body="{ data }"><span dir="ltr">{{ data.match_datetime ? new Date(data.match_datetime).toLocaleString() : '' }}</span></template>
                </Column>
                <Column :header="t('common.status')">
                    <template #body="{ data }"><Tag :value="data.status_group" :severity="statusSeverity(data.status_group)" /></template>
                </Column>
                <Column :header="t('common.actions')" :style="{ width: '12rem' }">
                    <template #body="{ data }">
                        <Button :label="t('matches.console')" icon="pi pi-sliders-h" size="small" outlined @click="openConsole(data)" />
                        <Button icon="pi pi-pencil" text rounded size="small" severity="secondary" @click="openEdit(data)" />
                        <Button icon="pi pi-trash" text rounded size="small" severity="danger" @click="del(data)" />
                    </template>
                </Column>
            </DataTable>
        </div>

        <Dialog v-model:visible="dialog" modal :header="form.id ? t('matches.editFixture') : t('fixtures.addFixture')" :style="{ width: '40rem' }">
            <div class="flex flex-col gap-4 pt-2">
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('fixtures.league') }}</label>
                        <Select v-model="form.league_id" :options="leagueOptions" option-label="label" option-value="id" filter class="w-full" :invalid="!!first('league_id')" />
                        <Message v-if="first('league_id')" severity="error" size="small" variant="simple">{{ first('league_id') }}</Message>
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('fixtures.kickoff') }}</label>
                        <DatePicker v-model="form.match_datetime" show-time hour-format="24" class="w-full" :invalid="!!first('match_datetime')" />
                    </div>
                </div>
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.homeTeam') }}</label>
                        <Select v-model="form.home_team_id" :options="teams" option-label="label" option-value="id" filter reset-filter-on-hide class="w-full" :invalid="!!first('home_team_id')" @filter="onTeamFilter" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.awayTeam') }}</label>
                        <Select v-model="form.away_team_id" :options="teams" option-label="label" option-value="id" filter reset-filter-on-hide class="w-full" :invalid="!!first('away_team_id')" @filter="onTeamFilter" />
                        <Message v-if="first('away_team_id')" severity="error" size="small" variant="simple">{{ first('away_team_id') }}</Message>
                    </div>
                </div>
                <div class="grid grid-cols-3 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('common.status') }}</label>
                        <Select v-model="form.status_group" :options="STATUSES" class="w-full" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.homeGoals') }}</label>
                        <InputNumber v-model="form.home_goals" class="w-full" :min="0" show-buttons />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('matches.awayGoals') }}</label>
                        <InputNumber v-model="form.away_goals" class="w-full" :min="0" show-buttons />
                    </div>
                </div>
                <Divider align="left"><span class="text-xs text-surface-500">{{ t('matches.officials') }}</span></Divider>
                <div class="grid grid-cols-2 gap-3">
                    <InputText v-model="form.referee" :placeholder="t('matches.referee')" class="w-full" />
                    <InputText v-model="form.supervisor" :placeholder="t('matches.supervisor')" class="w-full" />
                    <InputText v-model="form.referee_assistant_1" :placeholder="t('matches.assistant1')" class="w-full" />
                    <InputText v-model="form.referee_assistant_2" :placeholder="t('matches.assistant2')" class="w-full" />
                    <InputText v-model="form.referee_fourth_official" :placeholder="t('matches.fourthOfficial')" class="w-full" />
                    <InputText v-model="form.round" :placeholder="t('matches.round')" class="w-full" />
                </div>
            </div>
            <template #footer>
                <Button :label="t('common.cancel')" text severity="secondary" @click="dialog = false" />
                <Button :label="t('common.save')" icon="pi pi-check" :loading="saving" @click="save" />
            </template>
        </Dialog>
    </div>
</template>
