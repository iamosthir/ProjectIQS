import axios from 'axios';
import { getStoredLocale } from '@admin/i18n';

/**
 * Pre-configured axios instance for the admin JSON API.
 *
 * Same-origin session auth: `withCredentials` sends the session cookie and
 * axios echoes the Laravel XSRF-TOKEN cookie back as the X-XSRF-TOKEN header
 * automatically. Point `baseURL` at the admin API once it exists in web.php.
 */
const client = axios.create({
    baseURL: '/admin/api/v1',
    withCredentials: true,
    withXSRFToken: true,
    headers: {
        Accept: 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
    },
});

client.interceptors.request.use((config) => {
    config.headers['Accept-Language'] = getStoredLocale();
    return config;
});

client.interceptors.response.use(
    (response) => response,
    (error) => {
        // 401/403/422/429 handling is wired in the auth store / form layer.
        return Promise.reject(error);
    }
);

/**
 * Upload a single file to `url` as multipart/form-data.
 *
 * @param {string} url - endpoint path relative to the admin API baseURL.
 * @param {File} file - the file to upload.
 * @param {string} [field='file'] - the form field name the backend expects.
 * @returns {Promise<import('axios').AxiosResponse>}
 */
export function uploadFile(url, file, field = 'file') {
    const fd = new FormData();
    fd.append(field, file);
    return client.post(url, fd, {
        headers: { 'Content-Type': 'multipart/form-data' },
    });
}

export default client;
