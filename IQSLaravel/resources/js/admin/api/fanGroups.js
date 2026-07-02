import client from './client';

/** Admin fan-groups API (/admin/api/v1/fan-groups). */
export const fanGroupsApi = {
    list: (params = {}) => client.get('/fan-groups', { params }),
    get: (id) => client.get(`/fan-groups/${id}`),
    create: (p) => client.post('/fan-groups', p),
    update: (id, p) => client.put(`/fan-groups/${id}`, p),
    remove: (id) => client.delete(`/fan-groups/${id}`),
    verify: (id) => client.post(`/fan-groups/${id}/verify`),

    // Archives
    addMedia: (id, p) => client.post(`/fan-groups/${id}/media`, p),
    removeMedia: (id, mediaId) => client.delete(`/fan-groups/${id}/media/${mediaId}`),
    addChant: (id, p) => client.post(`/fan-groups/${id}/chants`, p),
    removeChant: (id, chantId) => client.delete(`/fan-groups/${id}/chants/${chantId}`),
    addDocument: (id, p) => client.post(`/fan-groups/${id}/documents`, p),
    removeDocument: (id, docId) => client.delete(`/fan-groups/${id}/documents/${docId}`),

    // Verifications
    verifications: (params = {}) => client.get('/fan-groups/verifications', { params }),
    approveVerification: (id) => client.post(`/fan-groups/verifications/${id}/approve`),
    rejectVerification: (id, note) => client.post(`/fan-groups/verifications/${id}/reject`, { note }),
};

export default fanGroupsApi;
