// ═══════════════════════════════════════════════════════════════
// 🔔 CS ID NOTIFICATION SERVICE (csidsignnoti)
// Manejo centralizado de notificaciones de inicio de sesión,
// generación de OTPs (One-Time Passwords) y reseteo de contraseñas.
// ═══════════════════════════════════════════════════════════════

export class CSIDNotificationService {
    constructor() {
        this.senderEmail = 'csidsignnoti@cokistudios.com';
        this.systemName = 'CS ID Security Core';
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
                    <p style="font-size: 13px; color: #94a3b8; margin: 0;">Este código expira en 10 minutos y es de un solo uso. Nunca lo compartas con nadie.</p>
                </div>
            `
        };
    }

    /**
     * 3. Notificación de Restablecimiento de Contraseña (Password Reset)
     */
    generatePasswordResetTemplate(userEmail, resetLink) {
        return {
            to: userEmail,
            from: this.senderEmail,
            subject: '🔒 Restablecimiento de contraseña — CS ID',
            html: `
                <div style="font-family: 'Outfit', -apple-system, sans-serif; background: #06090f; color: #f1f5f9; padding: 32px; border-radius: 16px; border: 1px solid rgba(255,255,255,0.1); max-width: 520px; margin: 0 auto;">
                    <h2 style="color: #38bdf8; margin: 0 0 8px 0; text-align: center;">Restablecer Contraseña</h2>
                    <p style="color: #94a3b8; font-size: 14px; text-align: center; margin-bottom: 24px;">Hemos recibido una solicitud para cambiar tu contraseña en Coki Studios ID.</p>
                    <div style="text-align: center; margin: 28px 0;">
                        <a href="${resetLink}" style="background: linear-gradient(135deg, #38bdf8, #6366f1); color: #ffffff; text-decoration: none; padding: 14px 28px; border-radius: 12px; font-weight: 700; font-size: 15px; display: inline-block; box-shadow: 0 8px 24px rgba(56,189,248,0.3);">
                            Restablecer mi Contraseña
                        </a>
                    </div>
                    <p style="font-size: 13px; color: #94a3b8; line-height: 1.5;">Si no solicitaste este cambio, puedes ignorar este correo; tu contraseña actual continuará siendo segura.</p>
                </div>
            `
        };
    }
}
