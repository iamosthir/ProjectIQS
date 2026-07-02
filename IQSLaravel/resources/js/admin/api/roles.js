import client from './client';

/** Role & permission management (/admin/api/v1/roles, /permissions). */
export const rolesApi = {
    list() {
        return client.get('/roles');
    },
    permissions() {
        return client.get('/permissions');
    },
    create(payload) {
        return client.post('/roles', payload);
    },
    update(id, payload) {
        return client.put(`/roles/${id}`, payload);
    },
    remove(id) {
        return client.delete(`/roles/${id}`);
    },
};

export default rolesApi;
