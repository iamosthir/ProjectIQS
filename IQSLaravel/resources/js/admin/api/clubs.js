import client from './client';

/** Admin clubs API (/admin/api/v1/clubs). */
export const clubsApi = {
    list: (params = {}) => client.get('/clubs', { params }),
    get: (id) => client.get(`/clubs/${id}`),
    create: (p) => client.post('/clubs', p),
    update: (id, p) => client.put(`/clubs/${id}`, p),
    remove: (id) => client.delete(`/clubs/${id}`),
    verify: (id) => client.post(`/clubs/${id}/verify`),

    // Nested content (board, staff, titles, captains, competitions)
    addChild: (clubId, type, p) => client.post(`/clubs/${clubId}/content/${type}`, p),
    updateChild: (clubId, type, id, p) => client.put(`/clubs/${clubId}/content/${type}/${id}`, p),
    removeChild: (clubId, type, id) => client.delete(`/clubs/${clubId}/content/${type}/${id}`),

    // News
    addNews: (clubId, p) => client.post(`/clubs/${clubId}/news`, p),
    updateNews: (clubId, newsId, p) => client.put(`/clubs/${clubId}/news/${newsId}`, p),
    removeNews: (clubId, newsId) => client.delete(`/clubs/${clubId}/news/${newsId}`),

    // Verifications
    verifications: (params = {}) => client.get('/clubs/verifications', { params }),
    approveVerification: (id) => client.post(`/clubs/verifications/${id}/approve`),
    rejectVerification: (id, note) => client.post(`/clubs/verifications/${id}/reject`, { note }),
};

export default clubsApi;
