// ═══════════════════════════════════════════════════════════════
//  COKI STUDIOS GLOBAL THEME ENGINE & UNIVERSAL WAFLERA LAUNCHER
//  Sincronización instantánea de temas, coherencia visual y App Grid
// ═══════════════════════════════════════════════════════════════

(function () {
    const SUN_SVG = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"></circle><line x1="12" y1="1" x2="12" y2="3"></line><line x1="12" y1="21" x2="12" y2="23"></line><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line><line x1="1" y1="12" x2="3" y2="12"></line><line x1="21" y1="12" x2="23" y2="12"></line><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line></svg>`;
    const MOON_SVG = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path></svg>`;
    const WAFFLE_SVG = `<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><circle cx="5" cy="5" r="2.1"></circle><circle cx="12" cy="5" r="2.1"></circle><circle cx="19" cy="5" r="2.1"></circle><circle cx="5" cy="12" r="2.1"></circle><circle cx="12" cy="12" r="2.1"></circle><circle cx="19" cy="12" r="2.1"></circle><circle cx="5" cy="19" r="2.1"></circle><circle cx="12" cy="19" r="2.1"></circle><circle cx="19" cy="19" r="2.1"></circle></svg>`;

    const CS_APPS = [
        { id: 'home', name: 'Inicio', sub: 'Portal CS', href: 'index.html', icon: 'assets/cs-logo.svg', match: ['/', '/index', '/index.html'] },
        { id: 'csid', name: 'CS ID', sub: 'Mi Cuenta', href: 'dashboard.html', icon: 'assets/csid-icon.svg', match: ['/dashboard', '/dashboard.html', '/register', '/register.html'] },
        { id: 'forkar', name: 'Forkar', sub: 'Comunidad', href: 'forkar.html', icon: 'assets/forkar-icon.svg', match: ['/forkar', '/forkar.html', '/forkar-post', '/forkar-post.html'] },
        { id: 'ecohub', name: 'Eco Hub', sub: 'Impacto Verde', href: 'eco-hub.html', icon: 'assets/ecohub-icon.svg', match: ['/eco-hub', '/eco-hub.html'] },
        { id: 'csms', name: 'CSMS', sub: 'Chat E2EE', href: 'messenger.html', icon: 'assets/csms-icon.svg', match: ['/messenger', '/messenger.html', '/csims', '/csims.html'] },
        { id: 'felte', name: 'Felte', sub: 'App Store', href: 'felte.html', icon: 'assets/felte-icon.svg', match: ['/felte', '/felte.html'] },
        { id: 'hiop', name: 'hiOP IDE', sub: 'Looping IDE', href: 'hiop-ide.html', icon: 'assets/hiop-icon.svg', match: ['/hiop-ide', '/hiop-ide.html'] },
        { id: 'find', name: 'Shine Find', sub: 'Buscador', href: 'shine-find.html', icon: 'assets/shine-find-icon.svg', match: ['/shine-find', '/shine-find.html'] },
        { id: 'maps', name: 'Shine Maps', sub: 'Mapas GPS', href: 'shine-maps.html', icon: 'assets/shine-maps-icon.svg', match: ['/shine-maps', '/shine-maps.html'] },
        { id: 'dev', name: 'Developers', sub: 'Consola & SDK', href: 'developer.html', icon: 'assets/dev-icon.svg', match: ['/developer', '/developer.html'] },
        { id: 'smiledev', name: 'smiledev', sub: 'Package Studio', href: 'smiledev.html', icon: 'assets/dev-icon.svg', match: ['/smiledev', '/smiledev.html'] },
        { id: 'products', name: 'Productos', sub: 'Catálogo CS', href: 'products.html', icon: 'assets/shine-loop-launcher-icon.svg', match: ['/products', '/products.html'] }
    ];

    function getPreferredTheme() {
        try {
            const saved = localStorage.getItem('coki-theme') || localStorage.getItem('coki_theme');
            if (saved === 'light' || saved === 'dark') return saved;
        } catch (e) {}
        return 'dark';
    }

    function applyTheme(theme) {
        const isLight = theme === 'light';
        const root = document.documentElement;
        if (isLight) {
            root.classList.add('light-theme');
            root.classList.remove('dark-theme');
        } else {
            root.classList.remove('light-theme');
            root.classList.add('dark-theme');
        }
        try {
            localStorage.setItem('coki-theme', theme);
            localStorage.setItem('coki_theme', theme);
        } catch (e) {}
        updateButtons(isLight);
    }

    function updateButtons(isLight) {
        const buttons = document.querySelectorAll('#theme-toggle, .theme-toggle-btn, [data-action="toggle-theme"]');
        buttons.forEach(btn => {
            btn.innerHTML = isLight ? MOON_SVG : SUN_SVG;
            btn.setAttribute('aria-label', isLight ? 'Activar modo oscuro' : 'Activar modo claro');
            btn.setAttribute('title', isLight ? 'Modo oscuro' : 'Modo claro');
        });
    }

    function ensureWafleraStyles() {
        if (document.getElementById('cs-waffle-fallback-styles')) return;
        const style = document.createElement('style');
        style.id = 'cs-waffle-fallback-styles';
        style.textContent = `
            .cs-waffle-btn, #cs-waffle-toggle {
                display: inline-flex; align-items: center; justify-content: center;
                width: 36px; height: 36px; border-radius: 10px;
                background: transparent; border: 1px solid transparent;
                cursor: pointer; color: #94a3b8; transition: all 0.2s ease;
                position: relative; flex-shrink: 0; padding: 0;
            }
            .cs-waffle-btn:hover, #cs-waffle-toggle:hover,
            .cs-waffle-btn.active, #cs-waffle-toggle.active {
                color: #ffffff; background: rgba(99, 102, 241, 0.14);
                border-color: rgba(99, 102, 241, 0.35);
            }
            html.light-theme .cs-waffle-btn, html.light-theme #cs-waffle-toggle {
                color: #475569 !important;
            }
            html.light-theme .cs-waffle-btn:hover, html.light-theme #cs-waffle-toggle:hover,
            html.light-theme .cs-waffle-btn.active, html.light-theme #cs-waffle-toggle.active {
                color: #4f46e5 !important; background: rgba(79, 70, 229, 0.1) !important;
                border-color: rgba(79, 70, 229, 0.28) !important;
            }
            .cs-waffle-floating-bar {
                position: fixed; top: 16px; right: 16px; z-index: 9998;
                display: flex; align-items: center; gap: 6px; padding: 5px 8px;
                border-radius: 14px; background: rgba(13, 17, 23, 0.85);
                backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px);
                border: 1px solid rgba(255, 255, 255, 0.1);
                box-shadow: 0 10px 30px rgba(0, 0, 0, 0.45);
            }
            html.light-theme .cs-waffle-floating-bar {
                background: rgba(255, 255, 255, 0.92) !important;
                border-color: rgba(15, 23, 42, 0.1) !important;
                box-shadow: 0 8px 24px rgba(15, 23, 42, 0.1) !important;
            }
            .cs-waffle-popover {
                position: fixed; top: 64px; right: 20px; width: 348px;
                max-width: calc(100vw - 24px); z-index: 10000;
                background: rgba(11, 15, 25, 0.96);
                backdrop-filter: blur(28px) saturate(190%);
                -webkit-backdrop-filter: blur(28px) saturate(190%);
                border: 1px solid rgba(255, 255, 255, 0.1);
                border-radius: 22px;
                box-shadow: 0 24px 64px rgba(0, 0, 0, 0.68), 0 0 0 1px rgba(99, 102, 241, 0.16);
                padding: 18px 16px 14px;
                opacity: 0; visibility: hidden;
                transform: translateY(-10px) scale(0.97);
                transition: opacity 0.2s cubic-bezier(0.16, 1, 0.3, 1),
                            transform 0.2s cubic-bezier(0.16, 1, 0.3, 1),
                            visibility 0.2s;
                font-family: 'Outfit', -apple-system, BlinkMacSystemFont, sans-serif;
                user-select: none;
            }
            .cs-waffle-popover.open {
                opacity: 1; visibility: visible; transform: translateY(0) scale(1);
            }
            html.light-theme .cs-waffle-popover {
                background: rgba(255, 255, 255, 0.97) !important;
                border-color: rgba(15, 23, 42, 0.1) !important;
                box-shadow: 0 24px 60px rgba(15, 23, 42, 0.16), 0 4px 16px rgba(15, 23, 42, 0.06) !important;
            }
            .cs-waffle-header {
                display: flex; align-items: center; justify-content: space-between;
                padding: 0 6px 12px; margin-bottom: 10px;
                border-bottom: 1px solid rgba(255, 255, 255, 0.07);
            }
            html.light-theme .cs-waffle-header { border-bottom-color: rgba(15, 23, 42, 0.07) !important; }
            .cs-waffle-title {
                display: flex; align-items: center; gap: 8px;
                font-size: 13px; font-weight: 800; color: #f8fafc;
            }
            html.light-theme .cs-waffle-title { color: #0f172a !important; }
            .cs-waffle-title img { width: 20px; height: 20px; border-radius: 5px; }
            .cs-waffle-badge {
                font-size: 10px; font-weight: 800; letter-spacing: 0.08em;
                text-transform: uppercase; padding: 3px 8px; border-radius: 999px;
                background: rgba(99, 102, 241, 0.15); color: #818cf8;
                border: 1px solid rgba(99, 102, 241, 0.3);
            }
            html.light-theme .cs-waffle-badge {
                background: rgba(79, 70, 229, 0.1) !important;
                color: #4f46e5 !important; border-color: rgba(79, 70, 229, 0.25) !important;
            }
            .cs-waffle-grid {
                display: grid; grid-template-columns: repeat(3, 1fr); gap: 6px;
            }
            .cs-waffle-item {
                display: flex; flex-direction: column; align-items: center;
                justify-content: center; text-align: center; padding: 12px 6px 10px;
                border-radius: 14px; text-decoration: none; color: #f1f5f9;
                border: 1px solid transparent; transition: all 0.18s ease;
            }
            .cs-waffle-item:hover {
                background: rgba(255, 255, 255, 0.06);
                border-color: rgba(255, 255, 255, 0.09); transform: translateY(-2px);
            }
            .cs-waffle-item.current {
                background: rgba(99, 102, 241, 0.12);
                border-color: rgba(99, 102, 241, 0.35);
            }
            html.light-theme .cs-waffle-item { color: #0f172a !important; }
            html.light-theme .cs-waffle-item:hover {
                background: #f1f5f9 !important; border-color: rgba(15, 23, 42, 0.08) !important;
            }
            html.light-theme .cs-waffle-item.current {
                background: rgba(79, 70, 229, 0.08) !important;
                border-color: rgba(79, 70, 229, 0.28) !important;
            }
            .cs-waffle-icon-wrap {
                width: 44px; height: 44px; border-radius: 12px;
                display: flex; align-items: center; justify-content: center;
                margin-bottom: 7px; overflow: hidden;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.28);
                transition: transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1);
            }
            .cs-waffle-item:hover .cs-waffle-icon-wrap { transform: scale(1.07); }
            .cs-waffle-icon-wrap img { width: 100%; height: 100%; object-fit: cover; display: block; }
            .cs-waffle-label {
                font-size: 12px; font-weight: 700; line-height: 1.2;
                color: inherit; white-space: nowrap;
            }
            .cs-waffle-sub {
                font-size: 10px; font-weight: 500; color: #64748b; margin-top: 2px;
            }
            .cs-waffle-footer {
                margin-top: 10px; padding-top: 10px;
                border-top: 1px solid rgba(255, 255, 255, 0.07);
                display: flex; align-items: center; justify-content: space-between; gap: 8px;
            }
            html.light-theme .cs-waffle-footer { border-top-color: rgba(15, 23, 42, 0.07) !important; }
            .cs-waffle-footer-link {
                font-size: 11.5px; font-weight: 600; color: #94a3b8;
                text-decoration: none; padding: 6px 10px; border-radius: 9px;
                transition: all 0.18s ease; display: inline-flex; align-items: center; gap: 5px;
            }
            .cs-waffle-footer-link:hover { color: #f8fafc; background: rgba(255, 255, 255, 0.06); }
            .cs-waffle-footer-link.primary { color: #818cf8; background: rgba(99, 102, 241, 0.1); }
            .cs-waffle-footer-link.primary:hover { color: #ffffff; background: #6366f1; }
            html.light-theme .cs-waffle-footer-link { color: #475569 !important; }
            html.light-theme .cs-waffle-footer-link:hover { color: #0f172a !important; background: #f1f5f9 !important; }
            html.light-theme .cs-waffle-footer-link.primary { color: #4f46e5 !important; background: rgba(79, 70, 229, 0.08) !important; }
            html.light-theme .cs-waffle-footer-link.primary:hover { color: #ffffff !important; background: #4f46e5 !important; }
        `;
        document.head.appendChild(style);
    }

    function isCurrentApp(app) {
        const path = (window.location.pathname || '/').toLowerCase();
        return app.match.some(m => path === m || path.endsWith(m));
    }

    function buildWafflePopover() {
        let popover = document.getElementById('cs-waffle-popover');
        if (popover) return popover;

        popover = document.createElement('div');
        popover.id = 'cs-waffle-popover';
        popover.className = 'cs-waffle-popover';
        popover.setAttribute('role', 'dialog');
        popover.setAttribute('aria-label', 'Aplicaciones de Coki Studios');

        const itemsHtml = CS_APPS.map(app => {
            const currentClass = isCurrentApp(app) ? ' current' : '';
            return `
                <a href="${app.href}" class="cs-waffle-item${currentClass}" data-app-id="${app.id}">
                    <div class="cs-waffle-icon-wrap">
                        <img src="${app.icon}" alt="${app.name}" loading="lazy">
                    </div>
                    <span class="cs-waffle-label">${app.name}</span>
                    <span class="cs-waffle-sub">${app.sub}</span>
                </a>
            `;
        }).join('');

        popover.innerHTML = `
            <div class="cs-waffle-header">
                <div class="cs-waffle-title">
                    <img src="assets/cs-logo.svg" alt="CS">
                    <span>Coki Studios Apps</span>
                </div>
                <span class="cs-waffle-badge">CS OS</span>
            </div>
            <div class="cs-waffle-grid">
                ${itemsHtml}
            </div>
            <div class="cs-waffle-footer">
                <a href="dashboard.html" class="cs-waffle-footer-link">Cuenta CS ID</a>
                <a href="products.html" class="cs-waffle-footer-link primary">Ver todo el ecosistema →</a>
            </div>
        `;

        document.body.appendChild(popover);
        return popover;
    }

    function positionPopover(triggerBtn, popover) {
        if (!triggerBtn || !popover) return;
        const rect = triggerBtn.getBoundingClientRect();
        const popWidth = Math.min(348, window.innerWidth - 24);
        const top = Math.max(12, Math.min(rect.bottom + 10, window.innerHeight - 440));
        let left;
        if (rect.left < 280) {
            left = Math.max(12, rect.left);
        } else {
            left = Math.max(12, Math.min(rect.right - popWidth, window.innerWidth - popWidth - 12));
        }
        popover.style.top = `${top}px`;
        popover.style.left = `${left}px`;
        popover.style.right = 'auto';
    }

    function initCSWaflera() {
        ensureWafleraStyles();
        let waffleBtns = Array.from(document.querySelectorAll('#cs-waffle-toggle, .cs-waffle-btn, [data-action="toggle-waffle"]'));

        if (waffleBtns.length === 0) {
            const btn = document.createElement('button');
            btn.id = 'cs-waffle-toggle';
            btn.className = 'cs-waffle-btn';
            btn.type = 'button';
            btn.title = 'Aplicaciones de Coki Studios';
            btn.setAttribute('aria-label', 'Aplicaciones de Coki Studios');
            btn.setAttribute('aria-expanded', 'false');

            const themeBtn = document.querySelector('#theme-toggle, .theme-toggle-btn');
            if (themeBtn && themeBtn.parentNode) {
                themeBtn.parentNode.insertBefore(btn, themeBtn);
                waffleBtns.push(btn);
            } else {
                const navTarget = document.querySelector('.nav-right, .nav-links, .cs-header-right, .title-actions, .top-bar, .topbar');
                if (navTarget) {
                    navTarget.insertBefore(btn, navTarget.firstChild);
                    waffleBtns.push(btn);
                } else {
                    const floating = document.createElement('div');
                    floating.className = 'cs-waffle-floating-bar';
                    const tBtn = document.createElement('button');
                    tBtn.id = 'theme-toggle';
                    tBtn.className = 'theme-toggle-btn';
                    tBtn.type = 'button';
                    floating.appendChild(btn);
                    floating.appendChild(tBtn);
                    document.body.appendChild(floating);
                    waffleBtns.push(btn);
                }
            }
        }

        const popover = buildWafflePopover();
        let activeTrigger = waffleBtns[0];

        function closeWaflera() {
            popover.classList.remove('open');
            waffleBtns.forEach(b => {
                b.classList.remove('active');
                b.setAttribute('aria-expanded', 'false');
            });
        }

        function openWaflera(trigger) {
            activeTrigger = trigger || waffleBtns[0];
            positionPopover(activeTrigger, popover);
            popover.classList.add('open');
            waffleBtns.forEach(b => {
                b.classList.toggle('active', b === activeTrigger);
                b.setAttribute('aria-expanded', b === activeTrigger ? 'true' : 'false');
            });
        }

        function toggleWaflera(trigger) {
            activeTrigger = trigger || waffleBtns[0];
            const isOpen = popover.classList.contains('open');
            if (isOpen) {
                closeWaflera();
            } else {
                openWaflera(activeTrigger);
            }
        }

        waffleBtns.forEach(btn => {
            if (!btn.innerHTML.trim()) {
                btn.innerHTML = WAFFLE_SVG;
            }
            if (btn.__cokiWaffleBound) return;
            btn.__cokiWaffleBound = true;
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                e.stopPropagation();
                toggleWaflera(btn);
            });
        });

        if (!window.__cokiWaffleGlobalBound) {
            window.__cokiWaffleGlobalBound = true;
            document.addEventListener('click', (e) => {
                if (!popover.classList.contains('open')) return;
                if (popover.contains(e.target)) return;
                if (waffleBtns.some(b => b.contains(e.target))) return;
                closeWaflera();
            });
            document.addEventListener('keydown', (e) => {
                if (e.key === 'Escape' && popover.classList.contains('open')) {
                    closeWaflera();
                }
            });
            window.addEventListener('resize', () => {
                if (popover.classList.contains('open') && activeTrigger) {
                    positionPopover(activeTrigger, popover);
                }
            });
        }

        window.CSWaflera = {
            open: () => openWaflera(activeTrigger),
            close: closeWaflera,
            toggle: () => toggleWaflera(activeTrigger)
        };
    }

    // 1. Aplicación inmediata para prevenir flash al cargar
    const currentTheme = getPreferredTheme();
    applyTheme(currentTheme);

    // 2. Vinculación de botones y Waflera una vez listo el DOM
    function initAllControls() {
        initCSWaflera();
        const isLight = document.documentElement.classList.contains('light-theme');
        updateButtons(isLight);

        const buttons = document.querySelectorAll('#theme-toggle, .theme-toggle-btn, [data-action="toggle-theme"]');
        buttons.forEach(btn => {
            if (btn.__cokiThemeBound) return;
            btn.__cokiThemeBound = true;
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                const nowLight = document.documentElement.classList.contains('light-theme');
                applyTheme(nowLight ? 'dark' : 'light');
            });
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initAllControls);
    } else {
        initAllControls();
    }

    // Sincronizar entre pestañas abiertas
    window.addEventListener('storage', (e) => {
        if ((e.key === 'coki-theme' || e.key === 'coki_theme') && (e.newValue === 'light' || e.newValue === 'dark')) {
            applyTheme(e.newValue);
        }
    });

    window.CokiTheme = {
        apply: applyTheme,
        toggle: () => {
            const isLight = document.documentElement.classList.contains('light-theme');
            applyTheme(isLight ? 'dark' : 'light');
        },
        get: () => document.documentElement.classList.contains('light-theme') ? 'light' : 'dark'
    };
})();
