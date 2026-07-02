import client from './client';

/**
 * Auth API calls against the admin backend (web.php, `web` guard).
 * Used by the auth store when DEMO_MODE is disabled.
 */
export const authApi = {
    login(credentials) {
        return client.post('/login', credentials);
    },
    logout() {
        return client.post('/logout');
    },
    me() {
        return client.get('/me');
    },
};

export default authApi;
