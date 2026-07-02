import client from './client';

/** Application settings (/admin/api/v1/settings). */
export const settingsApi = {
    list(params = {}) {
        return client.get('/settings', { params });
    },
    create(payload) {
        return client.post('/settings', payload);
    },
    update(id, payload) {
        return client.put(`/settings/${id}`, payload);
    },
    remove(id) {
        return client.delete(`/settings/${id}`);
    },
};

export default settingsApi;
