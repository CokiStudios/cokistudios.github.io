/**
 * loop-node-window: Dynamic HTML5 Window & 2D Game Creator for Node.js & Looping Engine
 * Author: Coki Studios Web & Loop Lab
 * Version: 2.0.0 (Quantum 2D Edition)
 * 
 * Zero external dependencies. Uses standard Node.js built-in modules (http, child_process, os, events, readline, fs, path, url).
 * Provides a high-refresh 60 FPS 2D Arcade Stage, Web Audio synthesis, real-time SSE metrics,
 * action callbacks, and bidirectional IPC communication for Looping (.loop) and Node.js.
 */

import http from 'http';
import { exec } from 'child_process';
import os from 'os';
import { EventEmitter } from 'events';
import readline from 'readline';
import { fileURLToPath } from 'url';
import fs from 'fs';
import path from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const DEFAULT_GAME_SCRIPT = `# ═══════════════════════════════════════════════════════════════
#  Holo Quantum Arcade 2D — Built with Looping Compile (.loop)
# Powered by loop-node-window & CS Looping Graphics Engine v2.8.5
# ═══════════════════════════════════════════════════════════════

import loop.engine as game

define game "QuantumRunner2D" version 2.8:
    create window with title "Holo Quantum Arcade" and size (760, 440)
    set theme to "dark_neon"
    
    # ── Configuración de Mundo y Físicas ──
    game.world(width: 1500, height: 440)
    game.gravity(980)
    game.friction(0.82)
    game.lives(3)

    print "🚀 Inicializando nivel 2D interactivo a 60 FPS..."

    # ── Héroe Protagonista (Doble Salto, Dash, Disparo & Inercia) ──
    spawn.player(name: "Angel Helium", at: (100, 320), speed: 280, jump: 440, health: 100)

    # ── Maglev Plataforma Móvil & Plataformas Neón ──
    spawn.platform(at: (60, 340), size: (180, 18), color: "#6366f1")
    spawn.moving_platform(at: (280, 260), size: (140, 18), range: (220, 520), speed: 85, color: "#06b6d4")
    spawn.platform(at: (560, 200), size: (160, 18), color: "#8b5cf6")
    spawn.platform(at: (780, 270), size: (150, 18), color: "#6366f1")
    spawn.moving_platform(at: (980, 220), size: (130, 18), range: (960, 1140), speed: 70, color: "#06b6d4")

    # ── Trampas Neón, Impulsores y Anillos de Salto ──
    spawn.spike(at: (440, 396), size: (44, 20), damage: 35)
    spawn.pad(at: (250, 396), power: 670)
    spawn.orb(at: (720, 180), power: 560, color: "#f59e0b")

    # ── Coleccionables & Kits de Salud ──
    spawn.coin(at: (340, 210), points: 100)
    spawn.coin(at: (620, 150), points: 150)
    spawn.coin(at: (840, 220), points: 200)
    spawn.coin(at: (1040, 170), points: 250)
    spawn.heart(at: (590, 150), heal: 35)

    # ── Enemigos Autónomos (Derrotables al pisarlos o disparando) ──
    spawn.enemy(name: "CorruptedForkbot", at: (800, 226), range: (780, 930), speed: 75, health: 30)
    spawn.enemy(name: "CyberDrone", at: (1240, 350), range: (1180, 1380), speed: 80, health: 40)

    # ── Portal de Victoria ──
    spawn.portal(at: (1380, 328), label: "NEON HUB")

    print "✔ Controles: [A/D o Flechas] Mover • [W / Espacio] Doble Salto • [Z / J] Disparo • [X / K] Dash"`;

class DynamicHTMLWindow extends EventEmitter {
    constructor(options = {}) {
        super();
        this.title = options.title || 'Holo Quantum Arcade 2D';
        this.port = options.port || 7890;
        this.width = options.width || 880;
        this.height = options.height || 640;
        this.autoOpen = options.autoOpen !== undefined ? options.autoOpen : true;
        this.soundEnabled = options.soundEnabled !== undefined ? options.soundEnabled : true;
        this.gameMode = options.gameMode !== undefined ? options.gameMode : true;
        
        // Game Script
        if (options.scriptPath && fs.existsSync(options.scriptPath)) {
            try {
                this.gameScript = fs.readFileSync(options.scriptPath, 'utf-8');
            } catch (e) {
                this.gameScript = DEFAULT_GAME_SCRIPT;
            }
        } else if (options.gameScript) {
            this.gameScript = options.gameScript;
        } else {
            this.gameScript = DEFAULT_GAME_SCRIPT;
        }

        this.metrics = Object.assign({
            'Status': 'Running @ 60 FPS',
            'Engine': 'Looping 2D Quantum',
            'PlayerScore': 0,
            'PlayerHP': 100,
            'Lives': 3,
            'Enemies': 2,
            'FPS': 60,
            'Events': 0
        }, options.metrics || {});

        this.cards = options.cards || [
            { id: 'c1', title: '2D Quantum Game Stage', content: 'Motor gráfico acelerado por hardware a 60 FPS con doble salto, dash, proyectiles y físicas de pisada.' },
            { id: 'c2', title: 'Web Audio Synthesizer', content: 'Síntesis acústica procedural en tiempo real para saltos, propulsores, monedas y victoria sin archivos externos.' }
        ];

        this.logs = [];
        this.clients = new Set();
        this.server = null;
        this.actualPort = this.port;

        this.addLog(`[System] DynamicHTMLWindow 2D inicializado para "${this.title}"`);
    }

    addLog(msg) {
        const time = new Date().toLocaleTimeString();
        const entry = `[${time}] ${msg}`;
        this.logs.unshift(entry);
        if (this.logs.length > 100) this.logs.pop();
        this.broadcast({ type: 'log', data: entry });
    }

    updateMetric(key, val) {
        this.metrics[key] = val;
        this.broadcast({ type: 'metric', key, value: val });
    }

    addCard(id, title, content) {
        const existing = this.cards.find(c => c.id === id);
        if (existing) {
            existing.title = title;
            existing.content = content;
        } else {
            this.cards.push({ id, title, content });
        }
        this.broadcast({ type: 'cards', cards: this.cards });
    }

    sendGameCommand(command, payload = {}) {
        this.broadcast({ type: 'game_command', command, payload });
        this.addLog(`[Game IPC Out] Command: "${command}" -> ${JSON.stringify(payload)}`);
    }

    setGameScript(script) {
        this.gameScript = script;
        this.broadcast({ type: 'game_script', script: this.gameScript });
        this.addLog(`[Game Engine] Nuevo script de nivel cargado dinámicamente (${script.split('\\n').length} líneas).`);
    }

    broadcast(payload) {
        const raw = `data: ${JSON.stringify(payload)}\n\n`;
        for (const client of this.clients) {
            try {
                client.write(raw);
            } catch (err) {
                this.clients.delete(client);
            }
        }
    }

    start() {
        return new Promise((resolve, reject) => {
            this.server = http.createServer((req, res) => {
                const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);

                // CORS headers
                res.setHeader('Access-Control-Allow-Origin', '*');
                res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
                res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

                if (req.method === 'OPTIONS') {
                    res.writeHead(204);
                    res.end();
                    return;
                }

                // Favicon endpoint
                if (url.pathname === '/favicon.ico') {
                    const iconSvg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect width="32" height="32" rx="8" fill="#060913"/><text x="16" y="22" font-size="18" font-family="system-ui" font-weight="bold" fill="#38bdf8" text-anchor="middle">🎮</text></svg>`;
                    res.writeHead(200, { 'Content-Type': 'image/svg+xml', 'Cache-Control': 'public, max-age=86400' });
                    res.end(iconSvg);
                    return;
                }

                // Serve Looping Engine Core JS (`/looping_core.js`)
                if (url.pathname === '/looping_core.js' || url.pathname === '/LoopingEngine/looping_core.js') {
                    const candidates = [
                        path.join(__dirname, '../../LoopingEngine/looping_core.js'),
                        path.join(process.cwd(), 'LoopingEngine/looping_core.js'),
                        path.join(os.homedir(), 'cokistudios.github.io/LoopingEngine/looping_core.js')
                    ];
                    let coreCode = '';
                    for (const p of candidates) {
                        if (fs.existsSync(p)) {
                            coreCode = fs.readFileSync(p, 'utf-8');
                            break;
                        }
                    }
                    if (coreCode) {
                        res.writeHead(200, { 'Content-Type': 'application/javascript; charset=utf-8' });
                        res.end(coreCode);
                        return;
                    }
                }

                // SSE Event Stream
                if (url.pathname === '/api/events') {
                    res.writeHead(200, {
                        'Content-Type': 'text/event-stream; charset=utf-8',
                        'Cache-Control': 'no-cache, no-transform',
                        'Connection': 'keep-alive',
                        'X-Accel-Buffering': 'no'
                    });
                    res.write(': connected\n\n');
                    this.clients.add(res);

                    const keepAlive = setInterval(() => {
                        try { res.write(': ping\n\n'); } catch (e) { clearInterval(keepAlive); }
                    }, 10000);

                    req.on('close', () => {
                        clearInterval(keepAlive);
                        this.clients.delete(res);
                    });
                    return;
                }

                // API: Get State
                if (url.pathname === '/api/state' && req.method === 'GET') {
                    res.writeHead(200, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({
                        title: this.title,
                        metrics: this.metrics,
                        cards: this.cards,
                        logs: this.logs,
                        soundEnabled: this.soundEnabled,
                        gameScript: this.gameScript
                    }));
                    return;
                }

                // API: Get Game Script
                if (url.pathname === '/api/game/script' && req.method === 'GET') {
                    res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
                    res.end(this.gameScript);
                    return;
                }

                // API: Post Action from client UI or Game Canvas
                if (url.pathname === '/api/action' && req.method === 'POST') {
                    let body = '';
                    req.on('data', chunk => body += chunk);
                    req.on('end', () => {
                        try {
                            const data = JSON.parse(body || '{}');
                            const action = data.action || 'unknown';
                            const payload = data.payload || {};

                            this.metrics['Events'] = (this.metrics['Events'] || 0) + 1;

                            // Handle Game-specific actions
                            if (action === 'game_score' && payload.score !== undefined) {
                                this.updateMetric('PlayerScore', payload.score);
                            } else if (action === 'game_hp' && payload.hp !== undefined) {
                                this.updateMetric('PlayerHP', payload.hp);
                            } else if (action === 'game_lives' && payload.lives !== undefined) {
                                this.updateMetric('Lives', payload.lives);
                            } else if (action === 'enemy_stomped') {
                                this.metrics['Enemies'] = Math.max(0, (this.metrics['Enemies'] || 2) - 1);
                                this.updateMetric('Enemies', this.metrics['Enemies']);
                                this.addLog(`[Game Combat] 💥 Enemigo neutralizado por pisada (+250 Pts)`);
                            } else if (action === 'coin_collected') {
                                this.addLog(`[Game Collect] ⭐ Moneda recolectada! (Score: ${payload.score})`);
                            } else if (action === 'stage_victory') {
                                this.updateMetric('Status', '🏆 VICTORY (Stage Cleared)');
                                this.addLog(`[Game Victory] 🏆 ¡Etapa 2D superada con éxito! Puntaje: ${payload.score}`);
                            } else if (action === 'game_over') {
                                this.updateMetric('Status', '💀 GAME OVER');
                                this.addLog(`[Game Over] 💀 Fin de la partida.`);
                            }

                            this.updateMetric('Events', this.metrics['Events']);
                            this.addLog(`[Action Received] ${action} -> ${JSON.stringify(payload)}`);
                            
                            this.emit('action', action, payload);

                            // Mirror game actions to stdout for parent Looping IPC
                            console.log(JSON.stringify({ event: 'action', action, payload }));

                            res.writeHead(200, { 'Content-Type': 'application/json' });
                            res.end(JSON.stringify({ success: true, action, events: this.metrics['Events'] }));
                        } catch (err) {
                            res.writeHead(400, { 'Content-Type': 'application/json' });
                            res.end(JSON.stringify({ error: err.message }));
                        }
                    });
                    return;
                }

                // API: Update State & Inject Commands (Looping / curl / Node)
                if (url.pathname === '/api/state' && req.method === 'POST') {
                    let body = '';
                    req.on('data', chunk => body += chunk);
                    req.on('end', () => {
                        try {
                            const data = JSON.parse(body || '{}');
                            if (data.metrics) {
                                for (const [k, v] of Object.entries(data.metrics)) {
                                    this.updateMetric(k, v);
                                }
                            }
                            if (data.log) this.addLog(data.log);
                            if (data.command) this.sendGameCommand(data.command, data.payload || {});
                            if (data.script) this.setGameScript(data.script);
                            if (data.title) {
                                this.title = data.title;
                                this.broadcast({ type: 'title', title: this.title });
                            }
                            res.writeHead(200, { 'Content-Type': 'application/json' });
                            res.end(JSON.stringify({ success: true }));
                        } catch (err) {
                            res.writeHead(400, { 'Content-Type': 'application/json' });
                            res.end(JSON.stringify({ error: err.message }));
                        }
                    });
                    return;
                }

                // Serve Main HTML5 UI
                if (url.pathname === '/' || url.pathname === '/index.html') {
                    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
                    res.end(this.renderHTML());
                    return;
                }

                // 404
                res.writeHead(404, { 'Content-Type': 'text/plain' });
                res.end('Not found');
            });

            this.server.on('error', (err) => {
                if (err.code === 'EADDRINUSE') {
                    this.server.listen(0);
                } else {
                    reject(err);
                }
            });

            this.server.listen(this.port, () => {
                this.actualPort = this.server.address().port;
                this.addLog(`[Server] Listening on http://localhost:${this.actualPort}`);
                if (this.autoOpen) {
                    this.openBrowser(`http://localhost:${this.actualPort}`);
                }
                resolve({ port: this.actualPort, url: `http://localhost:${this.actualPort}` });
            });
        });
    }

    openBrowser(url) {
        const platform = os.platform();
        let cmd = '';
        if (platform === 'darwin') {
            cmd = `open "${url}"`;
        } else if (platform === 'win32') {
            cmd = `start "" "${url}"`;
        } else {
            cmd = `xdg-open "${url}"`;
        }
        exec(cmd, (err) => {
            if (err) this.addLog(`[Browser] Note: open failed (${err.message}), URL is: ${url}`);
        });
    }

    stop() {
        if (this.server) {
            for (const client of this.clients) {
                try { client.end(); } catch (e) {}
            }
            this.clients.clear();
            this.server.close();
            this.server = null;
        }
    }

    renderHTML() {
        const escapedScript = JSON.stringify(this.gameScript);
        return `<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${this.title}</title>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-base: #060913;
            --bg-card: rgba(15, 23, 42, 0.78);
            --border: rgba(255, 255, 255, 0.09);
            --border-hover: rgba(56, 189, 248, 0.45);
            --text-main: #f8fafc;
            --text-sub: #94a3b8;
            --accent-cyan: #38bdf8;
            --accent-purple: #c084fc;
            --accent-green: #4ade80;
            --accent-yellow: #fbbf24;
            --accent-red: #ef4444;
            --font-sans: 'Plus Jakarta Sans', system-ui, sans-serif;
            --font-mono: 'JetBrains Mono', monospace;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background-color: var(--bg-base);
            color: var(--text-main);
            font-family: var(--font-sans);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            background-image: 
                radial-gradient(circle at 10% 20%, rgba(56, 189, 248, 0.12) 0%, transparent 40%),
                radial-gradient(circle at 90% 80%, rgba(192, 132, 252, 0.12) 0%, transparent 40%);
            overflow-x: hidden;
        }
        header {
            padding: 14px 24px;
            border-bottom: 1px solid var(--border);
            display: flex;
            align-items: center;
            justify-content: space-between;
            backdrop-filter: blur(16px);
            background: rgba(6, 9, 19, 0.88);
            position: sticky;
            top: 0;
            z-index: 20;
            flex-wrap: wrap;
            gap: 12px;
        }
        .brand-group {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .brand-icon {
            width: 36px;
            height: 36px;
            background: linear-gradient(135deg, var(--accent-cyan), var(--accent-purple));
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 800;
            font-size: 18px;
            color: #060913;
            box-shadow: 0 0 15px rgba(56, 189, 248, 0.35);
        }
        .header-title {
            font-size: 17px;
            font-weight: 700;
            letter-spacing: -0.02em;
        }
        .nav-tabs {
            display: flex;
            gap: 8px;
            align-items: center;
        }
        .nav-tab-btn {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid var(--border);
            color: var(--text-sub);
            padding: 6px 14px;
            border-radius: 8px;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            font-family: var(--font-sans);
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }
        .nav-tab-btn:hover {
            color: var(--text-main);
            border-color: var(--border-hover);
        }
        .nav-tab-btn.active {
            background: rgba(56, 189, 248, 0.16);
            border-color: var(--accent-cyan);
            color: var(--accent-cyan);
            font-weight: 700;
        }
        .status-pill {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: rgba(74, 222, 128, 0.15);
            border: 1px solid rgba(74, 222, 128, 0.3);
            color: var(--accent-green);
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 600;
            font-family: var(--font-mono);
        }
        .dot-live {
            width: 6px;
            height: 6px;
            border-radius: 50%;
            background: var(--accent-green);
            box-shadow: 0 0 8px var(--accent-green);
            animation: pulse 2s infinite;
        }
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.3; } }
        main {
            padding: 24px;
            max-width: 1160px;
            width: 100%;
            margin: 0 auto;
            flex: 1;
            display: flex;
            flex-direction: column;
            gap: 20px;
        }

        /* Game Stage Section */
        .game-section {
            background: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 20px;
            backdrop-filter: blur(14px);
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.45);
        }
        .game-header-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 14px;
            flex-wrap: wrap;
            gap: 12px;
        }
        .game-title-badge {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 14px;
            font-weight: 700;
            color: var(--accent-cyan);
            font-family: var(--font-mono);
        }
        .game-fps-badge {
            background: rgba(56, 189, 248, 0.14);
            border: 1px solid rgba(56, 189, 248, 0.3);
            color: var(--accent-cyan);
            padding: 2px 8px;
            border-radius: 6px;
            font-size: 11px;
            font-weight: 700;
        }
        .game-canvas-wrapper {
            position: relative;
            width: 100%;
            border-radius: 12px;
            overflow: hidden;
            border: 1px solid rgba(56, 189, 248, 0.35);
            background: #06090f;
            box-shadow: 0 8px 30px rgba(0, 0, 0, 0.6);
        }
        #game-stage-canvas {
            width: 100%;
            height: auto;
            max-height: 480px;
            display: block;
            object-fit: contain;
            touch-action: none;
        }
        .game-action-bar {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin-top: 16px;
            align-items: center;
            justify-content: space-between;
        }
        .ui-btn {
            background: rgba(56, 189, 248, 0.12);
            color: var(--accent-cyan);
            border: 1px solid rgba(56, 189, 248, 0.3);
            border-radius: 8px;
            padding: 8px 14px;
            font-size: 12.5px;
            font-weight: 600;
            font-family: var(--font-mono);
            cursor: pointer;
            transition: all 0.2s;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }
        .ui-btn:hover {
            background: var(--accent-cyan);
            color: #060913;
            transform: translateY(-2px);
            box-shadow: 0 4px 15px rgba(56, 189, 248, 0.35);
        }
        .ui-btn-purple {
            background: rgba(192, 132, 252, 0.12);
            color: var(--accent-purple);
            border: 1px solid rgba(192, 132, 252, 0.3);
        }
        .ui-btn-purple:hover {
            background: var(--accent-purple);
            color: #060913;
            box-shadow: 0 4px 15px rgba(192, 132, 252, 0.35);
        }
        .ui-btn-green {
            background: rgba(74, 222, 128, 0.12);
            color: var(--accent-green);
            border: 1px solid rgba(74, 222, 128, 0.3);
        }
        .ui-btn-green:hover {
            background: var(--accent-green);
            color: #060913;
            box-shadow: 0 4px 15px rgba(74, 222, 128, 0.35);
        }
        .ui-btn-yellow {
            background: rgba(251, 191, 36, 0.12);
            color: var(--accent-yellow);
            border: 1px solid rgba(251, 191, 36, 0.3);
        }
        .ui-btn-yellow:hover {
            background: var(--accent-yellow);
            color: #060913;
            box-shadow: 0 4px 15px rgba(251, 191, 36, 0.35);
        }
        .controls-hint {
            font-size: 11.5px;
            color: var(--text-sub);
            font-family: var(--font-mono);
            background: rgba(255, 255, 255, 0.04);
            padding: 8px 14px;
            border-radius: 8px;
            border: 1px solid var(--border);
            margin-top: 12px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 8px;
        }

        /* Metrics Tab */
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 16px;
        }
        .metric-card {
            background: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 16px 20px;
            backdrop-filter: blur(12px);
            transition: all 0.2s ease;
        }
        .metric-card:hover {
            border-color: var(--border-hover);
            transform: translateY(-2px);
        }
        .metric-label {
            font-size: 12px;
            color: var(--text-sub);
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            margin-bottom: 6px;
        }
        .metric-value {
            font-size: 26px;
            font-weight: 800;
            color: var(--text-main);
            font-family: var(--font-mono);
        }
        .log-terminal {
            background: #070b14;
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 16px;
            font-family: var(--font-mono);
            font-size: 12px;
            line-height: 1.6;
            color: #cbd5e1;
            height: 240px;
            overflow-y: auto;
        }
        .log-entry { margin-bottom: 4px; }
        .log-entry.new { animation: fadeIn 0.3s ease; }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(-4px); } to { opacity: 1; transform: translateY(0); } }
        footer {
            padding: 16px 24px;
            border-top: 1px solid var(--border);
            text-align: center;
            font-size: 12px;
            color: var(--text-sub);
        }
    </style>
</head>
<body>
    <header>
        <div class="brand-group">
            <div class="brand-icon">🎮</div>
            <h1 class="header-title" id="win-title">${this.title}</h1>
        </div>

        <div class="nav-tabs">
            <button class="nav-tab-btn active" id="tab-btn-game" onclick="switchTab('game')">🎮 2D Stage</button>
            <button class="nav-tab-btn" id="tab-btn-metrics" onclick="switchTab('metrics')">📊 Telemetría</button>
            <button class="nav-tab-btn" id="tab-btn-logs" onclick="switchTab('logs')">📜 Consola IPC</button>
        </div>

        <div style="display: flex; gap: 12px; align-items: center;">
            <button id="sound-btn" class="ui-btn" style="padding: 4px 12px; font-size: 11px;" onclick="toggleSound()">🔊 Sonido ON</button>
            <div class="status-pill">
                <div class="dot-live"></div>
                <span id="conn-status">CONECTADO :${this.actualPort}</span>
            </div>
        </div>
    </header>

    <main>
        <!-- Tab 1: 2D Arcade Stage -->
        <div id="tab-content-game">
            <div class="game-section">
                <div class="game-header-bar">
                    <div class="game-title-badge">
                        <span>STAGE RUNTIME</span>
                        <span class="game-fps-badge">60 FPS V-SYNC</span>
                    </div>
                    <div style="display: flex; gap: 16px; align-items: center; font-family: var(--font-mono); font-size: 13px;">
                        <span style="color: #38bdf8;">HÉROE: <strong id="hud-hp">100 HP</strong></span>
                        <span style="color: #fbbf24;">PUNTAJE: <strong id="hud-score">0</strong></span>
                    </div>
                </div>

                <div class="game-canvas-wrapper">
                    <canvas id="game-stage-canvas" width="760" height="440"></canvas>
                </div>

                <div class="game-action-bar">
                    <div style="display: flex; gap: 8px; flex-wrap: wrap;">
                        <button class="ui-btn ui-btn-yellow" onclick="injectGameCommand('spawn_coin')">
                            <span>★</span> Moneda (+150 Pts)
                        </button>
                        <button class="ui-btn ui-btn-green" onclick="injectGameCommand('heal')">
                            <span>💚</span> Curar (+35 HP)
                        </button>
                        <button class="ui-btn" onclick="injectGameCommand('boost')">
                            <span>🚀</span> Impulso Cuántico
                        </button>
                        <button class="ui-btn ui-btn-purple" onclick="injectGameCommand('spawn_enemy')">
                            <span>👾</span> Dron Enemigo
                        </button>
                    </div>

                    <button class="ui-btn" style="border-color: rgba(239, 68, 68, 0.4); color: #f87171;" onclick="restartGame()">
                        <span>🔄</span> Reiniciar Nivel
                    </button>
                </div>

                <div class="controls-hint">
                    <div>
                        <strong>Controles:</strong> [A / D / ◀ ▶] Mover • [W / Espacio / ▲] Salto / Doble Salto • [Z / J] Disparo Láser • [X / K] Dash
                    </div>
                    <div style="color: var(--accent-cyan);">
                        Gamepad &amp; Pantalla Táctil Activos
                    </div>
                </div>
            </div>
        </div>

        <!-- Tab 2: Telemetry & Metrics -->
        <div id="tab-content-metrics" style="display: none;">
            <div class="metrics-grid" id="metrics-grid">
                ${Object.entries(this.metrics).map(([k, v]) => `
                    <div class="metric-card" id="metric-card-${k}">
                        <div class="metric-label">${k}</div>
                        <div class="metric-value" id="val-${k}">${v}</div>
                    </div>
                `).join('')}
            </div>

            <div style="margin-top: 20px; display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px;">
                ${this.cards.map(c => `
                    <div class="metric-card">
                        <div class="section-title" style="font-size: 14px; margin-bottom: 8px;">${c.title}</div>
                        <p style="font-size: 13px; color: var(--text-sub); line-height: 1.5;">${c.content}</p>
                    </div>
                `).join('')}
            </div>
        </div>

        <!-- Tab 3: IPC Console & Logs -->
        <div id="tab-content-logs" style="display: none;">
            <div class="game-section">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
                    <div class="section-title" style="margin-bottom: 0;">📜 Registro de Eventos e IPC Bidireccional</div>
                    <button class="ui-btn" onclick="clearLogs()" style="padding: 4px 10px; font-size: 11px;">Limpiar</button>
                </div>
                <div class="log-terminal" id="terminal">
                    ${this.logs.map(l => `<div class="log-entry">${l}</div>`).join('')}
                </div>
            </div>
        </div>
    </main>

    <footer>
        Looping Engine • loop-node-window v2.0.0 Quantum • Coki Studios Web &amp; Loop Lab
    </footer>

    <script type="module">
        import { LoopingInterpreter } from '/looping_core.js';

        let soundEnabled = true;
        let activeTab = 'game';
        const canvas = document.getElementById('game-stage-canvas');

        // Initialize Looping 2D Interpreter
        const runtime = new LoopingInterpreter(canvas, (msg, type) => {
            addLocalLog(msg);
        });
        window.gameRuntime = runtime;

        // Load initial game script from Looping
        const initialScript = ${escapedScript};
        if (initialScript) {
            runtime.execute(initialScript);
        }

        function addLocalLog(msg) {
            const term = document.getElementById('terminal');
            if (term) {
                const div = document.createElement('div');
                div.className = 'log-entry new';
                div.textContent = '> ' + msg;
                term.insertBefore(div, term.firstChild);
            }
        }

        // Live HUD & Game State Sync loop
        let lastScore = -1;
        let lastHp = -1;
        let lastLives = -1;

        setInterval(() => {
            if (!runtime) return;

            const score = runtime.score || 0;
            const player = runtime.getPlayer ? runtime.getPlayer() : null;
            const hp = player ? Math.round(player.health) : 100;
            const lives = runtime.lives !== undefined ? runtime.lives : 3;

            const hudScore = document.getElementById('hud-score');
            const hudHp = document.getElementById('hud-hp');
            if (hudScore) hudScore.textContent = score;
            if (hudHp) hudHp.textContent = hp + ' HP';

            // Sync with Server if changed
            if (score !== lastScore) {
                lastScore = score;
                sendAction('game_score', { score });
            }
            if (hp !== lastHp) {
                lastHp = hp;
                sendAction('game_hp', { hp, maxHp: player ? player.maxHealth : 100 });
            }
            if (lives !== lastLives) {
                lastLives = lives;
                sendAction('game_lives', { lives });
            }

            if (runtime.gameWon && !window.__victorySent) {
                window.__victorySent = true;
                sendAction('stage_victory', { score });
            }
            if (runtime.gameOver && !window.__gameOverSent) {
                window.__gameOverSent = true;
                sendAction('game_over', { score });
            }
        }, 120);

        // Tab Switching
        window.switchTab = function(tab) {
            activeTab = tab;
            ['game', 'metrics', 'logs'].forEach(t => {
                const btn = document.getElementById('tab-btn-' + t);
                const pane = document.getElementById('tab-content-' + t);
                if (btn) btn.classList.toggle('active', t === tab);
                if (pane) pane.style.display = (t === tab ? 'block' : 'none');
            });
        };

        window.toggleSound = function() {
            soundEnabled = !soundEnabled;
            const btn = document.getElementById('sound-btn');
            btn.textContent = soundEnabled ? '🔊 Sonido ON' : '🔇 Sonido OFF';
        };

        window.sendAction = function(action, payload = {}) {
            fetch('/api/action', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ action, payload })
            }).then(r => r.json()).catch(err => {
                console.error('Action error:', err);
            });
        };

        window.injectGameCommand = function(cmd) {
            if (!runtime) return;
            const player = runtime.getPlayer ? runtime.getPlayer() : null;

            if (cmd === 'spawn_coin') {
                const rx = player ? player.x + 80 + Math.random() * 120 : 350;
                const ry = player ? player.y - 40 : 220;
                runtime.parseLine(\`spawn coin at (\${Math.round(rx)}, \${Math.round(ry)}) points 150\`);
                runtime.playSfx('coin');
                runtime.addPopup(rx, ry - 10, '+150 BONUS!', '#fbbf24');
                window.sendAction('spawn_bonus_coin', { x: rx, y: ry });
            } else if (cmd === 'heal') {
                if (player) {
                    player.health = Math.min(player.maxHealth, player.health + 35);
                    runtime.playSfx('heal');
                    runtime.addPopup(player.x, player.y - 12, '+35 HP', '#10b981');
                    window.sendAction('heal_player', { hp: player.health });
                }
            } else if (cmd === 'boost') {
                if (player) {
                    player.vy = -680;
                    runtime.playSfx('pad');
                    runtime.addPopup(player.x, player.y - 14, 'LIVE BOOST!', '#fbbf24');
                    window.sendAction('boost_player', { power: 680 });
                }
            } else if (cmd === 'spawn_enemy') {
                const ex = player ? player.x + 220 : 500;
                runtime.parseLine(\`spawn enemy "CyberDrone" at (\${Math.round(ex)}, 320) range (\${Math.round(ex - 120)}, \${Math.round(ex + 120)}) speed 80 health 35\`);
                runtime.addPopup(ex, 300, 'NUEVO DRON!', '#ef4444');
                window.sendAction('spawn_enemy', { x: ex });
            }
        };

        window.restartGame = function() {
            if (runtime) {
                window.__victorySent = false;
                window.__gameOverSent = false;
                runtime.restartGame();
                window.sendAction('game_restart', {});
            }
        };

        window.clearLogs = function() {
            document.getElementById('terminal').innerHTML = '<div class="log-entry">[Limpiado] Terminal restablecido.</div>';
        };

        // Real-time SSE Connection
        const evtSource = new EventSource('/api/events');
        evtSource.onmessage = (e) => {
            try {
                const msg = JSON.parse(e.data);
                if (msg.type === 'metric') {
                    let el = document.getElementById('val-' + msg.key);
                    if (!el) {
                        const grid = document.getElementById('metrics-grid');
                        if (grid) {
                            const card = document.createElement('div');
                            card.className = 'metric-card';
                            card.id = 'metric-card-' + msg.key;
                            card.innerHTML = '<div class="metric-label">' + msg.key + '</div><div class="metric-value" id="val-' + msg.key + '">' + msg.value + '</div>';
                            grid.appendChild(card);
                        }
                    } else {
                        el.textContent = msg.value;
                    }
                } else if (msg.type === 'log') {
                    const term = document.getElementById('terminal');
                    if (term) {
                        const div = document.createElement('div');
                        div.className = 'log-entry new';
                        div.textContent = msg.data;
                        term.insertBefore(div, term.firstChild);
                    }
                } else if (msg.type === 'title') {
                    document.getElementById('win-title').textContent = msg.title;
                    document.title = msg.title;
                } else if (msg.type === 'game_command') {
                    handleRemoteGameCommand(msg.command, msg.payload);
                } else if (msg.type === 'game_script') {
                    if (runtime && msg.script) {
                        runtime.execute(msg.script);
                    }
                }
            } catch (err) {}
        };

        function handleRemoteGameCommand(cmd, payload) {
            if (!runtime) return;
            const player = runtime.getPlayer ? runtime.getPlayer() : null;

            if (cmd === 'heal') {
                if (player) {
                    const amt = payload.amount || 30;
                    player.health = Math.min(player.maxHealth, player.health + amt);
                    runtime.playSfx('heal');
                    runtime.addPopup(player.x, player.y - 12, '+' + amt + ' HP', '#10b981');
                }
            } else if (cmd === 'boost') {
                if (player) {
                    player.vy = -(payload.power || 670);
                    runtime.playSfx('pad');
                    runtime.addPopup(player.x, player.y - 14, 'REMOTE BOOST!', '#fbbf24');
                }
            } else if (cmd === 'spawn') {
                if (payload.line) {
                    runtime.parseLine(payload.line);
                } else if (payload.entity === 'coin') {
                    const x = payload.x || 300;
                    const y = payload.y || 200;
                    runtime.parseLine(\`spawn coin at (\${x}, \${y}) points \${payload.points || 100}\`);
                }
            } else if (cmd === 'reload' || cmd === 'restart') {
                runtime.restartGame();
            }
        }

        evtSource.onerror = () => {
            document.getElementById('conn-status').textContent = 'RECONECTANDO...';
        };

        evtSource.onopen = () => {
            document.getElementById('conn-status').textContent = 'CONECTADO :' + location.port;
        };
    </script>
</body>
</html>`;
    }
}

// Helper factory function
function createWindow(options = {}) {
    const win = new DynamicHTMLWindow(options);
    win.start();
    return win;
}

// CLI / Stdin execution
const isMain = process.argv[1] && (
    process.argv[1].endsWith('loop-node-window/index.js') || 
    process.argv[1].endsWith('loop-node-window') ||
    (typeof import.meta !== 'undefined' && import.meta.url && fileURLToPath(import.meta.url) === process.argv[1])
);

if (isMain) {
    const args = process.argv.slice(2);
    let title = 'Holo Quantum Arcade 2D';
    let port = 7890;
    let autoOpen = true;
    let gameMode = true;
    let scriptPath = null;

    for (let i = 0; i < args.length; ++i) {
        if (args[i] === '--title' && args[i + 1]) title = args[++i];
        if (args[i] === '--port' && args[i + 1]) port = parseInt(args[++i], 10);
        if (args[i] === '--no-open') autoOpen = false;
        if (args[i] === '--game' || args[i] === '-g') gameMode = true;
        if (args[i] === '--script' && args[i + 1]) {
            scriptPath = args[++i];
            gameMode = true;
        }
    }

    const win = new DynamicHTMLWindow({ title, port, autoOpen, gameMode, scriptPath });
    win.start().then(({ port, url }) => {
        console.log(`[loop-node-window] 🎮 2D Arcade Window active on ${url}`);
        console.log(`[loop-node-window] Awaiting commands from stdin (format: JSON or "METRIC <k> <v>" or "LOG <text>" or "GAME_CMD <cmd> <json>")...`);

        const rl = readline.createInterface({ input: process.stdin, output: process.stdout, terminal: false });
        rl.on('line', (line) => {
            line = line.trim();
            if (!line) return;
            if (line.startsWith('{') && line.endsWith('}')) {
                try {
                    const data = JSON.parse(line);
                    if (data.metric && data.value !== undefined) win.updateMetric(data.metric, data.value);
                    if (data.log) win.addLog(data.log);
                    if (data.title) win.title = data.title;
                    if (data.game_cmd) win.sendGameCommand(data.game_cmd, data.payload || data);
                    if (data.script) win.setGameScript(data.script);
                } catch(e) {}
            } else if (line.startsWith('METRIC ')) {
                const parts = line.slice(7).split(' ');
                if (parts.length >= 2) win.updateMetric(parts[0], parts.slice(1).join(' '));
            } else if (line.startsWith('LOG ')) {
                win.addLog(line.slice(4));
            } else if (line.startsWith('GAME_CMD ')) {
                const space = line.indexOf(' ', 9);
                if (space !== -1) {
                    const cmd = line.slice(9, space).trim();
                    try {
                        const payload = JSON.parse(line.slice(space + 1));
                        win.sendGameCommand(cmd, payload);
                    } catch(e) {
                        win.sendGameCommand(cmd, {});
                    }
                } else {
                    win.sendGameCommand(line.slice(9).trim(), {});
                }
            } else if (line.startsWith('HEAL ')) {
                const amt = parseInt(line.slice(5), 10) || 35;
                win.sendGameCommand('heal', { amount: amt });
            } else if (line.startsWith('BOOST')) {
                win.sendGameCommand('boost', { power: 680 });
            }
        });
    });

    win.on('action', (action, payload) => {
        // Output clean JSON event to stdout for Looping / Python / CLI
        console.log(JSON.stringify({ event: 'action', action, payload }));
    });
}

export { DynamicHTMLWindow, createWindow };
export default DynamicHTMLWindow;
