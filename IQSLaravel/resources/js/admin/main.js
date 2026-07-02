import { createApp } from 'vue';
import { createPinia } from 'pinia';
import PrimeVue from 'primevue/config';
import ToastService from 'primevue/toastservice';
import ConfirmationService from 'primevue/confirmationservice';
import Tooltip from 'primevue/tooltip';
import Ripple from 'primevue/ripple';

import 'primeicons/primeicons.css';

import App from './App.vue';
import router from './router';
import { i18n, getStoredLocale } from './i18n';
import { primeLocaleFor } from './i18n/primevue-locales';
import { IqsPreset } from './theme/preset';
import { useUiStore } from './stores/ui';
import { registerComponents } from './plugins/primevue-components';

const app = createApp(App);
const pinia = createPinia();

app.use(pinia);
app.use(i18n);

app.use(PrimeVue, {
    ripple: true,
    theme: {
        preset: IqsPreset,
        options: {
            darkModeSelector: '.dark',
            cssLayer: false,
        },
    },
    locale: primeLocaleFor(getStoredLocale()),
});

app.use(ToastService);
app.use(ConfirmationService);
app.directive('tooltip', Tooltip);
app.directive('ripple', Ripple);

registerComponents(app);

// Sync the document (dark class / dir / lang) before mounting.
const ui = useUiStore(pinia);
ui.applyToDocument();

app.use(router);
app.mount('#admin-app');
