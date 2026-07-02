import client from './client';

/** Admin marketplace API (/admin/api/v1/marketplace). */
export const marketplaceApi = {
    // Categories
    categories: () => client.get('/marketplace/categories'),
    createCategory: (p) => client.post('/marketplace/categories', p),
    updateCategory: (id, p) => client.put(`/marketplace/categories/${id}`, p),
    deleteCategory: (id) => client.delete(`/marketplace/categories/${id}`),

    // Stores
    stores: (params = {}) => client.get('/marketplace/stores', { params }),
    store: (id) => client.get(`/marketplace/stores/${id}`),
    verifyStore: (id) => client.post(`/marketplace/stores/${id}/verify`),
    suspendStore: (id) => client.post(`/marketplace/stores/${id}/suspend`),
    activateStore: (id) => client.post(`/marketplace/stores/${id}/activate`),

    // Listings review queue
    listings: (params = {}) => client.get('/marketplace/listings', { params }),
    listing: (id) => client.get(`/marketplace/listings/${id}`),
    approveListing: (id) => client.post(`/marketplace/listings/${id}/approve`),
    rejectListing: (id, reason) => client.post(`/marketplace/listings/${id}/reject`, { reason }),
    featureListing: (id, days = 30) => client.post(`/marketplace/listings/${id}/feature`, { days }),

    contactsReport: () => client.get('/marketplace/contacts/report'),
};

export default marketplaceApi;
