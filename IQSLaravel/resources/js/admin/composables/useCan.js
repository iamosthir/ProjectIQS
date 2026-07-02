import { useAuthStore } from '@admin/stores/auth';

/**
 * Permission helper for client-side gating (nav visibility, button disabling).
 * The server remains the source of truth — this is UX only.
 *
 * Usage:
 *   const { can } = useCan();
 *   v-if="can('manage matches')"
 */
export function useCan() {
    const auth = useAuthStore();

    const can = (permission) => {
        if (!permission) {
            return true;
        }
        if (auth.isSuperAdmin) {
            return true;
        }
        return auth.permissions.includes(permission);
    };

    const canAny = (permissions = []) => permissions.some((p) => can(p));

    return { can, canAny };
}

export default useCan;
