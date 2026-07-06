import client from './client';

/** Admin match module API (/admin/api/v1). */
export const matchesApi = {
    // Leagues
    leagues: (params = {}) => client.get('/leagues', { params }),
    createLeague: (p) => client.post('/leagues', p),
    updateLeague: (id, p) => client.put(`/leagues/${id}`, p),
    deleteLeague: (id) => client.delete(`/leagues/${id}`),
    toggleLeagueLock: (id) => client.post(`/leagues/${id}/toggle-lock`),

    // Seasons
    seasons: (params = {}) => client.get('/seasons', { params }),
    createSeason: (p) => client.post('/seasons', p),
    updateSeason: (id, p) => client.put(`/seasons/${id}`, p),
    deleteSeason: (id) => client.delete(`/seasons/${id}`),

    // Venues
    venues: (params = {}) => client.get('/venues', { params }),
    createVenue: (p) => client.post('/venues', p),
    updateVenue: (id, p) => client.put(`/venues/${id}`, p),
    deleteVenue: (id) => client.delete(`/venues/${id}`),

    // Teams
    teams: (params = {}) => client.get('/teams', { params }),
    createTeam: (p) => client.post('/teams', p),
    updateTeam: (id, p) => client.put(`/teams/${id}`, p),
    deleteTeam: (id) => client.delete(`/teams/${id}`),
    toggleTeamLock: (id) => client.post(`/teams/${id}/toggle-lock`),

    // Players
    players: (params = {}) => client.get('/players', { params }),
    createPlayer: (p) => client.post('/players', p),
    updatePlayer: (id, p) => client.put(`/players/${id}`, p),
    deletePlayer: (id) => client.delete(`/players/${id}`),

    // Fixtures
    fixtures: (params = {}) => client.get('/fixtures', { params }),
    fixture: (id) => client.get(`/fixtures/${id}`),
    createFixture: (p) => client.post('/fixtures', p),
    updateFixture: (id, p) => client.put(`/fixtures/${id}`, p),
    deleteFixture: (id) => client.delete(`/fixtures/${id}`),

    // Standings
    standings: (params = {}) => client.get('/standings', { params }),
    createStanding: (p) => client.post('/standings', p),
    updateStanding: (id, p) => client.put(`/standings/${id}`, p),
    deleteStanding: (id) => client.delete(`/standings/${id}`),

    // Fixture detail console
    broadcasts: (fixtureId) => client.get(`/fixtures/${fixtureId}/broadcasts`),
    addBroadcast: (fixtureId, p) => client.post(`/fixtures/${fixtureId}/broadcasts`, p),
    deleteBroadcast: (fixtureId, id) => client.delete(`/fixtures/${fixtureId}/broadcasts/${id}`),
    lineups: (fixtureId) => client.get(`/fixtures/${fixtureId}/lineups`),
    saveLineup: (fixtureId, p) => client.post(`/fixtures/${fixtureId}/lineups`, p),
    events: (fixtureId) => client.get(`/fixtures/${fixtureId}/events`),
    addEvent: (fixtureId, p) => client.post(`/fixtures/${fixtureId}/events`, p),
    updateEvent: (fixtureId, id, p) => client.put(`/fixtures/${fixtureId}/events/${id}`, p),
    deleteEvent: (fixtureId, id) => client.delete(`/fixtures/${fixtureId}/events/${id}`),
    statistics: (fixtureId) => client.get(`/fixtures/${fixtureId}/statistics`),
    saveStatistics: (fixtureId, p) => client.post(`/fixtures/${fixtureId}/statistics`, p),
    fixtureNews: (fixtureId) => client.get(`/fixtures/${fixtureId}/news`),
    createNews: (fixtureId, p) => client.post(`/fixtures/${fixtureId}/news`, p),
    updateNews: (fixtureId, id, p) => client.put(`/fixtures/${fixtureId}/news/${id}`, p),
    deleteNews: (fixtureId, id) => client.delete(`/fixtures/${fixtureId}/news/${id}`),
    playerSearch: (q) => client.get('/players', { params: { 'filter[search]': q || undefined, per_page: 30 } }),
    fixturePredictions: (fixtureId, params = {}) => client.get(`/fixtures/${fixtureId}/predictions`, { params }),

    // League top scorers
    topScorers: (leagueId, params = {}) => client.get(`/leagues/${leagueId}/top-scorers`, { params }),
    addScorer: (leagueId, p) => client.post(`/leagues/${leagueId}/top-scorers`, p),
    updateScorer: (leagueId, id, p) => client.put(`/leagues/${leagueId}/top-scorers/${id}`, p),
    deleteScorer: (leagueId, id) => client.delete(`/leagues/${leagueId}/top-scorers/${id}`),

    // Sync console
    syncLeagues: (p = {}) => client.post('/sync/leagues', p),
    syncTeams: (p) => client.post('/sync/teams', p),
    syncStandings: (p) => client.post('/sync/standings', p),
    syncFixtures: (p) => client.post('/sync/fixtures', p),
    syncTopScorers: (p) => client.post('/sync/top-scorers', p),
    syncFixtureDetails: (fixtureId) => client.post(`/fixtures/${fixtureId}/sync-details`),
    syncLogs: (params = {}) => client.get('/sync/logs', { params }),

    // Auto-sync subscriptions (seasons.auto_sync)
    syncAutoStatus: () => client.get('/sync/auto'),
    toggleSeasonAutoSync: (seasonId, p) => client.post(`/sync/auto/seasons/${seasonId}`, p),

    // Comment moderation
    comments: (params = {}) => client.get('/comments', { params }),
    hideComment: (id) => client.post(`/comments/${id}/hide`),
    deleteComment: (id) => client.delete(`/comments/${id}`),
};

export default matchesApi;
