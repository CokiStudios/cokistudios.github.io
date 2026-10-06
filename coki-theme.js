// ═══════════════════════════════════════════════════════════════
//  COKI STUDIOS GLOBAL THEME ENGINE (DARK / LIGHT MODE)
//  Sincronización instantánea de temas y barra de navegación
// ═══════════════════════════════════════════════════════════════

(function () {
    const SUN_SVG = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"></circle><line x1="12" y1="1" x2="12" y2="3"></line><line x1="12" y1="21" x2="12" y2="23"></line><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line><line x1="1" y1="12" x2="3" y2="12"></line><line x1="21" y1="12" x2="23" y2="12"></line><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line></svg>`;
    const MOON_SVG = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path></svg>`;

    function getPreferredTheme() {
        const saved = localStorage.getItem('coki-theme');
        if (saved === 'light' || saved === 'dark') return saved;
        return window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark';
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

    // 1. Aplicación inmediata para prevenir flash al cargar
    const currentTheme = getPreferredTheme();
    applyTheme(currentTheme);

    // 2. Vinculación de botones una vez listo el DOM
    function initThemeControls() {
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
        document.addEventListener('DOMContentLoaded', initThemeControls);
    } else {
        initThemeControls();
    }

    // Sincronizar entre pestañas abiertas
    window.addEventListener('storage', (e) => {
        if (e.key === 'coki-theme' && (e.newValue === 'light' || e.newValue === 'dark')) {
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
