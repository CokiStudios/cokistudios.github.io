/* ═══════════════════════════════════════════════════════════════════════
   🔑 CS ID PASSKEY & BIOMETRIC SECURITY CENTER
   WebAuthn (Touch ID, Face ID, SEP / TEE) Interactive Simulator
   Coki Studios © 2026
   ═══════════════════════════════════════════════════════════════════════ */

(function () {
    let passkeys = JSON.parse(localStorage.getItem('cs_passkeys') || '[]');

    if (passkeys.length === 0) {
        passkeys = [
            {
                id: "pk_sep_mac",
                name: "Mac mini (Apple Silicon M-Series SEP)",
                type: "Secure Enclave (kSecAttrTokenIDSecureEnclave)",
                created: "2026-10-19",
                algorithm: "ES256 (ECDSA P-256)",
                icon: "💻"
            },
            {
                id: "pk_sep_iphone",
                name: "iPhone (Face ID / CryptoKit.SecureEnclave)",
                type: "Apple Secure Enclave Processor",
                created: "2026-10-15",
                algorithm: "ES256 (ECDSA P-256)",
                icon: "📱"
            }
        ];
        localStorage.setItem('cs_passkeys', JSON.stringify(passkeys));
    }

    window.initPasskeyLab = function () {
        renderPasskeysList();
    };

    function renderPasskeysList() {
        const listEl = document.getElementById('csid-passkeys-list');
        if (!listEl) return;

        listEl.innerHTML = passkeys.map(pk => `
            <div style="background:rgba(15,23,42,0.7); border:1px solid rgba(99,102,241,0.25); border-radius:12px; padding:14px; display:flex; justify-content:space-between; align-items:center;">
                <div style="display:flex; align-items:center; gap:12px;">
                    <span style="font-size:26px;">${pk.icon}</span>
                    <div>
                        <div style="font-weight:700; font-size:14px; color:var(--text);">${pk.name}</div>
                        <div style="font-size:11px; color:#a5b4fc; margin-top:2px;">${pk.type} • ${pk.algorithm}</div>
                    </div>
                </div>
                <div style="text-align:right;">
                    <span style="font-size:11px; color:#10b981; font-weight:700; background:rgba(16,185,129,0.12); padding:3px 8px; border-radius:999px;">● Activa</span>
                    <div style="font-size:11px; color:#64748b; margin-top:4px; font-family:'JetBrains Mono',monospace;">${pk.created}</div>
                </div>
            </div>
        `).join('');
    }

    window.simulateBiometricAuth = async function () {
        const statusBox = document.getElementById('csid-auth-status');
        const triggerBtn = document.getElementById('btn-test-passkey');
        if (triggerBtn) triggerBtn.disabled = true;

        if (statusBox) {
            statusBox.style.display = 'block';
            statusBox.innerHTML = `
                <div style="display:flex; align-items:center; gap:10px; color:#38bdf8;">
                    <svg class="cs-spin" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10" stroke-dasharray="32" stroke-linecap="round"></circle></svg>
                    <span>Solicitando autenticación biométrica de hardware (Touch ID / Face ID)...</span>
                </div>
            `;
        }

        // Simulate 800ms biometric sensor delay
        await new Promise(r => setTimeout(r, 850));

        // Generate challenge signature simulation
        const challenge = "csid_auth_challenge_" + Math.random().toString(36).substring(2, 10);
        const encoder = new TextEncoder();
        const hashBuf = await crypto.subtle.digest('SHA-256', encoder.encode(challenge));
        const hashHex = Array.from(new Uint8Array(hashBuf)).map(b => b.toString(16).padStart(2, '0')).join('');

        if (window.triggerSoundEffect) window.triggerSoundEffect('powerup');
        if (navigator.vibrate) navigator.vibrate([60, 40, 80]);

        if (statusBox) {
            statusBox.innerHTML = `
                <div style="background:rgba(16,185,129,0.15); border:1px solid rgba(16,185,129,0.4); border-radius:10px; padding:12px; color:#10b981; font-size:13px;">
                    <div style="font-weight:700; display:flex; align-items:center; gap:6px;">
                        <span>✔ Identidad Verificada por Secure Enclave (Touch ID / Face ID)</span>
                    </div>
                    <div style="font-size:11.5px; color:#94a3b8; margin-top:4px; font-family:'JetBrains Mono',monospace; word-break:break-all;">
                        Firma criptográfica P-256: 0x${hashHex.slice(0, 36)}...
                    </div>
                </div>
            `;
        }

        if (triggerBtn) triggerBtn.disabled = false;
    };

    window.registerNewPasskey = function () {
        const isApple = navigator.userAgent.includes('Mac') || navigator.userAgent.includes('iPhone');
        const newPk = {
            id: "pk_" + Date.now(),
            name: isApple ? "Dispositivo Apple (Touch ID / Face ID)" : "Dispositivo FIDO2 / Windows Hello",
            type: isApple ? "Apple Secure Enclave Processor" : "FIDO2 / StrongBox TEE",
            created: new Date().toISOString().split('T')[0],
            algorithm: "ES256 (ECDSA P-256)",
            icon: isApple ? "🍎" : "🔐"
        };

        passkeys.unshift(newPk);
        localStorage.setItem('cs_passkeys', JSON.stringify(passkeys));
        renderPasskeysList();
        if (window.triggerSoundEffect) window.triggerSoundEffect('coin');
        alert("✔ ¡Nueva Passkey vinculada con éxito a tu CS ID!");
    };

    document.addEventListener('DOMContentLoaded', window.initPasskeyLab);
})();
