/* ═══════════════════════════════════════════════════════════════════════
   💬 CSMS WEB CLIENT SIMULATOR (E2EE SEP/TEE REAL-TIME CHAT)
   Hardware-Backed Instant Messaging Client Demo
   Coki Studios © 2026
   ═══════════════════════════════════════════════════════════════════════ */

(function () {
    const CHANNELS = {
        'holo-games': {
            name: "🚀 Holo Games Devs",
            desc: "Discusión sobre Shine APU, XUI 240Hz y Looping v2.6",
            messages: [
                { sender: "Coki Lead", text: "El build de Holo Looping OoS corre a 240 FPS directos en el APU de Shine.", time: "10:14 AM", verified: true },
                { sender: "Shine Dev", text: "Confirmado. La latencia del pipeline C++ está por debajo de 0.2ms.", time: "10:15 AM", verified: true }
            ]
        },
        'forkar-eco': {
            name: "🌱 Forkar Eco Sabana",
            desc: "Red comunitaria Cota • Chía • Majuy • Bogotá",
            messages: [
                { sender: "Eco Guardian Cota", text: "Nueva estación de acopio inaugurada en el Parque Central de Cota (+40 Pts Eco).", time: "09:30 AM", verified: true },
                { sender: "Bici Sabana", text: "Validación NFC lista en la ruta hacia el Portal 80.", time: "09:42 AM", verified: true }
            ]
        },
        'vault-sep': {
            name: "🔐 CSMS Hardware Vault",
            desc: "Canal ultra-seguro respaldado por Apple SEP y Android TEE",
            messages: [
                { sender: "System Sentinel", text: "🔒 enc:v1:Clave simétrica derivada y protegida por el enclave de hardware.", time: "08:00 AM", verified: true }
            ]
        }
    };

    let activeChannel = 'holo-games';

    window.initCsmsWebSim = function () {
        renderChannels();
        renderMessages();
    };

    function renderChannels() {
        const tabsContainer = document.getElementById('csms-sim-channels');
        if (!tabsContainer) return;

        tabsContainer.innerHTML = Object.keys(CHANNELS).map(k => `
            <button class="csms-sim-tab ${k === activeChannel ? 'active' : ''}" onclick="window.switchCsmsChannel('${k}')">
                ${CHANNELS[k].name}
            </button>
        `).join('');
    }

    window.switchCsmsChannel = function (channelKey) {
        if (!CHANNELS[channelKey]) return;
        activeChannel = channelKey;
        renderChannels();
        renderMessages();
        if (window.triggerSoundEffect) window.triggerSoundEffect('jump');
    };

    function renderMessages() {
        const container = document.getElementById('csms-sim-messages');
        const titleEl = document.getElementById('csms-sim-channel-title');
        const descEl = document.getElementById('csms-sim-channel-desc');
        if (!container) return;

        const ch = CHANNELS[activeChannel];
        if (titleEl) titleEl.innerText = ch.name;
        if (descEl) descEl.innerText = ch.desc;

        container.innerHTML = ch.messages.map(m => `
            <div class="csms-sim-bubble ${m.sender === 'Tú' ? 'me' : 'them'}">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:4px; gap:8px;">
                    <span style="font-weight:700; font-size:12px; color:${m.sender === 'Tú' ? '#a5b4fc' : '#38bdf8'};">${m.sender}</span>
                    <span style="font-size:10px; color:#10b981; font-weight:600;">🔒 SEP E2EE</span>
                </div>
                <div style="font-size:13.5px; line-height:1.45;">${m.text}</div>
                <div style="font-size:10px; color:rgba(255,255,255,0.45); text-align:right; margin-top:4px;">${m.time}</div>
            </div>
        `).join('');

        container.scrollTop = container.scrollHeight;
    }

    window.sendCsmsSimMessage = function () {
        const input = document.getElementById('csms-sim-input');
        if (!input) return;
        const text = input.value.trim();
        if (!text) return;

        const now = new Date();
        const timeStr = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

        CHANNELS[activeChannel].messages.push({
            sender: "Tú",
            text: text,
            time: timeStr,
            verified: true
        });

        input.value = '';
        renderMessages();

        if (window.triggerSoundEffect) window.triggerSoundEffect('coin');
        if (navigator.vibrate) navigator.vibrate(30);
    };

    window.sendCsmsVoiceCapsule = function () {
        const now = new Date();
        const timeStr = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

        if (window.triggerSoundEffect) window.triggerSoundEffect('powerup');

        CHANNELS[activeChannel].messages.push({
            sender: "Tú",
            text: "🎙️ Cápsula de Voz Cifrada (3.2s) • [▶ Reproducir Audio E2EE]",
            time: timeStr,
            verified: true
        });

        renderMessages();
    };

    document.addEventListener('DOMContentLoaded', window.initCsmsWebSim);
})();
