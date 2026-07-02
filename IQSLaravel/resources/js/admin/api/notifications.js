import client from './client';

/** Admin notifications API (/admin/api/v1/notifications). */
export const notificationsApi = {
    compose: () => client.get('/notifications/compose'),
    send: (p) => client.post('/notifications/send', p),
    batches: (params = {}) => client.get('/notifications/batches', { params }),
    batch: (id) => client.get(`/notifications/batches/${id}`),
};

export default notificationsApi;
