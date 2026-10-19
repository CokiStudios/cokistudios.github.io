/* ═══════════════════════════════════════════════════════════════════════
   🤖 COKI AI ASSISTANT WIDGET (WORKERS AI & LLAMA 3.2 3B)
   Interactive floating assistant for Coki Studios platform
   ═══════════════════════════════════════════════════════════════════════ */

(function () {
    const KNOWLEDGE_BASE = {
        homebrew: `Para instalar Looping Engine v2.6 y el gestor smiledev en macOS vía Homebrew ejecuta:\n\n\`\`\`bash\nbrew tap CokiStudios/cokistudios.github.io\nbrew install looping smiledev\n\`\`\`\n\nEsto instalará los binarios universales (Apple Silicon y x86_64) listos en tu PATH.`,
        smiledev: `**smiledev** es el gestor oficial de paquetes para Looping.\n\nComandos clave:\n• \`smiledev upgrade\`: Auto-actualiza el motor Looping y smiledev a la última versión desde repo.cokistudios.com/engine.\n• \`smiledev install <modulo>\`: Instala módulos oficiales como \`pyloop-crypto\` o \`loop-gui-qt\`.\n• \`smiledev view <modulo>\`: Inspecciona metadatos y autor.\n• \`smiledev search <termino>\`: Busca módulos en la nube.`,
        csms: `**CSMS (Coki Studios Messaging Service)** cuenta con cifrado de extremo a extremo (E2EE) con respaldo en hardware:\n\n• **Apple SEP (Secure Enclave Processor)** en iOS/macOS y **StrongBox TEE** en Android.\n• Derivación de claves SHA-256 por sala: \`SHA-256(roomId:CSMS_E2EE_COKI_STUDIOS_v1_SALT_FORKAR)\`.\n• Cifrado simétrico AES-256-GCM con IV aleatorio de 12 bytes.\n• Payload oficial: \`🔒 enc:v1:<iv>:<ciphertext>\`.`,
        ecohub: `**Forkar Eco Hub** es la red de sostenibilidad de la Sabana de Bogotá:\n\n• **Cota**: Punto Verde Parque Principal, Estación Bici (Vía Siberia), Punto RAEE (Alcaldía).\n• **Chía**: Centro de Acopio Chía Centro (Av. Pradilla), Eco Estación Universitaria (Chía Norte).\n• **Bogotá**: Hub Intermodal Portal 80 y Punto Limpio Portal Suba.\n\nPuedes escanear códigos QR en las estaciones para acumular Puntos Eco canjeables en la Eco Rewards Store.`
    };

    function createWidget() {
        if (document.getElementById('coki-ai-bubble')) return;

        // Bubble Button
        const bubble = document.createElement('div');
        bubble.id = 'coki-ai-bubble';
        bubble.className = 'coki-ai-bubble-btn';
        bubble.title = 'Pregúntale a Coki AI';
        bubble.innerHTML = `
            <span class="coki-ai-bubble-badge"></span>
            <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
                <circle cx="9" cy="10" r="1.5" fill="currentColor"></circle>
                <circle cx="15" cy="10" r="1.5" fill="currentColor"></circle>
            </svg>
        `;

        // Chat Modal
        const modal = document.createElement('div');
        modal.id = 'coki-ai-modal';
        modal.className = 'coki-ai-widget-modal';
        modal.innerHTML = `
            <div class="coki-ai-widget-header">
                <div style="display:flex; align-items:center; gap:10px;">
                    <div style="width:30px; height:30px; border-radius:8px; background:linear-gradient(135deg, #6366f1, #06b6d4); display:flex; align-items:center; justify-content:center; color:#fff;">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polygon points="12 2 2 7 12 12 22 7 12 2"></polygon><polyline points="2 17 12 22 22 17"></polyline><polyline points="2 12 12 17 22 12"></polyline></svg>
                    </div>
                    <div>
                        <div style="font-weight:700; font-size:14px; color:var(--text);">Coki AI Assistant</div>
                        <div style="font-size:11px; color:#10b981; font-weight:600;">● Workers AI · Llama 3.2 3B</div>
                    </div>
                </div>
                <button id="coki-ai-close-btn" style="background:transparent; border:none; color:var(--text-sub); cursor:pointer; width:30px; height:30px; border-radius:6px; display:flex; align-items:center; justify-content:center; font-size:18px;">✕</button>
            </div>
            <div id="coki-ai-msgs" class="coki-ai-widget-messages">
                <div class="coki-ai-msg bot">
                    👋 ¡Hola! Soy el asistente inteligente de <b>Coki Studios</b>. Pregúntame sobre el motor <b>Looping v2.6</b>, el gestor <b>smiledev</b>, la mensajería <b>CSMS</b> o <b>Forkar Eco Hub</b>.
                </div>
            </div>
            <div class="coki-ai-quick-pills">
                <button class="coki-ai-pill-btn" data-q="homebrew">🍺 Instalar Looping con Homebrew</button>
                <button class="coki-ai-pill-btn" data-q="smiledev">🔄 ¿Cómo funciona smiledev upgrade?</button>
                <button class="coki-ai-pill-btn" data-q="csms">🔒 Criptografía CSMS E2EE</button>
                <button class="coki-ai-pill-btn" data-q="ecohub">🌱 Puntos Eco Hub en la Sabana</button>
            </div>
            <div class="coki-ai-input-wrap">
                <input type="text" id="coki-ai-input" class="coki-ai-input" placeholder="Haz una pregunta técnica..." />
                <button id="coki-ai-send" class="coki-ai-send-btn">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="22" y1="2" x2="11" y2="13"></line><polygon points="22 2 15 22 11 13 2 9 22 2"></polygon></svg>
                </button>
            </div>
        `;

        document.body.appendChild(bubble);
        document.body.appendChild(modal);

        bubble.addEventListener('click', () => {
            modal.classList.toggle('active');
            if (modal.classList.contains('active')) {
                document.getElementById('coki-ai-input').focus();
            }
        });

        document.getElementById('coki-ai-close-btn').addEventListener('click', () => {
            modal.classList.remove('active');
        });

        // Quick pills
        modal.querySelectorAll('.coki-ai-pill-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const key = btn.dataset.q;
                const text = btn.innerText;
                addUserMessage(text);
                const answer = KNOWLEDGE_BASE[key] || "Información disponible en cokistudios.github.io";
                setTimeout(() => addBotMessage(answer), 300);
            });
        });

        const sendBtn = document.getElementById('coki-ai-send');
        const input = document.getElementById('coki-ai-input');

        function handleSend() {
            const query = input.value.trim();
            if (!query) return;
            addUserMessage(query);
            input.value = '';

            // Loading state
            const loadingMsg = addBotMessage("Pensando...");

            // Query Workers AI or fallback
            fetch('/api/coki', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ prompt: query })
            })
            .then(res => res.json())
            .then(data => {
                if (data && (data.response || data.reply)) {
                    loadingMsg.innerHTML = formatMarkdown(data.response || data.reply);
                } else {
                    fallbackAnswer(query, loadingMsg);
                }
            })
            .catch(() => {
                fallbackAnswer(query, loadingMsg);
            });
        }

        sendBtn.addEventListener('click', handleSend);
        input.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') handleSend();
        });
    }

    function addUserMessage(text) {
        const msgs = document.getElementById('coki-ai-msgs');
        const div = document.createElement('div');
        div.className = 'coki-ai-msg user';
        div.innerText = text;
        msgs.appendChild(div);
        msgs.scrollTop = msgs.scrollHeight;
        return div;
    }

    function addBotMessage(text) {
        const msgs = document.getElementById('coki-ai-msgs');
        const div = document.createElement('div');
        div.className = 'coki-ai-msg bot';
        div.innerHTML = formatMarkdown(text);
        msgs.appendChild(div);
        msgs.scrollTop = msgs.scrollHeight;
        return div;
    }

    function formatMarkdown(text) {
        return text
            .replace(/```bash([\s\S]*?)```/g, '<pre style="background:rgba(3,7,18,0.9); padding:8px 10px; border-radius:6px; font-family:\'JetBrains Mono\',monospace; font-size:12px; margin:6px 0; overflow-x:auto; color:#38bdf8;"><code>$1</code></pre>')
            .replace(/`([^`]+)`/g, '<code style="background:rgba(255,255,255,0.1); padding:2px 5px; border-radius:4px; font-family:monospace; font-size:12px; color:#38bdf8;">$1</code>')
            .replace(/\*\*([^*]+)\*\*/g, '<b>$1</b>')
            .replace(/\*([^*]+)\*/g, '<i>$1</i>')
            .replace(/\n/g, '<br>');
    }

    function fallbackAnswer(query, loadingMsg) {
        const q = query.toLowerCase();
        let ans = "Puedes encontrar más información en los productos de Coki Studios o ejecutando `smiledev --help`.";
        if (q.includes('brew') || q.includes('instalar') || q.includes('homebrew')) {
            ans = KNOWLEDGE_BASE.homebrew;
        } else if (q.includes('smiledev') || q.includes('actualiz') || q.includes('upgrade')) {
            ans = KNOWLEDGE_BASE.smiledev;
        } else if (q.includes('csms') || q.includes('cifrado') || q.includes('seguridad') || q.includes('sep') || q.includes('tee')) {
            ans = KNOWLEDGE_BASE.csms;
        } else if (q.includes('eco') || q.includes('forkar') || q.includes('cota') || q.includes('chia') || q.includes('bogota')) {
            ans = KNOWLEDGE_BASE.ecohub;
        } else if (q.includes('looping')) {
            ans = "Looping v2.6.0 es el motor híbrido universal en C++17 de Coki Studios. Ofrece sintaxis expresiva (`? :`, `??`, `match`, pipelines `|>`), ejecución en <0.2ms y soporte multiplataforma.";
        }
        loadingMsg.innerHTML = formatMarkdown(ans);
    }

    window.openCokiAiWidget = function () {
        createWidget();
        const modal = document.getElementById('coki-ai-modal');
        if (modal) modal.classList.add('active');
    };

    document.addEventListener('DOMContentLoaded', createWidget);
})();
