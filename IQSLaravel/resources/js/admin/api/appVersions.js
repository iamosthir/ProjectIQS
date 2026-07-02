import client from './client';

/** Mobile app version gate (/admin/api/v1/app-versions). */
export const appVersionsApi = {
    list(params = {}) {
        return client.get('/app-versions', { params });
    },
    create(payload) {
        return client.post('/app-versions', payload);
    },
    update(id, payload) {
        return client.put(`/app-versions/${id}`, payload);
    },
    remove(id) {
        return client.delete(`/app-versions/${id}`);
    },
};

export default appVersionsApi;
