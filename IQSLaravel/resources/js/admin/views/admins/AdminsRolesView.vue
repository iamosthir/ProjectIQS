<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import PageHeader from '@admin/components/PageHeader.vue';
import { adminsApi } from '@admin/api/admins';
import { rolesApi } from '@admin/api/roles';
import { useFormErrors } from '@admin/composables/useFormErrors';

const { t } = useI18n();
const toast = useToast();
const confirm = useConfirm();
const { reset: resetErrors, setFrom, first } = useFormErrors();

const admins = ref([]);
const roles = ref([]);
const permissions = ref([]);
const loading = ref(false);
const search = ref('');

const adminDialog = ref(false);
const roleDialog = ref(false);
const saving = ref(false);
const adminForm = ref(emptyAdmin());
const roleForm = ref(emptyRole());

function emptyAdmin() {
    return { id: null, name: '', email: '', password: '', password_confirmation: '', phone: '', is_active: true, roles: [] };
}
function emptyRole() {
    return { id: null, name: '', permissions: [] };
}

function toastError(e) {
    toast.add({ severity: 'error', summary: t('common.actions'), detail: e?.response?.data?.message || 'Error', life: 4000 });
}

async function loadAll() {
    loading.value = true;
    try {
        const [a, r, p] = await Promise.all([
            adminsApi.list({ 'filter[search]': search.value || undefined, per_page: 50 }),
            rolesApi.list(),
            rolesApi.permissions(),
        ]);
        admins.value = a.data.data;
        roles.value = r.data.data;
        permissions.value = p.data.data;
    } catch (e) {
        toastError(e);
    } finally {
        loading.value = false;
    }
}

// --- Admins ---
function openCreateAdmin() {
    resetErrors();
    adminForm.value = emptyAdmin();
    adminDialog.value = true;
}
function openEditAdmin(row) {
    resetErrors();
    adminForm.value = { ...emptyAdmin(), id: row.id, name: row.name, email: row.email, phone: row.phone || '', is_active: row.is_active, roles: [...row.roles] };
    adminDialog.value = true;
}
async function saveAdmin() {
    saving.value = true;
    resetErrors();
    try {
        const payload = { ...adminForm.value };
        if (!payload.password) {
            delete payload.password;
            delete payload.password_confirmation;
        }
        if (adminForm.value.id) {
            await adminsApi.update(adminForm.value.id, payload);
            toast.add({ severity: 'success', summary: t('admins.updatedOk'), life: 3000 });
        } else {
            await adminsApi.create(payload);
            toast.add({ severity: 'success', summary: t('admins.createdOk'), life: 3000 });
        }
        adminDialog.value = false;
        await loadAll();
    } catch (e) {
        if (!setFrom(e)) toastError(e);
    } finally {
        saving.value = false;
    }
}
function confirmDeleteAdmin(row) {
    confirm.require({
        message: t('admins.deleteConfirm'),
        header: t('common.delete'),
        icon: 'pi pi-exclamation-triangle',
        rejectLabel: t('common.cancel'),
        acceptLabel: t('common.delete'),
        acceptClass: 'p-button-danger',
        accept: async () => {
            try {
                await adminsApi.remove(row.id);
                toast.add({ severity: 'success', summary: t('admins.deletedOk'), life: 3000 });
                await loadAll();
            } catch (e) {
                toastError(e);
            }
        },
    });
}

// --- Roles ---
function openCreateRole() {
    resetErrors();
    roleForm.value = emptyRole();
    roleDialog.value = true;
}
function openEditRole(row) {
    resetErrors();
    roleForm.value = { id: row.id, name: row.name, permissions: [...(row.permissions || [])] };
    roleDialog.value = true;
}
async function saveRole() {
    saving.value = true;
    resetErrors();
    try {
        if (roleForm.value.id) {
            await rolesApi.update(roleForm.value.id, { name: roleForm.value.name, permissions: roleForm.value.permissions });
            toast.add({ severity: 'success', summary: t('roles.updatedOk'), life: 3000 });
        } else {
            await rolesApi.create({ name: roleForm.value.name, permissions: roleForm.value.permissions });
            toast.add({ severity: 'success', summary: t('roles.createdOk'), life: 3000 });
        }
        roleDialog.value = false;
        await loadAll();
    } catch (e) {
        if (!setFrom(e)) toastError(e);
    } finally {
        saving.value = false;
    }
}
function confirmDeleteRole(row) {
    confirm.require({
        message: t('roles.deleteConfirm'),
        header: t('common.delete'),
        icon: 'pi pi-exclamation-triangle',
        rejectLabel: t('common.cancel'),
        acceptLabel: t('common.delete'),
        acceptClass: 'p-button-danger',
        accept: async () => {
            try {
                await rolesApi.remove(row.id);
                toast.add({ severity: 'success', summary: t('roles.deletedOk'), life: 3000 });
                await loadAll();
            } catch (e) {
                toastError(e);
            }
        },
    });
}

onMounted(loadAll);
</script>

<template>
    <div>
        <PageHeader :title="t('admins.title')" :subtitle="t('admins.subtitle')" icon="pi pi-id-card" />

        <Tabs value="admins">
            <TabList>
                <Tab value="admins">{{ t('admins.tabAdmins') }}</Tab>
                <Tab value="roles">{{ t('admins.tabRoles') }}</Tab>
            </TabList>
            <TabPanels>
                <!-- Admins -->
                <TabPanel value="admins">
                    <div class="mb-3 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                        <IconField class="w-full sm:max-w-xs">
                            <InputIcon class="pi pi-search" />
                            <InputText v-model="search" :placeholder="t('admins.searchPlaceholder')" class="w-full" @keyup.enter="loadAll" />
                        </IconField>
                        <Button :label="t('admins.newAdmin')" icon="pi pi-plus" @click="openCreateAdmin" />
                    </div>

                    <DataTable :value="admins" :loading="loading" data-key="id" class="text-sm" removable-sort>
                        <template #empty>
                            <div class="py-8 text-center text-surface-500">{{ t('common.noData') }}</div>
                        </template>
                        <Column :header="t('common.name')" field="name" sortable>
                            <template #body="{ data }">
                                <p class="font-medium text-surface-800 dark:text-surface-100">{{ data.name }}</p>
                                <p class="text-xs text-surface-500" dir="ltr">{{ data.email }}</p>
                            </template>
                        </Column>
                        <Column :header="t('admins.roles')">
                            <template #body="{ data }">
                                <div class="flex flex-wrap gap-1">
                                    <Tag v-for="r in data.roles" :key="r" :value="r" severity="secondary" />
                                </div>
                            </template>
                        </Column>
                        <Column :header="t('admins.lastLogin')">
                            <template #body="{ data }">
                                <span class="text-surface-600 dark:text-surface-300">
                                    {{ data.last_login_at ? new Date(data.last_login_at).toLocaleString() : t('admins.never') }}
                                </span>
                            </template>
                        </Column>
                        <Column :header="t('common.status')">
                            <template #body="{ data }">
                                <Tag :value="data.is_active ? t('common.active') : t('common.inactive')" :severity="data.is_active ? 'success' : 'secondary'" />
                            </template>
                        </Column>
                        <Column :header="t('common.actions')" :style="{ width: '7rem' }">
                            <template #body="{ data }">
                                <Button icon="pi pi-pencil" text rounded size="small" severity="secondary" @click="openEditAdmin(data)" />
                                <Button icon="pi pi-trash" text rounded size="small" severity="danger" @click="confirmDeleteAdmin(data)" />
                            </template>
                        </Column>
                    </DataTable>
                </TabPanel>

                <!-- Roles -->
                <TabPanel value="roles">
                    <div class="mb-3 flex justify-end">
                        <Button :label="t('roles.newRole')" icon="pi pi-plus" @click="openCreateRole" />
                    </div>
                    <DataTable :value="roles" :loading="loading" data-key="id" class="text-sm">
                        <template #empty>
                            <div class="py-8 text-center text-surface-500">{{ t('common.noData') }}</div>
                        </template>
                        <Column :header="t('roles.roleName')" field="name" sortable>
                            <template #body="{ data }">
                                <span class="font-medium text-surface-800 dark:text-surface-100">{{ data.name }}</span>
                                <Tag v-if="data.name === 'super-admin'" :value="t('roles.system')" severity="warn" class="ms-2" />
                            </template>
                        </Column>
                        <Column :header="t('roles.usersCount')" field="users_count" />
                        <Column :header="t('roles.permissions')">
                            <template #body="{ data }">
                                <span class="text-surface-600 dark:text-surface-300">{{ (data.permissions || []).length }}</span>
                            </template>
                        </Column>
                        <Column :header="t('common.actions')" :style="{ width: '7rem' }">
                            <template #body="{ data }">
                                <Button icon="pi pi-pencil" text rounded size="small" severity="secondary" :disabled="data.name === 'super-admin'" @click="openEditRole(data)" />
                                <Button icon="pi pi-trash" text rounded size="small" severity="danger" :disabled="data.name === 'super-admin'" @click="confirmDeleteRole(data)" />
                            </template>
                        </Column>
                    </DataTable>
                </TabPanel>
            </TabPanels>
        </Tabs>

        <!-- Admin dialog -->
        <Dialog v-model:visible="adminDialog" modal :header="adminForm.id ? t('admins.editAdmin') : t('admins.newAdmin')" :style="{ width: '32rem' }">
            <div class="flex flex-col gap-4 pt-2">
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('common.name') }}</label>
                    <InputText v-model="adminForm.name" class="w-full" :invalid="!!first('name')" />
                    <Message v-if="first('name')" severity="error" size="small" variant="simple">{{ first('name') }}</Message>
                </div>
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('common.email') }}</label>
                    <InputText v-model="adminForm.email" type="email" class="w-full" dir="ltr" :invalid="!!first('email')" />
                    <Message v-if="first('email')" severity="error" size="small" variant="simple">{{ first('email') }}</Message>
                </div>
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('admins.password') }}</label>
                        <Password v-model="adminForm.password" :feedback="false" toggle-mask fluid input-class="w-full" :invalid="!!first('password')" />
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">{{ t('admins.passwordConfirm') }}</label>
                        <Password v-model="adminForm.password_confirmation" :feedback="false" toggle-mask fluid input-class="w-full" />
                    </div>
                </div>
                <p v-if="adminForm.id" class="-mt-2 text-xs text-surface-500">{{ t('admins.passwordHint') }}</p>
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('common.phone') }}</label>
                    <InputText v-model="adminForm.phone" class="w-full" dir="ltr" />
                </div>
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('admins.roles') }}</label>
                    <MultiSelect v-model="adminForm.roles" :options="roles" option-label="name" option-value="name" class="w-full" :placeholder="t('admins.roles')" display="chip" />
                </div>
                <label class="flex items-center gap-2 text-sm">
                    <ToggleSwitch v-model="adminForm.is_active" /> {{ t('admins.activeAccount') }}
                </label>
            </div>
            <template #footer>
                <Button :label="t('common.cancel')" text severity="secondary" @click="adminDialog = false" />
                <Button :label="t('common.save')" icon="pi pi-check" :loading="saving" @click="saveAdmin" />
            </template>
        </Dialog>

        <!-- Role dialog -->
        <Dialog v-model:visible="roleDialog" modal :header="roleForm.id ? t('roles.editRole') : t('roles.newRole')" :style="{ width: '32rem' }">
            <div class="flex flex-col gap-4 pt-2">
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('roles.roleName') }}</label>
                    <InputText v-model="roleForm.name" class="w-full" :invalid="!!first('name')" />
                    <Message v-if="first('name')" severity="error" size="small" variant="simple">{{ first('name') }}</Message>
                </div>
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ t('roles.permissions') }}</label>
                    <MultiSelect v-model="roleForm.permissions" :options="permissions" filter class="w-full" :placeholder="t('roles.permissions')" display="chip" />
                </div>
            </div>
            <template #footer>
                <Button :label="t('common.cancel')" text severity="secondary" @click="roleDialog = false" />
                <Button :label="t('common.save')" icon="pi pi-check" :loading="saving" @click="saveRole" />
            </template>
        </Dialog>
    </div>
</template>
