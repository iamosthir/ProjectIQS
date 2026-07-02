<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToast } from 'primevue/usetoast';
import { uploadFile } from '@admin/api/client';

const props = defineProps({
    endpoint: { type: String, required: true },
    label: { type: String, default: '' },
    error: { type: String, default: '' },
});

const model = defineModel({ type: String, default: '' });

const { t } = useI18n();
const toast = useToast();

const uploading = ref(false);
const fileUploadRef = ref(null);

const preview = computed(() => {
    const p = model.value;
    if (!p) return null;
    return /^https?:\/\//.test(p) ? p : `/storage/${p}`;
});

async function onUpload(event) {
    const file = event.files?.[0];
    if (!file) return;
    uploading.value = true;
    try {
        const { data } = await uploadFile(props.endpoint, file);
        model.value = data.data.path;
        toast.add({ severity: 'success', summary: t('common.imageUploaded'), life: 2000 });
    } catch (e) {
        toast.add({ severity: 'error', summary: t('common.error'), detail: e?.response?.data?.message || t('common.somethingWrong'), life: 4000 });
    } finally {
        uploading.value = false;
        fileUploadRef.value?.clear?.();
    }
}
</script>

<template>
    <div>
        <label v-if="label" class="mb-1 block text-sm font-medium">{{ label }}</label>
        <div class="flex items-center gap-3">
            <img v-if="preview" :src="preview" alt="" class="h-16 w-28 rounded-lg border border-surface-200 object-cover dark:border-surface-700" />
            <div v-else class="flex h-16 w-28 items-center justify-center rounded-lg border border-dashed border-surface-300 text-surface-400 dark:border-surface-700">
                <i class="pi pi-image text-xl" />
            </div>
            <div class="flex min-w-0 flex-col gap-1">
                <FileUpload
                    ref="fileUploadRef"
                    mode="basic"
                    :auto="true"
                    custom-upload
                    accept="image/jpeg,image/png,image/webp,image/gif"
                    :max-file-size="5242880"
                    :choose-label="uploading ? t('common.uploading') : t('common.uploadImage')"
                    :disabled="uploading"
                    @uploader="onUpload"
                />
                <small v-if="model" :title="model" class="truncate text-surface-500 dark:text-surface-400" dir="ltr">{{ model }}</small>
            </div>
        </div>
        <Message v-if="error" severity="error" size="small" variant="simple">{{ error }}</Message>
    </div>
</template>
