// ═══════════════════════════════════════════════════════════════
// [L] LOOPING COMPILE — CORE RUNTIME & GRAPHIC ENGINE v2.0
// Next-Gen Game Programming Language for "Shine Loop" & "Holo Looping OoS"
// Developed by Holo Entertainment (Sub-division of Coki Studios)
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
        this.sounds = {};
        this.theme = 'dark_neon';
        this.isRunning = false;
        this.animationFrameId = null;
        this.lastTime = 0;
        this.fps = 60;
        this.score = 0;
        
        // Input Controller State (Keyboard + Shine Loop Gamepad)
        this.keysDown = {};
        this.mousePos = { x: 0, y: 0 };
        this.isMouseDown = false;
        this.gamepadState = {
            dpad: { left: false, right: false, up: false, down: false },
            btnA: false,
            btnB: false,
            btnX: false,
            btnY: false
        };
        
        this.setupInputListeners();
    }
    
    setupInputListeners() {
        if (!this.canvas) return;
        
        window.addEventListener('keydown', (e) => {
            const key = e.key.toLowerCase();
            this.keysDown[key] = true;
            this.keysDown[e.code.toLowerCase()] = true;
            
            // Map to Shine Loop Gamepad Buttons
            if (key === 'a' || key === 'arrowleft') this.gamepadState.dpad.left = true;
            if (key === 'd' || key === 'arrowright') this.gamepadState.dpad.right = true;
            if (key === 'w' || key === 'arrowup' || key === ' ') {
                this.gamepadState.btnA = true; // Jump / Primary Action
                this.gamepadState.dpad.up = true;
            }
            if (key === 's' || key === 'arrowdown') this.gamepadState.dpad.down = true;
            if (key === 'j' || key === 'z') this.gamepadState.btnB = true; // Attack / Boost
            if (key === 'k' || key === 'x') this.gamepadState.btnX = true; // Special
            
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
            if (key === 'j' || key === 'z') this.gamepadState.btnB = false;
            if (key === 'k' || key === 'x') this.gamepadState.btnX = false;
            
            this.triggerEvent('keyup', e.key);
        });
        
        this.canvas.addEventListener('mousemove', (e) => {
            const rect = this.canvas.getBoundingClientRect();
            this.mousePos.x = e.clientX - rect.left;
            this.mousePos.y = e.clientY - rect.top;
        });
        
        this.canvas.addEventListener('mousedown', (e) => {
            this.isMouseDown = true;
            this.triggerEvent('click', this.mousePos);
        });
        
        this.canvas.addEventListener('mouseup', () => {
            this.isMouseDown = false;
        });
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
        this.score = 0;
        if (this.ctx && this.canvas) {
            this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        }
    }

    // ── AST & Lexer Compiler ──
    execute(code) {
        this.reset();
        this.log("[SYS] Compiling Looping (.loop) Source Code...", "system");
        
        const lines = code.split('\n');
        
        for (let i = 0; i < lines.length; i++) {
            let line = lines[i].trim();
            if (!line || line.startsWith('#') || line.startsWith('//')) continue;
            
            try {
                this.parseLine(line);
            } catch (err) {
                this.log(`[ERROR] [Syntax Error at line ${i + 1}]: ${err.message}`, "error");
                return false;
            }
        }

        this.log(" Compilation Complete! Starting Shine Loop graphics pipeline @ 60FPS...", "success");
        this.startLoop();
        return true;
    }

    parseLine(line) {
        // 1. Module Imports
        if (line.startsWith('import ')) {
            this.log(`[MODULE] Loaded Holo Engine Library: ${line.replace('import ', '')}`, 'system');
            return;
        }

        // 2. App & Console Meta Definition (Supports: define app "Name" or define app as Name)
        if (line.startsWith('define app')) {
            let appName = 'HoloApp';
            const quoteMatch = line.match(/define app\s*(?:as)?\s*["'](.*?)["']/);
            const asMatch = line.match(/define app\s+as\s+([A-Za-z0-9_]+)/);
            if (quoteMatch) appName = quoteMatch[1];
            else if (asMatch) appName = asMatch[1];
            
            this.log(`[APP] Registered Game Title: "${appName}" for Shine Loop Console`, 'info');
            return;
        }

        // 3. Theme configuration
        if (line.startsWith('set theme to') || line.startsWith('set theme as')) {
            const match = line.match(/set theme (?:to|as) ["'](.*?)["']/);
            if (match) this.theme = match[1];
            return;
        }

        // 4. Variables: set <var> to <value> OR set <var> as <value>
        if (line.startsWith('set ') && (line.includes(' to ') || line.includes(' as '))) {
            const delimiter = line.includes(' to ') ? ' to ' : ' as ';
            const parts = line.replace('set ', '').split(delimiter);
            const varName = parts[0].trim();
            const valExpr = parts.slice(1).join(delimiter).trim();
            this.variables[varName] = this.evaluateExpression(valExpr);
            return;
        }

        // 5. Print output: print "...", var1, var2
        if (line.startsWith('print ')) {
            const expr = line.replace('print ', '').trim();
            const val = this.parsePrint(expr);
            this.log(val, 'output');
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
                this.log(`[DISPLAY] Shine Loop Display Mode: "${titleMatch[1]}" (${this.canvas.width}x${this.canvas.height})`, 'info');
            }
            return;
        }

        // 7. Draw Card UI: draw card at (x, y) with size (w, h) and title "..." and text "..."
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

        // 8. Draw Button UI: draw button at (x, y) with text "..." and action "..."
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

        // 9. Spawn Sprite / Player Entity: spawn sprite "name" at (x, y) with color "..." and size (w, h)
        if (line.startsWith('spawn sprite')) {
            const nameMatch = line.match(/spawn sprite ["'](.*?)["']/);
            const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
            const colorMatch = line.match(/color ["'](.*?)["']/);
            const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
            
            const name = nameMatch ? nameMatch[1] : 'Entity';
            const isPlayer = name.toLowerCase().includes('angel') || name.toLowerCase().includes('player') || name.toLowerCase().includes('forky');

            const sprite = {
                type: 'sprite',
                name: name,
                isPlayer: isPlayer,
                x: posMatch ? parseFloat(posMatch[1]) : 100,
                y: posMatch ? parseFloat(posMatch[2]) : 100,
                vx: 0,
                vy: 0,
                speed: 260,
                w: sizeMatch ? parseFloat(sizeMatch[1]) : 34,
                h: sizeMatch ? parseFloat(sizeMatch[2]) : 46,
                color: colorMatch ? colorMatch[1] : (isPlayer ? '#38bdf8' : '#ef4444'),
                isJumping: false,
                glowPulse: 0
            };
            this.gameEntities.push(sprite);
            this.log(`[SPRITE] Entity Spawned on Shine Loop Stage: "${sprite.name}"`, 'info');
            return;
        }

        // 10. Spawn Static Platform: spawn platform at (x, y) with size (w, h) and color "..."
        if (line.startsWith('spawn platform')) {
            const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
            const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
            const colorMatch = line.match(/color ["'](.*?)["']/);

            const platform = {
                type: 'platform',
                x: posMatch ? parseFloat(posMatch[1]) : 200,
                y: posMatch ? parseFloat(posMatch[2]) : 300,
                w: sizeMatch ? parseFloat(sizeMatch[1]) : 160,
                h: sizeMatch ? parseFloat(sizeMatch[2]) : 18,
                color: colorMatch ? colorMatch[1] : '#6366f1'
            };
            this.gameEntities.push(platform);
            this.log(`[PLATFORM] Platform Placed at (${platform.x}, ${platform.y})`, 'info');
            return;
        }

        // 11. Spawn Collectible Star/Coin: spawn coin at (x, y) with points <val>
        if (line.startsWith('spawn coin') || line.startsWith('spawn star')) {
            const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
            const pointsMatch = line.match(/points\s+(\d+)/);

            const coin = {
                type: 'coin',
                x: posMatch ? parseFloat(posMatch[1]) : 300,
                y: posMatch ? parseFloat(posMatch[2]) : 250,
                r: 10,
                points: pointsMatch ? parseInt(pointsMatch[1]) : 100,
                collected: false,
                floatOffset: Math.random() * 10
            };
            this.gameEntities.push(coin);
            this.log(`[STAR] Collectible Placed at (${coin.x}, ${coin.y}) [${coin.points} pts]`, 'info');
            return;
        }

        // 12. Particle System / Spark emitter: emit particles at (x, y) with color "..."
        if (line.startsWith('emit particles')) {
            const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
            const colorMatch = line.match(/color ["'](.*?)["']/);
            const px = posMatch ? parseInt(posMatch[1]) : 200;
            const py = posMatch ? parseInt(posMatch[2]) : 200;
            const pColor = colorMatch ? colorMatch[1] : '#6366f1';
            
            this.spawnParticleBurst(px, py, pColor, 20);
            return;
        }
    }

    spawnParticleBurst(x, y, color, count = 15) {
        for (let i = 0; i < count; i++) {
            const angle = Math.random() * Math.PI * 2;
            const speed = Math.random() * 150 + 50;
            this.particles.push({
                x: x,
                y: y,
                vx: Math.cos(angle) * speed,
                vy: Math.sin(angle) * speed,
                color: color,
                alpha: 1.0,
                size: Math.random() * 4 + 2,
                life: Math.random() * 0.8 + 0.4
            });
        }
    }

    evaluateExpression(expr) {
        if (expr === undefined || expr === null) return '';
        expr = String(expr).trim();
        if (!expr) return '';
        
        // Literal String in double quotes
        if (expr.startsWith('"') && expr.endsWith('"')) {
            return expr.slice(1, -1);
        }
        // Literal String in single quotes
        if (expr.startsWith("'") && expr.endsWith("'")) {
            return expr.slice(1, -1);
        }
        // Numbers
        if (!isNaN(expr) && expr !== '') {
            return Number(expr);
        }
        // Boolean
        if (expr === 'true') return true;
        if (expr === 'false') return false;

        // Variable lookup (with recursive resolution if needed)
        if (this.variables.hasOwnProperty(expr)) {
            let val = this.variables[expr];
            if (typeof val === 'string' && this.variables.hasOwnProperty(val)) {
                return this.variables[val];
            }
            return val;
        }

        return expr;
    }

    parsePrint(rawExpr) {
        // Split comma-separated arguments while respecting quoted strings
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
        if (current.trim()) {
            args.push(current.trim());
        }

        const evaluated = args.map(arg => this.evaluateExpression(arg));
        return evaluated.join(' ');
    }

    triggerEvent(event, data) {
        if (event === 'click') {
            for (let item of this.renderQueue) {
                if (item.type === 'button') {
                    if (data.x >= item.x && data.x <= item.x + item.w &&
                        data.y >= item.y && data.y <= item.y + item.h) {
                        this.log(`[GAME] Gamepad Trigger: [${item.text}] Activated!`, 'success');
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

    update(dt) {
        // Update Gamepad & Player Physics (Holo Looping OoS 60Hz Physics Core)
        for (let entity of this.gameEntities) {
            entity.glowPulse += dt * 5;

            if (entity.isPlayer) {
                // Movement via Gamepad or Keys
                if (this.gamepadState.dpad.left || this.keysDown['arrowleft'] || this.keysDown['a']) {
                    entity.vx = -entity.speed;
                } else if (this.gamepadState.dpad.right || this.keysDown['arrowright'] || this.keysDown['d']) {
                    entity.vx = entity.speed;
                } else {
                    entity.vx *= 0.82; // Friction deceleration
                }

                // Jump (Button A)
                if ((this.gamepadState.btnA || this.keysDown['arrowup'] || this.keysDown['w'] || this.keysDown[' ']) && !entity.isJumping) {
                    entity.vy = -420;
                    entity.isJumping = true;
                    this.spawnParticleBurst(entity.x + entity.w / 2, entity.y + entity.h, '#38bdf8', 12);
                }

                // Apply velocity
                entity.x += entity.vx * dt;

                // Gravity simulation
                entity.vy += 980 * dt;
                entity.y += entity.vy * dt;

                // Floor collision (Holo Game World Bounds)
                if (this.canvas && entity.y + entity.h >= this.canvas.height - 44) {
                    entity.y = this.canvas.height - 44 - entity.h;
                    entity.vy = 0;
                    entity.isJumping = false;
                }

                // Platform collisions
                for (let other of this.gameEntities) {
                    if (other.type === 'platform') {
                        // Check if landing on top of platform
                        if (entity.x + entity.w > other.x && entity.x < other.x + other.w) {
                            if (entity.y + entity.h >= other.y && entity.y + entity.h <= other.y + other.h + 12 && entity.vy >= 0) {
                                entity.y = other.y - entity.h;
                                entity.vy = 0;
                                entity.isJumping = false;
                            }
                        }
                    } else if (other.type === 'coin' && !other.collected) {
                        // Collect coin on overlap
                        const cx = other.x;
                        const cy = other.y;
                        if (entity.x + entity.w >= cx - other.r && entity.x <= cx + other.r &&
                            entity.y + entity.h >= cy - other.r && entity.y <= cy + other.r) {
                            other.collected = true;
                            this.score += other.points;
                            this.spawnParticleBurst(cx, cy, '#fbbf24', 20);
                            this.log(`[STAR] Coin Collected! Score: +${other.points} (Total: ${this.score})`, 'success');
                        }
                    }
                }

                // Screen edge clamp
                if (entity.x < 0) entity.x = 0;
                if (this.canvas && entity.x + entity.w > this.canvas.width) entity.x = this.canvas.width - entity.w;
            } else if (entity.type === 'sprite') {
                // Autonomous AI Patrol for Enemy NPCs
                if (!entity.patrolDir) entity.patrolDir = 1;
                entity.x += entity.patrolDir * 60 * dt;
                if (entity.x > 580) entity.patrolDir = -1;
                if (entity.x < 360) entity.patrolDir = 1;
            }
        }

        // Update Particle Sparks
        for (let i = this.particles.length - 1; i >= 0; i--) {
            const p = this.particles[i];
            p.x += p.vx * dt;
            p.y += p.vy * dt;
            p.vy += 400 * dt; // Gravity on particles
            p.alpha -= dt / p.life;
            if (p.alpha <= 0) {
                this.particles.splice(i, 1);
            }
        }
    }

    render() {
        if (!this.ctx || !this.canvas) return;
        const ctx = this.ctx;
        const w = this.canvas.width;
        const h = this.canvas.height;

        // 1. Clear Stage & Dark Neon Background
        ctx.fillStyle = '#06090f';
        ctx.fillRect(0, 0, w, h);

        // 2. Cyber Neon Wave (Xtraps Holo Ambient)
        ctx.strokeStyle = 'rgba(99, 102, 241, 0.12)';
        ctx.lineWidth = 2;
        ctx.beginPath();
        for (let x = 0; x <= w; x += 10) {
            const y = h / 2 + Math.sin(x * 0.01 + this.lastTime * 0.002) * 25;
            if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
        }
        ctx.stroke();

        // 3. Cyber Grid Lines
        ctx.strokeStyle = 'rgba(56, 189, 248, 0.04)';
        ctx.lineWidth = 1;
        for (let x = 0; x < w; x += 40) {
            ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, h); ctx.stroke();
        }
        for (let y = 0; y < h; y += 40) {
            ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke();
        }

        // 4. Ground Surface (Neon Barrier for Shine Loop Console)
        const groundGrad = ctx.createLinearGradient(0, h - 44, 0, h);
        groundGrad.addColorStop(0, '#0f172a');
        groundGrad.addColorStop(1, '#020617');
        ctx.fillStyle = groundGrad;
        ctx.fillRect(0, h - 44, w, 44);

        ctx.strokeStyle = '#38bdf8';
        ctx.shadowColor = '#38bdf8';
        ctx.shadowBlur = 10;
        ctx.lineWidth = 2.5;
        ctx.beginPath(); ctx.moveTo(0, h - 44); ctx.lineTo(w, h - 44); ctx.stroke();
        ctx.shadowBlur = 0;

        // 5. Render UI HUD Cards & Buttons
        for (let elem of this.renderQueue) {
            if (elem.type === 'card') {
                ctx.fillStyle = 'rgba(15, 23, 42, 0.82)';
                ctx.strokeStyle = 'rgba(99, 102, 241, 0.4)';
                ctx.lineWidth = 1.5;
                this.roundRect(ctx, elem.x, elem.y, elem.w, elem.h, 14, true, true);

                ctx.fillStyle = '#38bdf8';
                ctx.font = 'bold 15px Outfit, sans-serif';
                ctx.fillText(elem.title, elem.x + 18, elem.y + 32);

                ctx.fillStyle = '#94a3b8';
                ctx.font = '12px Outfit, sans-serif';
                const lines = elem.text.split('\n');
                for (let i = 0; i < lines.length; i++) {
                    ctx.fillText(lines[i], elem.x + 18, elem.y + 60 + (i * 20));
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

        // 6. Render Game Entities (Platforms, Coins & Sprites)
        for (let entity of this.gameEntities) {
            if (entity.type === 'platform') {
                // Neon Platform
                const pGrad = ctx.createLinearGradient(entity.x, entity.y, entity.x, entity.y + entity.h);
                pGrad.addColorStop(0, entity.color);
                pGrad.addColorStop(1, 'rgba(15, 23, 42, 0.9)');
                ctx.fillStyle = pGrad;
                ctx.strokeStyle = '#818cf8';
                ctx.lineWidth = 1.5;
                this.roundRect(ctx, entity.x, entity.y, entity.w, entity.h, 6, true, true);
            } else if (entity.type === 'coin' && !entity.collected) {
                // Spinning Neon Star/Coin
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
            } else if (entity.type === 'sprite') {
                ctx.fillStyle = entity.color;
                ctx.shadowColor = entity.color;
                ctx.shadowBlur = 14 + Math.sin(entity.glowPulse) * 4;
                this.roundRect(ctx, entity.x, entity.y, entity.w, entity.h, 8, true, false);
                
                // Name tag above sprite
                ctx.fillStyle = '#f1f5f9';
                ctx.font = 'bold 11px Outfit, sans-serif';
                ctx.textAlign = 'center';
                ctx.fillText(entity.name, entity.x + entity.w / 2, entity.y - 8);
                ctx.textAlign = 'left';
                ctx.shadowBlur = 0;
            }
        }

        // 7. Render Score Counter (if score > 0)
        if (this.score > 0) {
            ctx.fillStyle = 'rgba(15, 23, 42, 0.85)';
            ctx.strokeStyle = '#fbbf24';
            ctx.lineWidth = 1.5;
            this.roundRect(ctx, w - 160, 24, 135, 40, 10, true, true);

            ctx.fillStyle = '#fbbf24';
            ctx.font = 'bold 14px Outfit, sans-serif';
            ctx.fillText(`* SCORE: ${this.score}`, w - 145, 49);
        }

        // 7. Render Particle Bursts
        for (let p of this.particles) {
            ctx.fillStyle = p.color;
            ctx.globalAlpha = Math.max(0, p.alpha);
            ctx.beginPath();
            ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
            ctx.fill();
            ctx.globalAlpha = 1.0;
        }

        // 8. Shine Loop Console HUD Watermark
        ctx.fillStyle = 'rgba(255, 255, 255, 0.4)';
        ctx.font = '900 11px monospace';
        ctx.fillText("SHINE LOOP CONSOLE • HOLO LOOPING OOS", 20, h - 16);
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
