<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { storeToRefs } from 'pinia';
import { useUiStore } from '@admin/stores/ui';
import { useAuthStore } from '@admin/stores/auth';
import PageHeader from '@admin/components/PageHeader.vue';
import StatCard from '@admin/components/StatCard.vue';

const { t, locale } = useI18n();
const router = useRouter();
const ui = useUiStore();
const auth = useAuthStore();
const { isDark, isRtl } = storeToRefs(ui);

const stats = computed(() => [
    { key: 'liveMatches', title: t('dashboard.liveMatches'), value: isRtl.value ? '٨' : '8', icon: 'pi pi-bolt', color: 'rose' },
    { key: 'pendingListings', title: t('dashboard.pendingListings'), value: isRtl.value ? '١٢' : '12', icon: 'pi pi-inbox', color: 'amber', trend: 8, trendLabel: t('dashboard.vsLastWeek') },
    { key: 'paymentsToday', title: t('dashboard.paymentsToday'), value: isRtl.value ? '٢٫٤ م' : '2.4M', icon: 'pi pi-wallet', color: 'emerald', trend: 12.5, trendLabel: t('dashboard.vsLastWeek') },
    { key: 'newUsers', title: t('dashboard.newUsers'), value: isRtl.value ? '٣٤٢' : '342', icon: 'pi pi-users', color: 'blue', trend: 5.2, trendLabel: t('dashboard.vsLastWeek') },
]);

const quickActions = computed(() => [
    { label: t('dashboard.addFixture'), icon: 'pi pi-calendar-plus', to: 'fixtures' },
    { label: t('dashboard.reviewListings'), icon: 'pi pi-inbox', to: 'listings-review' },
    { label: t('dashboard.sendNotification'), icon: 'pi pi-send', to: 'notifications' },
    { label: t('dashboard.manageUsers'), icon: 'pi pi-users', to: 'users' },
]);

const activity = computed(() =>
    isRtl.value
        ? [
              { name: 'أحمد العبيدي', action: 'أنشأ إعلاناً جديداً', module: 'السوق', tag: 'success', time: 'قبل ٣ د' },
              { name: 'نادي الزوراء', action: 'طلب توثيق الصفحة', module: 'الأندية', tag: 'warn', time: 'قبل ١٢ د' },
              { name: 'سارة كريم', action: 'أكملت عملية دفع', module: 'المدفوعات', tag: 'info', time: 'قبل ٢٥ د' },
              { name: 'النظام', action: 'مزامنة مباريات الدوري الممتاز', module: 'المباريات', tag: 'secondary', time: 'قبل ساعة' },
              { name: 'مشرف السوق', action: 'رفض إعلاناً مخالفاً', module: 'السوق', tag: 'danger', time: 'قبل ساعتين' },
          ]
        : [
              { name: 'Ahmed Al-Obaidi', action: 'created a new listing', module: 'Marketplace', tag: 'success', time: '3m ago' },
              { name: 'Al-Zawraa SC', action: 'requested page verification', module: 'Clubs', tag: 'warn', time: '12m ago' },
              { name: 'Sara Karim', action: 'completed a payment', module: 'Payments', tag: 'info', time: '25m ago' },
              { name: 'System', action: 'synced Premier League fixtures', module: 'Matches', tag: 'secondary', time: '1h ago' },
              { name: 'Market moderator', action: 'rejected a listing', module: 'Marketplace', tag: 'danger', time: '2h ago' },
          ]
);

const revenueData = ref();
const revenueOptions = ref();
const platformData = ref();
const platformOptions = ref();

function cssVar(name, fallback) {
    const v = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
    return v || fallback;
}

function buildCharts() {
    const textMuted = cssVar('--p-text-muted-color', '#64748b');
    const border = cssVar('--p-content-border-color', isDark.value ? '#1e293b' : '#e2e8f0');
    const days =
        locale.value === 'ar'
            ? ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة']
            : ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    revenueData.value = {
        labels: days,
        datasets: [
            {
                label: t('dashboard.revenueOverview'),
                data: [820, 932, 901, 1290, 1330, 1520, 1450],
                fill: true,
                tension: 0.4,
                borderColor: '#10b981',
                backgroundColor: 'rgba(16,185,129,0.12)',
                pointBackgroundColor: '#10b981',
                pointBorderColor: '#fff',
                pointRadius: 4,
                pointHoverRadius: 6,
                borderWidth: 2.5,
            },
        ],
    };
    revenueOptions.value = {
        maintainAspectRatio: false,
        responsive: true,
        plugins: { legend: { display: false }, tooltip: { rtl: isRtl.value } },
        scales: {
            x: { ticks: { color: textMuted }, grid: { color: 'transparent' }, border: { display: false } },
            y: { ticks: { color: textMuted }, grid: { color: border }, border: { display: false }, beginAtZero: true },
        },
    };

    platformData.value = {
        labels: locale.value === 'ar' ? ['أندرويد', 'آيفون'] : ['Android', 'iOS'],
        datasets: [{ data: [64, 36], backgroundColor: ['#10b981', '#6ee7b7'], hoverBackgroundColor: ['#059669', '#34d399'], borderWidth: 0 }],
    };
    platformOptions.value = {
        maintainAspectRatio: false,
        responsive: true,
        cutout: '68%',
        plugins: {
            legend: { position: 'bottom', rtl: isRtl.value, labels: { color: textMuted, usePointStyle: true, padding: 16 } },
            tooltip: { rtl: isRtl.value },
        },
    };
}

onMounted(buildCharts);
watch([isDark, locale], buildCharts);
</script>

<template>
    <div>
        <PageHeader :title="t('dashboard.welcome', { name: isRtl ? auth.admin?.name : auth.admin?.name_en || auth.displayName })" :subtitle="t('dashboard.subtitle')">
            <template #actions>
                <Button :label="t('dashboard.viewReport')" icon="pi pi-chart-line" outlined />
                <Button :label="t('common.refresh')" icon="pi pi-refresh" />
            </template>
        </PageHeader>

        <!-- Stat cards -->
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <StatCard
                v-for="s in stats"
                :key="s.key"
                :title="s.title"
                :value="s.value"
                :icon="s.icon"
                :color="s.color"
                :trend="s.trend ?? null"
                :trend-label="s.trendLabel"
            />
        </div>

        <!-- Charts -->
        <div class="mt-4 grid grid-cols-1 gap-4 xl:grid-cols-3">
            <div class="rounded-2xl border border-surface-200 bg-surface-0 p-5 dark:border-surface-800 dark:bg-surface-900 xl:col-span-2">
                <div class="mb-4 flex items-center justify-between">
                    <div>
                        <h2 class="text-base font-bold text-surface-900 dark:text-surface-0">{{ t('dashboard.revenueOverview') }}</h2>
                        <p class="text-xs text-surface-500 dark:text-surface-400">{{ t('dashboard.last7days') }}</p>
                    </div>
                    <Button :label="t('common.export')" icon="pi pi-download" text size="small" severity="secondary" />
                </div>
                <div class="h-72">
                    <Chart type="line" :data="revenueData" :options="revenueOptions" class="h-full w-full" />
                </div>
            </div>

            <div class="rounded-2xl border border-surface-200 bg-surface-0 p-5 dark:border-surface-800 dark:bg-surface-900">
                <h2 class="mb-1 text-base font-bold text-surface-900 dark:text-surface-0">{{ t('dashboard.usersGrowth') }}</h2>
                <p class="text-xs text-surface-500 dark:text-surface-400">{{ t('dashboard.last7days') }}</p>
                <div class="mx-auto mt-4 h-64 max-w-xs">
                    <Chart type="doughnut" :data="platformData" :options="platformOptions" class="h-full w-full" />
                </div>
            </div>
        </div>

        <!-- Activity + quick actions -->
        <div class="mt-4 grid grid-cols-1 gap-4 xl:grid-cols-3">
            <div class="rounded-2xl border border-surface-200 bg-surface-0 dark:border-surface-800 dark:bg-surface-900 xl:col-span-2">
                <div class="flex items-center justify-between border-b border-surface-200 px-5 py-4 dark:border-surface-800">
                    <h2 class="text-base font-bold text-surface-900 dark:text-surface-0">{{ t('dashboard.recentActivity') }}</h2>
                    <Button :label="t('common.viewAll')" text size="small" />
                </div>
                <div class="overflow-x-auto">
                <DataTable :value="activity" class="text-sm" :pt="{ table: { class: 'min-w-full' } }">
                    <Column :header="t('common.name')">
                        <template #body="{ data }">
                            <div class="flex items-center gap-3">
                                <Avatar :label="data.name.charAt(0)" shape="circle" class="bg-emerald-100! text-emerald-700! dark:bg-emerald-500/20! dark:text-emerald-400!" />
                                <div>
                                    <p class="font-medium text-surface-800 dark:text-surface-100">{{ data.name }}</p>
                                    <p class="text-xs text-surface-500">{{ data.action }}</p>
                                </div>
                            </div>
                        </template>
                    </Column>
                    <Column :header="t('nav.content')">
                        <template #body="{ data }">
                            <Tag :value="data.module" :severity="data.tag" />
                        </template>
                    </Column>
                    <Column :header="t('common.date')">
                        <template #body="{ data }">
                            <span class="text-surface-500">{{ data.time }}</span>
                        </template>
                    </Column>
                </DataTable>
                </div>
            </div>

            <div class="rounded-2xl border border-surface-200 bg-surface-0 p-5 dark:border-surface-800 dark:bg-surface-900">
                <h2 class="mb-4 text-base font-bold text-surface-900 dark:text-surface-0">{{ t('dashboard.quickActions') }}</h2>
                <div class="space-y-2.5">
                    <Button
                        v-for="a in quickActions"
                        :key="a.to"
                        :label="a.label"
                        :icon="a.icon"
                        outlined
                        severity="secondary"
                        class="w-full justify-start!"
                        @click="router.push({ name: a.to })"
                    />
                </div>
            </div>
        </div>
    </div>
</template>
