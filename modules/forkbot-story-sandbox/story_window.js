import { DynamicHTMLWindow } from '../loop-node-window/index.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

class ForkbotSandboxWindow extends DynamicHTMLWindow {
    constructor() {
        const scriptPath = path.join(__dirname, 'main.loop');
        super({
            title: 'Forkbot — Historia, Sandbox & Tabla de Fuerza',
            port: 7890,
            scriptPath: fs.existsSync(scriptPath) ? scriptPath : undefined
        });
    }

    renderHTML() {
        const baseHTML = super.renderHTML();

        // Bloque que se inyecta limpiamente sobre la ventana original de loop-node-window
        const customUI = `
        <div style="background:rgba(15,23,42,0.85); border:1px solid rgba(56,189,248,0.3); border-radius:14px; padding:18px; margin-top:16px;">
            <h3 style="color:#38bdf8; font-size:15px; margin-bottom:8px;">📖 Historia Base: Forkbot vs. Blueline</h3>
            <p style="font-size:13px; color:#cbd5e1; line-height:1.5; margin-bottom:14px;">
                <strong>Inicio:</strong> En Hello! Inc. conectan una USB de "PELIGRO" en Forkbot y lo envían a pelear contra Blueline (1000 veces más grande).<br>
                <strong>Nudo:</strong> Blueline lo lanza a la Dimensión Visionaria con un agujero negro; allí ve futuros posibles y un virus entra en su sistema.<br>
                <strong>Desenlace:</strong> Regresa al Mundo Roto con fragmentos de suelo flotando, intenta coexistir por 4 años, pero tras recibir <strong>760 golpes</strong> desata su forma Monstruo y derrota a Blueline de un Súper Golpe.
            </p>

            <!-- Medidor de Fuerza Simple -->
            <div style="background:#060913; border:1px solid rgba(255,255,255,0.1); border-radius:10px; padding:12px; margin-bottom:14px; display:flex; align-items:center; gap:14px; flex-wrap:wrap;">
                <span style="font-size:12px; color:#94a3b8;">FUERZA / ENERGÍA ($E_m$): <strong id="fb-force-val" style="color:#38bdf8; font-size:16px; font-family:monospace;">49.4 J</strong></span>
                <div style="flex:1; height:12px; background:#1e293b; border-radius:99px; overflow:hidden; min-width:160px;">
                    <div id="fb-force-bar" style="width:20%; height:100%; background:#38bdf8; transition:0.2s;"></div>
                </div>
                <span id="fb-state-txt" style="font-size:12px; font-family:monospace; color:#4ade80;">🛡️ Robot Servicial</span>
            </div>

            <!-- Tabla Interactiva (Innova Mate) -->
            <h4 style="color:#c084fc; font-size:13px; margin-bottom:8px;">📊 Tabla Interactiva: $E_m = 0.5mv^2 + 9.8mh$</h4>
            <table style="width:100%; border-collapse:collapse; font-size:12px; font-family:monospace; text-align:center;">
                <thead>
                    <tr style="background:rgba(56,189,248,0.12); color:#38bdf8;">
                        <th style="padding:8px; border:1px solid rgba(255,255,255,0.1);">Fase / Escena</th>
                        <th style="padding:8px; border:1px solid rgba(255,255,255,0.1);">Masa m (kg)</th>
                        <th style="padding:8px; border:1px solid rgba(255,255,255,0.1);">Velocidad v (m/s)</th>
                        <th style="padding:8px; border:1px solid rgba(255,255,255,0.1);">Altura h (m)</th>
                        <th style="padding:8px; border:1px solid rgba(255,255,255,0.1);">Golpes</th>
                        <th style="padding:8px; border:1px solid rgba(255,255,255,0.1);">Energía (Em)</th>
                        <th style="padding:8px; border:1px solid rgba(255,255,255,0.1);">Sandbox</th>
                    </tr>
                </thead>
                <tbody id="fb-tbody">
                    <tr>
                        <td style="padding:6px; border:1px solid rgba(255,255,255,0.1);">1. Salto al Techo (Speed Up)</td>
                        <td style="border:1px solid rgba(255,255,255,0.1);"><input type="number" value="2.5" step="0.5" style="width:65px; background:#060913; color:#fff; border:1px solid #334155; text-align:center;" oninput="fbCalc()"></td>
                        <td style="border:1px solid rgba(255,255,255,0.1);"><input type="number" value="4.0" step="0.5" style="width:65px; background:#060913; color:#fff; border:1px solid #334155; text-align:center;" oninput="fbCalc()"></td>
                        <td style="border:1px solid rgba(255,255,255,0.1);"><input type="number" value="1.2" step="0.5" style="width:65px; background:#060913; color:#fff; border:1px solid #334155; text-align:center;" oninput="fbCalc()"></td>
                        <td style="border:1px solid rgba(255,255,255,0.1);"><input type="number" value="0" step="10" style="width:65px; background:#060913; color:#fff; border:1px solid #334155; text-align:center;" oninput="fbCalc()"></td>
                        <td class="fb-res" style="color:#4ade80; font-weight:bold; border:1px solid rgba(255,255,255,0.1);">49.4 J</td>
                        <td style="padding:6px; border:1px solid rgba(255,255,255,0.1);"><button class="ui-btn" style="padding:4px 10px; font-size:11px;" onclick="fbTest(this)">⚡ Impulsar</button></td>
                    </tr>
                    <tr>
                        <td style="padding:6px; border:1px solid rgba(255,255,255,0.1);">2. Escombros Flotantes (Jumping)</td>
                        <td style="border:1px solid rgba(255,255,255,0.1);"><input type="number" value="3.5" step="0.5" style="width:65px; background:#060913; color:#fff; border:1px solid #334155; text-align:center;" oninput="fbCalc()"></td>
                        <td style="border:1px solid rgba(255,255,255,0.1);"><input type="number" value="7.5" step="0.5" style="width:65px; background:#060913; color:#fff; border:1px solid #334155; text-align:center;" oninput="fbCalc()"></td>
                        <td style="border:1px solid rgba(255,255,255,0.1);"><input type="number" value="4.0" step="0.5" style="width:65px; background:#060913; color:#fff; border:1px solid #334155; text-align:center;" oninput="fbCalc()"></td>
                        <td style="border:1px solid rgba(255,255,255,0.1);"><input type="number" value="350" step="10" style="width:65px; background:#060913; color:#fff; border:1px solid #334155; text-align:center;" oninput="fbCalc()"></td>
                        <td class="fb-res" style="color:#4ade80; font-weight:bold; border:1px solid rgba(255,255,255,0.1);">235.6 J</td>
                        <td style="padding:6px; border:1px solid rgba(255,255,255,0.1);"><button class="ui-btn" style="padding:4px 10px; font-size:11px;" onclick="fbTest(this)">⚡ Impulsar</button></td>
                    </tr>
                    <tr>
                        <td style="padding:6px; border:1px solid rgba(255,255,255,0.1);">3. Súper Golpe Monstruo (Shoot)</td>
                        <td style="border:1px solid rgba(255,255,255,0.1);"><input type="number" value="8.0" step="0.5" style="width:65px; background:#060913; color:#fff; border:1px solid #334155; text-align:center;" oninput="fbCalc()"></td>
                        <td style="border:1px solid rgba(255,255,255,0.1);"><input type="number" value="14.0" step="0.5" style="width:65px; background:#060913; color:#fff; border:1px solid #334155; text-align:center;" oninput="fbCalc()"></td>
                        <td style="border:1px solid rgba(255,255,255,0.1);"><input type="number" value="6.0" step="0.5" style="width:65px; background:#060913; color:#fff; border:1px solid #334155; text-align:center;" oninput="fbCalc()"></td>
                        <td style="border:1px solid rgba(255,255,255,0.1);"><input type="number" value="760" step="10" style="width:65px; background:#060913; color:#fff; border:1px solid #334155; text-align:center;" oninput="fbCalc()"></td>
                        <td class="fb-res" style="color:#4ade80; font-weight:bold; border:1px solid rgba(255,255,255,0.1);">1254.4 J</td>
                        <td style="padding:6px; border:1px solid rgba(255,255,255,0.1);"><button class="ui-btn" style="padding:4px 10px; font-size:11px;" onclick="fbTest(this)">💥 Impulsar</button></td>
                    </tr>
                </tbody>
            </table>
        </div>
        <script>
            window.fbCalc = function() {
                document.querySelectorAll('#fb-tbody tr').forEach(tr => {
                    const ins = tr.querySelectorAll('input');
                    const m = parseFloat(ins[0].value)||0, v = parseFloat(ins[1].value)||0, h = parseFloat(ins[2].value)||0;
                    const em = (0.5 * m * v * v) + (9.8 * m * h);
                    tr.querySelector('.fb-res').textContent = em.toFixed(1) + ' J';
                });
            };
            window.fbTest = function(btn) {
                const ins = btn.closest('tr').querySelectorAll('input');
                const m = parseFloat(ins[0].value)||1, v = parseFloat(ins[1].value)||0, h = parseFloat(ins[2].value)||0, hits = parseInt(ins[3].value)||0;
                const em = (0.5 * m * v * v) + (9.8 * m * h);
                document.getElementById('fb-force-val').textContent = em.toFixed(1) + ' J';
                const bar = document.getElementById('fb-force-bar');
                bar.style.width = Math.min(100, Math.max(8, (em / 1300) * 100)) + '%';
                bar.style.background = hits >= 760 ? '#ef4444' : '#38bdf8';
                const st = document.getElementById('fb-state-txt');
                st.textContent = hits >= 760 ? '⚠️ MODO MONSTRUO (760+ Golpes)' : '🛡️ Robot Servicial (' + hits + '/760)';
                st.style.color = hits >= 760 ? '#ef4444' : '#4ade80';

                if (window.gameRuntime && window.gameRuntime.getPlayer) {
                    const p = window.gameRuntime.getPlayer();
                    if (p) {
                        p.vy = -Math.min(760, 260 + h * 60 + v * 15);
                        p.vx = Math.min(460, 100 + v * 20);
                        window.gameRuntime.playSfx(hits >= 760 ? 'damage' : 'pad');
                        window.gameRuntime.addPopup(p.x, p.y - 15, (hits >= 760 ? 'MONSTRUO: ' : 'Em: ') + em.toFixed(1) + ' J', hits >= 760 ? '#ef4444' : '#38bdf8');
                    }
                }
            };
        </script>`;

        return baseHTML.replace('</main>', customUI + '</main>');
    }
}

new ForkbotSandboxWindow().start();