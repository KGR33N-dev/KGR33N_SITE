import { AdminAuth } from '~/utils/adminAuth';

async function initHeaderAuth() {
    const loginBtn = document.getElementById('nav-login-btn');
    const userDropdown = document.getElementById('nav-user-dropdown');
    const userBtn = document.getElementById('nav-user-btn');
    const userMenu = document.getElementById('nav-user-menu');
    const logoutBtn = document.getElementById('nav-logout-btn');
    const adminBtn = document.getElementById('nav-admin-btn'); // Admin button

    // Helper to toggle visibility
    const toggle = (el: HTMLElement | null, show: boolean) => {
        if (!el) return;
        if (show) {
            el.classList.remove('hidden');
            // For Admin button specifically, we need to make sure 'block' is preserved/added if it was there in HTML class list logic,
            // but 'hidden' class handles display:none. Removing hidden is usually enough.
        } else {
            el.classList.add('hidden');
        }
    };

    try {
        // Get full user object to check role
        const user = await AdminAuth.verifyUser();

        if (user) {
            toggle(userDropdown, true);
            toggle(loginBtn, false);

            // Check for admin role
            if (adminBtn) {
                // Safe check for role name
                const roleName = user.role?.name;
                if (roleName === 'admin' || roleName === 'role.admin' || roleName === 'superuser') {
                    toggle(adminBtn, true);
                } else {
                    toggle(adminBtn, false);
                }
            }
        } else {
            toggle(loginBtn, true);
            toggle(userDropdown, false);
            if (adminBtn) toggle(adminBtn, false);
        }
    } catch (err) {
        console.error('Header auth check failed:', err);
        toggle(loginBtn, true);
        toggle(userDropdown, false);
    }

    // Dropdown logic
    if (userBtn && userMenu) {
        // Remove old listeners to avoid duplicates (though initHeaderAuth should run once per page load)
        // Actually, creating new anonymous functions adds new listeners.
        // Ideally we should use named functions or a flag.
        // But since this runs on page load, simple guard is enough.
        if (userBtn.dataset.hasListener) return;

        userBtn.dataset.hasListener = 'true';

        userBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            userMenu.classList.toggle('hidden');
        });

        // Close dropdown when clicking outside
        document.addEventListener('click', (e) => {
            if (!userBtn.contains(e.target as Node) && !userMenu.contains(e.target as Node)) {
                userMenu.classList.add('hidden');
            }
        });
    }

    // Logout logic
    if (logoutBtn && !logoutBtn.dataset.hasListener) {
        logoutBtn.dataset.hasListener = 'true';
        logoutBtn.addEventListener('click', async (e) => {
            e.preventDefault();
            await AdminAuth.logout();
        });
    }
}

// Run on initial load
initHeaderAuth();

// Run on view transitions (if enabled)
document.addEventListener('astro:page-load', () => {
    // Reset listeners flags if needed, or rely on distinct DOM elements
    const userBtn = document.getElementById('nav-user-btn');
    if (userBtn) delete userBtn.dataset.hasListener;
    const logoutBtn = document.getElementById('nav-logout-btn');
    if (logoutBtn) delete logoutBtn.dataset.hasListener;

    initHeaderAuth();
});

// Listen for custom auth events
window.addEventListener('auth:login', initHeaderAuth);
window.addEventListener('auth:logout', initHeaderAuth);
