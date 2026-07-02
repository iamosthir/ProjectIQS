import client from './client';

/** Promotional banners (/admin/api/v1/banners). */
export const bannersApi = {
    list(params = {}) {
        return client.get('/banners', { params });
    },
    create(payload) {
        return client.post('/banners', payload);
    },
    update(id, payload) {
        return client.put(`/banners/${id}`, payload);
    },
    remove(id) {
        return client.delete(`/banners/${id}`);
    },
};

/** Static content pages (/admin/api/v1/pages). */
export const pagesApi = {
    list(params = {}) {
        return client.get('/pages', { params });
    },
    create(payload) {
        return client.post('/pages', payload);
    },
    update(id, payload) {
        return client.put(`/pages/${id}`, payload);
    },
    remove(id) {
        return client.delete(`/pages/${id}`);
    },
};
