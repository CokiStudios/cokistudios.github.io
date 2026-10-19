/* ═══════════════════════════════════════════════════════════════════════
   🔒 CSMS E2EE CRYPTOLAB — HARDWARE-BACKED SECURITY VISUALIZER
   SEP (Apple Secure Enclave) & TEE (Android StrongBox) Simulator
   Coki Studios Messaging Service © 2026
   ═══════════════════════════════════════════════════════════════════════ */

(function () {
    const SALT = "CSMS_E2EE_COKI_STUDIOS_v1_SALT_FORKAR";

    // Helper: Buffer to Hex
    function bufToHex(buffer) {
        return Array.from(new Uint8Array(buffer))
            .map(b => b.toString(16).padStart(2, '0'))
            .join('');
    }

    // Helper: Buffer to Base64
    function bufToBase64(buffer) {
        let binary = '';
        const bytes = new Uint8Array(buffer);
        for (let i = 0; i < bytes.byteLength; i++) {
            binary += String.fromCharCode(bytes[i]);
        }
        return window.btoa(binary);
    }

    // Helper: Base64 to Buffer
    function base64ToBuf(b64) {
        const binary = window.atob(b64);
        const bytes = new Uint8Array(binary.length);
        for (let i = 0; i < binary.length; i++) {
            bytes[i] = binary.charCodeAt(i);
        }
        return bytes.buffer;
    }

    window.deriveCsmsKey = async function (roomId) {
        const input = `${roomId}:${SALT}`;
        const encoder = new TextEncoder();
        const keyHash = await crypto.subtle.digest('SHA-256', encoder.encode(input));
        return keyHash;
    };

    window.encryptCsmsMessage = async function () {
        const textInput = document.getElementById('csms-input-text');
        const roomInput = document.getElementById('csms-input-room');
        const step1El = document.getElementById('csms-step-key');
        const step2El = document.getElementById('csms-step-hardware');
        const step3El = document.getElementById('csms-step-payload');
        const step4El = document.getElementById('csms-step-decrypt');
        const verifyBadge = document.getElementById('csms-verify-badge');

        if (!textInput || !roomInput) return;

        const message = textInput.value || "¡Hola desde Coki Studios!";
        const roomId = roomInput.value.trim() || "general_community_chat";

        try {
            // Step 1: Derive SHA-256 Room Key
            const keyHashBuffer = await window.deriveCsmsKey(roomId);
            const keyHex = bufToHex(keyHashBuffer);
            if (step1El) {
                step1El.innerHTML = `<span style="color:#c084fc; font-family:'JetBrains Mono',monospace; font-size:11.5px; word-break:break-all;">SHA-256: ${keyHex.slice(0, 32)}...</span>`;
            }

            // Step 2: Hardware Enclave Import (Apple SEP / Android StrongBox TEE)
            const cryptoKey = await crypto.subtle.importKey(
                'raw',
                keyHashBuffer,
                { name: 'AES-GCM' },
                false,
                ['encrypt', 'decrypt']
            );

            // Detect device platform for realistic enclave badge
            const isApple = navigator.userAgent.includes('Mac') || navigator.userAgent.includes('iPhone') || navigator.userAgent.includes('iPad');
            const enclaveName = isApple ? 'Apple Secure Enclave (SEP)' : 'Android KeyStore (StrongBox TEE)';
            if (step2El) {
                step2El.innerHTML = `<span style="color:#00f5d4; font-weight:700;">✔ Protegido por ${enclaveName}</span><br><span style="color:#94a3b8; font-size:11px;">Clave simétrica aislada en silicio de hardware</span>`;
            }

            // Step 3: AES-256-GCM Encryption with 12-byte IV
            const iv = crypto.getRandomValues(new Uint8Array(12));
            const encoder = new TextEncoder();
            const cipherBuffer = await crypto.subtle.encrypt(
                { name: 'AES-GCM', iv: iv },
                cryptoKey,
                encoder.encode(message)
            );

            const b64Iv = bufToBase64(iv.buffer);
            const b64Cipher = bufToBase64(cipherBuffer);
            const payload = `🔒 enc:v1:${b64Iv}:${b64Cipher}`;

            if (step3El) {
                step3El.innerHTML = `<div style="background:rgba(3,7,18,0.8); border:1px solid rgba(139,92,246,0.3); border-radius:8px; padding:8px 10px; font-family:'JetBrains Mono',monospace; font-size:11px; color:#a7f3d0; word-break:break-all; max-height:80px; overflow-y:auto;">${payload}</div>`;
            }

            // Step 4: Verify Decryption Live
            const parts = payload.split(':');
            const decIv = base64ToBuf(parts[2]);
            const decCipher = base64ToBuf(parts[3]);

            const decryptedBuf = await crypto.subtle.decrypt(
                { name: 'AES-GCM', iv: decIv },
                cryptoKey,
                decCipher
            );
            const decryptedText = new TextDecoder().decode(decryptedBuf);

            if (step4El) {
                step4El.innerHTML = `<span style="color:#f1f5f9; font-weight:600;">"${decryptedText}"</span>`;
            }

            if (verifyBadge) {
                verifyBadge.style.display = 'inline-flex';
            }

        } catch (err) {
            console.error('CSMS Crypto error:', err);
        }
    };

    window.copyCsmsPayload = function (btn) {
        const payloadBox = document.querySelector('#csms-step-payload div');
        if (!payloadBox) return;
        navigator.clipboard.writeText(payloadBox.innerText).then(() => {
            const prev = btn.innerText;
            btn.innerText = '¡Copiado!';
            setTimeout(() => btn.innerText = prev, 1800);
        });
    };

    // Auto initialize
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            setTimeout(window.encryptCsmsMessage, 300);
        });
    } else {
        setTimeout(window.encryptCsmsMessage, 300);
    }
})();
