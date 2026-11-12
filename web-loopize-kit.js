// ═══════════════════════════════════════════════════════════════
//  WEB LOOPIZE KIT v1.0.0 (@cokistudios/web-loopize-kit)
//  Zero-Dependency Browser SDK & Web Components for Looping 3D,
//  Wavefront .obj Meshes, C# MonoBehaviour Scripting & loopize++
//  Coki Studios & Holo Entertainment © 2026
// ═══════════════════════════════════════════════════════════════

import {
    LoopingInterpreter,
    BUILTIN_OBJ_MODELS,
    resolveBuiltinOBJKey,
    parseWavefrontOBJ,
    normalizeOBJMesh,
    subdivideOBJMesh,
    exportWavefrontOBJ,
    CSharpMiniVM,
    LoopizeRuntimeJS
} from './LoopingEngine/looping_core.js';

export {
    LoopingInterpreter,
    BUILTIN_OBJ_MODELS,
    resolveBuiltinOBJKey,
    parseWavefrontOBJ,
    normalizeOBJMesh,
    subdivideOBJMesh,
    exportWavefrontOBJ,
    CSharpMiniVM,
    LoopizeRuntimeJS
};

export const KIT_VERSION = '1.0.0';

export const PRESETS = {
    orbital_arena: `// 🚀 Web Loopize Kit — Orbital Arena (.obj + C# + loopize++)
use "loopize++"
use "loop-game-plus"

define game3d "Web Loopize Orbital Arena" version 1.1:
    scene3d.world("Orbital Arena", gravity: 22.0, substeps: 4, sky: "cyber_night")
    scene3d.camera(mode: "chase", fov: 66, distance: 15, height: 6)
    lz_banner("Web Loopize Kit • Orbital Arena")

    cs! {
        public class OrbitalGuardian : MonoBehaviour {
            public float Speed = 42.0f;
            public void Start() {
                LoopingBridge.Set("guardian_ready", true);
                Console.WriteLine("[C#] OrbitalGuardian activo");
            }
            public void Update(float dt) {
                Scene3D.Rotate("OmegaTitan", 0.0f, Speed * dt, 0.0f);
                Scene3D.Rotate("WarpGate", 0.0f, 0.0f, Speed * 0.8f * dt);
            }
        }
    }

    spawn3d.box("DeckPrincipal", at: (0, 0, 12), size: (34, 1.2, 52), color: "#1e293b")
    spawn3d.player("AngelPilot", at: (0, 2.0, -4), speed: 24, jump: 16, health: 100, color: "#38bdf8")
    spawn3d.obj("OmegaTitan", obj: "omega_titan.obj", at: (0, 3.6, 20), scale: 1.5, color: "#f43f5e", cs: "OrbitalGuardian")
    spawn3d.obj("EnergyCrystalA", obj: "cyber_crystal.obj", at: (-5.5, 2.2, 8), scale: 1.1, color: "#fbbf24")
    spawn3d.obj("EnergyCrystalB", obj: "cyber_crystal.obj", at: (5.5, 2.2, 8), scale: 1.1, color: "#fbbf24")
    spawn3d.obj("WarpGate", obj: "star_gate.obj", at: (0, 4.2, 32), scale: 1.35, color: "#c084fc")

    lz_wave_rush(1, "valkyrie", 4, 80, "valkyrie_drone.obj")
    loopize.fsm_set("AngelPilot", "overdrive")
    lz_mission("sector_clear", "Superar el Portal Cuántico", 3, 1200)
    lz_report()`,

    valkyrie_swarm: `// 🐝 Web Loopize Kit — Valkyrie Interceptor Swarm
use "loopize++"

define game3d "Valkyrie Defense" version 1.1:
    scene3d.world("Sector Aegis", gravity: 24.0, substeps: 4, sky: "neon_dusk")
    lz_banner("Valkyrie Interceptor Swarm")

    cs! {
        public class ValkyrieSwarmAI : MonoBehaviour {
            public void Start() {
                Console.WriteLine("[C#] Escuadrón Valkyrie desplegado");
            }
            public void Update(float dt) {
                Scene3D.Rotate("ValkyrieAlpha", 0.0f, 65.0f * dt, 0.0f);
                Scene3D.Rotate("ValkyrieBeta", 0.0f, -65.0f * dt, 0.0f);
            }
        }
    }

    spawn3d.box("Runway", at: (0, 0, 14), size: (36, 1.2, 58), color: "#0f172a")
    spawn3d.player("Interceptor", at: (0, 2, -6), speed: 26, jump: 17, color: "#00f5d4")
    spawn3d.obj("ValkyrieAlpha", obj: "valkyrie_drone.obj", at: (-6, 3.0, 10), scale: 1.6, color: "#ef4444", cs: "ValkyrieSwarmAI")
    spawn3d.obj("ValkyrieBeta", obj: "valkyrie_drone.obj", at: (6, 3.0, 14), scale: 1.6, color: "#f97316")
    spawn3d.obj("CenterCrystal", obj: "cyber_crystal.obj", at: (0, 2.6, 24), scale: 1.4, color: "#fbbf24")
    lz_wave_rush(1, "valkyrie", 5, 65, "valkyrie_drone.obj")
    lz_report()`,

    crystal_shrine: `// 💎 Web Loopize Kit — Crystal Temple Showcase
use "loopize++"

define game3d "Crystal Shrine" version 1.1:
    scene3d.world("Sanctuary", gravity: 18.0, substeps: 4, sky: "aurora")
    spawn3d.box("Plaza", at: (0, 0, 10), size: (28, 1.0, 38), color: "#312e81")
    spawn3d.player("Explorer", at: (0, 2, -4), speed: 20, jump: 15, color: "#38bdf8")
    spawn3d.obj("MainGate", obj: "star_gate.obj", at: (0, 4.0, 18), scale: 1.4, color: "#c084fc")
    spawn3d.obj("Relic1", obj: "cyber_crystal.obj", at: (-4, 2.2, 6), scale: 1.2, color: "#fbbf24")
    spawn3d.obj("Relic2", obj: "cyber_crystal.obj", at: (4, 2.2, 6), scale: 1.2, color: "#00f5d4")
    spawn3d.obj("HeroShip", obj: "starfighter.obj", at: (0, 2.6, 10), scale: 1.3, color: "#38bdf8")`
};

export function createStage(canvasOrSelector, options = {}) {
    const canvas = typeof canvasOrSelector === 'string'
        ? document.querySelector(canvasOrSelector)
        : canvasOrSelector;
    if (!canvas) throw new Error('WebLoopizeKit.createStage: canvas not found');

    const onLog = typeof options.onLog === 'function' ? options.onLog : () => {};
    const runtime = new LoopingInterpreter(canvas, onLog);

    if (options.autoload !== false && options.code) {
        runtime.execute(options.code);
    } else if (options.preset && PRESETS[options.preset]) {
        runtime.execute(PRESETS[options.preset]);
    }

    return {
        version: KIT_VERSION,
        runtime,
        canvas,
        run(code) {
            runtime.reset();
            return runtime.execute(code);
        },
        runPreset(name) {
            const code = PRESETS[name] || PRESETS.orbital_arena;
            runtime.reset();
            return runtime.execute(code);
        },
        loadOBJText(objText, key = 'custom') {
            const mesh = parseWavefrontOBJ(objText, 1.0, key);
            runtime.objMeshes3D[key] = mesh;
            return mesh;
        },
        async loadOBJUrl(url, key = 'remote') {
            const res = await fetch(url);
            if (!res.ok) throw new Error(`HTTP ${res.status} fetching ${url}`);
            const text = await res.text();
            return this.loadOBJText(text, key);
        },
        runCSharp(csCode) {
            return runtime.csharpBridge.executeBlock(csCode);
        },
        setCameraMode(mode) {
            runtime.camera3D.mode = mode;
        },
        pause() {
            runtime.isRunning = false;
            if (runtime.animationFrameId) cancelAnimationFrame(runtime.animationFrameId);
        },
        resume() {
            if (!runtime.isRunning) runtime.startLoop();
        },
        stats() {
            return {
                fps: Math.round(runtime.fpsSmooth || 60),
                entities3D: runtime.entities3D.length,
                score: runtime.score,
                loopize: runtime.loopize.stats()
            };
        },
        destroy() {
            runtime.reset();
        }
    };
}

function hexToRgb(hex) {
    const clean = String(hex || '#38bdf8').replace('#', '');
    if (clean.length === 3) {
        return [
            parseInt(clean[0] + clean[0], 16) || 56,
            parseInt(clean[1] + clean[1], 16) || 189,
            parseInt(clean[2] + clean[2], 16) || 248
        ];
    }
    const n = parseInt(clean.padEnd(6, '0').slice(0, 6), 16);
    return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

const BaseHTMLElement = typeof HTMLElement !== 'undefined' ? HTMLElement : class {};

// ── <loopize-obj-viewer> Web Component ──
export class LoopizeObjViewerElement extends BaseHTMLElement {
    static get observedAttributes() {
        return ['model', 'color', 'wireframe', 'autorotate', 'label'];
    }

    constructor() {
        super();
        this.attachShadow({ mode: 'open' });
        this.mesh = null;
        this.yaw = 0.65;
        this.pitch = 0.35;
        this.zoom = 1.0;
        this.wireframe = false;
        this.autorotate = true;
        this.dragging = false;
        this.lastX = 0;
        this.lastY = 0;
        this.raf = null;
    }

    connectedCallback() {
        this.renderShell();
        this.wireframe = this.getAttribute('wireframe') === 'true';
        this.autorotate = this.getAttribute('autorotate') !== 'false';
        this.loadModel(this.getAttribute('model') || 'starfighter');
        this.startRender();
    }

    disconnectedCallback() {
        if (this.raf) cancelAnimationFrame(this.raf);
    }

    attributeChangedCallback(name, oldVal, newVal) {
        if (oldVal === newVal || !this.shadowRoot) return;
        if (name === 'model') this.loadModel(newVal);
        if (name === 'wireframe') this.wireframe = newVal === 'true';
        if (name === 'autorotate') this.autorotate = newVal !== 'false';
        if (name === 'label') {
            const lbl = this.shadowRoot.getElementById('lbl');
            if (lbl) lbl.textContent = newVal || 'OBJ Model';
        }
    }

    loadOBJString(text, name = 'CustomOBJ') {
        this.mesh = parseWavefrontOBJ(text, 1.0, name);
        normalizeOBJMesh(this.mesh, 2.2);
        this.updateStats();
    }

    async loadModel(spec) {
        const key = resolveBuiltinOBJKey(spec);
        if (key && BUILTIN_OBJ_MODELS[key]) {
            this.loadOBJString(BUILTIN_OBJ_MODELS[key], key);
        } else if (spec && (spec.endsWith('.obj') || spec.startsWith('http') || spec.startsWith('/'))) {
            try {
                const res = await fetch(spec);
                if (res.ok) this.loadOBJString(await res.text(), spec.split('/').pop());
            } catch (_) {}
        }
        if (!this.mesh) this.loadOBJString(BUILTIN_OBJ_MODELS.starfighter, 'starfighter');
    }

    updateStats() {
        const st = this.shadowRoot?.getElementById('stats');
        if (!st || !this.mesh) return;
        st.textContent = `${this.mesh.vertices.length}v • ${this.mesh.faces.length}f • ${this.mesh.triangles} tris`;
    }

    renderShell() {
        const h = this.getAttribute('height') || '240px';
        const label = this.getAttribute('label') || this.getAttribute('model') || 'starfighter';
        this.shadowRoot.innerHTML = `
            <style>
                :host { display: block; font-family: 'Outfit', system-ui, sans-serif; }
                .card {
                    position: relative;
                    border-radius: 14px;
                    overflow: hidden;
                    background: radial-gradient(circle at 50% 25%, #0f172a, #050811);
                    border: 1px solid rgba(56, 189, 248, 0.25);
                    box-shadow: 0 10px 28px rgba(0, 0, 0, 0.35);
                }
                canvas { display: block; width: 100%; height: ${h}; cursor: grab; touch-action: none; }
                canvas:active { cursor: grabbing; }
                .hud-top {
                    position: absolute; top: 10px; left: 12px; right: 12px;
                    display: flex; justify-content: space-between; align-items: center; gap: 8px;
                    pointer-events: none;
                }
                .pill {
                    background: rgba(15, 23, 42, 0.78);
                    backdrop-filter: blur(8px);
                    border: 1px solid rgba(255, 255, 255, 0.14);
                    color: #f8fafc; font-size: 11px; font-weight: 700;
                    padding: 4px 10px; border-radius: 999px; font-family: 'JetBrains Mono', monospace;
                }
                .hud-bot {
                    display: flex; justify-content: space-between; align-items: center; gap: 6px; flex-wrap: wrap;
                    padding: 8px 12px; background: rgba(2, 6, 23, 0.9); border-top: 1px solid rgba(255, 255, 255, 0.08);
                }
                button {
                    background: rgba(56, 189, 248, 0.12); color: #38bdf8;
                    border: 1px solid rgba(56, 189, 248, 0.35); border-radius: 8px;
                    padding: 4px 9px; font-size: 11px; font-weight: 700; cursor: pointer;
                }
                button:hover { background: rgba(56, 189, 248, 0.26); }
            </style>
            <div class="card" id="drop">
                <div class="hud-top">
                    <span class="pill" id="lbl">${label}</span>
                    <span class="pill" id="stats">...</span>
                </div>
                <canvas width="420" height="240"></canvas>
                <div class="hud-bot">
                    <span style="font-size:11px; color:#94a3b8; font-family:'JetBrains Mono',monospace;">Arrastra para orbitar • Drop .obj</span>
                    <div style="display:flex; gap:6px;">
                        <button id="btn-wire">Wire</button>
                        <button id="btn-sub">Subdiv</button>
                        <button id="btn-exp">.OBJ</button>
                    </div>
                </div>
            </div>
        `;
        const cv = this.shadowRoot.querySelector('canvas');
        const drop = this.shadowRoot.getElementById('drop');

        cv.addEventListener('pointerdown', e => {
            this.dragging = true;
            this.autorotate = false;
            this.lastX = e.clientX;
            this.lastY = e.clientY;
            cv.setPointerCapture(e.pointerId);
        });
        cv.addEventListener('pointermove', e => {
            if (!this.dragging) return;
            this.yaw += (e.clientX - this.lastX) * 0.012;
            this.pitch = Math.max(-1.2, Math.min(1.2, this.pitch + (e.clientY - this.lastY) * 0.012));
            this.lastX = e.clientX;
            this.lastY = e.clientY;
        });
        cv.addEventListener('pointerup', () => { this.dragging = false; });
        cv.addEventListener('wheel', e => {
            e.preventDefault();
            this.zoom = Math.max(0.55, Math.min(2.4, this.zoom - e.deltaY * 0.0012));
        }, { passive: false });

        drop.addEventListener('dragover', e => { e.preventDefault(); });
        drop.addEventListener('drop', async e => {
            e.preventDefault();
            const f = e.dataTransfer?.files?.[0];
            if (f && f.name.toLowerCase().endsWith('.obj')) {
                this.loadOBJString(await f.text(), f.name);
                this.shadowRoot.getElementById('lbl').textContent = f.name;
            }
        });

        this.shadowRoot.getElementById('btn-wire').addEventListener('click', () => { this.wireframe = !this.wireframe; });
        this.shadowRoot.getElementById('btn-sub').addEventListener('click', () => {
            if (this.mesh && this.mesh.faces.length < 1800) {
                this.mesh = subdivideOBJMesh(this.mesh);
                this.updateStats();
            }
        });
        this.shadowRoot.getElementById('btn-exp').addEventListener('click', () => {
            if (!this.mesh) return;
            const blob = new Blob([exportWavefrontOBJ(this.mesh)], { type: 'text/plain' });
            const a = document.createElement('a');
            a.href = URL.createObjectURL(blob);
            a.download = `${this.mesh.name || 'model'}.obj`;
            a.click();
        });
    }

    startRender() {
        const cv = this.shadowRoot?.querySelector('canvas');
        if (!cv) return;
        const ctx = cv.getContext('2d');
        const frame = () => {
            if (this.autorotate) this.yaw += 0.014;
            const w = cv.width, h = cv.height;
            ctx.clearRect(0, 0, w, h);

            // Subtle floor grid
            ctx.strokeStyle = 'rgba(56, 189, 248, 0.14)';
            ctx.lineWidth = 1;
            const cy = Math.cos(this.yaw), sy = Math.sin(this.yaw);
            const cp = Math.cos(this.pitch), sp = Math.sin(this.pitch);
            const proj = (vx, vy, vz) => {
                const x1 = vx * cy + vz * sy;
                const z1 = -vx * sy + vz * cy;
                const y2 = vy * cp - z1 * sp;
                const z2 = vy * sp + z1 * cp + 4.4 / this.zoom;
                if (z2 <= 0.25) return null;
                const sc = (h * 0.85) / z2;
                return [w * 0.5 + x1 * sc, h * 0.52 - y2 * sc, z2];
            };
            for (let g = -2; g <= 2; g += 1) {
                const a = proj(g * 0.7, -1.1, -1.4), b = proj(g * 0.7, -1.1, 1.4);
                const c = proj(-1.4, -1.1, g * 0.7), d = proj(1.4, -1.1, g * 0.7);
                if (a && b) { ctx.beginPath(); ctx.moveTo(a[0], a[1]); ctx.lineTo(b[0], b[1]); ctx.stroke(); }
                if (c && d) { ctx.beginPath(); ctx.moveTo(c[0], c[1]); ctx.lineTo(d[0], d[1]); ctx.stroke(); }
            }

            if (this.mesh && this.mesh.vertices.length) {
                const baseRgb = hexToRgb(this.getAttribute('color') || '#38bdf8');
                const polys = [];
                const pVerts = this.mesh.vertices.map(v => proj(v[0], v[1], v[2]));
                for (const f of this.mesh.faces) {
                    const pts = f.indices.map(idx => pVerts[idx]);
                    if (pts.some(p => !p)) continue;
                    const avgZ = pts.reduce((a, p) => a + p[2], 0) / pts.length;
                    const nx1 = f.nx * cy + f.nz * sy, nz1 = -f.nx * sy + f.nz * cy;
                    const ny2 = f.ny * cp - nz1 * sp, nz2 = f.ny * sp + nz1 * cp;
                    const lit = 0.38 + Math.max(0, -nx1 * 0.4 + ny2 * 0.8 - nz2 * 0.45) * 0.72;
                    const rgb = f.tint ? hexToRgb(f.tint) : baseRgb;
                    polys.push({ pts, avgZ, rgb, lit });
                }
                polys.sort((a, b) => b.avgZ - a.avgZ);
                for (const p of polys) {
                    ctx.beginPath();
                    ctx.moveTo(p.pts[0][0], p.pts[0][1]);
                    for (let k = 1; k < p.pts.length; k++) ctx.lineTo(p.pts[k][0], p.pts[k][1]);
                    ctx.closePath();
                    if (!this.wireframe) {
                        const r = Math.min(255, Math.round(p.rgb[0] * p.lit));
                        const g = Math.min(255, Math.round(p.rgb[1] * p.lit));
                        const b = Math.min(255, Math.round(p.rgb[2] * p.lit));
                        ctx.fillStyle = `rgb(${r},${g},${b})`;
                        ctx.fill();
                        ctx.strokeStyle = 'rgba(255,255,255,0.22)';
                    } else {
                        ctx.strokeStyle = `rgb(${p.rgb[0]},${p.rgb[1]},${p.rgb[2]})`;
                    }
                    ctx.lineWidth = this.wireframe ? 1.4 : 0.8;
                    ctx.stroke();
                }
            }
            this.raf = requestAnimationFrame(frame);
        };
        this.raf = requestAnimationFrame(frame);
    }
}

// ── <loopize-stage> Web Component ──
export class LoopizeStageElement extends BaseHTMLElement {
    constructor() {
        super();
        this.attachShadow({ mode: 'open' });
        this.stage = null;
        this.statTimer = null;
    }

    connectedCallback() {
        const preset = this.getAttribute('preset') || 'orbital_arena';
        const title = this.getAttribute('title') || 'WEB LOOPIZE KIT STAGE';
        const inlineScript = this.querySelector('script[type="text/looping"]')?.textContent;
        const height = this.getAttribute('height') || '390px';

        this.shadowRoot.innerHTML = `
            <style>
                :host { display: block; font-family: 'Outfit', system-ui, sans-serif; }
                .wrap {
                    border-radius: 16px; overflow: hidden;
                    background: #06090f; border: 1px solid rgba(56, 189, 248, 0.35);
                    box-shadow: 0 14px 36px rgba(0, 0, 0, 0.42);
                }
                .bar {
                    display: flex; justify-content: space-between; align-items: center; gap: 10px; flex-wrap: wrap;
                    padding: 10px 14px; background: rgba(15, 23, 42, 0.94); border-bottom: 1px solid rgba(255, 255, 255, 0.08);
                    color: #f8fafc; font-size: 12px; font-weight: 700;
                }
                .hud { display: flex; gap: 8px; flex-wrap: wrap; font-family: 'JetBrains Mono', monospace; font-size: 11px; color: #38bdf8; }
                .actions { display: flex; gap: 6px; }
                button {
                    background: rgba(56, 189, 248, 0.14); color: #f8fafc;
                    border: 1px solid rgba(56, 189, 248, 0.4); border-radius: 8px;
                    padding: 5px 10px; font-size: 11px; font-weight: 700; cursor: pointer;
                }
                button:hover { background: rgba(56, 189, 248, 0.32); }
                canvas { display: block; width: 100%; height: ${height}; background: #050811; }
                .foot {
                    padding: 8px 14px; background: rgba(2, 6, 23, 0.96);
                    border-top: 1px solid rgba(255, 255, 255, 0.08);
                    color: #94a3b8; font-family: 'JetBrains Mono', monospace; font-size: 11px;
                    max-height: 76px; overflow-y: auto; white-space: pre-wrap;
                }
            </style>
            <div class="wrap">
                <div class="bar">
                    <span>⚡ ${title}</span>
                    <div class="hud" id="hud">FPS: -- | ECS: -- | C#: --</div>
                    <div class="actions">
                        <button id="b-cam">Cámara</button>
                        <button id="b-reset">Reiniciar</button>
                    </div>
                </div>
                <canvas width="780" height="420"></canvas>
                <div class="foot" id="log">Inicializando Web Loopize Kit v${KIT_VERSION}...</div>
            </div>
        `;

        const cv = this.shadowRoot.querySelector('canvas');
        const logEl = this.shadowRoot.getElementById('log');
        const hudEl = this.shadowRoot.getElementById('hud');
        const logs = [];
        const initialCode = inlineScript || PRESETS[preset] || PRESETS.orbital_arena;

        this.stage = createStage(cv, {
            code: initialCode,
            onLog: (msg) => {
                logs.push(msg);
                if (logs.length > 6) logs.shift();
                logEl.textContent = logs.join('\n');
            }
        });

        const cams = ['chase', 'orbit', 'fps', 'topdown'];
        let camIdx = 0;
        this.shadowRoot.getElementById('b-cam').addEventListener('click', () => {
            camIdx = (camIdx + 1) % cams.length;
            this.stage.setCameraMode(cams[camIdx]);
        });
        this.shadowRoot.getElementById('b-reset').addEventListener('click', () => {
            logs.length = 0;
            this.stage.run(initialCode);
        });

        this.statTimer = setInterval(() => {
            if (!this.stage) return;
            const st = this.stage.stats();
            hudEl.textContent = `FPS: ${st.fps} | Entidades: ${st.entities3D} | ECS: ${st.loopize.ecs_count} | C#: ${st.loopize.cs_classes}`;
        }, 350);
    }

    disconnectedCallback() {
        if (this.statTimer) clearInterval(this.statTimer);
        if (this.stage) this.stage.destroy();
    }
}

if (typeof customElements !== 'undefined') {
    if (!customElements.get('loopize-obj-viewer')) customElements.define('loopize-obj-viewer', LoopizeObjViewerElement);
    if (!customElements.get('loopize-stage')) customElements.define('loopize-stage', LoopizeStageElement);
}

export const WebLoopizeKit = {
    version: KIT_VERSION,
    createStage,
    PRESETS,
    BUILTIN_OBJ_MODELS,
    parseWavefrontOBJ,
    normalizeOBJMesh,
    subdivideOBJMesh,
    exportWavefrontOBJ,
    LoopingInterpreter,
    CSharpMiniVM,
    LoopizeRuntimeJS
};

if (typeof window !== 'undefined') {
    window.WebLoopizeKit = WebLoopizeKit;
}

export default WebLoopizeKit;
