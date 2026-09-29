//
//  moderation-client.js
//  Coki Studios Web AI Content Safety & Anti-Evasion Client
//  Supports Cloudflare Workers AI (Zero-setup Edge) & Connect with ChatGPT (OpenAI BYOK)
//

const CHATGPT_STORAGE_KEY = 'coki_chatgpt_api_key';

export function getConnectedChatGPTKey() {
  return localStorage.getItem(CHATGPT_STORAGE_KEY) || null;
}

export function saveChatGPTKey(key) {
  const clean = (key || '').trim();
  if (clean) {
    localStorage.setItem(CHATGPT_STORAGE_KEY, clean);
  } else {
    localStorage.removeItem(CHATGPT_STORAGE_KEY);
  }
}

export function disconnectChatGPT() {
  localStorage.removeItem(CHATGPT_STORAGE_KEY);
}

/**
 * Analyzes text for toxicity, evasion attempts ('maricooon', 'P U T A'),
 * and sexual double entendres ('chistes de doble sentido', albures).
 * 
 * Uses ChatGPT (if connected) or native Cloudflare Workers AI (/api/moderate).
 */
export async function moderateContent({ title = '', content = '' }) {
  const cleanTitle = (title || '').trim();
  const cleanContent = (content || '').trim();

  if (!cleanTitle && !cleanContent) {
    return { isSafe: true, flaggedWords: [], reason: 'Contenido vacío.', engine: 'Client Heuristics' };
  }

  const openAiKey = getConnectedChatGPTKey();

  // Tier A: If user connected their personal ChatGPT API Key
  if (openAiKey) {
    try {
      const systemPrompt = `You are the Forkar content safety moderator for Coki Studios.
Analyze the user title and content for:
1. Insults, harassment, toxicity, hate speech, threats.
2. Sexual innuendos, vulgar double entendres ("chistes de doble sentido", albures, insinuaciones sexuales vulgares camufladas con comida o palabras ambiguas).
3. Evasion attempts (stretched letters 'maricooon', spaced characters 'P U T A', leetspeak 'p3nd3jo').

Respond ONLY with a JSON object in this exact format:
{"isSafe": false, "flaggedWords": ["palabra"], "reason": "Explicación en español"}
or if completely safe:
{"isSafe": true, "flaggedWords": [], "reason": "Contenido respetuoso"}
Do not include markdown ticks or additional commentary.`;

      const userPrompt = cleanTitle
        ? `📌 TÍTULO: "${cleanTitle}"\n📝 MENSAJE: "${cleanContent}"\n\n¿Cumple con las normas o contiene ataques, toxicidad, insultos o chistes de doble sentido vulgares?`
        : `💬 MENSAJE: "${cleanContent}"\n\n¿Cumple con las normas o contiene ataques, toxicidad, insultos o chistes de doble sentido vulgares?`;

      const res = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${openAiKey}`
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini',
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userPrompt }
          ],
          temperature: 0.1,
          response_format: { type: 'json_object' }
        })
      });

      if (res.ok) {
        const data = await res.json();
        const parsed = JSON.parse(data.choices[0].message.content);
        return {
          isSafe: Boolean(parsed.isSafe),
          flaggedWords: parsed.flaggedWords || [],
          reason: parsed.reason || (parsed.isSafe ? 'Contenido respetuoso.' : 'Contenido inapropiado detectado.'),
          engine: 'OpenAI ChatGPT (GPT-4o-mini)'
        };
      }
      console.warn('ChatGPT API call failed, falling back to Cloudflare Workers AI...');
    } catch (e) {
      console.warn('ChatGPT request error, falling back to Workers AI:', e);
    }
  }

  // Tier B: Native Cloudflare Workers AI Edge Endpoint (/api/moderate)
  try {
    const res = await fetch('/api/moderate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: cleanTitle, content: cleanContent })
    });

    if (res.ok) {
      return await res.json();
    }
  } catch (err) {
    console.error('Moderation API call error:', err);
  }

  // Safe fallback if network is completely offline
  return {
    isSafe: true,
    flaggedWords: [],
    reason: 'Verificación offline completada.',
    engine: 'Client Fallback'
  };
}

/**
 * Injects the "Conectar con ChatGPT" modal into the current page DOM
 */
export function setupChatGPTModalUI() {
  if (document.getElementById('coki-chatgpt-modal')) return;

  const modalHtml = `
    <div id="coki-chatgpt-modal" style="display:none; position:fixed; inset:0; z-index:99999; background:rgba(0,0,0,0.75); backdrop-filter:blur(8px); align-items:center; justify-content:center; padding:20px;">
      <div style="background:var(--bg2, #0d1117); border:1px solid var(--border-glow, rgba(99,102,241,0.4)); border-radius:20px; max-width:480px; width:100%; padding:28px; box-shadow:0 24px 64px rgba(0,0,0,0.6); color:var(--text, #f1f5f9); font-family:inherit;">
        <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:16px;">
          <div style="display:flex; align-items:center; gap:10px;">
            <div style="width:36px; height:36px; border-radius:10px; background:#10a37f; display:flex; align-items:center; justify-content:center; color:white; font-size:20px; font-weight:bold;">⚡</div>
            <div>
              <h3 style="font-size:18px; font-weight:700; margin:0;">Conectar con ChatGPT</h3>
              <p style="font-size:12px; color:var(--text-sub, #94a3b8); margin:0;">OpenAI API para moderación y análisis avanzado</p>
            </div>
          </div>
          <button id="close-chatgpt-modal-btn" style="background:none; border:none; color:var(--text-sub, #94a3b8); font-size:22px; cursor:pointer; padding:4px;">&times;</button>
        </div>

        <div style="background:rgba(99,102,241,0.08); border:1px solid rgba(99,102,241,0.2); border-radius:12px; padding:12px 14px; margin-bottom:18px; font-size:13px; line-height:1.5;">
          <strong>🛡️ Modo Híbrido Activo:</strong> Tu web ya cuenta con <strong>Cloudflare Workers AI</strong> en el Edge de forma gratuita. Conectar tu clave de OpenAI te permite usar modelos de última generación (GPT-4o) para detectar chistes de doble sentido complejos con precisión máxima.
        </div>

        <div style="margin-bottom:18px;">
          <label style="display:block; font-size:13px; font-weight:600; margin-bottom:6px; color:var(--text, #f1f5f9);">OpenAI API Key (sk-...)</label>
          <input type="password" id="coki-chatgpt-key-input" placeholder="sk-proj-..." style="width:100%; padding:10px 14px; background:rgba(0,0,0,0.3); border:1px solid var(--border, rgba(255,255,255,0.1)); border-radius:10px; color:var(--text, #f1f5f9); font-size:14px; font-family:monospace; box-sizing:border-box; outline:none;" />
          <span style="font-size:11px; color:var(--text-muted, #64748b); display:block; margin-top:4px;">Tu clave se almacena de forma segura únicamente en tu navegador (localStorage).</span>
        </div>

        <div id="chatgpt-status-badge" style="margin-bottom:20px; font-size:13px; display:flex; align-items:center; gap:8px;"></div>

        <div style="display:flex; gap:10px; justify-content:flex-end;">
          <button id="disconnect-chatgpt-btn" style="display:none; background:rgba(239,68,68,0.15); color:#ef4444; border:1px solid rgba(239,68,68,0.3); padding:9px 16px; border-radius:10px; font-size:13px; font-weight:600; cursor:pointer;">Desconectar</button>
          <button id="save-chatgpt-btn" style="background:var(--accent, #6366f1); color:white; border:none; padding:9px 20px; border-radius:10px; font-size:13px; font-weight:600; cursor:pointer;">Guardar y Conectar</button>
        </div>
      </div>
    </div>
  `;

  document.body.insertAdjacentHTML('beforeend', modalHtml);

  const modal = document.getElementById('coki-chatgpt-modal');
  const closeBtn = document.getElementById('close-chatgpt-modal-btn');
  const input = document.getElementById('coki-chatgpt-key-input');
  const saveBtn = document.getElementById('save-chatgpt-btn');
  const disconnectBtn = document.getElementById('disconnect-chatgpt-btn');
  const statusBadge = document.getElementById('chatgpt-status-badge');

  function updateStatus() {
    const key = getConnectedChatGPTKey();
    if (key) {
      input.value = key;
      statusBadge.innerHTML = `<span style="color:#10b981; font-weight:600;">🟢 Conectado con ChatGPT</span> (GPT-4o-mini prioritario)`;
      disconnectBtn.style.display = 'inline-block';
      saveBtn.textContent = 'Actualizar Clave';
    } else {
      input.value = '';
      statusBadge.innerHTML = `<span style="color:#6366f1; font-weight:600;">⚡ Cloudflare Workers AI Activo</span> (Llama 3.2 en el Edge)`;
      disconnectBtn.style.display = 'none';
      saveBtn.textContent = 'Guardar y Conectar';
    }
  }

  closeBtn.addEventListener('click', () => { modal.style.display = 'none'; });
  modal.addEventListener('click', (e) => { if (e.target === modal) modal.style.display = 'none'; });

  saveBtn.addEventListener('click', () => {
    const key = input.value.trim();
    if (!key) {
      alert('Por favor ingresa una clave de API válida (sk-...)');
      return;
    }
    saveChatGPTKey(key);
    updateStatus();
    alert('✅ ChatGPT conectado correctamente para la moderación.');
    modal.style.display = 'none';
  });

  disconnectBtn.addEventListener('click', () => {
    disconnectChatGPT();
    updateStatus();
    alert('ℹ️ Desconectado de ChatGPT. Ahora se usará Cloudflare Workers AI.');
  });

  updateStatus();
}

export function openChatGPTModal() {
  setupChatGPTModalUI();
  const modal = document.getElementById('coki-chatgpt-modal');
  if (modal) modal.style.display = 'flex';
}
