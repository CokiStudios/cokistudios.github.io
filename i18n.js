// ═══════════════════════════════════════════════════════════════
// 🌐 COKI STUDIOS GLOBAL I18N SYSTEM (MULTI-LANGUAGE + SUPABASE)
// Sincronización local y en la nube en user_metadata de Supabase
// ═══════════════════════════════════════════════════════════════

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = 'https://cmkumxprmmhuinxfppxl.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

let globalTranslations = {};

export async function initGlobalI18n() {
    try {
        const res = await fetch('translations.json');
        globalTranslations = await res.json();
        
        let initialLang = localStorage.getItem('coki-lang') || 'es';

        // ☁️ 1. Verificar si hay usuario conectado y obtener su idioma de Supabase
        try {
            const { data: { user } } = await supabase.auth.getUser();
            if (user && user.user_metadata && user.user_metadata.preferred_language) {
                initialLang = user.user_metadata.preferred_language;
                localStorage.setItem('coki-lang', initialLang);
            }
        } catch (authErr) {
            // Usuario anónimo, usa localStorage
        }

        // 2. Sincronizar todos los selectores de idioma en la página
        const switchers = document.querySelectorAll('.lang-select, #lang-switcher');
        switchers.forEach(s => {
            s.value = initialLang;
            s.addEventListener('change', async (e) => {
                const newLang = e.target.value;
                applyGlobalLanguage(newLang);
                await syncLanguageToSupabase(newLang);
            });
        });

        applyGlobalLanguage(initialLang);
    } catch (e) {
        console.warn('⚠️ No se pudo cargar translations.json:', e);
    }
}

export function applyGlobalLanguage(lang) {
    if (!globalTranslations || !globalTranslations[lang]) return;
    localStorage.setItem('coki-lang', lang);
    
    // Actualizar todos los elementos con data-i18n
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

// ☁️ Guarda el idioma seleccionado directamente en Supabase (user_metadata)
export async function syncLanguageToSupabase(lang) {
    try {
        const { data: { user } } = await supabase.auth.getUser();
        if (user) {
            const { error } = await supabase.auth.updateUser({
                data: {
                    preferred_language: lang
                }
            });
            if (error) {
                console.warn('⚠️ No se pudo sincronizar el idioma en Supabase:', error.message);
            } else {
                console.log(`☁️ Idioma '${lang}' guardado en la cuenta CSID (${user.email})`);
            }
        }
    } catch (e) {
        console.warn('Error al conectar con Supabase para guardar idioma:', e);
    }
}

// Iniciar automáticamente en DOMContentLoaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initGlobalI18n);
} else {
    initGlobalI18n();
}
