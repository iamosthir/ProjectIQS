<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { storeToRefs } from 'pinia';
import { useUiStore } from '@admin/stores/ui';
import PageHeader from '@admin/components/PageHeader.vue';
import StatCard from '@admin/components/StatCard.vue';

const { t } = useI18n();
const ui = useUiStore();
const { isRtl } = storeToRefs(ui);

const GOVERNORATES = [
    { ar: 'بغداد', en: 'Baghdad' },
    { ar: 'البصرة', en: 'Basra' },
    { ar: 'أربيل', en: 'Erbil' },
    { ar: 'النجف', en: 'Najaf' },
    { ar: 'كربلاء', en: 'Karbala' },
    { ar: 'نينوى', en: 'Nineveh' },
    { ar: 'ذي قار', en: 'Dhi Qar' },
];

const SAMPLE = [
    { id: 1, ar: 'أحمد العبيدي', en: 'Ahmed Al-Obaidi', phone: '+964 770 123 4567', gov: 0, status: 'active', joined: '2026-05-12', last: '2026-06-20' },
    { id: 2, ar: 'سارة كريم', en: 'Sara Karim', phone: '+964 781 222 1188', gov: 1, status: 'active', joined: '2026-05-18', last: '2026-06-19' },
    { id: 3, ar: 'مصطفى حسن', en: 'Mustafa Hassan', phone: '+964 750 909 4422', gov: 2, status: 'banned', joined: '2026-04-02', last: '2026-06-01' },
    { id: 4, ar: 'نور الهدى', en: 'Noor Al-Huda', phone: '+964 771 334 9090', gov: 3, status: 'active', joined: '2026-06-01', last: '2026-06-20' },
    { id: 5, ar: 'علي الجبوري', en: 'Ali Al-Jubouri', phone: '+964 782 556 7788', gov: 0, status: 'active', joined: '2026-03-22', last: '2026-06-18' },
    { id: 6, ar: 'زينب عبد', en: 'Zainab Abd', phone: '+964 751 667 1234', gov: 4, status: 'active', joined: '2026-06-10', last: '2026-06-20' },
    { id: 7, ar: 'حيدر صالح', en: 'Haidar Saleh', phone: '+964 770 998 4561', gov: 5, status: 'banned', joined: '2026-02-14', last: '2026-05-09' },
    { id: 8, ar: 'فاطمة الزهراء', en: 'Fatima Al-Zahraa', phone: '+964 781 445 7821', gov: 6, status: 'active', joined: '2026-06-15', last: '2026-06-19' },
    { id: 9, ar: 'يوسف كاظم', en: 'Yousif Kadhim', phone: '+964 750 221 3344', gov: 1, status: 'active', joined: '2026-05-30', last: '2026-06-17' },
    { id: 10, ar: 'مريم سعد', en: 'Mariam Saad', phone: '+964 771 778 9900', gov: 0, status: 'active', joined: '2026-06-08', last: '2026-06-20' },
];

const search = ref('');
const statusFilter = ref('all');

const statusOptions = computed(() => [
    { label: t('common.all'), value: 'all' },
    { label: t('users.statusActive'), value: 'active' },
    { label: t('users.statusBanned'), value: 'banned' },
]);

const rows = computed(() =>
    SAMPLE.map((u) => ({
        ...u,
        name: isRtl.value ? u.ar : u.en,
        governorate: isRtl.value ? GOVERNORATES[u.gov].ar : GOVERNORATES[u.gov].en,
        initial: (isRtl.value ? u.ar : u.en).charAt(0),
    }))
);

const filtered = computed(() => {
    const q = search.value.trim().toLowerCase();
    return rows.value.filter((u) => {
        const matchesStatus = statusFilter.value === 'all' || u.status === statusFilter.value;
        const matchesSearch = !q || u.name.toLowerCase().includes(q) || u.phone.includes(q);
        return matchesStatus && matchesSearch;
    });
});

const summary = computed(() => [
    { title: t('users.totalUsers'), value: isRtl.value ? '١٢٬٤٨٠' : '12,480', icon: 'pi pi-users', color: 'emerald', trend: 5.2 },
    { title: t('users.verified'), value: isRtl.value ? '٩٬٣٢٠' : '9,320', icon: 'pi pi-verified', color: 'blue' },
    { title: t('users.banned'), value: isRtl.value ? '٤٢' : '42', icon: 'pi pi-ban', color: 'rose' },
    { title: t('users.newThisMonth'), value: isRtl.value ? '٣٤٢' : '342', icon: 'pi pi-user-plus', color: 'amber', trend: 12 },
]);
</script>

<template>
    <div>
        <PageHeader :title="t('users.title')" :subtitle="t('users.subtitle')" icon="pi pi-user">
            <template #actions>
                <Button :label="t('common.export')" icon="pi pi-download" outlined severity="secondary" />
            </template>
        </PageHeader>

        <div class="mb-4 grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <StatCard v-for="s in summary" :key="s.title" v-bind="s" :trend="s.trend ?? null" :trend-label="t('dashboard.vsLastWeek')" />
        </div>

        <div class="rounded-2xl border border-surface-200 bg-surface-0 dark:border-surface-800 dark:bg-surface-900">
            <div class="flex flex-col gap-3 border-b border-surface-200 p-4 dark:border-surface-800 sm:flex-row sm:items-center sm:justify-between">
                <IconField class="w-full sm:max-w-xs">
                    <InputIcon class="pi pi-search" />
                    <InputText v-model="search" :placeholder="t('users.searchPlaceholder')" :aria-label="t('users.searchPlaceholder')" class="w-full" />
                </IconField>
                <SelectButton v-model="statusFilter" :options="statusOptions" option-label="label" option-value="value" :allow-empty="false" />
            </div>

            <div class="overflow-x-auto">
            <DataTable
                :value="filtered"
                paginator
                :rows="6"
                :rows-per-page-options="[6, 10, 20]"
                data-key="id"
                removable-sort
                class="text-sm"
                paginator-template="FirstPageLink PrevPageLink CurrentPageReport NextPageLink LastPageLink RowsPerPageDropdown"
                :current-page-report-template="isRtl ? '{first}–{last} من {totalRecords}' : '{first}–{last} of {totalRecords}'"
            >
                <template #empty>
                    <div class="py-8 text-center text-surface-500">{{ t('common.noData') }}</div>
                </template>

                <Column :header="t('common.name')" sortable field="name">
                    <template #body="{ data }">
                        <div class="flex items-center gap-3">
                            <Avatar :label="data.initial" shape="circle" class="bg-emerald-100! text-emerald-700! dark:bg-emerald-500/20! dark:text-emerald-400!" />
                            <div>
                                <p class="font-medium text-surface-800 dark:text-surface-100">{{ data.name }}</p>
                                <p class="text-xs text-surface-500" dir="ltr">{{ data.phone }}</p>
                            </div>
                        </div>
                    </template>
                </Column>
                <Column :header="t('users.governorate')" field="governorate" sortable />
                <Column :header="t('common.status')" field="status" sortable>
                    <template #body="{ data }">
                        <Tag
                            :value="data.status === 'active' ? t('users.statusActive') : t('users.statusBanned')"
                            :severity="data.status === 'active' ? 'success' : 'danger'"
                        />
                    </template>
                </Column>
                <Column :header="t('users.joined')" field="joined" sortable />
                <Column :header="t('users.lastActive')" field="last" sortable />
                <Column :header="t('common.actions')" :style="{ width: '7rem' }">
                    <template #body="{ data }">
                        <div class="flex items-center gap-1">
                            <Button icon="pi pi-eye" text rounded severity="secondary" size="small" :aria-label="t('users.viewProfile')" v-tooltip.bottom="t('users.viewProfile')" />
                            <Button
                                :icon="data.status === 'active' ? 'pi pi-ban' : 'pi pi-check-circle'"
                                text
                                rounded
                                size="small"
                                :severity="data.status === 'active' ? 'danger' : 'success'"
                                :aria-label="data.status === 'active' ? t('users.ban') : t('users.unban')"
                                v-tooltip.bottom="data.status === 'active' ? t('users.ban') : t('users.unban')"
                            />
                        </div>
                    </template>
                </Column>
            </DataTable>
            </div>
        </div>
    </div>
</template>
