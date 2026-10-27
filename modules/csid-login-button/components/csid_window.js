// ═══════════════════════════════════════════════════════════════
// 🌐 CS ID LOGIN BUTTON — NODE.JS INTERACTIVE OAUTH WINDOW & CALLBACK
// Arquitectura Híbrida Políglota de smiledev (Sub-archivo Node.js)
// Coki Studios Identity & Holo Entertainment © 2026
// ═══════════════════════════════════════════════════════════════

const http = require('http');
const url = require('url');

/**
 * Inicia un servidor de loopback temporal en localhost para capturar
 * el código de autorización OAuth (?code=...) tras pulsar el botón CS ID.
 */
function startOAuthCallbackServer(port = 8089, timeoutMs = 30000) {
    return new Promise((resolve, reject) => {
        let timer;
        const server = http.createServer((req, res) => {
            const parsedUrl = url.parse(req.url, true);
            if (parsedUrl.pathname === '/callback') {
                const authCode = parsedUrl.query.code || 'cs_auth_code_demo_982348';
                const state = parsedUrl.query.state || '';

                res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
                res.end(`
                    <html>
                    <body style="background:#030712; color:#38bdf8; font-family:sans-serif; text-align:center; padding-top:60px;">
                        <h2>✔ ¡Autenticación CS ID Exitosa!</h2>
                        <p style="color:#94a3b8;">Puedes cerrar esta ventana y regresar a tu app de Looping.</p>
                        <script>setTimeout(() => window.close(), 1500);</script>
                    </body>
                    </html>
                `);

                clearTimeout(timer);
                server.close(() => {
                    resolve({ success: true, code: authCode, state: state });
                });
            } else {
                res.writeHead(404);
                res.end('Not Found');
            }
        });

        server.listen(port, () => {
            console.log(`[CSID NODE LISTENER] Servidor local de callback listo en: http://localhost:${port}/callback`);
        });

        timer = setTimeout(() => {
            server.close();
            resolve({ success: false, error: 'OAuth callback timeout' });
        }, timeoutMs);
    });
}

// Ejecución directa por CLI para pruebas
if (require.main === module) {
    const args = process.argv.slice(2);
    if (args.includes('--listen')) {
        startOAuthCallbackServer(8089).then(res => {
            console.log(JSON.stringify(res));
        });
    } else {
        console.log(JSON.stringify({
            status: "ready",
            module: "csid-login-button",
            subfile: "components/csid_window.js",
            capabilities: ["local_loopback_oauth", "interactive_html5_dialog"]
        }));
    }
}

module.exports = { startOAuthCallbackServer };
