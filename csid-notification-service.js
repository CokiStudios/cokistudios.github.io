// ═══════════════════════════════════════════════════════════════
// 🔔 CS ID NOTIFICATION SERVICE (csidsignoti)
// Manejo centralizado de notificaciones de inicio de sesión,
// generación de OTPs (One-Time Passwords) y Coki Family Sharing
// a través de Amazon SES y SMTP desde no-reply@cokistudios.com.
// ═══════════════════════════════════════════════════════════════

export class CSIDNotificationService {
    constructor() {
        this.senderEmail = 'no-reply@cokistudios.com';
        this.systemName = 'CS ID Security Core';
        
        // Notificaciones y correos transaccionales delegados al backend seguro (Cloudflare Worker API)
        this.apiEndpoint = '/api/notify';
    }

    /**
     * 1. Notificación de Nuevo Inicio de Sesión (Sign-in Alert)
     */
    generateSignInAlertTemplate(userEmail, device = 'Dispositivo Apple / Shine OS', ip = 'Detectada autom.') {
        const timestamp = new Date().toLocaleString('es-CO', { timeZone: 'America/Bogota' });
        return {
            to: userEmail,
            from: this.senderEmail,
            subject: '🔔 Nuevo inicio de sesión detectado en tu cuenta de CS ID',
            html: `
                <div style="font-family: 'Outfit', -apple-system, sans-serif; background: #06090f; color: #f1f5f9; padding: 32px; border-radius: 16px; border: 1px solid rgba(255,255,255,0.1); max-width: 520px; margin: 0 auto;">
                    <div style="text-align: center; margin-bottom: 24px;">
                        <h2 style="color: #38bdf8; margin: 0;">CS ID Security Alert</h2>
                        <p style="color: #94a3b8; font-size: 14px;">Coki Studios Official Authentication Service</p>
                    </div>
                    <p style="font-size: 15px; line-height: 1.6;">Hola,</p>
                    <p style="font-size: 15px; line-height: 1.6;">Se ha detectado un nuevo inicio de sesión en tu cuenta oficial de <strong>CS ID</strong>:</p>
                    <div style="background: rgba(255,255,255,0.04); border: 1px solid rgba(255,255,255,0.08); border-radius: 12px; padding: 16px; margin: 20px 0; font-size: 14px;">
                        <p style="margin: 4px 0;"><strong>📱 Dispositivo:</strong> ${device}</p>
                        <p style="margin: 4px 0;"><strong>🕒 Fecha y Hora:</strong> ${timestamp}</p>
                        <p style="margin: 4px 0;"><strong>🌐 Origen:</strong> ${ip}</p>
                        <p style="margin: 4px 0;"><strong>✉️ Emisor Verificado:</strong> ${this.senderEmail}</p>
                    </div>
                    <p style="font-size: 13px; color: #94a3b8;">Si fuiste tú, puedes ignorar este mensaje. Si no reconoces esta actividad, cambia tu contraseña inmediatamente.</p>
                </div>
            `
        };
    }

    /**
     * 2. Generación y Notificación de Código OTP (One-Time Password)
     */
    generateOTPTemplate(userEmail, otpCode) {
        return {
            to: userEmail,
            from: this.senderEmail,
            subject: `🔑 Tu código de seguridad CS ID: ${otpCode}`,
            html: `
                <div style="font-family: 'Outfit', -apple-system, sans-serif; background: #06090f; color: #f1f5f9; padding: 32px; border-radius: 16px; border: 1px solid rgba(255,255,255,0.1); max-width: 520px; margin: 0 auto; text-align: center;">
                    <h2 style="color: #6366f1; margin: 0 0 8px 0;">Verificación de Dos Pasos (OTP)</h2>
                    <p style="color: #94a3b8; font-size: 14px; margin-bottom: 24px;">Ingresa el siguiente código temporal para verificar tu identidad en CS ID:</p>
                    <div style="background: rgba(99,102,241,0.12); border: 1.5px dashed #6366f1; border-radius: 12px; padding: 18px; display: inline-block; font-size: 32px; font-weight: 800; letter-spacing: 6px; color: #38bdf8; margin-bottom: 24px;">
                        ${otpCode}
                    </div>
                    <p style="font-size: 13px; color: #94a3b8; margin: 0;">Este código expira en 10 minutos y es de un solo uso. Enviado desde <strong>${this.senderEmail}</strong>.</p>
                </div>
            `
        };
    }

    /**
     * 3. Invitación a Grupo Familiar (Coki Family Sharing)
     */
    generateFamilyInviteTemplate(userEmail, inviterName = 'Un miembro', familyName = 'Familia Coki', role = 'Adulto', joinLink = 'https://cokistudios.com/dashboard?tab=family') {
        return {
            to: userEmail,
            from: this.senderEmail,
            subject: `👨‍👩‍👧‍👦 Has sido invitado a unirte a "${familyName}" en CS ID`,
            html: `
                <div style="font-family: 'Outfit', -apple-system, sans-serif; background: #06090f; color: #f1f5f9; padding: 32px; border-radius: 16px; border: 1px solid rgba(255,255,255,0.1); max-width: 520px; margin: 0 auto;">
                    <div style="text-align: center; margin-bottom: 24px;">
                        <h2 style="color: #38bdf8; margin: 0;">Coki Family Sharing</h2>
                        <p style="color: #94a3b8; font-size: 14px;">Comparte almacenamiento, apps y beneficios ecológicos</p>
                    </div>
                    <p style="font-size: 15px; line-height: 1.6;">Hola,</p>
                    <p style="font-size: 15px; line-height: 1.6;"><strong>${inviterName}</strong> te ha invitado a formar parte de su grupo familiar <strong>"${familyName}"</strong> con el rol de <strong>${role}</strong>.</p>
                    
                    <div style="background: rgba(99,102,241,0.08); border: 1px solid rgba(99,102,241,0.25); border-radius: 12px; padding: 18px; margin: 24px 0;">
                        <p style="margin: 0 0 10px 0; font-weight: 700; color: #c084fc;">Beneficios incluidos:</p>
                        <p style="margin: 4px 0; font-size: 13.5px; color: #cbd5e1;">✨ Acceso compartido a suscripciones de Felte Store</p>
                        <p style="margin: 4px 0; font-size: 13.5px; color: #cbd5e1;">📍 Ubicación en tiempo real con Shine Find & Horizon Maps</p>
                        <p style="margin: 4px 0; font-size: 13.5px; color: #cbd5e1;">🌱 Seguimiento conjunto de reducción de huella en Eco Hub</p>
                        <p style="margin: 4px 0; font-size: 13.5px; color: #cbd5e1;">💬 Mensajería ultrarrápida cifrada en CSMS</p>
                    </div>

                    <div style="text-align: center; margin: 28px 0;">
                        <a href="${joinLink}" style="background: linear-gradient(135deg, #38bdf8, #6366f1); color: #ffffff; text-decoration: none; padding: 14px 28px; border-radius: 12px; font-weight: 700; font-size: 15px; display: inline-block; box-shadow: 0 8px 24px rgba(56,189,248,0.3);">
                            Aceptar Invitación Familiar
                        </a>
                    </div>
                    <p style="font-size: 12.5px; color: #94a3b8; text-align: center; margin: 0;">Enviado de forma segura por Zoho SMTP desde <strong>${this.senderEmail}</strong>.</p>
                </div>
            `
        };
    }

    /**
     * 4. Enviar notificación mediante API de Cloudflare Workers (Zoho SMTP Gateway)
     */
    async sendNotification(endpoint, payload) {
        try {
            const res = await fetch(endpoint, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            return await res.json();
        } catch (err) {
            console.warn(`[CSIDNotificationService] Network error sending to ${endpoint}:`, err);
            return { success: false, error: err.message };
        }
    }

    async sendOTP(email, code) {
        return this.sendNotification('/api/notify/otp', { email, code });
    }

    async sendSignInAlert(email, device = 'Dispositivo Web', ip = '') {
        return this.sendNotification('/api/notify/signin', { email, device, ip });
    }

    async sendFamilyInvite(email, inviterName, familyName, role, joinLink) {
        return this.sendNotification('/api/notify/family-invite', { email, inviterName, familyName, role, joinLink });
    }
}
