// ═══════════════════════════════════════════════════════════════
// 🌐 COKI STUDIOS GLOBAL I18N SYSTEM (MULTI-LANGUAGE)
// ═══════════════════════════════════════════════════════════════

let globalTranslations = {};

export async function initGlobalI18n() {
    try {
        const res = await fetch('translations.json');
        globalTranslations = await res.json();
        const savedLang = localStorage.getItem('coki-lang') || 'es';
        
        // Sincronizar todos los selectores de idioma en la página
        const switchers = document.querySelectorAll('.lang-select, #lang-switcher');
        switchers.forEach(s => {
            s.value = savedLang;
            s.addEventListener('change', (e) => {
                applyGlobalLanguage(e.target.value);
            });
        });

        applyGlobalLanguage(savedLang);
    } catch (e) {
        console.warn('⚠️ No se pudo cargar translations.json:', e);
    }
}

export function applyGlobalLanguage(lang) {
    if (!globalTranslations || !globalTranslations[lang]) return;
    localStorage.setItem('coki-lang', lang);
    
    // Actualizar todos los elementos con data-i18n siempre con innerHTML para procesar tags como <br> y <span>
    document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        const translation = globalTranslations[lang][key];
        if (translation !== undefined && translation !== null) {
            if (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA') {
                el.placeholder = translation;
            } else {
                el.innerHTML = translation;
            }
        }
    });

    // Actualizar todos los dropdowns
    document.querySelectorAll('.lang-select, #lang-switcher').forEach(s => {
        s.value = lang;
    });
}

// Iniciar automáticamente en DOMContentLoaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initGlobalI18n);
} else {
    initGlobalI18n();
}
