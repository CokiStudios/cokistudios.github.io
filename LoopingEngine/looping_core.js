// ═══════════════════════════════════════════════════════════════
//  LOOPING COMPILE — CORE RUNTIME & GRAPHIC ENGINE v1.0.0 Commercial
//  Architecture Core: 2.8A (Quantum Signature & Universal Modules)
//  Next-Gen 2D Game & Native UI Runtime for Coki Studios & Loop OS
//  Developed by Holo Entertainment & Coki Studios © 2026
// ═══════════════════════════════════════════════════════════════

export class LoopingInterpreter {
    constructor(canvas, terminalOutput) {
        this.canvas = canvas;
        this.ctx = canvas ? canvas.getContext('2d') : null;
        this.terminalOutput = terminalOutput || console.log;
        
        // Virtual Machine & System State
        this.systemTarget = "Holo Looping Runtime Core";
        this.targetPlatform = "Shine Loop Game Runtime";
        
        this.variables = {};
        this.functions = {};
        this.gameEntities = [];
        this.renderQueue = [];
        this.particles = [];
        this.projectiles = [];
        this.popups = [];
        this.sounds = {};
        this.theme = 'dark_neon';
        this.isRunning = false;
        this.animationFrameId = null;
        this.lastTime = 0;
        this.fps = 60;
        this.score = 0;
        this.lives = 3;
        this.maxLives = 3;
        this.gameOver = false;
        this.gameWon = false;
        this.sourceCode = '';
        
        // World & Physics Configuration
        this.gravity = 980;
        this.friction = 0.82;
        this.world = { width: 1200, height: 480, hasCustomBounds: false };
        this.camera = { x: 0, y: 0, targetX: 0, targetY: 0, smooth: 0.12, shake: 0 };
        this.coyoteTime = 0.12;
        this.jumpBuffer = 0.12;
        
        // Web Audio Synthesizer Core
        this.audioCtx = null;
        
        // Input Controller State (Keyboard + Gamepad + Touch)
        this.keysDown = {};
        this.mousePos = { x: 0, y: 0 };
        this.isMouseDown = false;
        this.gamepadState = {
            dpad: { left: false, right: false, up: false, down: false },
            btnA: false, // Jump
            btnB: false, // Attack / Shoot
            btnX: false, // Dash / Special
            btnY: false
        };
        this.touchState = {
            hasTouch: false,
            left: false, right: false, up: false, down: false,
            btnA: false, btnB: false
        };
        
        this.setupInputListeners();
    }
    
    setupInputListeners() {
        if (!this.canvas) return;
        
        const ensureAudio = () => {
            try {
                if (!this.audioCtx) {
                    const AudioCtx = window.AudioContext || window.webkitAudioContext;
                    if (AudioCtx) this.audioCtx = new AudioCtx();
                }
                if (this.audioCtx && this.audioCtx.state === 'suspended') {
                    this.audioCtx.resume();
                }
            } catch (e) {}
        };

        window.addEventListener('keydown', (e) => {
            ensureAudio();
            const key = e.key.toLowerCase();
            this.keysDown[key] = true;
            this.keysDown[e.code.toLowerCase()] = true;
            
            // Map to Shine Loop Gamepad Buttons
            if (key === 'a' || key === 'arrowleft') this.gamepadState.dpad.left = true;
            if (key === 'd' || key === 'arrowright') this.gamepadState.dpad.right = true;
            if (key === 'w' || key === 'arrowup' || key === ' ') {
                this.gamepadState.btnA = true;
                this.gamepadState.dpad.up = true;
                // Buffer jump
                const p = this.getPlayer();
                if (p) p.jumpBufferTimer = this.jumpBuffer;
            }
            if (key === 's' || key === 'arrowdown') this.gamepadState.dpad.down = true;
            if (key === 'j' || key === 'z' || key === 'enter') {
                this.gamepadState.btnB = true;
                const p = this.getPlayer();
                if (p && !this.gameOver && !this.gameWon) this.shootProjectile(p);
            }
            if (key === 'k' || key === 'x' || key === 'shift') {
                this.gamepadState.btnX = true;
                const p = this.getPlayer();
                if (p) this.triggerDash(p);
            }
            if (key === 'r') {
                if (this.gameOver || this.gameWon) {
                    this.restartGame();
                }
            }
            
            this.triggerEvent('keydown', e.key);
        });
        
        window.addEventListener('keyup', (e) => {
            const key = e.key.toLowerCase();
            this.keysDown[key] = false;
            this.keysDown[e.code.toLowerCase()] = false;
            
            if (key === 'a' || key === 'arrowleft') this.gamepadState.dpad.left = false;
            if (key === 'd' || key === 'arrowright') this.gamepadState.dpad.right = false;
            if (key === 'w' || key === 'arrowup' || key === ' ') {
                this.gamepadState.btnA = false;
                this.gamepadState.dpad.up = false;
            }
            if (key === 's' || key === 'arrowdown') this.gamepadState.dpad.down = false;
            if (key === 'j' || key === 'z' || key === 'enter') this.gamepadState.btnB = false;
            if (key === 'k' || key === 'x' || key === 'shift') this.gamepadState.btnX = false;
            
            this.triggerEvent('keyup', e.key);
        });
        
        this.canvas.addEventListener('mousemove', (e) => {
            const rect = this.canvas.getBoundingClientRect();
            const scaleX = this.canvas.width / rect.width;
            const scaleY = this.canvas.height / rect.height;
            this.mousePos.x = (e.clientX - rect.left) * scaleX;
            this.mousePos.y = (e.clientY - rect.top) * scaleY;
        });
        
        this.canvas.addEventListener('mousedown', (e) => {
            ensureAudio();
            this.isMouseDown = true;
            this.triggerEvent('click', this.mousePos);

            if (this.gameOver || this.gameWon) {
                this.restartGame();
                return;
            }

            // Interactive Button Click Dispatcher (CS Button System)
            for (let elem of this.renderQueue) {
                if (elem.type === 'button') {
                    if (this.mousePos.x >= elem.x && this.mousePos.x <= elem.x + elem.w &&
                        this.mousePos.y >= elem.y && this.mousePos.y <= elem.y + elem.h) {
                        
                        elem.isPressed = true;
                        this.log(`[BUTTON CLICK] Triggered action: "${elem.action || elem.text}"`, 'success');
                        this.playSfx('coin');

                        if (elem.action && typeof this.functions[elem.action] === 'function') {
                            this.functions[elem.action]();
                        } else if (elem.action === 'launch_arcade' || elem.action === 'launch_forkar') {
                            this.log(`[LAUNCHER] Booting game module: ${elem.action} @ 60 FPS...`, 'system');
                        }
                    }
                }
            }

            // Check touch controls click / tap
            this.handleVirtualControlClick(this.mousePos.x, this.mousePos.y, true);
        });
        
        this.canvas.addEventListener('mouseup', () => {
            this.isMouseDown = false;
            for (let elem of this.renderQueue) {
                if (elem.type === 'button') elem.isPressed = false;
            }
            this.handleVirtualControlClick(0, 0, false);
        });

        // Touch Listeners for Mobile & iPad (Universal Responsive Controls)
        const handleTouch = (e) => {
            ensureAudio();
            this.touchState.hasTouch = true;
            const rect = this.canvas.getBoundingClientRect();
            const scaleX = this.canvas.width / rect.width;
            const scaleY = this.canvas.height / rect.height;

            if (this.gameOver || this.gameWon) {
                this.restartGame();
                return;
            }

            // Reset touch state
            this.touchState.left = false;
            this.touchState.right = false;
            this.touchState.up = false;
            this.touchState.btnA = false;
            this.touchState.btnB = false;

            for (let i = 0; i < e.touches.length; i++) {
                const t = e.touches[i];
                const tx = (t.clientX - rect.left) * scaleX;
                const ty = (t.clientY - rect.top) * scaleY;
                this.evaluateTouchCoordinate(tx, ty);
            }
        };

        this.canvas.addEventListener('touchstart', (e) => {
            e.preventDefault();
            handleTouch(e);
        }, { passive: false });

        this.canvas.addEventListener('touchmove', (e) => {
            e.preventDefault();
            handleTouch(e);
        }, { passive: false });

        this.canvas.addEventListener('touchend', (e) => {
            e.preventDefault();
            if (e.touches.length === 0) {
                this.touchState.left = false;
                this.touchState.right = false;
                this.touchState.up = false;
                this.touchState.btnA = false;
                this.touchState.btnB = false;
            } else {
                handleTouch(e);
            }
        }, { passive: false });
    }

    evaluateTouchCoordinate(tx, ty) {
        const h = this.canvas.height;
        const w = this.canvas.width;

        // Bottom Left D-Pad region
        if (tx < 180 && ty > h - 140) {
            if (tx < 85) this.touchState.left = true;
            else if (tx > 95) this.touchState.right = true;
            if (ty < h - 70) this.touchState.up = true;
        }

        // Bottom Right Action buttons region
        if (tx > w - 180 && ty > h - 140) {
            if (tx > w - 90) {
                this.touchState.btnA = true; // Jump
                const p = this.getPlayer();
                if (p) p.jumpBufferTimer = this.jumpBuffer;
            } else {
                this.touchState.btnB = true; // Shoot
                const p = this.getPlayer();
                if (p && !this.gameOver && !this.gameWon) this.shootProjectile(p);
            }
        }
    }

    handleVirtualControlClick(x, y, isDown) {
        if (!isDown) {
            this.touchState.left = false;
            this.touchState.right = false;
            this.touchState.btnA = false;
            this.touchState.btnB = false;
            return;
        }
        this.evaluateTouchCoordinate(x, y);
    }

    getPlayer() {
        return this.gameEntities.find(e => e.isPlayer);
    }

    triggerDash(player) {
        if (player.dashCooldown <= 0 && !this.gameOver && !this.gameWon) {
            player.isDashing = true;
            player.dashTimer = 0.18;
            player.dashCooldown = 0.6;
            player.vx = (player.facing || 1) * 620;
            player.vy = 0;
            this.playSfx('dash');
            this.spawnParticleBurst(player.x + player.w / 2, player.y + player.h / 2, '#00f5d4', 22);
            this.addPopup(player.x, player.y - 12, 'DASH!', '#00f5d4');
        }
    }

    shootProjectile(player) {
        const now = performance.now();
        if (player.lastShotTime && now - player.lastShotTime < 200) return;
        player.lastShotTime = now;

        const dir = player.facing || 1;
        const px = dir > 0 ? player.x + player.w + 2 : player.x - 14;
        const py = player.y + player.h * 0.42;

        this.projectiles.push({
            type: 'projectile',
            x: px,
            y: py,
            vx: dir * 580,
            vy: 0,
            w: 14,
            h: 5,
            color: player.color || '#38bdf8',
            isPlayer: true,
            damage: 25,
            life: 1.4
        });

        this.playSfx('shoot');
        this.spawnParticleBurst(px, py, '#38bdf8', 6);
    }

    // ── Web Audio Synthesizer (Zero External Dependencies) ──
    playSfx(type) {
        try {
            const AudioCtx = window.AudioContext || window.webkitAudioContext;
            if (!AudioCtx) return;
            if (!this.audioCtx) this.audioCtx = new AudioCtx();
            if (this.audioCtx.state === 'suspended') this.audioCtx.resume();
            
            const ctx = this.audioCtx;
            const now = ctx.currentTime;

            if (type === 'jump') {
                const osc = ctx.createOscillator();
                const gain = ctx.createGain();
                osc.type = 'sine';
                osc.frequency.setValueAtTime(260, now);
                osc.frequency.exponentialRampToValueAtTime(620, now + 0.12);
                gain.gain.setValueAtTime(0.12, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);
                osc.connect(gain);
                gain.connect(ctx.destination);
                osc.start(now);
                osc.stop(now + 0.12);
            } else if (type === 'double_jump') {
                const osc = ctx.createOscillator();
                const gain = ctx.createGain();
                osc.type = 'triangle';
                osc.frequency.setValueAtTime(520, now);
                osc.frequency.exponentialRampToValueAtTime(920, now + 0.14);
                gain.gain.setValueAtTime(0.14, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.14);
                osc.connect(gain);
                gain.connect(ctx.destination);
                osc.start(now);
                osc.stop(now + 0.14);
            } else if (type === 'dash') {
                const osc = ctx.createOscillator();
                const gain = ctx.createGain();
                osc.type = 'sawtooth';
                osc.frequency.setValueAtTime(320, now);
                osc.frequency.exponentialRampToValueAtTime(120, now + 0.15);
                gain.gain.setValueAtTime(0.12, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.15);
                osc.connect(gain);
                gain.connect(ctx.destination);
                osc.start(now);
                osc.stop(now + 0.15);
            } else if (type === 'coin') {
                const osc1 = ctx.createOscillator();
                const osc2 = ctx.createOscillator();
                const gain = ctx.createGain();
                osc1.type = 'sine';
                osc2.type = 'sine';
                osc1.frequency.setValueAtTime(987.77, now); // B5
                osc2.frequency.setValueAtTime(1318.51, now + 0.06); // E6
                gain.gain.setValueAtTime(0.12, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.22);
                osc1.connect(gain);
                osc2.connect(gain);
                gain.connect(ctx.destination);
                osc1.start(now);
                osc1.stop(now + 0.08);
                osc2.start(now + 0.06);
                osc2.stop(now + 0.22);
            } else if (type === 'pad') {
                const osc = ctx.createOscillator();
                const gain = ctx.createGain();
                osc.type = 'sine';
                osc.frequency.setValueAtTime(180, now);
                osc.frequency.exponentialRampToValueAtTime(860, now + 0.22);
                gain.gain.setValueAtTime(0.18, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.22);
                osc.connect(gain);
                gain.connect(ctx.destination);
                osc.start(now);
                osc.stop(now + 0.22);
            } else if (type === 'stomp') {
                const osc = ctx.createOscillator();
                const gain = ctx.createGain();
                osc.type = 'square';
                osc.frequency.setValueAtTime(160, now);
                osc.frequency.exponentialRampToValueAtTime(45, now + 0.14);
                gain.gain.setValueAtTime(0.2, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.14);
                osc.connect(gain);
                gain.connect(ctx.destination);
                osc.start(now);
                osc.stop(now + 0.14);
            } else if (type === 'hurt') {
                const osc = ctx.createOscillator();
                const gain = ctx.createGain();
                osc.type = 'sawtooth';
                osc.frequency.setValueAtTime(190, now);
                osc.frequency.exponentialRampToValueAtTime(65, now + 0.2);
                gain.gain.setValueAtTime(0.22, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.2);
                osc.connect(gain);
                gain.connect(ctx.destination);
                osc.start(now);
                osc.stop(now + 0.2);
            } else if (type === 'shoot') {
                const osc = ctx.createOscillator();
                const gain = ctx.createGain();
                osc.type = 'square';
                osc.frequency.setValueAtTime(940, now);
                osc.frequency.exponentialRampToValueAtTime(220, now + 0.08);
                gain.gain.setValueAtTime(0.09, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);
                osc.connect(gain);
                gain.connect(ctx.destination);
                osc.start(now);
                osc.stop(now + 0.08);
            } else if (type === 'heal') {
                const notes = [523.25, 659.25, 783.99]; // C5, E5, G5
                notes.forEach((freq, idx) => {
                    const osc = ctx.createOscillator();
                    const gain = ctx.createGain();
                    const t = now + idx * 0.08;
                    osc.type = 'sine';
                    osc.frequency.setValueAtTime(freq, t);
                    gain.gain.setValueAtTime(0.12, t);
                    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.18);
                    osc.connect(gain);
                    gain.connect(ctx.destination);
                    osc.start(t);
                    osc.stop(t + 0.18);
                });
            } else if (type === 'victory') {
                const notes = [587.33, 739.99, 880.00, 1174.66]; // D5, F#5, A5, D6
                notes.forEach((freq, idx) => {
                    const osc = ctx.createOscillator();
                    const gain = ctx.createGain();
                    const t = now + idx * 0.11;
                    osc.type = 'sine';
                    osc.frequency.setValueAtTime(freq, t);
                    gain.gain.setValueAtTime(0.16, t);
                    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.2);
                    osc.connect(gain);
                    gain.connect(ctx.destination);
                    osc.start(t);
                    osc.stop(t + 0.2);
                });
            } else if (type === 'gameover') {
                const notes = [349.23, 311.13, 277.18, 220.00];
                notes.forEach((freq, idx) => {
                    const osc = ctx.createOscillator();
                    const gain = ctx.createGain();
                    const t = now + idx * 0.14;
                    osc.type = 'sawtooth';
                    osc.frequency.setValueAtTime(freq, t);
                    gain.gain.setValueAtTime(0.14, t);
                    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.22);
                    osc.connect(gain);
                    gain.connect(ctx.destination);
                    osc.start(t);
                    osc.stop(t + 0.22);
                });
            }
        } catch (e) {}
    }

    addPopup(x, y, text, color = '#38bdf8') {
        this.popups.push({
            x: x,
            y: y,
            text: text,
            color: color,
            alpha: 1.0,
            vy: -48
        });
    }

    triggerGameOver() {
        if (this.gameOver) return;
        this.gameOver = true;
        this.playSfx('gameover');
        this.camera.shake = 16;
        this.log('💀 [GAME OVER] Operación terminada. Presiona [R] o Toca para Reintentar.', 'error');
    }

    triggerVictory() {
        if (this.gameWon) return;
        this.gameWon = true;
        this.score += 500;
        this.playSfx('victory');
        this.log(`🏆 [VICTORY] ¡Etapa completada con éxito! Puntaje Final: ${this.score}`, 'success');
    }

    restartGame() {
        this.log('🔄 Reiniciando misión Shine Loop...', 'system');
        this.score = 0;
        this.lives = this.maxLives;
        this.gameOver = false;
        this.gameWon = false;
        if (this.sourceCode) {
            this.execute(this.sourceCode);
        }
    }

    log(message, type = 'info') {
        if (typeof this.terminalOutput === 'function') {
            this.terminalOutput(message, type);
        } else {
            console.log(`[Holo-Looping-${type.toUpperCase()}]:`, message);
        }
    }

    reset() {
        if (this.animationFrameId) {
            cancelAnimationFrame(this.animationFrameId);
            this.animationFrameId = null;
        }
        this.isRunning = false;
        this.variables = {};
        this.functions = {};
        this.gameEntities = [];
        this.renderQueue = [];
        this.particles = [];
        this.projectiles = [];
        this.popups = [];
        this.camera = { x: 0, y: 0, targetX: 0, targetY: 0, smooth: 0.12, shake: 0 };
        this.world = { width: this.canvas ? this.canvas.width : 1200, height: this.canvas ? this.canvas.height : 480, hasCustomBounds: false };
        this.gameOver = false;
        this.gameWon = false;
        if (this.ctx && this.canvas) {
            this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        }
    }

    // ── AST & Lexer Compiler ──
    execute(code) {
        this.sourceCode = code;
        this.reset();
        this.log("⚙️ Compilando Código Fuente Looping v1.0 Commercial (Arch 2.8A)...", "system");
        
        const lines = code.split(/\r?\n/);
        let i = 0;

        while (i < lines.length) {
            let line = lines[i].trim();
            i++;

            if (!line || line.startsWith('#') || line.startsWith('//')) continue;

            // Multiline Python Block: python { ... } OR py: ... end
            if (line.startsWith('python {') || line === 'python:' || line === 'py:' || line.startsWith('py:begin')) {
                let pyBlockLines = [];
                if (line.startsWith('python {') && line.endsWith('}')) {
                    pyBlockLines.push(line.slice(8, -1).trim());
                } else {
                    while (i < lines.length) {
                        const nextLine = lines[i];
                        i++;
                        const trimmedNext = nextLine.trim();
                        if (trimmedNext === '}' || trimmedNext === 'end' || trimmedNext === 'py:end') {
                            break;
                        }
                        pyBlockLines.push(nextLine);
                    }
                }
                const pyCode = pyBlockLines.join('\n');
                this.log(`[PYTHON BLOCK] Interpretando módulo Python integrado (${pyBlockLines.length} líneas)...`, 'system');
                this.executePythonSimulation(pyCode);
                continue;
            }

            // Function Definition: function <name>(<args>) { ... }
            if (line.startsWith('function ') || line.startsWith('def ')) {
                const fnMatch = line.match(/(?:function|def)\s+([A-Za-z0-9_]+)\s*\((.*?)\)\s*\{?/);
                if (fnMatch) {
                    const fnName = fnMatch[1];
                    const fnParams = fnMatch[2].split(',').map(s => s.trim()).filter(Boolean);
                    const bodyLines = [];

                    while (i < lines.length) {
                        const nextLine = lines[i];
                        i++;
                        if (nextLine.trim() === '}' || nextLine.trim() === 'end') break;
                        bodyLines.push(nextLine);
                    }

                    this.functions[fnName] = { params: fnParams, body: bodyLines.join('\n') };
                    this.log(`[FUNCTION] Registrada función "${fnName}" (${fnParams.length} parámetros)`, 'info');
                    continue;
                }
            }

            // Loop / Repeat: repeat <N> times { ... } OR loop <N> { ... }
            if (line.startsWith('repeat ') || line.startsWith('loop ')) {
                const countMatch = line.match(/(?:repeat|loop)\s+(\d+|[A-Za-z0-9_]+)\s*(?:times)?\s*\{?/i);
                if (countMatch) {
                    const countVal = Number(this.evaluateExpression(countMatch[1])) || 0;
                    const bodyLines = [];
                    while (i < lines.length) {
                        const nextLine = lines[i];
                        i++;
                        if (nextLine.trim() === '}' || nextLine.trim() === 'end') break;
                        bodyLines.push(nextLine);
                    }
                    const loopScript = bodyLines.join('\n');
                    for (let c = 0; c < countVal; c++) {
                        this.variables['i'] = c;
                        this.variables['loop_index'] = c;
                        this.executeSubScript(loopScript);
                    }
                    continue;
                }
            }

            try {
                this.parseLine(line);
            } catch (err) {
                this.log(`❌ [Syntax Error at line ${i}]: ${err.message}`, "error");
                return false;
            }
        }

        // Adjust world bounds if not explicitly set
        if (!this.world.hasCustomBounds && this.canvas) {
            let maxX = this.canvas.width;
            for (let ent of this.gameEntities) {
                if (ent.x + (ent.w || 40) > maxX) maxX = ent.x + (ent.w || 40) + 100;
            }
            this.world.width = Math.max(this.canvas.width, maxX);
            this.world.height = this.canvas.height;
        }

        this.log("✨ Compilación 2D Completa. Inicializando pipeline gráfico Shine Loop @ 60 FPS...", "success");
        this.startLoop();
        return true;
    }

    executeSubScript(script) {
        const lines = script.split(/\r?\n/);
        for (let l of lines) {
            let line = l.trim();
            if (!line || line.startsWith('#') || line.startsWith('//')) continue;
            this.parseLine(line);
        }
    }

    executePythonSimulation(pyCode) {
        try {
            const lines = pyCode.split('\n');
            for (let raw of lines) {
                const line = raw.trim();
                if (!line || line.startsWith('#')) continue;

                const assignMatch = line.match(/^([A-Za-z0-9_]+)\s*=\s*(.*)$/);
                if (assignMatch) {
                    const k = assignMatch[1];
                    const v = assignMatch[2];
                    this.variables[k] = this.evaluateExpression(v);
                } else if (line.startsWith('print(')) {
                    const pMatch = line.match(/print\((.*)\)/);
                    if (pMatch) {
                        this.log(`[PYTHON] ${this.parsePrint(pMatch[1])}`, 'output');
                    }
                }
            }
        } catch (e) {
            this.log(`[PYTHON ERROR] ${e.message}`, 'error');
        }
    }

    // Helper: Parse named arguments like at: (120, 380), size: (32, 44), color: "#38bdf8"
    parseNamedArgs(argStr) {
        const res = {};
        if (!argStr) return res;
        const regex = /([A-Za-z0-9_]+)\s*:\s*(\([^)]+\)|"[^"]*"|'[^']*'|[^,]+)/g;
        let match;
        while ((match = regex.exec(argStr)) !== null) {
            const key = match[1].trim();
            let val = match[2].trim();
            if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
                res[key] = val.slice(1, -1);
            } else if (val.startsWith('(') && val.endsWith(')')) {
                const parts = val.slice(1, -1).split(',').map(s => parseFloat(s.trim()));
                res[key] = parts;
            } else if (!isNaN(val)) {
                res[key] = parseFloat(val);
            } else if (val === 'true') res[key] = true;
            else if (val === 'false') res[key] = false;
            else res[key] = val;
        }
        return res;
    }

    parseLine(line) {
        // 1. Module Imports
        if (line.startsWith('import ') && !line.startsWith('import python ')) {
            const modulePath = line.replace('import ', '').trim();
            this.log(`[MODULE LOADER] Vinculado módulo: ${modulePath}`, 'system');
            return;
        }

        // 1.1 Python Imports
        if (line.startsWith('use python ') || line.startsWith('import python ')) {
            const pyLib = line.replace(/^(use|import) python /, '').trim().replace(/['"]/g, '');
            this.log(`[PYTHON BRIDGE] Enlace de biblioteca: ${pyLib}`, 'system');
            return;
        }

        // 2. App & Game Definition
        if (line.startsWith('define app') || line.startsWith('define game')) {
            let appName = 'HoloGame';
            const quoteMatch = line.match(/define (?:app|game)\s*(?:as)?\s*["'](.*?)["']/);
            const asMatch = line.match(/define (?:app|game)\s+as\s+([A-Za-z0-9_]+)/);
            if (quoteMatch) appName = quoteMatch[1];
            else if (asMatch) appName = asMatch[1];
            
            this.log(`[APP] Registrado título: "${appName}" en Shine Loop Console`, 'info');
            return;
        }

        // 3. UI System Profile
        if (line.startsWith('set ui_profile to') || line.startsWith('set ui_profile as') || line.startsWith('set ui to')) {
            const match = line.match(/set (?:ui_profile|ui) (?:to|as) ["'](.*?)["']/);
            if (match) {
                this.uiProfile = match[1].toLowerCase();
                this.log(`[CS DESIGN UI] Perfil UI cargado: "${this.uiProfile.toUpperCase()}"`, 'info');
            }
            return;
        }

        // 4. Theme configuration
        if (line.startsWith('set theme to') || line.startsWith('set theme as')) {
            const match = line.match(/set theme (?:to|as) ["'](.*?)["']/);
            if (match) this.theme = match[1];
            return;
        }

        // 5. Game Configuration Directives (Gravity, World, Friction, Lives)
        if (line.startsWith('game.gravity(') || line.startsWith('set gravity to ')) {
            const m = line.match(/(?:game\.gravity\(|set gravity to\s+)([\d.]+)/);
            if (m) {
                this.gravity = parseFloat(m[1]);
                this.log(`[PHYSICS] Gravedad configurada: ${this.gravity} px/s²`, 'system');
            }
            return;
        }

        if (line.startsWith('game.friction(') || line.startsWith('set friction to ')) {
            const m = line.match(/(?:game\.friction\(|set friction to\s+)([\d.]+)/);
            if (m) {
                this.friction = parseFloat(m[1]);
                this.log(`[PHYSICS] Fricción de superficie: ${this.friction}`, 'system');
            }
            return;
        }

        if (line.startsWith('game.world(') || line.startsWith('set world_size to ')) {
            const sizeMatch = line.match(/\((\d+),\s*(\d+)\)/);
            if (sizeMatch) {
                this.world.width = parseInt(sizeMatch[1]);
                this.world.height = parseInt(sizeMatch[2]);
                this.world.hasCustomBounds = true;
                this.log(`[WORLD] Dimensiones de nivel configuradas: ${this.world.width}x${this.world.height}px`, 'info');
            }
            return;
        }

        if (line.startsWith('game.lives(') || line.startsWith('set lives to ')) {
            const m = line.match(/(?:game\.lives\(|set lives to\s+)(\d+)/);
            if (m) {
                this.lives = parseInt(m[1]);
                this.maxLives = this.lives;
                this.log(`[GAME] Vidas iniciales: ${this.lives}`, 'info');
            }
            return;
        }

        // 6. Window Canvas: create window with title "Title" and size (width, height)
        if (line.startsWith('create window')) {
            const titleMatch = line.match(/title ["'](.*?)["']/);
            const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
            if (sizeMatch && this.canvas) {
                this.canvas.width = parseInt(sizeMatch[1]);
                this.canvas.height = parseInt(sizeMatch[2]);
            }
            if (titleMatch) {
                this.log(` Modo de Visualización Shine Loop: "${titleMatch[1]}" (${this.canvas.width}x${this.canvas.height})`, 'info');
            }
            return;
        }

        // 7. Bubbly Dot Component
        if (line.startsWith('spawn bubbly_dot') || line.startsWith('draw bubbly_dot')) {
            const textMatch = line.match(/text ["'](.*?)["']/);
            const stateMatch = line.match(/state ["'](.*?)["']/);
            this.bubblyDot = {
                active: true,
                text: textMatch ? textMatch[1] : 'Shine Audio Active',
                state: stateMatch ? stateMatch[1] : 'music',
                pulse: 0
            };
            return;
        }

        // 8. Conditional Logic
        if (line.startsWith('if ')) {
            const conditionMatch = line.match(/^if\s+(.*?)\s+(?:then|do)\s+(.*)$/i);
            if (conditionMatch) {
                const condition = conditionMatch[1];
                const action = conditionMatch[2];
                if (this.evaluateCondition(condition)) {
                    this.parseLine(action);
                }
                return;
            }
        }

        // 9. Input Field UI Component
        if (line.startsWith('draw input at')) {
            const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
            const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
            const placeMatch = line.match(/placeholder ["'](.*?)["']/);
            const varMatch = line.match(/var ["'](.*?)["']/);

            this.renderQueue.push({
                type: 'input',
                x: posMatch ? parseInt(posMatch[1]) : 50,
                y: posMatch ? parseInt(posMatch[2]) : 200,
                w: sizeMatch ? parseInt(sizeMatch[1]) : 260,
                h: sizeMatch ? parseInt(sizeMatch[2]) : 40,
                placeholder: placeMatch ? placeMatch[1] : 'Type here...',
                targetVar: varMatch ? varMatch[1] : 'user_input',
                value: ''
            });
            return;
        }

        // 10. Variables: set <var> to <value>
        if (line.startsWith('set ') && (line.includes(' to ') || line.includes(' as ') || line.includes(' = '))) {
            let delimiter = ' to ';
            if (line.includes(' to ')) delimiter = ' to ';
            else if (line.includes(' as ')) delimiter = ' as ';
            else if (line.includes(' = ')) delimiter = ' = ';

            const parts = line.replace('set ', '').split(delimiter);
            const varName = parts[0].trim();
            const valExpr = parts.slice(1).join(delimiter).trim();
            this.variables[varName] = this.evaluateExpression(valExpr);
            return;
        }

        // Shorthand assignments: x = 10, x += 5
        const assignMatch = line.match(/^([A-Za-z0-9_]+)\s*(\+=|-=|\*=|\/=|=)\s*(.*)$/);
        if (assignMatch && !line.startsWith('create ') && !line.startsWith('draw ') && !line.startsWith('spawn ')) {
            const varName = assignMatch[1];
            const op = assignMatch[2];
            const expr = assignMatch[3];
            const val = this.evaluateExpression(expr);

            if (op === '=') this.variables[varName] = val;
            else if (op === '+=') this.variables[varName] = (Number(this.variables[varName]) || 0) + Number(val);
            else if (op === '-=') this.variables[varName] = (Number(this.variables[varName]) || 0) - Number(val);
            else if (op === '*=') this.variables[varName] = (Number(this.variables[varName]) || 0) * Number(val);
            else if (op === '/=') this.variables[varName] = (Number(this.variables[varName]) || 0) / Number(val);
            return;
        }

        // 11. Function Calls: call <fn>()
        if (line.startsWith('call ')) {
            const callMatch = line.match(/call\s+([A-Za-z0-9_]+)\s*(?:\((.*?)\))?/);
            if (callMatch) {
                const fnName = callMatch[1];
                if (this.functions[fnName]) {
                    this.executeSubScript(this.functions[fnName].body);
                }
                return;
            }
        }

        // 12. Print output
        if (line.startsWith('print ') || line.startsWith('echo ')) {
            const expr = line.replace(/^(print|echo)\s+/, '').trim();
            const val = this.parsePrint(expr);
            this.log(val, 'output');
            return;
        }

        // 13. System Calls & Kernel Control
        if (line.startsWith('syscall')) {
            const match = line.match(/syscall\s+([A-Za-z0-9_]+)(?:\s+with\s+args\s+["'](.*?)["'])?/);
            if (match) {
                this.log(`[KERNEL SYSCALL] 0x${Math.floor(Math.random() * 0xFFFFFF).toString(16).toUpperCase()} :: ${match[1]}() -> OK`, 'system');
            }
            return;
        }

        // 14. Hardware Audio Tone
        if (line.startsWith('play tone') || line.startsWith('audio.tone(')) {
            const freqMatch = line.match(/(?:at\s+|freq:\s*|tone\()(\d+)/i);
            const durMatch = line.match(/(?:for\s+|dur:\s*|,\s*)(\d+)\s*(?:ms|\))/i);
            const freq = freqMatch ? parseInt(freqMatch[1]) : 440;
            const dur = durMatch ? parseInt(durMatch[1]) : 100;
            try {
                if (!this.audioCtx) {
                    const AudioCtx = window.AudioContext || window.webkitAudioContext;
                    if (AudioCtx) this.audioCtx = new AudioCtx();
                }
                if (this.audioCtx) {
                    const ctx = this.audioCtx;
                    const osc = ctx.createOscillator();
                    const gain = ctx.createGain();
                    osc.type = 'sine';
                    osc.frequency.setValueAtTime(freq, ctx.currentTime);
                    gain.gain.setValueAtTime(0.1, ctx.currentTime);
                    gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + (dur / 1000));
                    osc.connect(gain);
                    gain.connect(ctx.destination);
                    osc.start();
                    osc.stop(ctx.currentTime + (dur / 1000));
                }
            } catch (e) {}
            this.log(`[AUDIO HARDWARE] Tono sintetizado: ${freq}Hz (${dur}ms)`, 'system');
            return;
        }

        // 15. UI Card & Button
        if (line.startsWith('draw card at')) {
            const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
            const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
            const titleMatch = line.match(/title ["'](.*?)["']/);
            const textMatch = line.match(/text ["'](.*?)["']/);
            
            this.renderQueue.push({
                type: 'card',
                x: posMatch ? parseInt(posMatch[1]) : 50,
                y: posMatch ? parseInt(posMatch[2]) : 50,
                w: sizeMatch ? parseInt(sizeMatch[1]) : 300,
                h: sizeMatch ? parseInt(sizeMatch[2]) : 140,
                title: titleMatch ? titleMatch[1] : 'Holo UI Card',
                text: textMatch ? textMatch[1] : ''
            });
            return;
        }

        if (line.startsWith('draw button at')) {
            const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
            const textMatch = line.match(/text ["'](.*?)["']/);
            const actionMatch = line.match(/action ["'](.*?)["']/);
            
            this.renderQueue.push({
                type: 'button',
                x: posMatch ? parseInt(posMatch[1]) : 50,
                y: posMatch ? parseInt(posMatch[2]) : 200,
                w: 180,
                h: 44,
                text: textMatch ? textMatch[1] : 'Shine Action',
                action: actionMatch ? actionMatch[1] : ''
            });
            return;
        }

        // ═══════════════════════════════════════════════════════════════
        //  2D GAME ENTITY SPAWNERS (Classic & Modern Functional Syntax)
        // ═══════════════════════════════════════════════════════════════

        // 16. Player / Sprite: spawn sprite / spawn.sprite / spawn.player / spawn player
        if (line.startsWith('spawn sprite') || line.startsWith('spawn.sprite') || 
            line.startsWith('spawn.player') || line.startsWith('spawn player')) {
            
            let name = 'Angel Helium';
            let x = 100, y = 300, w = 34, h = 46;
            let color = '#38bdf8';
            let speed = 270;
            let jumpForce = 430;
            let health = 100;
            let doubleJump = true;

            if (line.includes('(') && (line.startsWith('spawn.sprite(') || line.startsWith('spawn.player('))) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.name) name = args.name;
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.size && Array.isArray(args.size)) { w = args.size[0]; h = args.size[1]; }
                if (args.color) color = args.color;
                if (args.speed) speed = args.speed;
                if (args.jump) jumpForce = args.jump;
                if (args.health) health = args.health;
                if (args.double_jump !== undefined) doubleJump = args.double_jump;
            } else {
                const nameMatch = line.match(/spawn (?:sprite|player)\s+["'](.*?)["']/);
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const colorMatch = line.match(/color ["'](.*?)["']/);
                const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
                if (nameMatch) name = nameMatch[1];
                if (posMatch) { x = parseFloat(posMatch[1]); y = parseFloat(posMatch[2]); }
                if (sizeMatch) { w = parseFloat(sizeMatch[1]); h = parseFloat(sizeMatch[2]); }
                if (colorMatch) color = colorMatch[1];
            }

            const isPlayer = line.includes('player') || name.toLowerCase().includes('angel') || 
                             name.toLowerCase().includes('player') || name.toLowerCase().includes('forky');

            const sprite = {
                type: 'sprite',
                name: name,
                isPlayer: isPlayer,
                x: x,
                y: y,
                w: w,
                h: h,
                vx: 0,
                vy: 0,
                speed: speed,
                jumpForce: jumpForce,
                health: health,
                maxHealth: health,
                color: color,
                facing: 1,
                isJumping: false,
                doubleJumpAvailable: doubleJump,
                canDoubleJump: doubleJump,
                coyoteTimer: 0,
                jumpBufferTimer: 0,
                isDashing: false,
                dashTimer: 0,
                dashCooldown: 0,
                invulnerableTimer: 0,
                squash: 1.0,
                stretch: 1.0,
                glowPulse: 0,
                lastShotTime: 0
            };

            this.gameEntities.push(sprite);
            this.log(`🎮 Entidad 2D generada: "${sprite.name}" (${isPlayer ? 'PROTAGONISTA' : 'NPC'})`, 'info');
            return;
        }

        // 17. Enemy NPC: spawn enemy / spawn.enemy
        if (line.startsWith('spawn enemy') || line.startsWith('spawn.enemy')) {
            let name = 'CorruptedForkbot';
            let x = 460, y = 300, w = 34, h = 44;
            let color = '#ef4444';
            let minX = 350, maxX = 620;
            let speed = 75;
            let health = 30;

            if (line.includes('(') && line.startsWith('spawn.enemy(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.name) name = args.name;
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.size && Array.isArray(args.size)) { w = args.size[0]; h = args.size[1]; }
                if (args.range && Array.isArray(args.range)) { minX = args.range[0]; maxX = args.range[1]; }
                if (args.color) color = args.color;
                if (args.speed) speed = args.speed;
                if (args.health) health = args.health;
            } else {
                const nameMatch = line.match(/spawn enemy\s+["'](.*?)["']/);
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
                const rangeMatch = line.match(/range \((\d+),\s*(\d+)\)/);
                const colorMatch = line.match(/color ["'](.*?)["']/);
                if (nameMatch) name = nameMatch[1];
                if (posMatch) { x = parseFloat(posMatch[1]); y = parseFloat(posMatch[2]); }
                if (sizeMatch) { w = parseFloat(sizeMatch[1]); h = parseFloat(sizeMatch[2]); }
                if (rangeMatch) { minX = parseFloat(rangeMatch[1]); maxX = parseFloat(rangeMatch[2]); }
                else { minX = x - 120; maxX = x + 120; }
                if (colorMatch) color = colorMatch[1];
            }

            const enemy = {
                type: 'enemy',
                name: name,
                x: x,
                y: y,
                w: w,
                h: h,
                vx: speed,
                vy: 0,
                speed: speed,
                dir: 1,
                minX: minX,
                maxX: maxX,
                health: health,
                maxHealth: health,
                color: color,
                isAlive: true,
                glowPulse: 0
            };
            this.gameEntities.push(enemy);
            this.log(`👾 Enemigo autónomo desplegado: "${enemy.name}" [Patrulla: ${minX}-${maxX}]`, 'info');
            return;
        }

        // 18. Moving Platform: spawn moving_platform / spawn.moving_platform
        if (line.startsWith('spawn moving_platform') || line.startsWith('spawn.moving_platform')) {
            let x = 250, y = 280, w = 130, h = 18;
            let axis = 'x';
            let minP = 200, maxP = 450;
            let speed = 75;
            let color = '#06b6d4';

            if (line.includes('(') && line.startsWith('spawn.moving_platform(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.size && Array.isArray(args.size)) { w = args.size[0]; h = args.size[1]; }
                if (args.axis) axis = args.axis;
                if (args.range && Array.isArray(args.range)) { minP = args.range[0]; maxP = args.range[1]; }
                if (args.speed) speed = args.speed;
                if (args.color) color = args.color;
            } else {
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
                const axisMatch = line.match(/axis ["'](.*?)["']/);
                const rangeMatch = line.match(/range \((\d+),\s*(\d+)\)/);
                const speedMatch = line.match(/speed (\d+)/);
                const colorMatch = line.match(/color ["'](.*?)["']/);
                if (posMatch) { x = parseFloat(posMatch[1]); y = parseFloat(posMatch[2]); }
                if (sizeMatch) { w = parseFloat(sizeMatch[1]); h = parseFloat(sizeMatch[2]); }
                if (axisMatch) axis = axisMatch[1];
                if (rangeMatch) { minP = parseFloat(rangeMatch[1]); maxP = parseFloat(rangeMatch[2]); }
                else { minP = x; maxP = x + 180; }
                if (speedMatch) speed = parseFloat(speedMatch[1]);
                if (colorMatch) color = colorMatch[1];
            }

            const mp = {
                type: 'moving_platform',
                x: x,
                y: y,
                w: w,
                h: h,
                axis: axis,
                minPos: minP,
                maxPos: maxP,
                speed: speed,
                dir: 1,
                vx: axis === 'x' ? speed : 0,
                vy: axis === 'y' ? speed : 0,
                color: color
            };
            this.gameEntities.push(mp);
            this.log(` Maglev Plataforma Móvil en (${x}, ${y}) [Eje ${axis.toUpperCase()} | Rango ${minP}-${maxP}]`, 'info');
            return;
        }

        // 19. Static Platform: spawn platform / spawn.platform
        if (line.startsWith('spawn platform') || line.startsWith('spawn.platform')) {
            let x = 200, y = 300, w = 160, h = 18;
            let color = '#6366f1';

            if (line.includes('(') && line.startsWith('spawn.platform(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.size && Array.isArray(args.size)) { w = args.size[0]; h = args.size[1]; }
                if (args.color) color = args.color;
            } else {
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
                const colorMatch = line.match(/color ["'](.*?)["']/);
                if (posMatch) { x = parseFloat(posMatch[1]); y = parseFloat(posMatch[2]); }
                if (sizeMatch) { w = parseFloat(sizeMatch[1]); h = parseFloat(sizeMatch[2]); }
                if (colorMatch) color = colorMatch[1];
            }

            const platform = {
                type: 'platform',
                x: x,
                y: y,
                w: w,
                h: h,
                color: color
            };
            this.gameEntities.push(platform);
            return;
        }

        // 20. Spikes / Hazards: spawn spike / spawn hazard / spawn.spike
        if (line.startsWith('spawn spike') || line.startsWith('spawn hazard') || line.startsWith('spawn.spike')) {
            let x = 300, y = 420, w = 34, h = 20;
            let damage = 35;
            let color = '#ef4444';

            if (line.includes('(') && line.startsWith('spawn.spike(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.size && Array.isArray(args.size)) { w = args.size[0]; h = args.size[1]; }
                if (args.damage) damage = args.damage;
                if (args.color) color = args.color;
            } else {
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
                const damMatch = line.match(/damage (\d+)/);
                const colMatch = line.match(/color ["'](.*?)["']/);
                if (posMatch) { x = parseFloat(posMatch[1]); y = parseFloat(posMatch[2]); }
                if (sizeMatch) { w = parseFloat(sizeMatch[1]); h = parseFloat(sizeMatch[2]); }
                if (damMatch) damage = parseFloat(damMatch[1]);
                if (colMatch) color = colMatch[1];
            }

            const spike = {
                type: 'spike',
                x: x,
                y: y,
                w: w,
                h: h,
                damage: damage,
                color: color
            };
            this.gameEntities.push(spike);
            this.log(`⚠️ Trampa de Picos Neón en (${x}, ${y})`, 'info');
            return;
        }

        // 21. Jump Pad: spawn jump_pad / spawn pad / spawn.pad
        if (line.startsWith('spawn jump_pad') || line.startsWith('spawn pad') || line.startsWith('spawn.pad')) {
            let x = 200, y = 420, w = 44, h = 14;
            let power = 650;
            let color = '#fbbf24';

            if (line.includes('(') && line.startsWith('spawn.pad(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.size && Array.isArray(args.size)) { w = args.size[0]; h = args.size[1]; }
                if (args.power) power = args.power;
                if (args.color) color = args.color;
            } else {
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const powMatch = line.match(/power (\d+)/);
                const colMatch = line.match(/color ["'](.*?)["']/);
                if (posMatch) { x = parseFloat(posMatch[1]); y = parseFloat(posMatch[2]); }
                if (powMatch) power = parseFloat(powMatch[1]);
                if (colMatch) color = colMatch[1];
            }

            const pad = {
                type: 'jump_pad',
                x: x,
                y: y,
                w: w,
                h: h,
                power: power,
                color: color,
                pulse: 0
            };
            this.gameEntities.push(pad);
            this.log(`🚀 Plataforma Impulsora en (${x}, ${y}) [Impulso: ${power}]`, 'info');
            return;
        }

        // 22. Jump Ring / Orb: spawn orb / spawn jump_ring / spawn.orb
        if (line.startsWith('spawn orb') || line.startsWith('spawn jump_ring') || line.startsWith('spawn.orb')) {
            let x = 350, y = 220, r = 16;
            let power = 550;
            let color = '#f59e0b';

            if (line.includes('(') && line.startsWith('spawn.orb(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.power) power = args.power;
                if (args.color) color = args.color;
            } else {
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const powMatch = line.match(/power (\d+)/);
                const colMatch = line.match(/color ["'](.*?)["']/);
                if (posMatch) { x = parseFloat(posMatch[1]); y = parseFloat(posMatch[2]); }
                if (powMatch) power = parseFloat(powMatch[1]);
                if (colMatch) color = colMatch[1];
            }

            const orb = {
                type: 'orb',
                x: x,
                y: y,
                r: r,
                power: power,
                color: color,
                pulse: 0
            };
            this.gameEntities.push(orb);
            this.log(`✨ Anillo de Salto Aéreo en (${x}, ${y})`, 'info');
            return;
        }

        // 23. Collectible Star / Coin: spawn coin / spawn star / spawn.coin
        if (line.startsWith('spawn coin') || line.startsWith('spawn star') || line.startsWith('spawn.coin')) {
            let x = 300, y = 250, points = 100;

            if (line.includes('(') && line.startsWith('spawn.coin(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.points) points = args.points;
            } else {
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const pointsMatch = line.match(/points\s+(\d+)/);
                if (posMatch) { x = parseFloat(posMatch[1]); y = parseFloat(posMatch[2]); }
                if (pointsMatch) points = parseInt(pointsMatch[1]);
            }

            const coin = {
                type: 'coin',
                x: x,
                y: y,
                r: 10,
                points: points,
                collected: false,
                floatOffset: Math.random() * 10
            };
            this.gameEntities.push(coin);
            return;
        }

        // 24. Health Pack / Heart: spawn heart / spawn potion / spawn.heart
        if (line.startsWith('spawn heart') || line.startsWith('spawn potion') || line.startsWith('spawn.heart')) {
            let x = 400, y = 260, heal = 30;

            if (line.includes('(') && line.startsWith('spawn.heart(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.heal) heal = args.heal;
            } else {
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const healMatch = line.match(/health (\d+)|heal (\d+)/);
                if (posMatch) { x = parseFloat(posMatch[1]); y = parseFloat(posMatch[2]); }
                if (healMatch) heal = parseInt(healMatch[1] || healMatch[2]);
            }

            const heart = {
                type: 'heart',
                x: x,
                y: y,
                r: 11,
                heal: heal,
                collected: false,
                floatOffset: Math.random() * 10
            };
            this.gameEntities.push(heart);
            this.log(`💚 Kit de Salud en (${x}, ${y}) [+${heal} HP]`, 'info');
            return;
        }

        // 25. Goal / Victory Portal: spawn portal / spawn goal / spawn.portal
        if (line.startsWith('spawn portal') || line.startsWith('spawn goal') || line.startsWith('spawn.portal')) {
            let x = 700, y = 350, w = 44, h = 68;
            let label = 'STAGE GOAL';

            if (line.includes('(') && line.startsWith('spawn.portal(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.size && Array.isArray(args.size)) { w = args.size[0]; h = args.size[1]; }
                if (args.label) label = args.label;
            } else {
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const labelMatch = line.match(/(?:label|destination)\s+["'](.*?)["']/);
                if (posMatch) { x = parseFloat(posMatch[1]); y = parseFloat(posMatch[2]); }
                if (labelMatch) label = labelMatch[1];
            }

            const portal = {
                type: 'portal',
                x: x,
                y: y,
                w: w,
                h: h,
                label: label,
                angle: 0,
                color: '#a855f7'
            };
            this.gameEntities.push(portal);
            this.log(`🌌 Portal de Victoria en (${x}, ${y}) ["${label}"]`, 'info');
            return;
        }

        // 26. Particle System / Spark emitter: emit particles
        if (line.startsWith('emit particles') || line.startsWith('fx.particles(')) {
            let px = 200, py = 200, pColor = '#38bdf8';
            if (line.includes('(') && line.startsWith('fx.particles(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { px = args.at[0]; py = args.at[1]; }
                if (args.color) pColor = args.color;
            } else {
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const colorMatch = line.match(/color ["'](.*?)["']/);
                if (posMatch) { px = parseInt(posMatch[1]); py = parseInt(posMatch[2]); }
                if (colorMatch) pColor = colorMatch[1];
            }
            this.spawnParticleBurst(px, py, pColor, 20);
            return;
        }
    }

    spawnParticleBurst(x, y, color, count = 16) {
        for (let i = 0; i < count; i++) {
            const angle = Math.random() * Math.PI * 2;
            const speed = Math.random() * 160 + 40;
            this.particles.push({
                x: x,
                y: y,
                vx: Math.cos(angle) * speed,
                vy: Math.sin(angle) * speed,
                color: color,
                alpha: 1.0,
                size: Math.random() * 4 + 2,
                life: Math.random() * 0.7 + 0.35
            });
        }
    }

    evaluateCondition(cond) {
        cond = cond.trim();
        const ops = ['==', '!=', '>=', '<=', '>', '<'];
        for (let op of ops) {
            if (cond.includes(op)) {
                const parts = cond.split(op);
                const left = this.evaluateExpression(parts[0]);
                const right = this.evaluateExpression(parts[1]);

                if (op === '==') return left == right;
                if (op === '!=') return left != right;
                if (op === '>=') return Number(left) >= Number(right);
                if (op === '<=') return Number(left) <= Number(right);
                if (op === '>') return Number(left) > Number(right);
                if (op === '<') return Number(left) < Number(right);
            }
        }
        return Boolean(this.evaluateExpression(cond));
    }

    isSingleQuotedLiteral(expr) {
        if (!expr || expr.length < 2) return false;
        const first = expr[0];
        if (first !== '"' && first !== "'") return false;
        for (let i = 1; i < expr.length; i++) {
            if (expr[i] === first && expr[i - 1] !== '\\') {
                return i === expr.length - 1;
            }
        }
        return false;
    }

    evaluateExpression(expr) {
        if (expr === undefined || expr === null) return '';
        expr = String(expr).trim();
        if (!expr) return '';

        if (expr.startsWith('py:') || expr.startsWith('py ')) {
            expr = expr.replace(/^(py:\s*|py\s+)/, '').trim();
        } else if (expr.startsWith('python:') || expr.startsWith('python eval ') || expr.startsWith('python ')) {
            expr = expr.replace(/^(python eval\s*|python:\s*|python\s+)/, '').trim();
        }
        
        if (this.isSingleQuotedLiteral(expr)) {
            let strContent = expr.slice(1, -1);
            strContent = strContent.replace(/\{([A-Za-z0-9_]+)\}/g, (match, varKey) => {
                return this.variables.hasOwnProperty(varKey) ? this.variables[varKey] : match;
            });
            return strContent;
        }

        if (!isNaN(expr) && expr !== '') return Number(expr);
        if (expr === 'true') return true;
        if (expr === 'false') return false;

        // Python Math Module & Arithmetic Expressions
        if (expr.startsWith('math.') || expr.includes(' + ') || expr.includes(' - ') || expr.includes(' * ') || expr.includes(' / ') || expr.includes(' % ')) {
            try {
                let resolvedExpr = expr;
                const varKeys = Object.keys(this.variables).sort((a, b) => b.length - a.length);
                for (let k of varKeys) {
                    const regex = new RegExp(`\\b${k}\\b`, 'g');
                    const val = this.variables[k];
                    const valRepr = typeof val === 'string' ? JSON.stringify(val) : String(val);
                    resolvedExpr = resolvedExpr.replace(regex, valRepr);
                }
                
                resolvedExpr = resolvedExpr
                    .replace(/math\.pi/g, Math.PI.toString())
                    .replace(/math\.e/g, Math.E.toString())
                    .replace(/math\.sqrt/g, 'Math.sqrt')
                    .replace(/math\.pow/g, 'Math.pow')
                    .replace(/math\.sin/g, 'Math.sin')
                    .replace(/math\.cos/g, 'Math.cos')
                    .replace(/math\.tan/g, 'Math.tan')
                    .replace(/math\.floor/g, 'Math.floor')
                    .replace(/math\.ceil/g, 'Math.ceil')
                    .replace(/math\.round/g, 'Math.round')
                    .replace(/math\.abs/g, 'Math.abs')
                    .replace(/math\.min/g, 'Math.min')
                    .replace(/math\.max/g, 'Math.max')
                    .replace(/math\.random/g, 'Math.random');

                return Function(`"use strict"; return (${resolvedExpr});`)();
            } catch(e) {}
        }

        if (this.variables.hasOwnProperty(expr)) {
            return this.variables[expr];
        }

        return expr;
    }

    parsePrint(rawExpr) {
        const args = [];
        let current = '';
        let inQuotes = false;
        let quoteChar = '';

        for (let i = 0; i < rawExpr.length; i++) {
            const char = rawExpr[i];
            if ((char === '"' || char === "'") && (i === 0 || rawExpr[i - 1] !== '\\')) {
                if (!inQuotes) {
                    inQuotes = true;
                    quoteChar = char;
                } else if (quoteChar === char) {
                    inQuotes = false;
                }
            }

            if (char === ',' && !inQuotes) {
                args.push(current.trim());
                current = '';
            } else {
                current += char;
            }
        }
        if (current.trim()) args.push(current.trim());

        const evaluated = args.map(arg => this.evaluateExpression(arg));
        return evaluated.join(' ');
    }

    triggerEvent(event, data) {
        if (event === 'click') {
            for (let item of this.renderQueue) {
                if (item.type === 'button') {
                    if (data.x >= item.x && data.x <= item.x + item.w &&
                        data.y >= item.y && data.y <= item.y + item.h) {
                        this.spawnParticleBurst(data.x, data.y, '#38bdf8', 25);
                    }
                }
            }
        }
    }

    startLoop() {
        this.isRunning = true;
        this.lastTime = performance.now();
        
        const loop = (timestamp) => {
            if (!this.isRunning) return;
            const dt = Math.min((timestamp - this.lastTime) / 1000, 0.1);
            this.lastTime = timestamp;
            
            this.update(dt);
            this.render();
            
            this.animationFrameId = requestAnimationFrame(loop);
        };
        this.animationFrameId = requestAnimationFrame(loop);
    }

    // ── GAMEPLAY PHYSICS & ENTITY SIMULATION ──
    update(dt) {
        // Poll Gamepad Hardware via Standard HTML5 API
        if (navigator.getGamepads) {
            const gps = navigator.getGamepads();
            if (gps && gps[0]) {
                const gp = gps[0];
                const axisX = gp.axes[0] || 0;
                const axisY = gp.axes[1] || 0;
                if (axisX < -0.3 || (gp.buttons[14] && gp.buttons[14].pressed)) this.gamepadState.dpad.left = true;
                if (axisX > 0.3 || (gp.buttons[15] && gp.buttons[15].pressed)) this.gamepadState.dpad.right = true;
                if (axisY < -0.3 || (gp.buttons[12] && gp.buttons[12].pressed) || (gp.buttons[0] && gp.buttons[0].pressed)) {
                    this.gamepadState.btnA = true;
                }
                if ((gp.buttons[1] && gp.buttons[1].pressed) || (gp.buttons[2] && gp.buttons[2].pressed)) {
                    this.gamepadState.btnB = true;
                }
                if (gp.buttons[3] && gp.buttons[3].pressed) {
                    this.gamepadState.btnX = true;
                }
            }
        }

        const floorY = this.canvas ? this.canvas.height - 44 : 436;

        // 1. Update Moving Platforms First (So players can ride smoothly)
        for (let other of this.gameEntities) {
            if (other.type === 'moving_platform') {
                if (other.axis === 'x') {
                    other.x += other.dir * other.speed * dt;
                    other.vx = other.dir * other.speed;
                    other.vy = 0;
                    if (other.x >= other.maxPos) { other.x = other.maxPos; other.dir = -1; }
                    if (other.x <= other.minPos) { other.x = other.minPos; other.dir = 1; }
                } else {
                    other.y += other.dir * other.speed * dt;
                    other.vx = 0;
                    other.vy = other.dir * other.speed;
                    if (other.y >= other.maxPos) { other.y = other.maxPos; other.dir = -1; }
                    if (other.y <= other.minPos) { other.y = other.minPos; other.dir = 1; }
                }
            } else if (other.type === 'portal') {
                other.angle += dt * 2.5;
            } else if (other.type === 'jump_pad' || other.type === 'orb') {
                if (other.pulse > 0) other.pulse = Math.max(0, other.pulse - dt * 3.5);
            }
        }

        // 2. Update Entities (Player, Enemies, Projectiles)
        for (let entity of this.gameEntities) {
            entity.glowPulse = (entity.glowPulse || 0) + dt * 5;

            if (entity.isPlayer && !this.gameOver) {
                // Timers
                if (entity.coyoteTimer > 0) entity.coyoteTimer -= dt;
                if (entity.jumpBufferTimer > 0) entity.jumpBufferTimer -= dt;
                if (entity.invulnerableTimer > 0) entity.invulnerableTimer -= dt;
                if (entity.dashCooldown > 0) entity.dashCooldown -= dt;
                
                // Dash handling
                if (entity.isDashing) {
                    entity.dashTimer -= dt;
                    this.spawnParticleBurst(entity.x + entity.w / 2, entity.y + entity.h / 2, '#00f5d4', 2);
                    if (entity.dashTimer <= 0) {
                        entity.isDashing = false;
                    }
                } else {
                    // Left / Right Movement
                    const moveLeft = this.gamepadState.dpad.left || this.touchState.left || 
                                     this.keysDown['arrowleft'] || this.keysDown['a'];
                    const moveRight = this.gamepadState.dpad.right || this.touchState.right || 
                                      this.keysDown['arrowright'] || this.keysDown['d'];

                    if (moveLeft) {
                        entity.vx = -entity.speed;
                        entity.facing = -1;
                    } else if (moveRight) {
                        entity.vx = entity.speed;
                        entity.facing = 1;
                    } else {
                        entity.vx *= this.friction;
                    }

                    // Jump Execution (Jump Buffering + Coyote Time)
                    const wantsJump = this.gamepadState.btnA || this.touchState.btnA || 
                                      this.keysDown['arrowup'] || this.keysDown['w'] || this.keysDown[' '];

                    if (wantsJump && entity.jumpBufferTimer <= 0) {
                        entity.jumpBufferTimer = this.jumpBuffer;
                    }

                    if (entity.jumpBufferTimer > 0) {
                        if (entity.coyoteTimer > 0 && !entity.isJumping) {
                            // First Jump
                            entity.vy = -entity.jumpForce;
                            entity.isJumping = true;
                            entity.coyoteTimer = 0;
                            entity.jumpBufferTimer = 0;
                            entity.doubleJumpAvailable = entity.canDoubleJump;
                            entity.stretch = 1.25;
                            entity.squash = 0.85;
                            this.playSfx('jump');
                            this.spawnParticleBurst(entity.x + entity.w / 2, entity.y + entity.h, '#38bdf8', 12);
                        } else if (entity.doubleJumpAvailable && entity.isJumping) {
                            // Double Jump
                            entity.vy = -entity.jumpForce * 0.92;
                            entity.doubleJumpAvailable = false;
                            entity.jumpBufferTimer = 0;
                            entity.stretch = 1.3;
                            entity.squash = 0.8;
                            this.playSfx('double_jump');
                            this.spawnParticleBurst(entity.x + entity.w / 2, entity.y + entity.h, '#c084fc', 18);
                            this.addPopup(entity.x, entity.y - 12, 'DOUBLE JUMP!', '#c084fc');
                        }
                    }

                    // Apply Gravity
                    entity.vy += this.gravity * dt;
                }

                // Apply Velocities
                entity.x += entity.vx * dt;
                entity.y += entity.vy * dt;

                // Squash & Stretch decay
                entity.squash += (1.0 - entity.squash) * dt * 10;
                entity.stretch += (1.0 - entity.stretch) * dt * 10;

                // Floor Collision
                if (entity.y + entity.h >= floorY) {
                    entity.y = floorY - entity.h;
                    entity.vy = 0;
                    entity.isJumping = false;
                    entity.coyoteTimer = this.coyoteTime;
                    entity.doubleJumpAvailable = entity.canDoubleJump;
                }

                // Entity Interactions & Collisions
                let onMovingPlatform = null;

                for (let other of this.gameEntities) {
                    if (other === entity) continue;

                    // Static Platform Collision
                    if (other.type === 'platform') {
                        if (entity.x + entity.w > other.x && entity.x < other.x + other.w) {
                            if (entity.y + entity.h >= other.y && entity.y + entity.h <= other.y + other.h + 14 && entity.vy >= 0) {
                                entity.y = other.y - entity.h;
                                entity.vy = 0;
                                entity.isJumping = false;
                                entity.coyoteTimer = this.coyoteTime;
                                entity.doubleJumpAvailable = entity.canDoubleJump;
                            }
                        }
                    } 
                    // Moving Platform Collision (Ride along!)
                    else if (other.type === 'moving_platform') {
                        if (entity.x + entity.w > other.x && entity.x < other.x + other.w) {
                            if (entity.y + entity.h >= other.y && entity.y + entity.h <= other.y + other.h + 16 && entity.vy >= 0) {
                                entity.y = other.y - entity.h;
                                entity.vy = 0;
                                entity.isJumping = false;
                                entity.coyoteTimer = this.coyoteTime;
                                entity.doubleJumpAvailable = entity.canDoubleJump;
                                onMovingPlatform = other;
                            }
                        }
                    }
                    // Spike / Hazard Collision
                    else if (other.type === 'spike') {
                        if (entity.x + entity.w > other.x + 4 && entity.x < other.x + other.w - 4 &&
                            entity.y + entity.h >= other.y + 6 && entity.y <= other.y + other.h) {
                            
                            if (entity.invulnerableTimer <= 0) {
                                entity.health -= other.damage || 35;
                                entity.invulnerableTimer = 1.0;
                                this.camera.shake = 10;
                                this.playSfx('hurt');
                                this.addPopup(entity.x, entity.y - 12, `-${other.damage || 35} HP`, '#ef4444');
                                this.spawnParticleBurst(entity.x + entity.w / 2, entity.y + entity.h / 2, '#ef4444', 20);
                                entity.vy = -300; // Knockback rebound

                                if (entity.health <= 0) {
                                    this.lives--;
                                    if (this.lives > 0) {
                                        entity.health = entity.maxHealth;
                                        entity.x = 100;
                                        entity.y = 280;
                                        entity.vy = 0;
                                        this.log(`⚠️ Te quedan ${this.lives} vidas. Reapareciendo...`, 'error');
                                    } else {
                                        this.triggerGameOver();
                                    }
                                }
                            }
                        }
                    }
                    // Jump Pad Collision
                    else if (other.type === 'jump_pad') {
                        if (entity.x + entity.w > other.x && entity.x < other.x + other.w) {
                            if (entity.y + entity.h >= other.y && entity.y + entity.h <= other.y + other.h + 12 && entity.vy >= 0) {
                                entity.vy = -(other.power || 650);
                                entity.isJumping = true;
                                entity.doubleJumpAvailable = true;
                                other.pulse = 1.0;
                                this.playSfx('pad');
                                this.addPopup(other.x + other.w / 2, other.y - 14, 'MEGA BOOST!', '#fbbf24');
                                this.spawnParticleBurst(other.x + other.w / 2, other.y, '#fbbf24', 22);
                            }
                        }
                    }
                    // Jump Ring / Orb Collision
                    else if (other.type === 'orb') {
                        const dist = Math.hypot((entity.x + entity.w / 2) - other.x, (entity.y + entity.h / 2) - other.y);
                        if (dist < other.r + 26) {
                            if (this.gamepadState.btnA || this.keysDown[' '] || this.keysDown['w'] || this.touchState.btnA) {
                                entity.vy = -(other.power || 540);
                                entity.isJumping = true;
                                entity.doubleJumpAvailable = true;
                                other.pulse = 1.0;
                                this.playSfx('pad');
                                this.addPopup(other.x, other.y - 14, 'AIR BOOST!', '#f59e0b');
                                this.spawnParticleBurst(other.x, other.y, '#f59e0b', 24);
                            }
                        }
                    }
                    // Coin Collectible
                    else if (other.type === 'coin' && !other.collected) {
                        const cx = other.x;
                        const cy = other.y;
                        if (entity.x + entity.w >= cx - other.r && entity.x <= cx + other.r &&
                            entity.y + entity.h >= cy - other.r && entity.y <= cy + other.r) {
                            other.collected = true;
                            this.score += other.points;
                            this.playSfx('coin');
                            this.addPopup(cx, cy - 10, `+${other.points}`, '#fbbf24');
                            this.spawnParticleBurst(cx, cy, '#fbbf24', 20);
                            this.log(` Moneda obtenida! +${other.points} (Puntaje Total: ${this.score})`, 'success');
                        }
                    }
                    // Health Pack Collectible
                    else if (other.type === 'heart' && !other.collected) {
                        const dist = Math.hypot((entity.x + entity.w / 2) - other.x, (entity.y + entity.h / 2) - other.y);
                        if (dist < other.r + 20) {
                            other.collected = true;
                            entity.health = Math.min(entity.maxHealth, entity.health + (other.heal || 30));
                            this.playSfx('heal');
                            this.addPopup(other.x, other.y - 12, `+${other.heal || 30} HP`, '#10b981');
                            this.spawnParticleBurst(other.x, other.y, '#10b981', 20);
                        }
                    }
                    // Portal / Victory Goal
                    else if (other.type === 'portal') {
                        if (entity.x + entity.w > other.x && entity.x < other.x + other.w &&
                            entity.y + entity.h > other.y && entity.y < other.y + other.h) {
                            this.triggerVictory();
                        }
                    }
                    // Enemy Interaction: Stomp vs Collision Damage
                    else if (other.type === 'enemy' && other.isAlive) {
                        if (entity.x + entity.w > other.x && entity.x < other.x + other.w &&
                            entity.y + entity.h >= other.y && entity.y <= other.y + other.h) {
                            
                            // Stomp from above!
                            if (entity.vy > 0 && (entity.y + entity.h) <= (other.y + other.h * 0.5 + 10)) {
                                other.isAlive = false;
                                entity.vy = -380; // Rebound bounce!
                                entity.doubleJumpAvailable = true;
                                this.score += 250;
                                this.playSfx('stomp');
                                this.addPopup(other.x + other.w / 2, other.y - 14, '+250 STOMP!', '#38bdf8');
                                this.spawnParticleBurst(other.x + other.w / 2, other.y + other.h / 2, '#ef4444', 26);
                                this.log(`💥 Enemigo "${other.name}" neutralizado por pisada! (+250 Pts)`, 'success');
                            } 
                            // Collision Damage to player
                            else if (entity.invulnerableTimer <= 0) {
                                entity.health -= 25;
                                entity.invulnerableTimer = 1.0;
                                this.camera.shake = 9;
                                this.playSfx('hurt');
                                this.addPopup(entity.x, entity.y - 12, '-25 HP', '#ef4444');
                                this.spawnParticleBurst(entity.x + entity.w / 2, entity.y + entity.h / 2, '#ef4444', 16);
                                entity.vx = -entity.facing * 240;
                                entity.vy = -220;

                                if (entity.health <= 0) {
                                    this.lives--;
                                    if (this.lives > 0) {
                                        entity.health = entity.maxHealth;
                                        entity.x = 100;
                                        entity.y = 280;
                                        this.log(`⚠️ Te quedan ${this.lives} vidas. Reapareciendo...`, 'error');
                                    } else {
                                        this.triggerGameOver();
                                    }
                                }
                            }
                        }
                    }
                }

                // If standing on moving platform, ride along with its velocity!
                if (onMovingPlatform) {
                    entity.x += onMovingPlatform.vx * dt;
                    entity.y += onMovingPlatform.vy * dt;
                }

                // World Boundaries Clamping
                if (entity.x < 0) entity.x = 0;
                if (entity.x + entity.w > this.world.width) entity.x = this.world.width - entity.w;

            } else if (entity.type === 'enemy' && entity.isAlive) {
                // Autonomous AI Patrol for Enemy NPCs
                entity.x += entity.dir * entity.speed * dt;
                if (entity.x >= entity.maxX) { entity.x = entity.maxX; entity.dir = -1; }
                if (entity.x <= entity.minX) { entity.x = entity.minX; entity.dir = 1; }
            }
        }

        // 3. Update Projectiles
        for (let i = this.projectiles.length - 1; i >= 0; i--) {
            const pr = this.projectiles[i];
            pr.x += pr.vx * dt;
            pr.y += pr.vy * dt;
            pr.life -= dt;

            // Spawn subtle trail
            if (Math.random() < 0.4) {
                this.particles.push({
                    x: pr.x + (pr.vx > 0 ? 0 : pr.w),
                    y: pr.y + pr.h / 2,
                    vx: (Math.random() - 0.5) * 20,
                    vy: (Math.random() - 0.5) * 20,
                    color: pr.color,
                    alpha: 0.6,
                    size: 2,
                    life: 0.2
                });
            }

            // Check collision with enemies
            if (pr.isPlayer) {
                for (let other of this.gameEntities) {
                    if (other.type === 'enemy' && other.isAlive) {
                        if (pr.x + pr.w >= other.x && pr.x <= other.x + other.w &&
                            pr.y + pr.h >= other.y && pr.y <= other.y + other.h) {
                            
                            other.health -= pr.damage;
                            this.playSfx('stomp');
                            this.addPopup(other.x + other.w / 2, other.y - 10, `-${pr.damage}`, '#38bdf8');
                            this.spawnParticleBurst(pr.x, pr.y, '#38bdf8', 12);
                            pr.life = 0; // Destroy projectile

                            if (other.health <= 0) {
                                other.isAlive = false;
                                this.score += 200;
                                this.addPopup(other.x + other.w / 2, other.y - 14, '+200 DESTROYED!', '#fbbf24');
                                this.spawnParticleBurst(other.x + other.w / 2, other.y + other.h / 2, '#ef4444', 24);
                            }
                            break;
                        }
                    }
                }
            }

            if (pr.life <= 0 || pr.x < 0 || pr.x > this.world.width) {
                this.projectiles.splice(i, 1);
            }
        }

        // 4. Update Particle Sparks
        for (let i = this.particles.length - 1; i >= 0; i--) {
            const p = this.particles[i];
            p.x += p.vx * dt;
            p.y += p.vy * dt;
            p.vy += 320 * dt; // Gravity on particles
            p.alpha -= dt / p.life;
            if (p.alpha <= 0) {
                this.particles.splice(i, 1);
            }
        }

        // 5. Update Floating Popups
        for (let i = this.popups.length - 1; i >= 0; i--) {
            const pop = this.popups[i];
            pop.y += pop.vy * dt;
            pop.alpha -= dt * 1.1;
            if (pop.alpha <= 0) {
                this.popups.splice(i, 1);
            }
        }

        // 6. Smooth Camera Tracking Follow
        const player = this.getPlayer();
        if (player && this.canvas) {
            const targetCamX = player.x + player.w / 2 - (this.canvas.width / 2);
            const targetCamY = player.y + player.h / 2 - (this.canvas.height / 2);
            const maxCamX = Math.max(0, this.world.width - this.canvas.width);
            const maxCamY = Math.max(0, this.world.height - this.canvas.height);

            this.camera.x += (Math.max(0, Math.min(maxCamX, targetCamX)) - this.camera.x) * this.camera.smooth;
            this.camera.y += (Math.max(0, Math.min(maxCamY, targetCamY)) - this.camera.y) * this.camera.smooth;
        }

        // Camera Shake Decay
        if (this.camera.shake > 0) {
            this.camera.shake = Math.max(0, this.camera.shake - dt * 22);
        }
    }

    // ── GRAPHICS & SHINE LOOP RENDERING PIPELINE ──
    render() {
        if (!this.ctx || !this.canvas) return;
        const ctx = this.ctx;
        const w = this.canvas.width;
        const h = this.canvas.height;

        // Apply Camera Shake
        const shakeX = (Math.random() - 0.5) * this.camera.shake;
        const shakeY = (Math.random() - 0.5) * this.camera.shake;

        // 1. Clear Stage & Deep Cyber Background
        ctx.fillStyle = '#06090f';
        ctx.fillRect(0, 0, w, h);

        // 2. Parallax Cyber Starfield & Waves
        const parallaxX = this.camera.x * 0.15;
        ctx.save();
        ctx.strokeStyle = 'rgba(99, 102, 241, 0.14)';
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        for (let x = 0; x <= w + 40; x += 15) {
            const y = h * 0.45 + Math.sin((x + parallaxX) * 0.015 + this.lastTime * 0.0018) * 24;
            if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
        }
        ctx.stroke();

        // Cyber Grid Lines (Parallaxed)
        ctx.strokeStyle = 'rgba(56, 189, 248, 0.05)';
        ctx.lineWidth = 1;
        const gridOffset = (this.camera.x * 0.3) % 40;
        for (let x = -gridOffset; x < w; x += 40) {
            ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, h); ctx.stroke();
        }
        for (let y = 0; y < h; y += 40) {
            ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke();
        }
        ctx.restore();

        // ═══════════════════════════════════════════════════════════════
        //  WORLD SPACE (Camera Translated)
        // ═══════════════════════════════════════════════════════════════
        ctx.save();
        ctx.translate(-Math.round(this.camera.x + shakeX), -Math.round(this.camera.y + shakeY));

        // 3. World Ground Surface
        const floorY = h - 44;
        const groundGrad = ctx.createLinearGradient(0, floorY, 0, h);
        groundGrad.addColorStop(0, '#0f172a');
        groundGrad.addColorStop(1, '#020617');
        ctx.fillStyle = groundGrad;
        ctx.fillRect(0, floorY, this.world.width, 44);

        // Neon Barrier Line
        ctx.strokeStyle = '#38bdf8';
        ctx.shadowColor = '#38bdf8';
        ctx.shadowBlur = 10;
        ctx.lineWidth = 2.5;
        ctx.beginPath();
        ctx.moveTo(0, floorY);
        ctx.lineTo(this.world.width, floorY);
        ctx.stroke();
        ctx.shadowBlur = 0;

        // Ground Hazard Stripes
        ctx.strokeStyle = 'rgba(56, 189, 248, 0.12)';
        ctx.lineWidth = 2;
        for (let gx = 0; gx < this.world.width; gx += 48) {
            ctx.beginPath();
            ctx.moveTo(gx, floorY + 2);
            ctx.lineTo(gx + 20, floorY + 42);
            ctx.stroke();
        }

        // 4. Render Game Entities
        for (let entity of this.gameEntities) {
            // Static Platform
            if (entity.type === 'platform') {
                const pGrad = ctx.createLinearGradient(entity.x, entity.y, entity.x, entity.y + entity.h);
                pGrad.addColorStop(0, entity.color);
                pGrad.addColorStop(1, 'rgba(15, 23, 42, 0.92)');
                ctx.fillStyle = pGrad;
                ctx.strokeStyle = '#818cf8';
                ctx.lineWidth = 1.5;
                ctx.shadowColor = entity.color;
                ctx.shadowBlur = 8;
                this.roundRect(ctx, entity.x, entity.y, entity.w, entity.h, 6, true, true);
                ctx.shadowBlur = 0;
            }
            // Maglev Moving Platform
            else if (entity.type === 'moving_platform') {
                const mpGrad = ctx.createLinearGradient(entity.x, entity.y, entity.x, entity.y + entity.h);
                mpGrad.addColorStop(0, '#06b6d4');
                mpGrad.addColorStop(1, 'rgba(8, 47, 73, 0.95)');
                ctx.fillStyle = mpGrad;
                ctx.strokeStyle = '#22d3ee';
                ctx.lineWidth = 1.8;
                ctx.shadowColor = '#06b6d4';
                ctx.shadowBlur = 12;
                this.roundRect(ctx, entity.x, entity.y, entity.w, entity.h, 7, true, true);
                ctx.shadowBlur = 0;

                // Animated Maglev Directional Chevrons
                ctx.fillStyle = 'rgba(255, 255, 255, 0.6)';
                const chevronX = entity.x + entity.w / 2 + Math.sin(this.lastTime * 0.008) * 18;
                ctx.beginPath();
                ctx.arc(chevronX, entity.y + entity.h / 2, 3, 0, Math.PI * 2);
                ctx.fill();
            }
            // Spikes / Hazards
            else if (entity.type === 'spike') {
                ctx.fillStyle = '#ef4444';
                ctx.shadowColor = '#ef4444';
                ctx.shadowBlur = 10;
                const spikeCount = Math.max(1, Math.floor(entity.w / 14));
                const sWidth = entity.w / spikeCount;

                for (let k = 0; k < spikeCount; k++) {
                    const sx = entity.x + k * sWidth;
                    ctx.beginPath();
                    ctx.moveTo(sx, entity.y + entity.h);
                    ctx.lineTo(sx + sWidth / 2, entity.y);
                    ctx.lineTo(sx + sWidth, entity.y + entity.h);
                    ctx.closePath();
                    ctx.fill();
                }
                ctx.shadowBlur = 0;
            }
            // Jump Pad
            else if (entity.type === 'jump_pad') {
                ctx.fillStyle = '#1e1b4b';
                ctx.strokeStyle = '#fbbf24';
                ctx.lineWidth = 1.8;
                this.roundRect(ctx, entity.x, entity.y, entity.w, entity.h, 5, true, true);

                // Pulsing spring wave
                ctx.fillStyle = '#fbbf24';
                ctx.shadowColor = '#f59e0b';
                ctx.shadowBlur = 8 + (entity.pulse || 0) * 12;
                const padH = 4 + (entity.pulse || 0) * 6;
                ctx.fillRect(entity.x + 6, entity.y - padH, entity.w - 12, padH);
                ctx.shadowBlur = 0;
            }
            // Jump Ring / Orb
            else if (entity.type === 'orb') {
                ctx.save();
                ctx.strokeStyle = entity.color;
                ctx.shadowColor = entity.color;
                ctx.shadowBlur = 14 + (entity.pulse || 0) * 10;
                ctx.lineWidth = 2.5;

                // Outer Ring
                ctx.beginPath();
                ctx.arc(entity.x, entity.y, entity.r, 0, Math.PI * 2);
                ctx.stroke();

                // Inner pulsing core
                ctx.fillStyle = '#ffffff';
                ctx.beginPath();
                ctx.arc(entity.x, entity.y, 4 + Math.sin(this.lastTime * 0.008) * 1.5, 0, Math.PI * 2);
                ctx.fill();
                ctx.restore();
            }
            // Spinning Star/Coin
            else if (entity.type === 'coin' && !entity.collected) {
                const floatY = entity.y + Math.sin(this.lastTime * 0.005 + entity.floatOffset) * 4;
                ctx.fillStyle = '#fbbf24';
                ctx.shadowColor = '#f59e0b';
                ctx.shadowBlur = 12;
                ctx.beginPath();
                ctx.arc(entity.x, floatY, entity.r, 0, Math.PI * 2);
                ctx.fill();
                
                ctx.fillStyle = '#000000';
                ctx.font = 'bold 10px monospace';
                ctx.textAlign = 'center';
                ctx.fillText("*", entity.x, floatY + 3.5);
                ctx.textAlign = 'left';
                ctx.shadowBlur = 0;
            }
            // Health Heart Collectible
            else if (entity.type === 'heart' && !entity.collected) {
                const floatY = entity.y + Math.sin(this.lastTime * 0.006 + entity.floatOffset) * 4;
                ctx.fillStyle = '#10b981';
                ctx.shadowColor = '#10b981';
                ctx.shadowBlur = 14;
                ctx.beginPath();
                ctx.arc(entity.x, floatY, entity.r, 0, Math.PI * 2);
                ctx.fill();
                
                ctx.fillStyle = '#ffffff';
                ctx.font = 'bold 11px sans-serif';
                ctx.textAlign = 'center';
                ctx.fillText("+", entity.x, floatY + 4);
                ctx.textAlign = 'left';
                ctx.shadowBlur = 0;
            }
            // Victory Portal Vortex
            else if (entity.type === 'portal') {
                ctx.save();
                ctx.translate(entity.x + entity.w / 2, entity.y + entity.h / 2);
                ctx.rotate(entity.angle || 0);

                ctx.strokeStyle = '#c084fc';
                ctx.shadowColor = '#c084fc';
                ctx.shadowBlur = 16;
                ctx.lineWidth = 3;
                ctx.beginPath();
                ctx.ellipse(0, 0, entity.w / 2, entity.h / 2, 0, 0, Math.PI * 2);
                ctx.stroke();

                ctx.strokeStyle = '#38bdf8';
                ctx.lineWidth = 1.5;
                ctx.beginPath();
                ctx.ellipse(0, 0, entity.w / 3, entity.h / 3, Math.PI / 4, 0, Math.PI * 2);
                ctx.stroke();
                ctx.restore();

                // Stage Goal Label
                ctx.fillStyle = '#f8fafc';
                ctx.font = 'bold 11px Outfit, sans-serif';
                ctx.textAlign = 'center';
                ctx.fillText(entity.label || "GOAL", entity.x + entity.w / 2, entity.y - 10);
                ctx.textAlign = 'left';
            }
            // Autonomous Enemy NPC
            else if (entity.type === 'enemy' && entity.isAlive) {
                ctx.fillStyle = entity.color;
                ctx.shadowColor = entity.color;
                ctx.shadowBlur = 12;
                this.roundRect(ctx, entity.x, entity.y, entity.w, entity.h, 8, true, false);
                ctx.shadowBlur = 0;

                // Glowing Robotic Eye Visor
                ctx.fillStyle = '#ffffff';
                const eyeX = entity.dir > 0 ? entity.x + entity.w - 12 : entity.x + 4;
                ctx.fillRect(eyeX, entity.y + 12, 8, 4);

                // Enemy HP Bar
                if (entity.health < entity.maxHealth) {
                    ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
                    ctx.fillRect(entity.x, entity.y - 10, entity.w, 4);
                    ctx.fillStyle = '#ef4444';
                    ctx.fillRect(entity.x, entity.y - 10, entity.w * (entity.health / entity.maxHealth), 4);
                }

                // Name tag
                ctx.fillStyle = '#f87171';
                ctx.font = 'bold 10px Outfit, sans-serif';
                ctx.textAlign = 'center';
                ctx.fillText(entity.name, entity.x + entity.w / 2, entity.y - 12);
                ctx.textAlign = 'left';
            }
            // Player Hero Character
            else if (entity.isPlayer) {
                // I-Frame Blinking when hurt
                if (entity.invulnerableTimer > 0 && Math.floor(this.lastTime / 90) % 2 === 0) {
                    continue;
                }

                ctx.save();
                ctx.translate(entity.x + entity.w / 2, entity.y + entity.h / 2);
                ctx.scale((entity.facing || 1) * (entity.squash || 1), entity.stretch || 1);

                // Hero Body Capsule
                const heroGrad = ctx.createLinearGradient(-entity.w / 2, -entity.h / 2, entity.w / 2, entity.h / 2);
                heroGrad.addColorStop(0, entity.color || '#38bdf8');
                heroGrad.addColorStop(1, '#0284c7');
                ctx.fillStyle = heroGrad;
                ctx.shadowColor = entity.color || '#38bdf8';
                ctx.shadowBlur = 14 + Math.sin(entity.glowPulse || 0) * 4;
                this.roundRect(ctx, -entity.w / 2, -entity.h / 2, entity.w, entity.h, 10, true, false);
                ctx.shadowBlur = 0;

                // High-Tech Cyber Helmet Visor
                ctx.fillStyle = '#ffffff';
                ctx.shadowColor = '#ffffff';
                ctx.shadowBlur = 6;
                this.roundRect(ctx, 0, -entity.h / 2 + 10, entity.w / 2 - 2, 7, 3, true, false);
                ctx.shadowBlur = 0;

                // Jetpack / Thruster on the back
                ctx.fillStyle = '#1e293b';
                ctx.fillRect(-entity.w / 2 - 4, -entity.h / 4, 4, entity.h / 2);

                ctx.restore();

                // Player Name Tag
                ctx.fillStyle = '#38bdf8';
                ctx.font = 'bold 11px Outfit, sans-serif';
                ctx.textAlign = 'center';
                ctx.fillText(entity.name, entity.x + entity.w / 2, entity.y - 10);
                ctx.textAlign = 'left';
            }
        }

        // 5. Render Projectiles
        for (let pr of this.projectiles) {
            ctx.fillStyle = pr.color;
            ctx.shadowColor = pr.color;
            ctx.shadowBlur = 12;
            this.roundRect(ctx, pr.x, pr.y, pr.w, pr.h, 3, true, false);
            ctx.shadowBlur = 0;
        }

        // 6. Render Particle Bursts
        for (let p of this.particles) {
            ctx.fillStyle = p.color;
            ctx.globalAlpha = Math.max(0, p.alpha);
            ctx.beginPath();
            ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
            ctx.fill();
            ctx.globalAlpha = 1.0;
        }

        // 7. Render Floating Text Popups
        for (let pop of this.popups) {
            ctx.fillStyle = pop.color;
            ctx.globalAlpha = Math.max(0, pop.alpha);
            ctx.font = 'bold 13px Outfit, sans-serif';
            ctx.shadowColor = pop.color;
            ctx.shadowBlur = 8;
            ctx.fillText(pop.text, pop.x, pop.y);
            ctx.shadowBlur = 0;
            ctx.globalAlpha = 1.0;
        }

        ctx.restore(); // Restore Camera Translation

        // ═══════════════════════════════════════════════════════════════
        //  SCREEN SPACE OVERLAYS & HEADS-UP DISPLAY (HUD)
        // ═══════════════════════════════════════════════════════════════

        // Render UI HUD Cards & Buttons
        for (let elem of this.renderQueue) {
            if (elem.type === 'card') {
                const cardGrad = ctx.createLinearGradient(elem.x, elem.y, elem.x + elem.w, elem.y + elem.h);
                cardGrad.addColorStop(0, 'rgba(15, 23, 42, 0.82)');
                cardGrad.addColorStop(1, 'rgba(30, 41, 59, 0.88)');

                ctx.fillStyle = cardGrad;
                ctx.strokeStyle = 'rgba(255, 255, 255, 0.16)';
                ctx.lineWidth = 1.2;
                this.roundRect(ctx, elem.x, elem.y, elem.w, elem.h, 14, true, true);

                ctx.fillStyle = '#38bdf8';
                ctx.font = 'bold 14px Outfit, sans-serif';
                ctx.fillText(elem.title, elem.x + 16, elem.y + 28);

                ctx.fillStyle = '#94a3b8';
                ctx.font = '11.5px Outfit, monospace, sans-serif';
                const lines = String(elem.text || '').replace(/\\n/g, '\n').split('\n');
                for (let i = 0; i < lines.length; i++) {
                    const lineY = elem.y + 52 + (i * 20);
                    if (lineY < elem.y + elem.h - 8) {
                        ctx.fillText(lines[i], elem.x + 16, lineY);
                    }
                }
            } else if (elem.type === 'button') {
                const btnGrad = ctx.createLinearGradient(elem.x, elem.y, elem.x + elem.w, elem.y + elem.h);
                btnGrad.addColorStop(0, '#6366f1');
                btnGrad.addColorStop(1, '#8b5cf6');
                ctx.fillStyle = btnGrad;
                ctx.strokeStyle = '#a5b4fc';
                ctx.lineWidth = 1.5;
                this.roundRect(ctx, elem.x, elem.y, elem.w, elem.h, 10, true, true);

                ctx.fillStyle = '#ffffff';
                ctx.font = 'bold 13px Outfit, sans-serif';
                ctx.textAlign = 'center';
                ctx.fillText(elem.text, elem.x + elem.w / 2, elem.y + 26);
                ctx.textAlign = 'left';
            }
        }

        // Top Status HUD (Health, Lives, Score)
        const player = this.getPlayer();
        if (player) {
            // Health Bar Container (Top Left)
            ctx.fillStyle = 'rgba(15, 23, 42, 0.85)';
            ctx.strokeStyle = 'rgba(56, 189, 248, 0.4)';
            ctx.lineWidth = 1.2;
            this.roundRect(ctx, 16, 16, 210, 48, 12, true, true);

            // Health bar fill
            const hpRatio = Math.max(0, player.health / player.maxHealth);
            const hpWidth = 120 * hpRatio;
            const hpColor = hpRatio > 0.5 ? '#10b981' : (hpRatio > 0.25 ? '#f59e0b' : '#ef4444');

            ctx.fillStyle = 'rgba(255, 255, 255, 0.1)';
            this.roundRect(ctx, 72, 26, 120, 12, 6, true, false);

            ctx.fillStyle = hpColor;
            ctx.shadowColor = hpColor;
            ctx.shadowBlur = 8;
            if (hpWidth > 0) this.roundRect(ctx, 72, 26, hpWidth, 12, 6, true, false);
            ctx.shadowBlur = 0;

            // Player Avatar Tag
            ctx.fillStyle = '#38bdf8';
            ctx.font = 'bold 12px Outfit, sans-serif';
            ctx.fillText("HP", 46, 36);

            // Lives counter
            ctx.fillStyle = '#ef4444';
            for (let l = 0; l < this.lives; l++) {
                ctx.beginPath();
                ctx.arc(76 + l * 18, 49, 4.5, 0, Math.PI * 2);
                ctx.fill();
            }
        }

        // Score Badge (Top Right)
        ctx.fillStyle = 'rgba(15, 23, 42, 0.85)';
        ctx.strokeStyle = '#fbbf24';
        ctx.lineWidth = 1.5;
        this.roundRect(ctx, w - 170, 16, 154, 44, 12, true, true);

        ctx.fillStyle = '#fbbf24';
        ctx.font = 'bold 14px Outfit, sans-serif';
        ctx.fillText(`★ SCORE: ${this.score}`, w - 154, 43);

        // Virtual Touch Controls Overlay for Mobile / Tablets
        if (this.touchState.hasTouch || w < 768) {
            // D-Pad Left/Right
            ctx.fillStyle = 'rgba(30, 41, 59, 0.6)';
            ctx.strokeStyle = 'rgba(56, 189, 248, 0.4)';
            ctx.lineWidth = 1.5;
            
            // Left Button
            this.roundRect(ctx, 20, h - 70, 52, 48, 12, true, true);
            ctx.fillStyle = '#f8fafc';
            ctx.font = 'bold 18px monospace';
            ctx.textAlign = 'center';
            ctx.fillText('◀', 46, h - 39);

            // Right Button
            ctx.fillStyle = 'rgba(30, 41, 59, 0.6)';
            this.roundRect(ctx, 80, h - 70, 52, 48, 12, true, true);
            ctx.fillStyle = '#f8fafc';
            ctx.fillText('▶', 106, h - 39);

            // Jump Button (A)
            ctx.fillStyle = 'rgba(56, 189, 248, 0.35)';
            ctx.strokeStyle = '#38bdf8';
            this.roundRect(ctx, w - 74, h - 70, 54, 48, 12, true, true);
            ctx.fillStyle = '#ffffff';
            ctx.fillText('A', w - 47, h - 39);

            // Shoot Button (B)
            ctx.fillStyle = 'rgba(239, 68, 68, 0.35)';
            ctx.strokeStyle = '#ef4444';
            this.roundRect(ctx, w - 138, h - 70, 54, 48, 12, true, true);
            ctx.fillStyle = '#ffffff';
            ctx.fillText('B', w - 111, h - 39);
            ctx.textAlign = 'left';
        }

        // Game Over Overlay
        if (this.gameOver) {
            ctx.fillStyle = 'rgba(6, 9, 15, 0.88)';
            ctx.fillRect(0, 0, w, h);

            ctx.fillStyle = '#ef4444';
            ctx.shadowColor = '#ef4444';
            ctx.shadowBlur = 20;
            ctx.font = '900 32px Outfit, sans-serif';
            ctx.textAlign = 'center';
            ctx.fillText("OPERACIÓN TERMINADA", w / 2, h / 2 - 30);
            ctx.shadowBlur = 0;

            ctx.fillStyle = '#f1f5f9';
            ctx.font = '16px Outfit, sans-serif';
            ctx.fillText(`Puntaje Final: ${this.score} Puntos`, w / 2, h / 2 + 10);

            ctx.fillStyle = '#38bdf8';
            ctx.font = 'bold 14px Outfit, sans-serif';
            ctx.fillText("Presiona [R] o Toca la pantalla para Reintentar", w / 2, h / 2 + 48);
            ctx.textAlign = 'left';
        }

        // Victory Overlay
        if (this.gameWon) {
            ctx.fillStyle = 'rgba(6, 9, 15, 0.85)';
            ctx.fillRect(0, 0, w, h);

            ctx.fillStyle = '#fbbf24';
            ctx.shadowColor = '#fbbf24';
            ctx.shadowBlur = 24;
            ctx.font = '900 34px Outfit, sans-serif';
            ctx.textAlign = 'center';
            ctx.fillText("¡MISIÓN CUMPLIDA!", w / 2, h / 2 - 35);
            ctx.shadowBlur = 0;

            ctx.fillStyle = '#f8fafc';
            ctx.font = 'bold 18px Outfit, sans-serif';
            ctx.fillText(`ETAPA COMPLETADA • ${this.score} PUNTOS`, w / 2, h / 2 + 12);

            ctx.fillStyle = '#38bdf8';
            ctx.font = 'bold 14px Outfit, sans-serif';
            ctx.fillText("Presiona [R] o Toca la pantalla para Jugar de Nuevo", w / 2, h / 2 + 52);
            ctx.textAlign = 'left';
        }

        // Bottom Watermark & Controls Helper
        ctx.fillStyle = 'rgba(255, 255, 255, 0.4)';
        ctx.font = '900 11px monospace';
        ctx.fillText("SHINE LOOP CONSOLE • 60 FPS 2D ENGINE • CS QUANTUM", 20, h - 16);
    }

    roundRect(ctx, x, y, width, height, radius, fill, stroke) {
        ctx.beginPath();
        ctx.moveTo(x + radius, y);
        ctx.lineTo(x + width - radius, y);
        ctx.quadraticCurveTo(x + width, y, x + width, y + radius);
        ctx.lineTo(x + width, y + height - radius);
        ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
        ctx.lineTo(x + radius, y + height);
        ctx.quadraticCurveTo(x, y + height, x, y + height - radius);
        ctx.lineTo(x, y + radius);
        ctx.quadraticCurveTo(x, y, x + radius, y);
        ctx.closePath();
        if (fill) ctx.fill();
        if (stroke) ctx.stroke();
    }
}
