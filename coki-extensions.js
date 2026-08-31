import { supabase } from './coki-auth.js';

// ==========================================
// 1. SETUP WIZARD (ASISTENTE DE CONFIGURACIÓN)
// ==========================================
export async function checkAndShowSetupWizard() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    const metadata = user.user_metadata || {};
    // Verificamos si falta el nombre o la biografía
    const isProfileComplete = metadata.full_name && metadata.bio;

    // Si el perfil está incompleto y el usuario no lo ha saltado en esta sesión local
    if (!isProfileComplete && !localStorage.getItem('wizard_skipped')) {
        injectWizardHTML();
    }
}

function injectWizardHTML() {
    // Evitar inyectar múltiples veces
    if (document.getElementById('coki-setup-wizard')) return;

    const wizardHTML = `
        <div id="coki-setup-wizard" style="position: fixed; inset: 0; z-index: 9999; background: rgba(0,0,0,0.8); backdrop-filter: blur(10px); display: flex; align-items: center; justify-content: center; font-family: 'Outfit', sans-serif;">
            <div style="background: #0d1117; border: 1px solid rgba(255,255,255,0.1); border-radius: 20px; padding: 40px; width: 90%; max-width: 400px; color: white; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.5);">
                <h2 style="margin-bottom: 10px; font-size: 24px; font-weight: 800;">¡Bienvenido a Coki Studios! </h2>
                <p style="color: #94a3b8; margin-bottom: 24px; font-size: 14px; line-height: 1.5;">Completa tu perfil para que la comunidad pueda conocerte e interactuar contigo.</p>
                
                <div style="margin-bottom: 16px;">
                    <label style="display: block; font-size: 12px; font-weight: 600; color: #94a3b8; margin-bottom: 8px;">NOMBRE COMPLETO / ALIAS</label>
                    <input type="text" id="wizard-name" placeholder="Ej. JeriX Ortiz" style="width: 100%; padding: 12px; background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1); border-radius: 12px; color: white; outline: none; box-sizing: border-box; font-family: inherit;">
                </div>
                
                <div style="margin-bottom: 24px;">
                    <label style="display: block; font-size: 12px; font-weight: 600; color: #94a3b8; margin-bottom: 8px;">ROL / ESTADO</label>
                    <input type="text" id="wizard-bio" placeholder="Ej. iOS Developer en Coki Studios" style="width: 100%; padding: 12px; background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1); border-radius: 12px; color: white; outline: none; box-sizing: border-box; font-family: inherit;">
                </div>

                <button onclick="window.saveWizardProfile()" style="width: 100%; padding: 14px; background: #6366f1; color: white; border: none; border-radius: 12px; font-size: 14px; font-weight: 700; cursor: pointer; transition: all 0.2s; margin-bottom: 12px;">Guardar Perfil</button>
                <button onclick="window.closeWizard()" style="width: 100%; padding: 14px; background: transparent; color: #94a3b8; border: none; font-size: 14px; font-weight: 600; cursor: pointer; transition: all 0.2s;">Saltar por ahora</button>
            </div>
        </div>
    `;

    document.body.insertAdjacentHTML('beforeend', wizardHTML);

    // Funciones globales para que los botones del modal puedan acceder a ellas
    window.closeWizard = () => {
        localStorage.setItem('wizard_skipped', 'true');
        document.getElementById('coki-setup-wizard').remove();
    };

    window.saveWizardProfile = async () => {
        const name = document.getElementById('wizard-name').value.trim();
        const bio = document.getElementById('wizard-bio').value.trim();

        if (!name) {
            alert("Por favor, ingresa al menos tu nombre o alias.");
            return;
        }

        const btn = document.querySelector('#coki-setup-wizard button');
        btn.textContent = "Guardando...";
        btn.disabled = true;

        // 1. Actualizamos la metadata en Supabase Auth
        const { error: authError } = await supabase.auth.updateUser({
            data: { full_name: name, bio: bio }
        });

        if (authError) {
            alert("Error al guardar: " + authError.message);
            btn.textContent = "Guardar Perfil";
            btn.disabled = false;
            return;
        }

        // 2. Sincronizamos con la tabla public.profiles si existe
        const { data: { user } } = await supabase.auth.getUser();
        if (user) {
            await supabase
                .from('profiles')
                .update({ full_name: name, bio: bio })
                .eq('id', user.id);
        }

        alert("¡Perfil configurado con éxito!");
        document.getElementById('coki-setup-wizard').remove();
        window.location.reload();
    };
}

// ==========================================
// 2. RENDERIZADO DE MENCIONES (@)
// ==========================================
export function renderMentionsInDOM() {
    // Buscamos los contenedores de texto en los posts y los comentarios
    const contentElements = document.querySelectorAll('.post-body, .comment-text');

    // Expresión regular para detectar menciones: @ seguido de caracteres alfanuméricos y guiones bajos
    const mentionRegex = /@([a-zA-Z0-9_]+)/g;

    contentElements.forEach(el => {
        // Evitamos procesar dos veces el mismo elemento si se vuelve a llamar la función
        if (el.dataset.mentionsProcessed) return;

        let html = el.innerHTML;

        // Reemplazamos el texto plano por una etiqueta <a> que apunte a CSMS
        const replaced = html.replace(mentionRegex, (match, username) => {
            return `<a href="messenger.html?new_chat=${encodeURIComponent(username)}" style="color: var(--accent); text-decoration: none; font-weight: 600; padding: 0 2px;" onmouseover="this.style.textDecoration='underline'" onmouseout="this.style.textDecoration='none'">${match}</a>`;
        });

        if (html !== replaced) {
            el.innerHTML = replaced;
        }
        el.dataset.mentionsProcessed = "true";
    });
}