import client from './client';

/** Admin user management (/admin/api/v1/admins). */
export const adminsApi = {
    list(params = {}) {
        return client.get('/admins', { params });
    },
    create(payload) {
        return client.post('/admins', payload);
    },
    update(id, payload) {
        return client.put(`/admins/${id}`, payload);
    },
    remove(id) {
        return client.delete(`/admins/${id}`);
    },
};

export default adminsApi;
