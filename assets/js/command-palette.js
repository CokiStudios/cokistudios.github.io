/* ═══════════════════════════════════════════════════════════════════════
   ⌘ GLOBAL COMMAND PALETTE (CMD+K / SPOTLIGHT)
   Quick navigation, actions, downloads and developer tools
   Coki Studios © 2026
   ═══════════════════════════════════════════════════════════════════════ */

(function () {
    const COMMANDS = [
        {
            title: "Looping Engine v2.7.0 Quantum Signature",
            category: "Motor",
            desc: "Regex, HMAC-SHA256, Data Science Math, AST Inspector y REPL C++17",
            action: () => { window.location.hash = '#engine-section'; }
        },
        {
            title: "hiOP Studio Web IDE (Looping v2.7)",
            category: "IDE",
            desc: "Editor interactivo .loop con vista previa 60FPS, AST y formateador",
            action: () => { window.location.href = 'hiop-ide'; }
        },
        {
            title: "Forkar Eco Hub — Retos, Sondeos & Certificado CO₂",
            category: "Eco Hub",
            desc: "Misiones semanales, sondeos ciudadanos, ranking Sabana y certificado PNG",
            action: () => { window.location.href = 'eco-hub'; }
        },
        {
            title: "Instalar vía Homebrew (brew install looping smiledev)",
            category: "CLI",
            desc: "Copiar comando oficial de Homebrew tap",
            action: () => {
                navigator.clipboard.writeText('brew tap CokiStudios/cokistudios.github.io && brew install looping smiledev');
                alert('¡Comando Homebrew copiado al portapapeles!');
            }
        },
        {
            title: "Auto-Actualizar Motor (smiledev upgrade)",
            category: "CLI",
            desc: "Actualizar smiledev y Looping desde repo.cokistudios.com/engine",
            action: () => {
                navigator.clipboard.writeText('smiledev upgrade');
                alert('¡Comando "smiledev upgrade" copiado al portapapeles!');
            }
        },
        {
            title: "CSMS Messenger (E2EE con SEP / TEE)",
            category: "Producto",
            desc: "Mensajería ultrarrápida cifrada para iOS, macOS y Web",
            action: () => { window.location.href = 'messenger'; }
        },
        {
            title: "Forkar & Eco Hub (Sabana de Bogotá)",
            category: "Comunidad",
            desc: "Red de sostenibilidad, retos y estaciones en Cota, Chía y Bogotá",
            action: () => { window.location.href = 'forkar'; }
        },
        {
            title: "Felte Store",
            category: "Tienda",
            desc: "Tienda oficial de productos, merchandise y software",
            action: () => { window.location.href = 'felte.html'; }
        },
        {
            title: "CS ID — Mi Cuenta & Perfil",
            category: "Identidad",
            desc: "Gestión unificada de cuenta, seguridad y Passkeys",
            action: () => { window.location.href = 'register'; }
        },
        {
            title: "Catálogo de Productos",
            category: "Explorar",
            desc: "Todos los proyectos, juegos y servicios de Coki Studios",
            action: () => { window.location.href = 'products'; }
        },
        {
            title: "Descargar DMG (Looping macOS Universal)",
            category: "Descargas",
            desc: "Instalador gráfico .dmg para Apple Silicon y procesadores Intel",
            action: () => { window.location.href = 'https://repo.cokistudios.com/engine/Looping-Engine-v2.6.0-macOS.dmg'; }
        },
        {
            title: "Descargar PKG (Instalador Nativo macOS)",
            category: "Descargas",
            desc: "Paquete oficial .pkg para administradores de sistemas",
            action: () => { window.location.href = 'https://repo.cokistudios.com/engine/Instalar-Looping.pkg'; }
        },
        {
            title: "Cambiar Tema (Oscuro / Claro)",
            category: "Ajustes",
            desc: "Alternar entre modo oscuro y tema claro",
            action: () => {
                const btn = document.getElementById('theme-toggle');
                if (btn) btn.click();
            }
        },
        {
            title: "Simulador Consola Shine Handheld & Phone Duo",
            category: "Hardware",
            desc: "Probar el chasis 3D, controles táctiles y minijuego espacial Holo",
            action: () => { window.location.hash = '#shine-hardware-simulator'; }
        },
        {
            title: "Radar Forkar Eco Hub (Cota • Chía • Bogotá)",
            category: "Eco Hub",
            desc: "Calculadora de CO₂, validación en estaciones y árboles Majuy",
            action: () => { window.location.hash = '#eco-radar-section'; }
        },
        {
            title: "CSMS Web Messenger (Chat en Vivo)",
            category: "Mensajería",
            desc: "Simulador de chat E2EE con canales temáticos y notas de voz",
            action: () => { window.location.hash = '#csms-web-simulator-section'; }
        },
        {
            title: "Centro de Passkeys & Seguridad Biométrica CSID",
            category: "Seguridad",
            desc: "Probar Touch ID / Face ID con firma criptográfica P-256",
            action: () => {
                window.location.hash = '#csid-passkeys-list';
                if (window.simulateBiometricAuth) window.simulateBiometricAuth();
            }
        },
        {
            title: "Bolsa de Compras Felte Store",
            category: "Tienda",
            desc: "Ver carrito, seleccionar moneda (COP/USD/EUR) y canjear Puntos Eco",
            action: () => { window.location.hash = '#felte-store-section'; }
        },
        {
            title: "Abrir Asistente Coki AI",
            category: "IA",
            desc: "Preguntar sobre Looping, smiledev, CSMS o Eco Hub",
            action: () => {
                if (window.openCokiAiWidget) window.openCokiAiWidget();
            }
        }
    ];

    let selectedIndex = 0;
    let filteredCommands = [...COMMANDS];

    function createPaletteModal() {
        if (document.getElementById('cs-cmd-backdrop')) return;

        const backdrop = document.createElement('div');
        backdrop.id = 'cs-cmd-backdrop';
        backdrop.className = 'cs-cmd-palette-backdrop';
        backdrop.innerHTML = `
            <div class="cs-cmd-palette-modal" onclick="event.stopPropagation()">
                <div class="cs-cmd-input-wrap">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="color:var(--text-sub);">
                        <circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                    </svg>
                    <input type="text" id="cs-cmd-input" class="cs-cmd-input" placeholder="Escribe para buscar comandos, productos, descargas..." autocomplete="off" spellcheck="false" />
                    <kbd style="padding: 2px 6px; border-radius: 4px; background: rgba(255,255,255,0.08); font-size: 11px; color: var(--text-sub);">ESC</kbd>
                </div>
                <div id="cs-cmd-results" class="cs-cmd-results"></div>
                <div class="cs-cmd-footer">
                    <span>Navega con <b>↑</b> <b>↓</b> y ejecuta con <b>↵ Enter</b></span>
                    <span>Coki Studios Spotlight</span>
                </div>
            </div>
        `;

        backdrop.addEventListener('click', closePalette);
        document.body.appendChild(backdrop);

        const input = document.getElementById('cs-cmd-input');
        input.addEventListener('input', (e) => {
            renderResults(e.target.value);
        });

        input.addEventListener('keydown', (e) => {
            if (e.key === 'ArrowDown') {
                e.preventDefault();
                selectedIndex = (selectedIndex + 1) % filteredCommands.length;
                updateSelected();
            } else if (e.key === 'ArrowUp') {
                e.preventDefault();
                selectedIndex = (selectedIndex - 1 + filteredCommands.length) % filteredCommands.length;
                updateSelected();
            } else if (e.key === 'Enter') {
                e.preventDefault();
                if (filteredCommands[selectedIndex]) {
                    closePalette();
                    filteredCommands[selectedIndex].action();
                }
            } else if (e.key === 'Escape') {
                closePalette();
            }
        });
    }

    function renderResults(filterText = '') {
        const resultsEl = document.getElementById('cs-cmd-results');
        const term = filterText.toLowerCase().trim();

        filteredCommands = COMMANDS.filter(cmd => {
            return cmd.title.toLowerCase().includes(term) ||
                   cmd.desc.toLowerCase().includes(term) ||
                   cmd.category.toLowerCase().includes(term);
        });

        selectedIndex = 0;

        if (filteredCommands.length === 0) {
            resultsEl.innerHTML = `<div style="padding:24px; text-align:center; color:var(--text-sub); font-size:14px;">No se encontraron resultados para "${filterText}"</div>`;
            return;
        }

        resultsEl.innerHTML = filteredCommands.map((cmd, idx) => `
            <div class="cs-cmd-item ${idx === 0 ? 'selected' : ''}" data-idx="${idx}">
                <div class="cs-cmd-item-left">
                    <span class="cs-cmd-item-badge">${cmd.category}</span>
                    <div>
                        <div style="font-weight: 600; font-size: 14px;">${cmd.title}</div>
                        <div style="font-size: 12px; color: var(--text-sub); margin-top: 2px;">${cmd.desc}</div>
                    </div>
                </div>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="color:var(--text-sub);"><polyline points="9 18 15 12 9 6"></polyline></svg>
            </div>
        `).join('');

        resultsEl.querySelectorAll('.cs-cmd-item').forEach(item => {
            item.addEventListener('click', () => {
                const idx = parseInt(item.dataset.idx, 10);
                if (filteredCommands[idx]) {
                    closePalette();
                    filteredCommands[idx].action();
                }
            });
        });
    }

    function updateSelected() {
        const items = document.querySelectorAll('.cs-cmd-item');
        items.forEach((item, idx) => {
            if (idx === selectedIndex) {
                item.classList.add('selected');
                item.scrollIntoView({ block: 'nearest' });
            } else {
                item.classList.remove('selected');
            }
        });
    }

    function openPalette() {
        createPaletteModal();
        const backdrop = document.getElementById('cs-cmd-backdrop');
        const input = document.getElementById('cs-cmd-input');
        if (!backdrop || !input) return;

        backdrop.classList.add('active');
        input.value = '';
        renderResults('');
        setTimeout(() => input.focus(), 50);
    }

    function closePalette() {
        const backdrop = document.getElementById('cs-cmd-backdrop');
        if (backdrop) backdrop.classList.remove('active');
    }

    window.openCommandPalette = openPalette;

    // Keyboard trigger: Cmd+K, Ctrl+K or '/'
    document.addEventListener('keydown', (e) => {
        if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
            e.preventDefault();
            const backdrop = document.getElementById('cs-cmd-backdrop');
            if (backdrop && backdrop.classList.contains('active')) {
                closePalette();
            } else {
                openPalette();
            }
        }
    });

    // Auto initialize trigger button
    document.addEventListener('DOMContentLoaded', () => {
        const trigger = document.getElementById('cmdPaletteTrigger');
        if (trigger) trigger.addEventListener('click', openPalette);
    });
})();
