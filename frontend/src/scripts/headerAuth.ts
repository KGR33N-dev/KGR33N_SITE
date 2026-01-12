import { AdminAuth } from '~/utils/adminAuth';

async function initHeaderAuth() {
    // Desktop elements
    const loginBtn = document.getElementById('nav-login-btn');
    const userDropdown = document.getElementById('nav-user-dropdown');
    const userBtn = document.getElementById('nav-user-btn');
    const userMenu = document.getElementById('nav-user-menu');
    const logoutBtn = document.getElementById('nav-logout-btn');
    const adminBtn = document.getElementById('nav-admin-btn');

    // Mobile elements
    const loginBtnMobile = document.getElementById('nav-login-btn-mobile');
    const userDropdownMobile = document.getElementById('nav-user-dropdown-mobile');
    const userBtnMobile = document.getElementById('nav-user-btn-mobile');
    const userMenuMobile = document.getElementById('nav-user-menu-mobile');
    const logoutBtnMobile = document.getElementById('nav-logout-btn-mobile');
    const adminBtnMobile = document.getElementById('nav-admin-btn-mobile');

    // Helper to toggle visibility
    const toggle = (el: HTMLElement | null, show: boolean) => {
        if (!el) return;
        if (show) {
            el.classList.remove('hidden');
        } else {
            el.classList.add('hidden');
        }
    };

    try {
        // Get full user object to check role
        const user = await AdminAuth.verifyUser();

        if (user) {
            // Desktop
            toggle(userDropdown, true);
            toggle(loginBtn, false);
            // Mobile
            toggle(userDropdownMobile, true);
            toggle(loginBtnMobile, false);

            // Check for admin role
            const roleName = user.role?.name;
            const isAdmin = roleName === 'admin' || roleName === 'role.admin' || roleName === 'superuser';

            if (adminBtn) toggle(adminBtn, isAdmin);
            if (adminBtnMobile) toggle(adminBtnMobile, isAdmin);
        } else {
            // Desktop
            toggle(loginBtn, true);
            toggle(userDropdown, false);
            if (adminBtn) toggle(adminBtn, false);
            // Mobile
            toggle(loginBtnMobile, true);
            toggle(userDropdownMobile, false);
            if (adminBtnMobile) toggle(adminBtnMobile, false);
        }
    } catch (err) {
        console.error('Header auth check failed:', err);
        // Desktop
        toggle(loginBtn, true);
        toggle(userDropdown, false);
        // Mobile
        toggle(loginBtnMobile, true);
        toggle(userDropdownMobile, false);
    }

    // Desktop dropdown logic
    if (userBtn && userMenu) {
        if (userBtn.dataset.hasListener) return;
        userBtn.dataset.hasListener = 'true';

        userBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            userMenu.classList.toggle('hidden');
        });

        document.addEventListener('click', (e) => {
            if (!userBtn.contains(e.target as Node) && !userMenu.contains(e.target as Node)) {
                userMenu.classList.add('hidden');
            }
        });
    }

    // Mobile dropdown logic
    if (userBtnMobile && userMenuMobile) {
        if (!userBtnMobile.dataset.hasListener) {
            userBtnMobile.dataset.hasListener = 'true';

            userBtnMobile.addEventListener('click', (e) => {
                e.stopPropagation();
                userMenuMobile.classList.toggle('hidden');
            });

            document.addEventListener('click', (e) => {
                if (!userBtnMobile.contains(e.target as Node) && !userMenuMobile.contains(e.target as Node)) {
                    userMenuMobile.classList.add('hidden');
                }
            });
        }
    }

    // Logout logic - Desktop
    if (logoutBtn && !logoutBtn.dataset.hasListener) {
        logoutBtn.dataset.hasListener = 'true';
        logoutBtn.addEventListener('click', async (e) => {
            e.preventDefault();
            await AdminAuth.logout();
        });
    }

    // Logout logic - Mobile
    if (logoutBtnMobile && !logoutBtnMobile.dataset.hasListener) {
        logoutBtnMobile.dataset.hasListener = 'true';
        logoutBtnMobile.addEventListener('click', async (e) => {
            e.preventDefault();
            await AdminAuth.logout();
        });
    }
}

// Run on initial load
initHeaderAuth();

// Run on view transitions (if enabled)
document.addEventListener('astro:page-load', () => {
    // Reset listeners flags for desktop
    const userBtn = document.getElementById('nav-user-btn');
    if (userBtn) delete userBtn.dataset.hasListener;
    const logoutBtn = document.getElementById('nav-logout-btn');
    if (logoutBtn) delete logoutBtn.dataset.hasListener;

    // Reset listeners flags for mobile
    const userBtnMobile = document.getElementById('nav-user-btn-mobile');
    if (userBtnMobile) delete userBtnMobile.dataset.hasListener;
    const logoutBtnMobile = document.getElementById('nav-logout-btn-mobile');
    if (logoutBtnMobile) delete logoutBtnMobile.dataset.hasListener;

    initHeaderAuth();
});

// Listen for custom auth events
window.addEventListener('auth:login', initHeaderAuth);
window.addEventListener('auth:logout', initHeaderAuth);
