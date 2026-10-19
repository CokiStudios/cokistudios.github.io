/* ═══════════════════════════════════════════════════════════════════════
   📱 MOBILE LIQUID GLASS DRAWER
   Smooth mobile navigation drawer with touch gestures & theme toggle
   Coki Studios © 2026
   ═══════════════════════════════════════════════════════════════════════ */

(function () {
    function initMobileDrawer() {
        if (document.getElementById('cs-mobile-drawer-overlay')) return;

        // Drawer overlay and container
        const overlay = document.createElement('div');
        overlay.id = 'cs-mobile-drawer-overlay';
        overlay.className = 'cs-mobile-drawer-overlay';
        overlay.innerHTML = `
            <div class="cs-mobile-drawer" onclick="event.stopPropagation()">
                <div class="cs-drawer-header">
                    <div style="display:flex; align-items:center; gap:10px;">
                        <img src="assets/cs-logo.png" alt="CS Logo" style="width:32px; height:32px; border-radius:8px;">
                        <span style="font-weight:700; font-size:16px; color:var(--text);">Coki Studios</span>
                    </div>
                    <button id="cs-drawer-close" class="cs-drawer-close-btn" aria-label="Cerrar">✕</button>
                </div>

                <div class="cs-drawer-nav">
                    <a href="/" class="cs-drawer-link">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path><polyline points="9 22 9 12 15 12 15 22"></polyline></svg>
                        Inicio
                    </a>
                    <a href="https://repo.cokistudios.com/engine" class="cs-drawer-link" style="color:#38bdf8;">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="16 18 22 12 16 6"></polyline><polyline points="8 6 2 12 8 18"></polyline></svg>
                        Looping Engine v2.6.0
                    </a>
                    <a href="forkar" class="cs-drawer-link">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
                        Forkar & Eco Hub
                    </a>
                    <a href="messenger" class="cs-drawer-link">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg>
                        CSMS Messenger
                    </a>
                    <a href="felte.html" class="cs-drawer-link" style="color:#00f5d4;">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="9" cy="21" r="1"></circle><circle cx="20" cy="21" r="1"></circle><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path></svg>
                        Felte Store
                    </a>
                    <a href="products" class="cs-drawer-link">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2" ry="2"></rect><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"></path></svg>
                        Productos
                    </a>
                    <a href="register" class="cs-drawer-link" style="color:#818cf8;">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>
                        CS ID (Mi Cuenta)
                    </a>
                </div>

                <div class="cs-drawer-footer">
                    <div style="display:flex; justify-content:space-between; align-items:center;">
                        <span style="font-size:13px; color:var(--text-sub); font-weight:600;">Idioma</span>
                        <select id="drawer-lang-select" style="background:rgba(255,255,255,0.06); border:1px solid var(--border); color:var(--text); font-family:inherit; font-size:13px; font-weight:600; padding:6px 10px; border-radius:8px;">
                            <option value="es">🇪🇸 ES</option>
                            <option value="en">🇺🇸 EN</option>
                            <option value="fr">🇫🇷 FR</option>
                            <option value="pt">🇧🇷 PT</option>
                        </select>
                    </div>

                    <div style="display:flex; justify-content:space-between; align-items:center;">
                        <span style="font-size:13px; color:var(--text-sub); font-weight:600;">Tema Visual</span>
                        <button id="drawer-theme-btn" style="background:rgba(255,255,255,0.06); border:1px solid var(--border); color:var(--text); padding:6px 12px; border-radius:8px; font-size:13px; cursor:pointer; font-weight:600;">
                            🌓 Alternar Tema
                        </button>
                    </div>

                    <div style="text-align:center; margin-top:8px;">
                        <span style="font-family:'JetBrains Mono',monospace; font-size:11px; color:#38bdf8; background:rgba(56,189,248,0.1); padding:3px 8px; border-radius:6px;">
                            Looping v2.6.0 Universal · smiledev
                        </span>
                    </div>
                </div>
            </div>
        `;

        document.body.appendChild(overlay);

        function closeDrawer() {
            overlay.classList.remove('active');
        }

        overlay.addEventListener('click', closeDrawer);
        document.getElementById('cs-drawer-close').addEventListener('click', closeDrawer);

        // Synchronize language selector
        const mainLangSelect = document.querySelector('.lang-select');
        const drawerLangSelect = document.getElementById('drawer-lang-select');
        if (mainLangSelect && drawerLangSelect) {
            drawerLangSelect.value = mainLangSelect.value || 'es';
            drawerLangSelect.addEventListener('change', (e) => {
                mainLangSelect.value = e.target.value;
                mainLangSelect.dispatchEvent(new Event('change'));
            });
        }

        // Synchronize theme toggle
        const drawerThemeBtn = document.getElementById('drawer-theme-btn');
        if (drawerThemeBtn) {
            drawerThemeBtn.addEventListener('click', () => {
                const mainBtn = document.getElementById('theme-toggle');
                if (mainBtn) mainBtn.click();
            });
        }

        // Link close
        overlay.querySelectorAll('.cs-drawer-link').forEach(link => {
            link.addEventListener('click', closeDrawer);
        });
    }

    window.toggleMobileDrawer = function () {
        initMobileDrawer();
        const overlay = document.getElementById('cs-mobile-drawer-overlay');
        if (overlay) overlay.classList.toggle('active');
    };

    document.addEventListener('DOMContentLoaded', () => {
        initMobileDrawer();
        const hamburgerBtn = document.getElementById('mobileMenuBtn');
        if (hamburgerBtn) {
            hamburgerBtn.addEventListener('click', window.toggleMobileDrawer);
        }
    });
})();
