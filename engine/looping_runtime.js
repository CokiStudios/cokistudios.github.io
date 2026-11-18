/**
 * Looping C++17 WebAssembly Thin Host Runtime (`web/looping_runtime.js`)
 * ---------------------------------------------------------------------
 * Replaces the legacy `looping_core.js` JS re-implementation completely.
 * All parsing, AST, interpreter execution, C# interop, CSID/CSMS crypto,
 * loopize++ ECS, 2D physics/AI, and 3D software Z-buffer rendering execute
 * inside the real compiled C++17 engine (`looping_wasm.wasm`).
 */

let wasmModulePromise = null;

async function loadWasmFactory(wasmJsUrl) {
    const resolvedJs = wasmJsUrl || new URL('./looping_wasm.js', import.meta.url).href;
    const mod = await import(resolvedJs);
    return mod.default || mod.createLoopingWasm || mod;
}

export class LoopingWasmRuntime {
    constructor(canvas = null, onLogOrOptions = null) {
        const opts = (typeof onLogOrOptions === 'function')
            ? { onLog: onLogOrOptions }
            : (onLogOrOptions || {});

        this.canvas = canvas || null;
        this.ctx = (this.canvas && typeof this.canvas.getContext === 'function')
            ? this.canvas.getContext('2d')
            : null;
        this.onLog = typeof opts.onLog === 'function' ? opts.onLog : () => {};
        this.wasmJsUrl = opts.wasmJsUrl || null;
        this.wasmUrl = opts.wasmUrl || null;
        this.autoStart = opts.autoStart !== false;

        this.mod = null;
        this.api = null;
        this.handle = 0;
        this.snapshot = {
            is3DMode: false,
            score: 0,
            lives: 3,
            maxLives: 3,
            combo: 0,
            fps: 60,
            gravity: 1180,
            timeScale: 1.0,
            gameOver: false,
            gameWon: false,
            scenario: { name: 'Quantum Stage', weather: 'clear', bg: '#050816', accent: '#38bdf8' },
            world: { width: 1200, height: 420 },
            camera: { x: 0, y: 0, shake: 0 },
            camera3D: { enabled: false, mode: 'chase', fov: 65 },
            player: null,
            entities: [],
            particles: [],
            projectiles: [],
            popups: [],
            stagePresets: [],
            algebraTable: null,
            sfx: [],
            logs: []
        };

        this.soundEnabled = true;
        this.audioCtx = null;
        this._rafId = null;
        this._lastTime = 0;
        this._keysDown = new Set();
        this._yawDelta = 0;
        this._pitchDelta = 0;
        this._pendingCalls = [];
        this._localPopups = [];
        this._stars = Array.from({ length: 70 }, (_, i) => ({
            x: (i * 197.3) % 1600,
            y: (i * 89.7) % 420,
            s: (i % 3) + 1,
            sp: 0.25 + (i % 4) * 0.2
        }));
        this._offscreen = null;
        this._offCtx = null;
        this._imgData = null;

        this.camera3D = new Proxy({}, {
            get: (_, prop) => {
                if (prop === 'enabled') return Boolean(this.snapshot.is3DMode || (this.snapshot.camera3D && this.snapshot.camera3D.enabled));
                if (prop === 'mode') return (this.snapshot.camera3D && this.snapshot.camera3D.mode) || 'chase';
                if (prop === 'fov') return (this.snapshot.camera3D && this.snapshot.camera3D.fov) || 65;
                return undefined;
            },
            set: (_, prop, val) => {
                if (prop === 'enabled') {
                    const cur = this.camera3D.enabled;
                    if (Boolean(val) !== cur) this.toggle3DLayer();
                    return true;
                }
                return true;
            }
        });

        this._bindInputs();
        this.ready = this._init();
    }

    async _init() {
        const factory = await loadWasmFactory(this.wasmJsUrl);
        if (!wasmModulePromise || this.wasmUrl) {
            const moduleOpts = {};
            if (this.wasmUrl) {
                moduleOpts.locateFile = (p) => (p.endsWith('.wasm') ? this.wasmUrl : p);
            }
            wasmModulePromise = factory(moduleOpts);
        }
        this.mod = await wasmModulePromise;
        this.api = {
            lp_create: this.mod.cwrap('lp_create', 'number', []),
            lp_destroy: this.mod.cwrap('lp_destroy', null, ['number']),
            lp_execute: this.mod.cwrap('lp_execute', 'string', ['number', 'string']),
            lp_parse_line: this.mod.cwrap('lp_parse_line', 'string', ['number', 'string']),
            lp_eval_expr: this.mod.cwrap('lp_eval_expr', 'string', ['number', 'string']),
            lp_set_input: this.mod.cwrap('lp_set_input', null, ['number', 'number', 'number', 'number']),
            lp_step: this.mod.cwrap('lp_step', 'string', ['number', 'number', 'number', 'number']),
            lp_get_snapshot_json: this.mod.cwrap('lp_get_snapshot_json', 'string', ['number', 'number', 'number']),
            lp_render_3d_rgba: this.mod.cwrap('lp_render_3d_rgba', 'number', ['number', 'number', 'number']),
            lp_get_vars_json: this.mod.cwrap('lp_get_vars_json', 'string', ['number']),
            lp_get_ui_json: this.mod.cwrap('lp_get_ui_json', 'string', ['number']),
            lp_click_button: this.mod.cwrap('lp_click_button', 'string', ['number', 'string']),
            lp_heal_player: this.mod.cwrap('lp_heal_player', null, ['number', 'number']),
            lp_boost_player: this.mod.cwrap('lp_boost_player', null, ['number', 'number']),
            lp_activate_preset: this.mod.cwrap('lp_activate_preset', null, ['number', 'number']),
            lp_set_time_scale: this.mod.cwrap('lp_set_time_scale', null, ['number', 'number']),
            lp_toggle_3d: this.mod.cwrap('lp_toggle_3d', null, ['number']),
            lp_cycle_camera3d: this.mod.cwrap('lp_cycle_camera3d', null, ['number']),
            lp_restart: this.mod.cwrap('lp_restart', 'string', ['number']),
            lp_check_ast: this.mod.cwrap('lp_check_ast', 'string', ['string']),
            lp_format_code: this.mod.cwrap('lp_format_code', 'string', ['string']),
            lp_invis_encode_hex: this.mod.cwrap('lp_invis_encode_hex', 'string', ['string', 'string']),
            lp_bench: this.mod.cwrap('lp_bench', 'string', []),
            lp_run_selftest: this.mod.cwrap('lp_run_selftest', 'string', []),
            lp_version_json: this.mod.cwrap('lp_version_json', 'string', [])
        };

        this.handle = this.api.lp_create();

        // Drain queued calls triggered before ready resolved
        const queued = this._pendingCalls.splice(0, this._pendingCalls.length);
        for (const fn of queued) fn();

        this._refreshSnapshot();
        if (this.autoStart && this.canvas && typeof requestAnimationFrame === 'function') {
            this.startLoop();
        }
        return this;
    }

    // Reactive getters for drop-in compatibility with loop-node-window
    get score() { return this.snapshot.score || 0; }
    get lives() { return this.snapshot.lives !== undefined ? this.snapshot.lives : 3; }
    get maxLives() { return this.snapshot.maxLives || 3; }
    get combo() { return this.snapshot.combo || 0; }
    get gravity() { return this.snapshot.gravity || 1180; }
    set gravity(v) {
        if (this.api && this.handle) {
            this.parseLine(`game.gravity(${Number(v) || 1180})`);
        }
    }
    get timeScale() { return this.snapshot.timeScale !== undefined ? this.snapshot.timeScale : 1.0; }
    set timeScale(v) { this.setTimeScale(v); }
    get gameOver() { return Boolean(this.snapshot.gameOver); }
    get gameWon() { return Boolean(this.snapshot.gameWon); }
    get is3DMode() { return Boolean(this.snapshot.is3DMode); }
    get camera() { return this.snapshot.camera || { x: 0, y: 0, shake: 0 }; }
    get scenario() { return this.snapshot.scenario || { name: 'Looping Stage', weather: 'clear', bg: '#050816', accent: '#38bdf8' }; }
    get stagePresets() { return this.snapshot.stagePresets || []; }
    get algebraTable() { return this.snapshot.algebraTable || null; }

    _emitLogs(list, type = 'info') {
        if (!Array.isArray(list)) return;
        for (const msg of list) {
            if (msg) this.onLog(msg, type);
        }
    }

    _processSnapAudioAndLogs(snap) {
        if (!snap) return;
        if (Array.isArray(snap.sfx)) {
            for (const sfx of snap.sfx) this.playSfx(sfx);
        }
        if (Array.isArray(snap.logs)) {
            this._emitLogs(snap.logs, 'stage');
        }
    }

    _refreshSnapshot() {
        if (!this.api || !this.handle) return this.snapshot;
        const w = this.canvas ? (this.canvas.width || 960) : 960;
        const h = this.canvas ? (this.canvas.height || 420) : 420;
        try {
            const raw = this.api.lp_get_snapshot_json(this.handle, w, h);
            this.snapshot = JSON.parse(raw);
            this._processSnapAudioAndLogs(this.snapshot);
        } catch (err) {
            this.onLog(`[WASM Snapshot Error] ${err.message}`, 'error');
        }
        return this.snapshot;
    }

    execute(code) {
        if (!this.api || !this.handle) {
            this._pendingCalls.push(() => this.execute(code));
            return { ok: true, queued: true, logs: [] };
        }
        const raw = this.api.lp_execute(this.handle, String(code || ''));
        const res = JSON.parse(raw);
        this._emitLogs(res.logs, res.ok ? 'info' : 'error');
        this._refreshSnapshot();
        return res;
    }

    parseLine(line) {
        if (!this.api || !this.handle) {
            this._pendingCalls.push(() => this.parseLine(line));
            return { ok: true, queued: true, logs: [] };
        }
        const raw = this.api.lp_parse_line(this.handle, String(line || ''));
        const res = JSON.parse(raw);
        this._emitLogs(res.logs, res.ok ? 'info' : 'error');
        this._refreshSnapshot();
        return res;
    }

    evalExpr(expr) {
        if (!this.api || !this.handle) return { ok: false, value: null, logs: ['WASM not initialized'] };
        return JSON.parse(this.api.lp_eval_expr(this.handle, String(expr || '')));
    }

    restartGame() {
        if (!this.api || !this.handle) return { ok: false, logs: [] };
        const res = JSON.parse(this.api.lp_restart(this.handle));
        this._emitLogs(res.logs, res.ok ? 'info' : 'error');
        this._refreshSnapshot();
        return res;
    }

    step(dt = 1 / 60) {
        if (!this.api || !this.handle) return this.snapshot;
        const mask = this._computeKeyMask();
        this.api.lp_set_input(this.handle, mask, this._yawDelta, this._pitchDelta);
        this._yawDelta = 0;
        this._pitchDelta = 0;

        const w = this.canvas ? (this.canvas.width || 960) : 960;
        const h = this.canvas ? (this.canvas.height || 420) : 420;
        const raw = this.api.lp_step(this.handle, dt, w, h);
        this.snapshot = JSON.parse(raw);
        this._processSnapAudioAndLogs(this.snapshot);
        return this.snapshot;
    }

    getPlayer() {
        const p = this.snapshot.player;
        if (!p) return null;
        const rt = this;
        return {
            ...p,
            get health() { return p.health; },
            set health(v) {
                const delta = Number(v) - Number(p.health || 0);
                if (delta > 0 && rt.api && rt.handle) {
                    rt.api.lp_heal_player(rt.handle, delta);
                    rt._refreshSnapshot();
                }
            },
            get vy() { return p.vy || 0; },
            set vy(v) {
                if (Number(v) < 0 && rt.api && rt.handle) {
                    rt.api.lp_boost_player(rt.handle, Math.abs(Number(v)));
                    rt._refreshSnapshot();
                }
            }
        };
    }

    healPlayer(amt = 35) {
        if (!this.api || !this.handle) return;
        this.api.lp_heal_player(this.handle, amt);
        this._refreshSnapshot();
    }

    boostPlayer(power = 680) {
        if (!this.api || !this.handle) return;
        this.api.lp_boost_player(this.handle, power);
        this._refreshSnapshot();
    }

    activatePreset(idx = 0) {
        if (!this.api || !this.handle) return;
        this.api.lp_activate_preset(this.handle, idx);
        this._refreshSnapshot();
    }

    setTimeScale(ts = 1.0) {
        if (!this.api || !this.handle) return;
        this.api.lp_set_time_scale(this.handle, ts);
        this.snapshot.timeScale = Math.max(0.1, Math.min(3.0, Number(ts) || 1.0));
    }

    toggle3DLayer() {
        if (!this.api || !this.handle) return;
        this.api.lp_toggle_3d(this.handle);
        this._refreshSnapshot();
    }

    cycleCamera3D() {
        if (!this.api || !this.handle) return;
        this.api.lp_cycle_camera3d(this.handle);
        this._refreshSnapshot();
    }

    addPopup(x, y, text, color = '#ffffff') {
        this._localPopups.push({ x, y, text, color, alpha: 1.0 });
    }

    spawnParticleBurst() {
        // Particles are natively simulated inside C++ LoopingStageRuntime on each step
    }

    getVars() {
        if (!this.api || !this.handle) return {};
        return JSON.parse(this.api.lp_get_vars_json(this.handle));
    }

    getUI() {
        if (!this.api || !this.handle) return { cards: [], buttons: [], swiftuiComponents: [] };
        return JSON.parse(this.api.lp_get_ui_json(this.handle));
    }

    clickButton(label) {
        if (!this.api || !this.handle) return { ok: false, logs: [] };
        const res = JSON.parse(this.api.lp_click_button(this.handle, String(label || '')));
        this._emitLogs(res.logs, res.ok ? 'info' : 'error');
        this._refreshSnapshot();
        return res;
    }

    checkAST(code) {
        if (!this.api) return { ok: false };
        return JSON.parse(this.api.lp_check_ast(String(code || '')));
    }

    formatCode(code) {
        if (!this.api) return String(code || '');
        return this.api.lp_format_code(String(code || ''));
    }

    encodeInvisHex(code, targetUi = 'shine_ui') {
        if (!this.api) return { valid: false };
        return JSON.parse(this.api.lp_invis_encode_hex(String(code || ''), targetUi));
    }

    bench() {
        if (!this.api) return null;
        return JSON.parse(this.api.lp_bench());
    }

    runSelftest() {
        if (!this.api) return null;
        return JSON.parse(this.api.lp_run_selftest());
    }

    getVersion() {
        if (!this.api) return null;
        return JSON.parse(this.api.lp_version_json());
    }

    startLoop() {
        if (this._rafId || typeof requestAnimationFrame !== 'function') return;
        this._lastTime = performance.now();
        const tick = (now) => {
            const dt = Math.min(0.05, Math.max(0.001, (now - this._lastTime) / 1000));
            this._lastTime = now;
            this.step(dt);
            this._updateLocalPopups(dt);
            this.render();
            this._rafId = requestAnimationFrame(tick);
        };
        this._rafId = requestAnimationFrame(tick);
    }

    stop() {
        if (this._rafId && typeof cancelAnimationFrame === 'function') {
            cancelAnimationFrame(this._rafId);
            this._rafId = null;
        }
    }

    destroy() {
        this.stop();
        if (this.api && this.handle) {
            this.api.lp_destroy(this.handle);
            this.handle = 0;
        }
    }

    _updateLocalPopups(dt) {
        for (let i = this._localPopups.length - 1; i >= 0; i--) {
            this._localPopups[i].y -= 28 * dt;
            this._localPopups[i].alpha -= dt * 1.1;
            if (this._localPopups[i].alpha <= 0) this._localPopups.splice(i, 1);
        }
    }

    _computeKeyMask() {
        let mask = 0;
        const k = this._keysDown;
        if (k.has('ArrowLeft') || k.has('KeyA')) mask |= 1;
        if (k.has('ArrowRight') || k.has('KeyD')) mask |= 2;
        if (k.has('ArrowUp') || k.has('KeyW')) mask |= 4;
        if (k.has('ArrowDown') || k.has('KeyS')) mask |= 8;
        if (k.has('Space')) mask |= 16;
        if (k.has('KeyF') || k.has('KeyJ') || k.has('Enter')) mask |= 32;
        if (k.has('ShiftLeft') || k.has('ShiftRight') || k.has('KeyK')) mask |= 64;
        if (k.has('KeyE')) mask |= 128;
        return mask;
    }

    _bindInputs() {
        if (typeof window === 'undefined' || !this.canvas) return;
        const isTyping = (el) => el && (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA' || el.isContentEditable);

        this._onKeyDown = (e) => {
            if (isTyping(document.activeElement)) return;
            this._keysDown.add(e.code);
            if (e.code === 'Space' || e.code.startsWith('Arrow')) e.preventDefault();
            if (e.code === 'KeyV') {
                if (this.is3DMode) this.cycleCamera3D();
                else this.toggle3DLayer();
            } else if (e.code === 'KeyC') {
                this.setTimeScale(this.timeScale < 0.8 ? 1.0 : 0.42);
            } else if (e.code === 'KeyR') {
                this.restartGame();
            }
        };
        this._onKeyUp = (e) => { this._keysDown.delete(e.code); };

        window.addEventListener('keydown', this._onKeyDown);
        window.addEventListener('keyup', this._onKeyUp);

        let dragging = false, lastX = 0, lastY = 0;
        this.canvas.addEventListener('pointerdown', (e) => {
            dragging = true;
            lastX = e.clientX;
            lastY = e.clientY;
        });
        window.addEventListener('pointerup', () => { dragging = false; });
        window.addEventListener('pointermove', (e) => {
            if (!dragging) return;
            this._yawDelta += (e.clientX - lastX) * 0.008;
            this._pitchDelta += (e.clientY - lastY) * 0.006;
            lastX = e.clientX;
            lastY = e.clientY;
        });
    }

    render() {
        if (!this.ctx || !this.canvas) return;
        const ctx = this.ctx;
        const w = this.canvas.width;
        const h = this.canvas.height;
        const snap = this.snapshot;

        if (snap.is3DMode && this.api && this.handle && this.mod && this.mod.HEAPU8) {
            this._render3D(ctx, w, h, snap);
        } else {
            this._render2D(ctx, w, h, snap);
        }

        // Draw Game Over / Victory overlay from C++ engine
        if (snap.gameOver || snap.gameWon) {
            ctx.save();
            ctx.fillStyle = snap.gameWon ? 'rgba(6, 78, 59, 0.72)' : 'rgba(69, 10, 10, 0.75)';
            ctx.fillRect(0, 0, w, h);
            ctx.fillStyle = '#ffffff';
            ctx.font = 'bold 34px system-ui, sans-serif';
            ctx.textAlign = 'center';
            ctx.fillText(snap.gameWon ? '🏆 VICTORY — STAGE CLEAR!' : '💥 GAME OVER', w / 2, h / 2 - 12);
            ctx.font = '600 16px monospace';
            ctx.fillStyle = '#cbd5e1';
            ctx.fillText(`SCORE: ${snap.score}   |   Press [R] to Restart`, w / 2, h / 2 + 24);
            ctx.restore();
        }
    }

    _render3D(ctx, w, h, snap) {
        const rw = Math.max(240, Math.min(360, Math.floor(w * 0.45)));
        const rh = Math.max(150, Math.min(240, Math.floor(h * 0.45)));
        const ptr = this.api.lp_render_3d_rgba(this.handle, rw, rh);
        if (ptr) {
            if (!this._offscreen || this._offscreen.width !== rw || this._offscreen.height !== rh) {
                this._offscreen = document.createElement('canvas');
                this._offscreen.width = rw;
                this._offscreen.height = rh;
                this._offCtx = this._offscreen.getContext('2d');
                this._imgData = this._offCtx.createImageData(rw, rh);
            }
            const uptr = ptr >>> 0;
            const len = rw * rh * 4;
            this._imgData.data.set(this.mod.HEAPU8.subarray(uptr, uptr + len));
            this._offCtx.putImageData(this._imgData, 0, 0);
            ctx.imageSmoothingEnabled = false;
            ctx.drawImage(this._offscreen, 0, 0, w, h);
            ctx.imageSmoothingEnabled = true;
        } else {
            ctx.fillStyle = '#050816';
            ctx.fillRect(0, 0, w, h);
        }

        // 3D Projected Popups & Telemetry HUD
        ctx.save();
        for (const pop of (snap.popups || [])) {
            ctx.globalAlpha = Math.max(0, Math.min(1, pop.alpha));
            ctx.fillStyle = pop.color || '#ffffff';
            ctx.font = 'bold 14px monospace';
            ctx.textAlign = 'center';
            ctx.fillText(pop.text, pop.x, pop.y);
        }
        ctx.globalAlpha = 1;

        ctx.fillStyle = 'rgba(2, 6, 23, 0.72)';
        ctx.fillRect(12, 12, 340, 52);
        ctx.strokeStyle = 'rgba(56, 189, 248, 0.45)';
        ctx.strokeRect(12, 12, 340, 52);
        ctx.fillStyle = '#38bdf8';
        ctx.font = 'bold 12px monospace';
        const p = snap.player;
        const posStr = p ? `(${p.x.toFixed(1)}, ${p.y.toFixed(1)}, ${p.z.toFixed(1)})` : '(0,0,0)';
        ctx.fillText(`🧊 C++ WASM 3D Z-BUFFER  |  CAM: ${snap.camera3D.mode.toUpperCase()} [V]`, 22, 31);
        ctx.fillStyle = '#e2e8f0';
        ctx.fillText(`HP:${p ? Math.round(p.health) : 100}  SCORE:${snap.score}  POS:${posStr}`, 22, 51);
        ctx.restore();
    }

    _render2D(ctx, w, h, snap) {
        const bg = (snap.scenario && snap.scenario.bg) || '#050816';
        const accent = (snap.scenario && snap.scenario.accent) || '#38bdf8';
        const camX = (snap.camera && snap.camera.x) || 0;
        const camY = (snap.camera && snap.camera.y) || 0;
        const shake = (snap.camera && snap.camera.shake) || 0;
        const sx = shake > 0 ? (Math.random() - 0.5) * shake : 0;
        const sy = shake > 0 ? (Math.random() - 0.5) * shake : 0;

        const grad = ctx.createLinearGradient(0, 0, 0, h);
        grad.addColorStop(0, bg);
        grad.addColorStop(1, '#020617');
        ctx.fillStyle = grad;
        ctx.fillRect(0, 0, w, h);

        // Parallax starfield & cyber grid
        ctx.fillStyle = 'rgba(148, 163, 184, 0.45)';
        for (const st of this._stars) {
            const px = ((st.x - camX * st.sp) % w + w) % w;
            ctx.fillRect(px, st.y % h, st.s, st.s);
        }

        ctx.save();
        ctx.translate(-camX + sx, -camY + sy);

        // Floor baseline
        const floorY = (snap.world && snap.world.height ? snap.world.height : 420) - 44;
        const worldW = (snap.world && snap.world.width) || 1200;
        ctx.fillStyle = '#0f172a';
        ctx.fillRect(0, floorY, worldW, 80);
        ctx.fillStyle = accent;
        ctx.fillRect(0, floorY, worldW, 3);

        for (const e of (snap.entities || [])) {
            if (e.collected || e.broken || e.alive === false) continue;
            if (e.type === 'player') {
                this._drawPlayer2D(ctx, e);
            } else if (e.type === 'platform' || e.type === 'moving_platform' || e.type === 'breakable') {
                ctx.fillStyle = e.color || '#334155';
                ctx.fillRect(e.x, e.y, e.w, e.h);
                ctx.strokeStyle = 'rgba(255,255,255,0.22)';
                ctx.strokeRect(e.x, e.y, e.w, e.h);
                if (e.type === 'breakable') {
                    ctx.beginPath();
                    ctx.moveTo(e.x + 4, e.y + 4);
                    ctx.lineTo(e.x + e.w - 4, e.y + e.h - 4);
                    ctx.stroke();
                }
            } else if (e.type === 'gravity_zone') {
                ctx.fillStyle = 'rgba(139, 92, 246, 0.16)';
                ctx.fillRect(e.x, e.y, e.w, e.h);
                ctx.strokeStyle = 'rgba(167, 139, 250, 0.5)';
                ctx.setLineDash([6, 4]);
                ctx.strokeRect(e.x, e.y, e.w, e.h);
                ctx.setLineDash([]);
            } else if (e.type === 'spike') {
                ctx.fillStyle = e.color || '#ef4444';
                ctx.beginPath();
                ctx.moveTo(e.x, e.y + e.h);
                ctx.lineTo(e.x + e.w / 2, e.y);
                ctx.lineTo(e.x + e.w, e.y + e.h);
                ctx.closePath();
                ctx.fill();
            } else if (e.type === 'jump_pad') {
                ctx.fillStyle = e.color || '#fbbf24';
                ctx.fillRect(e.x, e.y + (e.pulse > 0 ? 3 : 0), e.w, e.h);
            } else if (e.type === 'orb') {
                ctx.strokeStyle = e.color || '#f59e0b';
                ctx.lineWidth = 3;
                ctx.beginPath();
                ctx.arc(e.x, e.y, (e.r || 14) + Math.sin(performance.now() * 0.008) * 2, 0, Math.PI * 2);
                ctx.stroke();
            } else if (e.type === 'coin') {
                ctx.fillStyle = e.color || '#fbbf24';
                ctx.beginPath();
                ctx.arc(e.x, e.y, e.r || 10, 0, Math.PI * 2);
                ctx.fill();
            } else if (e.type === 'heart') {
                ctx.fillStyle = e.color || '#ec4899';
                ctx.beginPath();
                ctx.arc(e.x, e.y, e.r || 11, 0, Math.PI * 2);
                ctx.fill();
                ctx.fillStyle = '#fff';
                ctx.font = 'bold 12px sans-serif';
                ctx.textAlign = 'center';
                ctx.fillText('+', e.x, e.y + 4);
            } else if (e.type === 'checkpoint') {
                ctx.fillStyle = e.activated ? '#4ade80' : '#94a3b8';
                ctx.fillRect(e.x, e.y, 6, e.h);
                ctx.fillRect(e.x + 6, e.y, 22, 16);
            } else if (e.type === 'portal' || e.type === 'teleporter') {
                ctx.save();
                ctx.translate(e.x + e.w / 2, e.y + e.h / 2);
                ctx.rotate(e.angle || 0);
                ctx.strokeStyle = e.color || '#a855f7';
                ctx.lineWidth = 4;
                ctx.beginPath();
                ctx.ellipse(0, 0, e.w / 2, e.h / 2, 0, 0, Math.PI * 1.7);
                ctx.stroke();
                ctx.restore();
            } else if (e.type === 'laser_hazard') {
                ctx.fillStyle = e.active ? '#ef4444' : 'rgba(239,68,68,0.2)';
                ctx.fillRect(e.x, e.y, e.w, e.h);
            } else if (e.type === 'saw') {
                ctx.save();
                ctx.translate(e.x, e.y);
                ctx.rotate(e.angle || 0);
                ctx.fillStyle = e.color || '#f43f5e';
                ctx.beginPath();
                ctx.arc(0, 0, e.r || 18, 0, Math.PI * 2);
                ctx.fill();
                ctx.restore();
            } else if (e.type === 'enemy' || e.type === 'boss' || e.type === 'turret' || e.type === 'sprite') {
                ctx.fillStyle = e.color || (e.type === 'boss' ? '#dc2626' : '#f43f5e');
                ctx.fillRect(e.x, e.y, e.w, e.h);
                const hpPct = Math.max(0, Math.min(1, (e.health || 1) / Math.max(1, e.maxHealth || 1)));
                ctx.fillStyle = '#0f172a';
                ctx.fillRect(e.x, e.y - 8, e.w, 4);
                ctx.fillStyle = '#ef4444';
                ctx.fillRect(e.x, e.y - 8, e.w * hpPct, 4);
            } else if (e.type === 'powerup') {
                ctx.fillStyle = e.color || '#38bdf8';
                ctx.beginPath();
                ctx.arc(e.x, e.y, 12, 0, Math.PI * 2);
                ctx.fill();
            }
        }

        for (const pr of (snap.projectiles || [])) {
            ctx.fillStyle = pr.color || '#38bdf8';
            ctx.beginPath();
            ctx.arc(pr.x, pr.y, pr.r || 5, 0, Math.PI * 2);
            ctx.fill();
        }
        for (const pt of (snap.particles || [])) {
            ctx.globalAlpha = pt.alpha;
            ctx.fillStyle = pt.color || '#ffffff';
            ctx.fillRect(pt.x - pt.size / 2, pt.y - pt.size / 2, pt.size, pt.size);
        }
        ctx.globalAlpha = 1;

        for (const pop of [...(snap.popups || []), ...this._localPopups]) {
            ctx.globalAlpha = Math.max(0, Math.min(1, pop.alpha));
            ctx.fillStyle = pop.color || '#ffffff';
            ctx.font = 'bold 13px monospace';
            ctx.textAlign = 'center';
            ctx.fillText(pop.text, pop.x, pop.y);
        }
        ctx.globalAlpha = 1;
        ctx.restore();
    }

    _drawPlayer2D(ctx, p) {
        ctx.save();
        const cx = p.x + p.w / 2;
        const cy = p.y + p.h;
        ctx.translate(cx, cy);
        ctx.scale(p.squash || 1, p.stretch || 1);
        ctx.translate(-cx, -cy);

        ctx.fillStyle = p.overdrive ? '#f43f5e' : (p.color || '#38bdf8');
        ctx.fillRect(p.x, p.y, p.w, p.h);
        ctx.strokeStyle = p.isDashing ? '#ffffff' : 'rgba(255,255,255,0.45)';
        ctx.lineWidth = p.isDashing ? 3 : 1.5;
        ctx.strokeRect(p.x, p.y, p.w, p.h);

        // Cyber visor
        const eyeX = p.facing >= 0 ? p.x + p.w - 13 : p.x + 3;
        ctx.fillStyle = '#0f172a';
        ctx.fillRect(eyeX, p.y + 8, 10, 6);
        ctx.fillStyle = '#00f5d4';
        ctx.fillRect(eyeX + 2, p.y + 9, 6, 4);
        ctx.restore();
    }

    playSfx(type = 'coin') {
        if (!this.soundEnabled || typeof window === 'undefined') return;
        const Ctx = window.AudioContext || window.webkitAudioContext;
        if (!Ctx) return;
        if (!this.audioCtx) this.audioCtx = new Ctx();
        if (this.audioCtx.state === 'suspended') this.audioCtx.resume().catch(() => {});

        const ac = this.audioCtx;
        const osc = ac.createOscillator();
        const gain = ac.createGain();
        osc.connect(gain);
        gain.connect(ac.destination);

        let freq = 660, freqEnd = 880, dur = 0.09, wave = 'sine';
        if (typeof type === 'string' && type.startsWith('tone:')) {
            const parts = type.split(':');
            freq = freqEnd = parseFloat(parts[1]) || 440;
            dur = parseFloat(parts[2]) || 0.14;
        } else if (type === 'jump') { freq = 340; freqEnd = 560; dur = 0.11; }
        else if (type === 'double_jump') { freq = 520; freqEnd = 860; dur = 0.12; wave = 'triangle'; }
        else if (type === 'pad') { freq = 420; freqEnd = 1040; dur = 0.18; wave = 'triangle'; }
        else if (type === 'dash') { freq = 720; freqEnd = 240; dur = 0.10; wave = 'sawtooth'; }
        else if (type === 'shoot') { freq = 920; freqEnd = 340; dur = 0.07; wave = 'square'; }
        else if (type === 'hurt' || type === 'gameover') { freq = 220; freqEnd = 90; dur = 0.22; wave = 'sawtooth'; }
        else if (type === 'heal' || type === 'victory') { freq = 523; freqEnd = 1046; dur = 0.20; }
        else if (type === 'stomp') { freq = 280; freqEnd = 140; dur = 0.12; wave = 'square'; }

        const now = ac.currentTime;
        osc.type = wave;
        osc.frequency.setValueAtTime(freq, now);
        osc.frequency.exponentialRampToValueAtTime(Math.max(40, freqEnd), now + dur);
        gain.gain.setValueAtTime(0.08, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + dur);
        osc.start(now);
        osc.stop(now + dur);
    }
}

export { LoopingWasmRuntime as LoopingInterpreter, loadWasmFactory };
