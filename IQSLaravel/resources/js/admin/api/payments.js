import client from './client';

/** Admin payments API (/admin/api/v1/payments). */
export const paymentsApi = {
    list: (params = {}) => client.get('/payments', { params }),
    show: (id) => client.get(`/payments/${id}`),
    refund: (id) => client.post(`/payments/${id}/refund`),
    webhooks: (params = {}) => client.get('/payments/webhooks', { params }),
};

export default paymentsApi;
