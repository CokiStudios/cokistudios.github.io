// ═══════════════════════════════════════════════════════════════
// ♾️ LOOPING COMPILE — CORE RUNTIME & GRAPHIC ENGINE v1.0
// Proprietary Language Interpreter by Holo & Coki Studios
// ═══════════════════════════════════════════════════════════════

export class LoopingInterpreter {
    constructor(canvas, terminalOutput) {
        this.canvas = canvas;
        this.ctx = canvas ? canvas.getContext('2d') : null;
        this.terminalOutput = terminalOutput || console.log;
        
        // Environment State
        this.variables = {};
        this.functions = {};
        this.eventListeners = [];
        this.renderQueue = [];
        this.gameEntities = [];
        this.theme = 'dark_neon';
        this.isRunning = false;
        this.animationFrameId = null;
        this.lastTime = 0;
        
        // Input state
        this.keysDown = {};
        this.mousePos = { x: 0, y: 0 };
        this.isMouseDown = false;
        
        this.setupInputListeners();
    }
    
    setupInputListeners() {
        if (!this.canvas) return;
        
        window.addEventListener('keydown', (e) => {
            this.keysDown[e.key.toLowerCase()] = true;
            this.keysDown[e.code.toLowerCase()] = true;
            this.triggerEvent('keydown', e.key);
        });
        
        window.addEventListener('keyup', (e) => {
            this.keysDown[e.key.toLowerCase()] = false;
            this.keysDown[e.code.toLowerCase()] = false;
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
            console.log(`[Looping ${type.toUpperCase()}]:`, message);
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
        this.eventListeners = [];
        this.renderQueue = [];
        this.gameEntities = [];
        if (this.ctx && this.canvas) {
            this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        }
    }

    // ── Lexer & Code Parser ──
    execute(code) {
        this.reset();
        this.log("⚡ Compiling with CS Looping Runtime Engine...", "system");
        
        const lines = code.split('\n');
        let inBlock = null;
        let blockContent = [];
        
        for (let i = 0; i < lines.length; i++) {
            let line = lines[i].trim();
            if (!line || line.startsWith('#') || line.startsWith('//')) continue;
            
            try {
                this.parseLine(line);
            } catch (err) {
                this.log(`❌ Error at line ${i + 1}: ${err.message}`, "error");
                return false;
            }
        }

        this.log("✅ Compilation successful! Running application...", "success");
        this.startLoop();
        return true;
    }

    parseLine(line) {
        // 1. Theme configuration
        if (line.startsWith('set theme to')) {
            const match = line.match(/set theme to ["'](.*?)["']/);
            if (match) this.theme = match[1];
            return;
        }

        // 2. Variable assignments: set <var> to <value>
        if (line.startsWith('set ') && line.includes(' to ')) {
            const parts = line.replace('set ', '').split(' to ');
            const varName = parts[0].trim();
            const valExpr = parts[1].trim();
            this.variables[varName] = this.evaluateExpression(valExpr);
            return;
        }

        // 3. Print statements: print "Hello", x
        if (line.startsWith('print ')) {
            const expr = line.replace('print ', '').trim();
            const val = this.evaluateExpression(expr);
            this.log(val, 'output');
            return;
        }

        // 4. GUI Window Creation: create window with title "Title" and size (width, height)
        if (line.startsWith('create window')) {
            const titleMatch = line.match(/title ["'](.*?)["']/);
            const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
            if (sizeMatch && this.canvas) {
                this.canvas.width = parseInt(sizeMatch[1]);
                this.canvas.height = parseInt(sizeMatch[2]);
            }
            if (titleMatch) {
                this.log(`🖼️ Window created: "${titleMatch[1]}"`, 'info');
            }
            return;
        }

        // 5. Draw Card UI: draw card at (x, y) with size (w, h) and title "..." and text "..."
        if (line.startsWith('draw card at')) {
            const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
            const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
            const titleMatch = line.match(/title ["'](.*?)["']/);
            const textMatch = line.match(/text ["'](.*?)["']/);
            
            const card = {
                type: 'card',
                x: posMatch ? parseInt(posMatch[1]) : 50,
                y: posMatch ? parseInt(posMatch[2]) : 50,
                w: sizeMatch ? parseInt(sizeMatch[1]) : 300,
                h: sizeMatch ? parseInt(sizeMatch[2]) : 140,
                title: titleMatch ? titleMatch[1] : 'Looping Card',
                text: textMatch ? textMatch[1] : ''
            };
            this.renderQueue.push(card);
            return;
        }

        // 6. Draw Button UI: draw button at (x, y) with text "..." and action "..."
        if (line.startsWith('draw button at')) {
            const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
            const textMatch = line.match(/text ["'](.*?)["']/);
            const actionMatch = line.match(/action ["'](.*?)["']/);
            
            const btn = {
                type: 'button',
                x: posMatch ? parseInt(posMatch[1]) : 50,
                y: posMatch ? parseInt(posMatch[2]) : 200,
                w: 160,
                h: 44,
                text: textMatch ? textMatch[1] : 'Click Me',
                action: actionMatch ? actionMatch[1] : ''
            };
            this.renderQueue.push(btn);
            return;
        }

        // 7. Game Engine Sprite: spawn sprite "name" at (x, y) with color "..." and size (w, h)
        if (line.startsWith('spawn sprite')) {
            const nameMatch = line.match(/spawn sprite ["'](.*?)["']/);
            const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
            const colorMatch = line.match(/color ["'](.*?)["']/);
            const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
            
            const sprite = {
                name: nameMatch ? nameMatch[1] : 'sprite',
                x: posMatch ? parseFloat(posMatch[1]) : 100,
                y: posMatch ? parseFloat(posMatch[2]) : 100,
                vx: 0,
                vy: 0,
                w: sizeMatch ? parseFloat(sizeMatch[1]) : 32,
                h: sizeMatch ? parseFloat(sizeMatch[2]) : 32,
                color: colorMatch ? colorMatch[1] : '#38bdf8',
                isJumping: false
            };
            this.gameEntities.push(sprite);
            return;
        }
    }

    evaluateExpression(expr) {
        if (!expr) return '';
        // If string literal
        if ((expr.startsWith('"') && expr.endsWith('"')) || (expr.startsWith("'") && expr.endsWith("'"))) {
            return expr.slice(1, -1);
        }
        // If number
        if (!isNaN(expr)) {
            return Number(expr);
        }
        // If variable
        if (this.variables.hasOwnProperty(expr)) {
            return this.variables[expr];
        }
        return expr;
    }

    triggerEvent(event, data) {
        if (event === 'click') {
            for (let item of this.renderQueue) {
                if (item.type === 'button') {
                    if (data.x >= item.x && data.x <= item.x + item.w &&
                        data.y >= item.y && data.y <= item.y + item.h) {
                        this.log(`🔘 Button Clicked: "${item.text}"`, 'info');
                        if (item.action) {
                            this.log(`⚡ Executing action: ${item.action}`, 'system');
                        }
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
            const dt = (timestamp - this.lastTime) / 1000;
            this.lastTime = timestamp;
            
            this.update(dt);
            this.render();
            
            this.animationFrameId = requestAnimationFrame(loop);
        };
        this.animationFrameId = requestAnimationFrame(loop);
    }

    update(dt) {
        // Simple 2D game movement update
        for (let entity of this.gameEntities) {
            if (this.keysDown['arrowleft'] || this.keysDown['a']) {
                entity.x -= 200 * dt;
            }
            if (this.keysDown['arrowright'] || this.keysDown['d']) {
                entity.x += 200 * dt;
            }
            if ((this.keysDown['arrowup'] || this.keysDown['w'] || this.keysDown[' ']) && !entity.isJumping) {
                entity.vy = -350;
                entity.isJumping = true;
            }

            // Gravity
            entity.vy += 800 * dt;
            entity.y += entity.vy * dt;

            // Floor collision
            if (this.canvas && entity.y + entity.h >= this.canvas.height - 40) {
                entity.y = this.canvas.height - 40 - entity.h;
                entity.vy = 0;
                entity.isJumping = false;
            }
        }
    }

    render() {
        if (!this.ctx || !this.canvas) return;
        const ctx = this.ctx;
        const w = this.canvas.width;
        const h = this.canvas.height;

        // Background
        ctx.fillStyle = this.theme === 'dark_neon' ? '#06090f' : '#0d1117';
        ctx.fillRect(0, 0, w, h);

        // Cyber Grid Lines
        ctx.strokeStyle = 'rgba(56, 189, 248, 0.06)';
        ctx.lineWidth = 1;
        for (let x = 0; x < w; x += 40) {
            ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, h); ctx.stroke();
        }
        for (let y = 0; y < h; y += 40) {
            ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke();
        }

        // Draw Ground Floor
        ctx.fillStyle = 'rgba(15, 23, 42, 0.9)';
        ctx.fillRect(0, h - 40, w, 40);
        ctx.strokeStyle = '#38bdf8';
        ctx.lineWidth = 2;
        ctx.beginPath(); ctx.moveTo(0, h - 40); ctx.lineTo(w, h - 40); ctx.stroke();

        // Render UI Elements in Queue
        for (let elem of this.renderQueue) {
            if (elem.type === 'card') {
                // Glassmorphism Card
                ctx.fillStyle = 'rgba(30, 41, 59, 0.7)';
                ctx.strokeStyle = 'rgba(99, 102, 241, 0.4)';
                ctx.lineWidth = 1.5;
                this.roundRect(ctx, elem.x, elem.y, elem.w, elem.h, 14, true, true);

                // Card Title
                ctx.fillStyle = '#38bdf8';
                ctx.font = 'bold 16px Outfit, sans-serif';
                ctx.fillText(elem.title, elem.x + 20, elem.y + 36);

                // Card Text
                ctx.fillStyle = '#94a3b8';
                ctx.font = '13px Outfit, sans-serif';
                ctx.fillText(elem.text, elem.x + 20, elem.y + 68);
            } else if (elem.type === 'button') {
                // Neon Button
                ctx.fillStyle = 'rgba(99, 102, 241, 0.9)';
                ctx.strokeStyle = '#818cf8';
                ctx.lineWidth = 1.5;
                this.roundRect(ctx, elem.x, elem.y, elem.w, elem.h, 10, true, true);

                ctx.fillStyle = '#ffffff';
                ctx.font = 'bold 14px Outfit, sans-serif';
                ctx.textAlign = 'center';
                ctx.fillText(elem.text, elem.x + elem.w / 2, elem.y + 27);
                ctx.textAlign = 'left';
            }
        }

        // Render Game Entities
        for (let sprite of this.gameEntities) {
            ctx.fillStyle = sprite.color;
            ctx.shadowColor = sprite.color;
            ctx.shadowBlur = 12;
            this.roundRect(ctx, sprite.x, sprite.y, sprite.w, sprite.h, 8, true, false);
            ctx.shadowBlur = 0; // reset
        }
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
