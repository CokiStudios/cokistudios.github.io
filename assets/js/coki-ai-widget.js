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
                    <img src="/assets/coki-ai-icon.svg" alt="Coki AI" style="width:30px; height:30px; border-radius:8px;">
                    <div>
                        <div style="font-weight:700; font-size:14px; color:var(--text);">Coki AI · Looping</div>
                        <div style="font-size:11px; color:#10b981; font-weight:600; display:flex; align-items:center; gap:8px;">
                            <span>● 7B MLX / Edge</span>
                            <a href="https://huggingface.co/CokiStudios" target="_blank" rel="noopener noreferrer" style="color:var(--accent, #6366f1); text-decoration:none; font-weight:700;">Hugging Face ↗</a>
                        </div>
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

        let ragCache = null;

        async function getRagContext(query) {
            try {
                if (!ragCache) {
                    const res = await fetch('/assets/data/coki-rag-index.json');
                    if (res.ok) {
                        const json = await res.json();
                        ragCache = Array.isArray(json.chunks) ? json.chunks : [];
                    } else {
                        ragCache = [];
                    }
                }
                if (!ragCache.length) return '';
                const tokens = (query.toLowerCase().match(/[a-z0-9_+.!]{2,}/g) || []).slice(0, 8);
                if (!tokens.length) return '';
                const ranked = ragCache
                    .map(ch => {
                        const title = (ch.title || '').toLowerCase();
                        const kw = Array.isArray(ch.keywords) ? ch.keywords.join(' ') : '';
                        const body = (ch.content || '').toLowerCase();
                        let score = 0;
                        for (const t of tokens) {
                            if (title.includes(t)) score += 3;
                            if (kw.includes(t)) score += 2;
                            if (body.includes(t)) score += 1;
                        }
                        return { score, ch };
                    })
                    .filter(x => x.score > 0)
                    .sort((a, b) => b.score - a.score)
                    .slice(0, 2);
                return ranked.map(x => `[${x.ch.source}] ${x.ch.title}\n${(x.ch.content || '').slice(0, 480)}`).join('\n---\n');
            } catch (_) {
                return '';
            }
        }

        let localMlxModelCache = null;

        async function resolveLocalMlxModel() {
            if (localMlxModelCache) return localMlxModelCache;
            const probe = new AbortController();
            const probeTimer = setTimeout(() => probe.abort(), 1200);
            try {
                const res = await fetch('http://127.0.0.1:8080/v1/models', { signal: probe.signal });
                clearTimeout(probeTimer);
                if (!res.ok) return null;
                const payload = await res.json();
                const items = Array.isArray(payload.data) ? payload.data.map(m => m && m.id).filter(Boolean) : [];
                if (!items.length) return null;
                localMlxModelCache = items.find(id => id.includes('coki-looping')) || items[items.length - 1];
                return localMlxModelCache;
            } catch (_) {
                clearTimeout(probeTimer);
                return null;
            }
        }

        async function tryLocalMlx(query, context) {
            const isLocalHost = ['localhost', '127.0.0.1', ''].includes(window.location.hostname);
            if (!isLocalHost) return null;
            try {
                const activeModel = await resolveLocalMlxModel();
                if (!activeModel) return null;
                const controller = new AbortController();
                const timer = setTimeout(() => controller.abort(), 25000);
                const sys = 'Eres Coki AI, experto en el lenguaje Looping de Coki Studios.' + (context ? '\nContexto:\n' + context : '');
                const res = await fetch('http://127.0.0.1:8080/v1/chat/completions', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    signal: controller.signal,
                    body: JSON.stringify({
                        model: activeModel,
                        messages: [
                            { role: 'system', content: sys },
                            { role: 'user', content: query }
                        ],
                        temperature: 0.25,
                        max_tokens: 700
                    })
                });
                clearTimeout(timer);
                if (!res.ok) {
                    localMlxModelCache = null;
                    return null;
                }
                const data = await res.json();
                return data && data.choices && data.choices[0] && data.choices[0].message
                    ? data.choices[0].message.content
                    : null;
            } catch (_) {
                return null;
            }
        }

        async function handleSend() {
            const query = input.value.trim();
            if (!query) return;
            addUserMessage(query);
            input.value = '';

            // Loading state
            const loadingMsg = addBotMessage("Pensando...");
            const ragContext = await getRagContext(query);

            const localReply = await tryLocalMlx(query, ragContext);
            if (localReply) {
                loadingMsg.innerHTML = formatMarkdown(localReply);
                return;
            }

            // Query Workers AI or fallback
            fetch('/api/coki', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ query: query, prompt: query, context: ragContext })
            })
            .then(res => res.json())
            .then(data => {
                const replyText = data && (data.answer || data.response || data.reply);
                if (replyText) {
                    loadingMsg.innerHTML = formatMarkdown(replyText);
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

    function escapeHtml(str) {
        if (!str) return '';
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }

    function formatMarkdown(text) {
        if (!text) return '';
        const escaped = escapeHtml(text);
        return escaped
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
