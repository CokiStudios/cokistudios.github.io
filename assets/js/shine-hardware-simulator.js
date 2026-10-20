/* ═══════════════════════════════════════════════════════════════════════
   🎮 SHINE HARDWARE SIMULATOR & PLAYABLE RETRO ARCADE
   Shine Handheld Console APU & Phone Duo (flUI Fold) Simulator
   Holo Entertainment & Coki Studios © 2026
   ═══════════════════════════════════════════════════════════════════════ */

(function () {
    let canvas, ctx;
    let animFrameId = null;
    let gameRunning = false;
    let score = 0;
    let apuFps = 60;
    let lastTime = 0;
    let currentFps = 60;

    // Player state
    const player = {
        x: 140,
        y: 130,
        width: 22,
        height: 18,
        speed: 3.5,
        color: '#00f5d4'
    };

    // Keys
    const keys = {
        ArrowUp: false,
        ArrowDown: false,
        ArrowLeft: false,
        ArrowRight: false,
        Space: false
    };

    // Game objects
    let stars = [];
    let crystals = [];
    let obstacles = [];

    function initGame() {
        canvas = document.getElementById('shine-screen-canvas');
        if (!canvas) return;
        ctx = canvas.getContext('2d');

        // Initialize stars
        stars = [];
        for (let i = 0; i < 40; i++) {
            stars.push({
                x: Math.random() * canvas.width,
                y: Math.random() * canvas.height,
                size: Math.random() * 2 + 0.5,
                speed: Math.random() * 1.5 + 0.5
            });
        }

        crystals = [];
        obstacles = [];
        score = 0;
        player.x = 40;
        player.y = canvas.height / 2;

        setupKeyListeners();
        setupTouchControls();

        // Start render loop
        if (!animFrameId) {
            lastTime = performance.now();
            gameLoop(lastTime);
        }
    }

    function setupKeyListeners() {
        window.addEventListener('keydown', (e) => {
            if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Space'].includes(e.code)) {
                // Only prevent default if focus is on simulator
                const simBox = document.getElementById('shine-hardware-simulator');
                if (simBox && simBox.matches(':hover')) {
                    e.preventDefault();
                }
                keys[e.code] = true;
            }
        });

        window.addEventListener('keyup', (e) => {
            if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Space'].includes(e.code)) {
                keys[e.code] = false;
            }
        });
    }

    function setupTouchControls() {
        const bindBtn = (id, keyCode) => {
            const btn = document.getElementById(id);
            if (!btn) return;

            const press = (e) => {
                e.preventDefault();
                keys[keyCode] = true;
                btn.classList.add('pressed');
            };
            const release = (e) => {
                e.preventDefault();
                keys[keyCode] = false;
                btn.classList.remove('pressed');
            };

            btn.addEventListener('mousedown', press);
            btn.addEventListener('mouseup', release);
            btn.addEventListener('mouseleave', release);
            btn.addEventListener('touchstart', press, { passive: false });
            btn.addEventListener('touchend', release, { passive: false });
        };

        bindBtn('btn-dpad-up', 'ArrowUp');
        bindBtn('btn-dpad-down', 'ArrowDown');
        bindBtn('btn-dpad-left', 'ArrowLeft');
        bindBtn('btn-dpad-right', 'ArrowRight');
        bindBtn('btn-act-a', 'Space');
        bindBtn('btn-act-b', 'Space');
    }

    function spawnObjects() {
        if (Math.random() < 0.035) {
            crystals.push({
                x: canvas.width + 10,
                y: Math.random() * (canvas.height - 30) + 15,
                size: 8,
                speed: 2.2
            });
        }

        if (Math.random() < 0.025) {
            obstacles.push({
                x: canvas.width + 10,
                y: Math.random() * (canvas.height - 30) + 15,
                size: 14,
                speed: 3.0
            });
        }
    }

    function update() {
        // Player movement
        if (keys.ArrowUp && player.y > 10) player.y -= player.speed;
        if (keys.ArrowDown && player.y < canvas.height - player.height - 10) player.y += player.speed;
        if (keys.ArrowLeft && player.x > 10) player.x -= player.speed;
        if (keys.ArrowRight && player.x < canvas.width - player.width - 10) player.x += player.speed;

        // Background stars
        stars.forEach(s => {
            s.x -= s.speed;
            if (s.x < 0) s.x = canvas.width;
        });

        spawnObjects();

        // Crystals update & collision
        for (let i = crystals.length - 1; i >= 0; i--) {
            const c = crystals[i];
            c.x -= c.speed;

            // Collision check
            if (
                player.x < c.x + c.size &&
                player.x + player.width > c.x - c.size &&
                player.y < c.y + c.size &&
                player.y + player.height > c.y - c.size
            ) {
                crystals.splice(i, 1);
                score += 100;
                if (window.triggerSoundEffect) window.triggerSoundEffect('coin');
                continue;
            }

            if (c.x < -10) crystals.splice(i, 1);
        }

        // Obstacles update & collision
        for (let i = obstacles.length - 1; i >= 0; i--) {
            const o = obstacles[i];
            o.x -= o.speed;

            if (
                player.x < o.x + o.size &&
                player.x + player.width > o.x - o.size &&
                player.y < o.y + o.size &&
                player.y + player.height > o.y - o.size
            ) {
                obstacles.splice(i, 1);
                score = Math.max(0, score - 50);
                if (window.triggerSoundEffect) window.triggerSoundEffect('hit');
                continue;
            }

            if (o.x < -20) obstacles.splice(i, 1);
        }
    }

    function render() {
        ctx.fillStyle = '#05070d';
        ctx.fillRect(0, 0, canvas.width, canvas.height);

        // Draw stars
        ctx.fillStyle = '#94a3b8';
        stars.forEach(s => {
            ctx.fillRect(s.x, s.y, s.size, s.size);
        });

        // Draw Crystals (Neon Emerald)
        crystals.forEach(c => {
            ctx.save();
            ctx.fillStyle = '#10b981';
            ctx.shadowColor = '#10b981';
            ctx.shadowBlur = 8;
            ctx.beginPath();
            ctx.arc(c.x, c.y, c.size, 0, Math.PI * 2);
            ctx.fill();
            ctx.restore();
        });

        // Draw Obstacles (Orange Debris)
        obstacles.forEach(o => {
            ctx.save();
            ctx.fillStyle = '#f59e0b';
            ctx.shadowColor = '#f59e0b';
            ctx.shadowBlur = 6;
            ctx.fillRect(o.x - o.size / 2, o.y - o.size / 2, o.size, o.size);
            ctx.restore();
        });

        // Draw Player Shuttle (Cyan Triangle with engine flame)
        ctx.save();
        ctx.shadowColor = '#00f5d4';
        ctx.shadowBlur = 10;
        ctx.fillStyle = player.color;
        ctx.beginPath();
        ctx.moveTo(player.x + player.width, player.y + player.height / 2);
        ctx.lineTo(player.x, player.y);
        ctx.lineTo(player.x + 4, player.y + player.height / 2);
        ctx.lineTo(player.x, player.y + player.height);
        ctx.closePath();
        ctx.fill();

        // Engine flame
        ctx.fillStyle = '#38bdf8';
        ctx.beginPath();
        ctx.moveTo(player.x, player.y + player.height / 2 - 2);
        ctx.lineTo(player.x - 6 - Math.random() * 4, player.y + player.height / 2);
        ctx.lineTo(player.x, player.y + player.height / 2 + 2);
        ctx.closePath();
        ctx.fill();
        ctx.restore();

        // Top HUD
        ctx.fillStyle = 'rgba(255, 255, 255, 0.85)';
        ctx.font = '700 11px "JetBrains Mono", monospace';
        ctx.fillText(`SCORE: ${score}`, 12, 18);
        ctx.fillStyle = '#00f5d4';
        ctx.fillText(`APU: ${currentFps} FPS (XUI Direct)`, canvas.width - 160, 18);
    }

    function gameLoop(timestamp) {
        animFrameId = requestAnimationFrame(gameLoop);
        const delta = timestamp - lastTime;
        lastTime = timestamp;
        currentFps = Math.min(apuFps, Math.round(1000 / Math.max(1, delta)));

        update();
        render();
    }

    window.toggleConsoleMode = function (mode) {
        const consoleEl = document.getElementById('shine-hardware-chassis');
        const modeBtnH = document.getElementById('btn-mode-handheld');
        const modeBtnD = document.getElementById('btn-mode-duo');
        if (!consoleEl) return;

        if (mode === 'duo') {
            consoleEl.classList.add('mode-phone-duo');
            if (modeBtnD) modeBtnD.classList.add('active');
            if (modeBtnH) modeBtnH.classList.remove('active');
        } else {
            consoleEl.classList.remove('mode-phone-duo');
            if (modeBtnH) modeBtnH.classList.add('active');
            if (modeBtnD) modeBtnD.classList.remove('active');
        }
    };

    window.toggleOverclock = function () {
        const badge = document.getElementById('shine-apu-badge');
        if (apuFps === 60) {
            apuFps = 240;
            player.speed = 5.0;
            if (badge) {
                badge.innerText = '⚡ APU OVERCLOCK: 240Hz (XUI)';
                badge.style.color = '#38bdf8';
            }
        } else {
            apuFps = 60;
            player.speed = 3.5;
            if (badge) {
                badge.innerText = '● SHINE APU: 60Hz Direct V-Sync';
                badge.style.color = '#00f5d4';
            }
        }
        if (window.triggerSoundEffect) window.triggerSoundEffect('powerup');
    };

    document.addEventListener('DOMContentLoaded', initGame);
})();
