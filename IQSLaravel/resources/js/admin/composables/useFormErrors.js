import { ref } from 'vue';

/**
 * Maps Laravel 422 validation errors onto form fields. Server-side validation
 * is the source of truth — bind `first(field)` to PrimeVue `invalid` + Message.
 */
export function useFormErrors() {
    const errors = ref({});

    function reset() {
        errors.value = {};
    }

    /**
     * Absorb an axios error. Returns true if it was a 422 (fields populated),
     * false otherwise (caller should toast `error.response.data.message`).
     */
    function setFrom(error) {
        const res = error?.response;
        if (res?.status === 422 && res.data?.errors) {
            errors.value = res.data.errors;
            return true;
        }
        return false;
    }

    function first(field) {
        return errors.value[field]?.[0];
    }

    return { errors, reset, setFrom, first };
}

export default useFormErrors;
