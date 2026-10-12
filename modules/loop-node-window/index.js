/**
 * loop-node-window: Dynamic HTML5 Window Creator for Node.js & Looping Engine
 * Author: Coki Studios Web & Loop Lab
 * Version: 1.0.0
 * 
 * Zero external dependencies. Uses standard Node.js libraries (http, child_process, os, events, readline).
 * Provides an interactive glassmorphic HTML5 window with Web Audio synthesis, real-time SSE metrics,
 * action callbacks, and bidirectional communication for Looping (.loop) and Node.js.
 */

import http from 'http';
import { exec } from 'child_process';
import os from 'os';
import { EventEmitter } from 'events';
import readline from 'readline';
import { fileURLToPath } from 'url';

class DynamicHTMLWindow extends EventEmitter {
    constructor(options = {}) {
        super();
        this.title = options.title || 'Loop Dynamic HTML5 Window';
        this.port = options.port || 7890;
        this.width = options.width || 860;
        this.height = options.height || 580;
        this.autoOpen = options.autoOpen !== undefined ? options.autoOpen : true;
        this.soundEnabled = options.soundEnabled !== undefined ? options.soundEnabled : true;
        
        this.metrics = Object.assign({
            'Status': 'Running',
            'Engine': 'Loop + Node.js',
            'FPS': 60,
            'Events': 0
        }, options.metrics || {});

        this.cards = options.cards || [
            { id: 'c1', title: 'Looping Runtime Bridge', content: 'Connected bi-directionally via Node.js HTTP/SSE micro-engine.' },
            { id: 'c2', title: 'Audio & Telemetry', content: 'Web Audio API synthesizer active with real-time UI sonic feedback.' }
        ];

        this.logs = [];
        this.clients = new Set();
        this.server = null;
        this.actualPort = this.port;

        this.addLog(`[System] DynamicHTMLWindow initialized for "${this.title}"`);
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
                    const iconSvg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect width="32" height="32" rx="8" fill="#060913"/><text x="16" y="22" font-size="18" font-family="system-ui" font-weight="bold" fill="#38bdf8" text-anchor="middle">⟳</text></svg>`;
                    res.writeHead(200, { 'Content-Type': 'image/svg+xml', 'Cache-Control': 'public, max-age=86400' });
                    res.end(iconSvg);
                    return;
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
                        soundEnabled: this.soundEnabled
                    }));
                    return;
                }

                // API: Post Action from client UI
                if (url.pathname === '/api/action' && req.method === 'POST') {
                    let body = '';
                    req.on('data', chunk => body += chunk);
                    req.on('end', () => {
                        try {
                            const data = JSON.parse(body || '{}');
                            const action = data.action || 'unknown';
                            this.metrics['Events'] = (this.metrics['Events'] || 0) + 1;
                            this.updateMetric('Events', this.metrics['Events']);
                            this.addLog(`[Action Received] ${action} -> ${JSON.stringify(data.payload || {})}`);
                            this.emit('action', action, data.payload);
                            res.writeHead(200, { 'Content-Type': 'application/json' });
                            res.end(JSON.stringify({ success: true, action, events: this.metrics['Events'] }));
                        } catch (err) {
                            res.writeHead(400, { 'Content-Type': 'application/json' });
                            res.end(JSON.stringify({ error: err.message }));
                        }
                    });
                    return;
                }

                // API: Update State from external callers (Looping / curl / Node)
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
                    // Try random port
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
        return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${this.title}</title>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-base: #060913;
            --bg-card: rgba(15, 23, 42, 0.75);
            --border: rgba(255, 255, 255, 0.09);
            --border-hover: rgba(56, 189, 248, 0.4);
            --text-main: #f8fafc;
            --text-sub: #94a3b8;
            --accent-cyan: #38bdf8;
            --accent-purple: #c084fc;
            --accent-green: #4ade80;
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
            padding: 18px 28px;
            border-bottom: 1px solid var(--border);
            display: flex;
            align-items: center;
            justify-content: space-between;
            backdrop-filter: blur(16px);
            background: rgba(6, 9, 19, 0.85);
            position: sticky;
            top: 0;
            z-index: 10;
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
            box-shadow: 0 0 15px rgba(56, 189, 248, 0.3);
        }
        .header-title {
            font-size: 18px;
            font-weight: 700;
            letter-spacing: -0.02em;
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
            padding: 28px;
            max-width: 1100px;
            width: 100%;
            margin: 0 auto;
            flex: 1;
            display: flex;
            flex-direction: column;
            gap: 24px;
        }
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
        .interactive-section {
            background: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: 14px;
            padding: 24px;
            backdrop-filter: blur(12px);
        }
        .section-title {
            font-size: 16px;
            font-weight: 700;
            margin-bottom: 16px;
            display: flex;
            align-items: center;
            gap: 8px;
            color: var(--accent-cyan);
        }
        .btn-row {
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            margin-bottom: 20px;
        }
        .ui-btn {
            background: rgba(56, 189, 248, 0.12);
            color: var(--accent-cyan);
            border: 1px solid rgba(56, 189, 248, 0.3);
            border-radius: 8px;
            padding: 10px 18px;
            font-size: 13px;
            font-weight: 600;
            font-family: var(--font-mono);
            cursor: pointer;
            transition: all 0.2s;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        .ui-btn:hover {
            background: var(--accent-cyan);
            color: #060913;
            transform: translateY(-2px);
            box-shadow: 0 4px 15px rgba(56, 189, 248, 0.3);
        }
        .ui-btn-purple {
            background: rgba(192, 132, 252, 0.12);
            color: var(--accent-purple);
            border: 1px solid rgba(192, 132, 252, 0.3);
        }
        .ui-btn-purple:hover {
            background: var(--accent-purple);
            color: #060913;
            box-shadow: 0 4px 15px rgba(192, 132, 252, 0.3);
        }
        .canvas-container {
            width: 100%;
            height: 120px;
            background: rgba(6, 9, 19, 0.8);
            border: 1px solid var(--border);
            border-radius: 10px;
            overflow: hidden;
            position: relative;
        }
        canvas {
            width: 100%;
            height: 100%;
            display: block;
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
            height: 180px;
            overflow-y: auto;
        }
        .log-entry { margin-bottom: 4px; }
        .log-entry.new { animation: fadeIn 0.3s ease; }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(-4px); } to { opacity: 1; transform: translateY(0); } }
        footer {
            padding: 16px 28px;
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
            <div class="brand-icon">⟳</div>
            <h1 class="header-title" id="win-title">${this.title}</h1>
        </div>
        <div style="display: flex; gap: 12px; align-items: center;">
            <button id="sound-btn" class="ui-btn" style="padding: 4px 12px; font-size: 11px;" onclick="toggleSound()">🔊 Sound ON</button>
            <div class="status-pill">
                <div class="dot-live"></div>
                <span id="conn-status">CONNECTED :${this.actualPort}</span>
            </div>
        </div>
    </header>

    <main>
        <div class="metrics-grid" id="metrics-grid">
            ${Object.entries(this.metrics).map(([k, v]) => `
                <div class="metric-card" id="metric-card-${k}">
                    <div class="metric-label">${k}</div>
                    <div class="metric-value" id="val-${k}">${v}</div>
                </div>
            `).join('')}
        </div>

        <div class="interactive-section">
            <div class="section-title">⚡ Interactive Controls & Sound Synthesis</div>
            <div class="btn-row">
                <button class="ui-btn" onclick="sendAction('ping', { msg: 'Looping pulse' })">
                    <span>📡</span> Ping Engine
                </button>
                <button class="ui-btn ui-btn-purple" onclick="sendAction('spawn_object', { entity: 'ParticleEmitter' })">
                    <span>✨</span> Spawn Entity
                </button>
                <button class="ui-btn" onclick="sendAction('bench_test', { iterations: 1000 })">
                    <span>⏱️</span> Run Micro-Benchmark
                </button>
                <button class="ui-btn ui-btn-purple" onclick="clearLogs()">
                    <span>🧹</span> Clear Logs
                </button>
            </div>
            <div class="canvas-container">
                <canvas id="viz-canvas"></canvas>
            </div>
        </div>

        <div class="interactive-section">
            <div class="section-title">📜 Real-Time Event Log & Loop IPC</div>
            <div class="log-terminal" id="terminal">
                ${this.logs.map(l => `<div class="log-entry">${l}</div>`).join('')}
            </div>
        </div>
    </main>

    <footer>
        Looping Engine • loop-node-window v1.0.0 • Coki Studios Web & Loop Lab
    </footer>

    <script>
        let soundEnabled = true;
        let audioCtx = null;

        function getAudioContext() {
            if (!audioCtx) {
                audioCtx = new (window.AudioContext || window.webkitAudioContext)();
            }
            if (audioCtx.state === 'suspended') {
                audioCtx.resume();
            }
            return audioCtx;
        }

        function playTone(freq, type = 'sine', duration = 0.1) {
            if (!soundEnabled) return;
            try {
                const ctx = getAudioContext();
                const osc = ctx.createOscillator();
                const gain = ctx.createGain();
                osc.type = type;
                osc.frequency.setValueAtTime(freq, ctx.currentTime);
                gain.gain.setValueAtTime(0.12, ctx.currentTime);
                gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + duration);
                osc.connect(gain);
                gain.connect(ctx.destination);
                osc.start();
                osc.stop(ctx.currentTime + duration);
            } catch(e) {}
        }

        function toggleSound() {
            soundEnabled = !soundEnabled;
            const btn = document.getElementById('sound-btn');
            btn.textContent = soundEnabled ? '🔊 Sound ON' : '🔇 Sound OFF';
            if (soundEnabled) playTone(440, 'sine', 0.15);
        }

        function sendAction(action, payload = {}) {
            playTone(587.33, 'triangle', 0.12);
            fetch('/api/action', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ action, payload })
            }).then(r => r.json()).catch(err => {
                console.error('Action error:', err);
            });
        }

        function clearLogs() {
            document.getElementById('terminal').innerHTML = '<div class="log-entry">[Cleared] Terminal reset.</div>';
            playTone(330, 'sine', 0.08);
        }

        // Real-time SSE Connection
        const evtSource = new EventSource('/api/events');
        evtSource.onmessage = (e) => {
            try {
                const msg = JSON.parse(e.data);
                if (msg.type === 'metric') {
                    let el = document.getElementById('val-' + msg.key);
                    if (!el) {
                        const grid = document.getElementById('metrics-grid');
                        const card = document.createElement('div');
                        card.className = 'metric-card';
                        card.id = 'metric-card-' + msg.key;
                        card.innerHTML = '<div class="metric-label">' + msg.key + '</div><div class="metric-value" id="val-' + msg.key + '">' + msg.value + '</div>';
                        grid.appendChild(card);
                    } else {
                        el.textContent = msg.value;
                    }
                } else if (msg.type === 'log') {
                    const term = document.getElementById('terminal');
                    const div = document.createElement('div');
                    div.className = 'log-entry new';
                    div.textContent = msg.data;
                    term.insertBefore(div, term.firstChild);
                } else if (msg.type === 'title') {
                    document.getElementById('win-title').textContent = msg.title;
                    document.title = msg.title;
                }
            } catch (err) {}
        };

        evtSource.onerror = () => {
            document.getElementById('conn-status').textContent = 'RECONNECTING...';
        };

        evtSource.onopen = () => {
            document.getElementById('conn-status').textContent = 'CONNECTED :' + location.port;
        };

        // Canvas Visualizer
        const canvas = document.getElementById('viz-canvas');
        const ctx = canvas.getContext('2d');
        function resizeCanvas() {
            canvas.width = canvas.parentElement.clientWidth;
            canvas.height = canvas.parentElement.clientHeight;
        }
        window.addEventListener('resize', resizeCanvas);
        resizeCanvas();

        let phase = 0;
        function renderLoop() {
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            phase += 0.03;
            
            // Draw background glow wave
            ctx.beginPath();
            ctx.moveTo(0, canvas.height / 2);
            for (let x = 0; x < canvas.width; x += 5) {
                const y = canvas.height / 2 + Math.sin(x * 0.015 + phase) * 20 + Math.cos(x * 0.03 - phase) * 10;
                ctx.lineTo(x, y);
            }
            ctx.strokeStyle = 'rgba(56, 189, 248, 0.4)';
            ctx.lineWidth = 2;
            ctx.stroke();

            // Draw purple harmonic wave
            ctx.beginPath();
            ctx.moveTo(0, canvas.height / 2);
            for (let x = 0; x < canvas.width; x += 5) {
                const y = canvas.height / 2 + Math.cos(x * 0.02 + phase * 1.5) * 15;
                ctx.lineTo(x, y);
            }
            ctx.strokeStyle = 'rgba(192, 132, 252, 0.35)';
            ctx.lineWidth = 1.5;
            ctx.stroke();

            requestAnimationFrame(renderLoop);
        }
        requestAnimationFrame(renderLoop);
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
    let title = 'Looping HTML5 Window';
    let port = 7890;
    let autoOpen = true;

    for (let i = 0; i < args.length; ++i) {
        if (args[i] === '--title' && args[i + 1]) title = args[++i];
        if (args[i] === '--port' && args[i + 1]) port = parseInt(args[++i], 10);
        if (args[i] === '--no-open') autoOpen = false;
    }

    const win = new DynamicHTMLWindow({ title, port, autoOpen });
    win.start().then(({ port, url }) => {
        console.log(`[loop-node-window] Window active on ${url}`);
        console.log(`[loop-node-window] Awaiting commands from stdin (format: JSON or "METRIC <key> <val>" or "LOG <text>")...`);

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
                } catch(e) {}
            } else if (line.startsWith('METRIC ')) {
                const parts = line.slice(7).split(' ');
                if (parts.length >= 2) win.updateMetric(parts[0], parts.slice(1).join(' '));
            } else if (line.startsWith('LOG ')) {
                win.addLog(line.slice(4));
            }
        });
    });

    win.on('action', (action, payload) => {
        console.log(JSON.stringify({ event: 'action', action, payload }));
    });
}

export { DynamicHTMLWindow, createWindow };
export default DynamicHTMLWindow;
