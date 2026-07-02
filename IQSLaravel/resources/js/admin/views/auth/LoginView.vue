<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter, useRoute } from 'vue-router';
import { storeToRefs } from 'pinia';
import { useToast } from 'primevue/usetoast';
import { useUiStore } from '@admin/stores/ui';
import { useAuthStore } from '@admin/stores/auth';
import AppLogo from '@admin/components/AppLogo.vue';

const { t } = useI18n();
const router = useRouter();
const route = useRoute();
const toast = useToast();
const ui = useUiStore();
const auth = useAuthStore();
const { isDark, isRtl } = storeToRefs(ui);

const email = ref('admin@iqs.app');
const password = ref('password');
const remember = ref(true);
const submitting = ref(false);

const features = {
    ar: ['تغطية المباريات والبطولات', 'السوق الرياضي والأندية', 'إشعارات فورية للجماهير'],
    en: ['Live match & league coverage', 'Marketplace & club pages', 'Real-time fan notifications'],
};

async function onSubmit() {
    if (submitting.value) {
        return;
    }
    submitting.value = true;
    try {
        await auth.login({ email: email.value, password: password.value, remember: remember.value });
        const redirect = route.query.redirect;
        router.push(typeof redirect === 'string' ? redirect : { name: 'dashboard' });
    } catch (e) {
        toast.add({
            severity: 'error',
            summary: t('login.signIn'),
            detail: e?.response?.data?.message || 'Login failed',
            life: 4000,
        });
    } finally {
        submitting.value = false;
    }
}
</script>

<template>
    <div class="grid h-full bg-surface-50 dark:bg-surface-950 lg:grid-cols-2">
        <!-- Brand panel -->
        <div class="relative hidden flex-col justify-between overflow-hidden bg-gradient-to-br from-emerald-600 via-emerald-700 to-emerald-900 p-12 text-white lg:flex">
            <div class="pointer-events-none absolute -top-24 -end-24 size-80 rounded-full bg-white/10 blur-2xl"></div>
            <div class="pointer-events-none absolute -bottom-32 -start-16 size-96 rounded-full bg-emerald-400/20 blur-3xl"></div>

            <div class="relative flex items-center gap-3">
                <span class="grid size-11 place-items-center rounded-xl bg-white/15 backdrop-blur">
                    <svg viewBox="0 0 32 32" class="size-7" fill="none" aria-hidden="true">
                        <circle cx="16" cy="16" r="11" stroke="currentColor" stroke-width="2" />
                        <path d="M16 9.6l4.3 3.12-1.64 5.05h-5.32L11.7 12.72z" fill="currentColor" />
                        <path d="M16 9.6V6M20.3 12.72l3.4-1.1M18.66 17.77l2.05 2.86M13.34 17.77l-2.05 2.86M11.7 12.72l-3.4-1.1" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" />
                    </svg>
                </span>
                <span class="text-2xl font-extrabold tracking-tight">IQS</span>
            </div>

            <div class="relative max-w-md">
                <h2 class="text-3xl font-bold leading-snug">{{ t('common.appNameFull') }}</h2>
                <p class="mt-4 text-emerald-50/90">{{ t('login.brandTagline') }}</p>
                <ul class="mt-8 space-y-3">
                    <li v-for="f in features[isRtl ? 'ar' : 'en']" :key="f" class="flex items-center gap-3 text-emerald-50">
                        <span class="grid size-6 place-items-center rounded-full bg-white/20"><i class="pi pi-check text-xs"></i></span>
                        {{ f }}
                    </li>
                </ul>
            </div>

            <p class="relative text-sm text-emerald-100/70">© 2026 {{ t('login.rights') }}</p>
        </div>

        <!-- Form panel -->
        <div class="relative flex items-center justify-center p-6 sm:p-10">
            <div class="absolute top-4 end-4 flex items-center gap-1">
                <Button type="button" text rounded severity="secondary" :label="isRtl ? 'EN' : 'ع'" icon="pi pi-globe" :aria-label="t('topbar.toggleLanguage')" v-tooltip.bottom="t('topbar.toggleLanguage')" @click="ui.toggleLocale()" />
                <Button type="button" text rounded severity="secondary" :icon="isDark ? 'pi pi-sun' : 'pi pi-moon'" :aria-label="t('topbar.toggleTheme')" v-tooltip.bottom="isDark ? t('topbar.lightMode') : t('topbar.darkMode')" @click="ui.toggleTheme()" />
            </div>

            <div class="w-full max-w-sm">
                <div class="mb-8 flex justify-center lg:hidden">
                    <AppLogo />
                </div>

                <h1 class="text-2xl font-bold text-surface-900 dark:text-surface-0">{{ t('login.title') }}</h1>
                <p class="mt-1 text-sm text-surface-500 dark:text-surface-400">{{ t('login.subtitle') }}</p>

                <form class="mt-8 space-y-5" @submit.prevent="onSubmit">
                    <div>
                        <label class="mb-1.5 block text-sm font-medium text-surface-700 dark:text-surface-200" for="email">{{ t('login.email') }}</label>
                        <IconField>
                            <InputIcon class="pi pi-envelope" />
                            <InputText id="email" v-model="email" type="email" :placeholder="t('login.emailPlaceholder')" class="w-full" autocomplete="username" required />
                        </IconField>
                    </div>

                    <div>
                        <label class="mb-1.5 block text-sm font-medium text-surface-700 dark:text-surface-200" for="password">{{ t('login.password') }}</label>
                        <Password
                            id="password"
                            v-model="password"
                            :feedback="false"
                            toggle-mask
                            :placeholder="t('login.passwordPlaceholder')"
                            fluid
                            input-class="w-full"
                            autocomplete="current-password"
                        />
                    </div>

                    <div class="flex items-center justify-between">
                        <label class="flex cursor-pointer items-center gap-2 text-sm text-surface-600 dark:text-surface-300">
                            <Checkbox v-model="remember" :binary="true" />
                            {{ t('login.remember') }}
                        </label>
                        <a href="#" class="text-sm font-medium text-emerald-600 hover:underline dark:text-emerald-400" @click.prevent>{{ t('login.forgot') }}</a>
                    </div>

                    <Button
                        type="submit"
                        :label="submitting ? t('login.signingIn') : t('login.signIn')"
                        :loading="submitting"
                        icon="pi pi-sign-in"
                        class="w-full"
                        size="large"
                    />
                </form>

                <div class="mt-6 flex items-start gap-2 rounded-lg bg-amber-50 px-3 py-2.5 text-xs text-amber-700 dark:bg-amber-500/10 dark:text-amber-400">
                    <i class="pi pi-info-circle mt-0.5"></i>
                    <span>{{ t('login.demoNote') }}</span>
                </div>
            </div>
        </div>
    </div>
</template>
