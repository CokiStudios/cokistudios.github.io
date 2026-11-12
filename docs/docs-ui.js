// ═══════════════════════════════════════════════════════════════
// COKI STUDIOS DOCS RUNTIME — Search Index, Copy Buttons & Navigation
// ═══════════════════════════════════════════════════════════════

(function () {
    const pathname = window.location.pathname || '/';
    const inDocsPrefix = pathname === '/docs' || pathname.startsWith('/docs/');
    const DOCS_BASE = inDocsPrefix ? '/docs' : '';

    const SEARCH_ITEMS = [
        { title: 'Inicio — Documentación Coki Studios', desc: 'Portal central de docs.cokistudios.com y arquitectura del ecosistema.', path: '/', tags: 'inicio docs home overview' },
        { title: 'Looping Engine v1.1 (Arch 3.0A)', desc: 'Lenguaje, 2D, Quantum 3D, Web Audio, pipelines |> y REPL.', path: '/looping/#overview', tags: 'looping engine 2d 3d sfx physics repl' },
        { title: 'Quantum 3D & Z-Buffer 240Hz', desc: 'scene3d.world, camera3d.set, spawn3d, físicas sub-stepped.', path: '/looping/#quantum3d', tags: 'quantum 3d camera3d scene3d spawn3d' },
        { title: 'Wavefront .OBJ Pipeline', desc: 'obj3d.load, obj3d.parse, obj3d.subdivide, obj3d.normalize, spawn3d.obj, Möller–Trumbore.', path: '/loopize/#obj', tags: 'obj mesh3d obj3d wavefront starfighter valkyrie omega' },
        { title: 'C# MonoBehaviour Bridge (cs!)', desc: 'Clases C# embebidas, LoopingBridge.Get/Set, Scene3D y compilación --target csharp.', path: '/loopize/#csharp', tags: 'csharp cs! monobehaviour bridge dotnet c#' },
        { title: 'Librería Híbrida loopize++', desc: 'ECS, Wave Director (lz_wave_rush), Spring-Arm Shake, FSM, Tweens, Combo x8 y Misiones XP.', path: '/loopize/#ecs-waves', tags: 'loopize++ ecs wave fsm tween combo quest aabb' },
        { title: 'Web Loopize Kit (<loopize-stage>)', desc: 'Web Components zero-dependencies para modelos .obj y escenas 3D en navegador.', path: '/loopize/#web-kit', tags: 'web-loopize-kit custom element web component browser' },
        { title: 'smiledev CLI & LoopModules', desc: 'Gestor universal de paquetes: install, init, link, pack, publish, add-repo y doctor.', path: '/smiledev/#commands', tags: 'smiledev cli brew install publish repo' },
        { title: 'Manifiesto smile.json Híbrido', desc: 'Configuración de módulos en .loop, Python, C++17, C# y Web JS.', path: '/smiledev/#manifest', tags: 'smile.json manifest hybrid polyglot' },
        { title: 'CS ID Connect (OAuth 2.1 + PKCE)', desc: 'Autenticación federada con <csid-connect-button>, One-Tap, SwiftUI y Kotlin AndroidKeyStore.', path: '/csid/#oauth', tags: 'csid oauth pkce passkey webauthn swift kotlin' },
        { title: 'CSMS E2EE & Edge Endpoints', desc: 'Cifrado AES-256-GCM enc:v1 y endpoints en cokistudios.com, repo, developer, docs y cdn.', path: '/csid/#edge', tags: 'csms e2ee aes gcm endpoints cdn repo developer docs' }
    ];

    function buildDocUrl(relPath) {
        if (!relPath.startsWith('/')) return relPath;
        return `${DOCS_BASE}${relPath}` || '/';
    }

    // Inject Copy Buttons inside pre wrappers
    function initCopyButtons() {
        document.querySelectorAll('pre').forEach((pre) => {
            if (pre.parentElement && pre.parentElement.classList.contains('docs-pre-wrap')) return;
            const wrap = document.createElement('div');
            wrap.className = 'docs-pre-wrap';
            pre.parentNode.insertBefore(wrap, pre);
            wrap.appendChild(pre);

            const btn = document.createElement('button');
            btn.type = 'button';
            btn.className = 'docs-copy-btn';
            btn.textContent = 'Copiar';
            btn.addEventListener('click', async () => {
                try {
                    await navigator.clipboard.writeText(pre.innerText.trim());
                    btn.textContent = 'Copiado!';
                    setTimeout(() => { btn.textContent = 'Copiar'; }, 1500);
                } catch {
                    btn.textContent = 'Error';
                }
            });
            wrap.appendChild(btn);
        });
    }

    // Build Search Modal
    function initSearchModal() {
        let backdrop = document.getElementById('docs-search-modal');
        if (!backdrop) {
            backdrop = document.createElement('div');
            backdrop.id = 'docs-search-modal';
            backdrop.className = 'docs-modal-backdrop';
            backdrop.innerHTML = `
                <div class="docs-modal" role="dialog" aria-label="Buscar en Documentación">
                    <div class="docs-modal-input-row">
                        <span style="color:var(--docs-accent);font-weight:800;">⌕</span>
                        <input id="docs-search-input" class="docs-modal-input" type="search" placeholder="Buscar Looping, .obj, C#, loopize++, smiledev, CS ID..." autocomplete="off">
                        <button type="button" id="docs-search-close" class="docs-kbd" style="background:none;cursor:pointer;">ESC</button>
                    </div>
                    <div id="docs-search-results" class="docs-modal-results"></div>
                </div>
            `;
            document.body.appendChild(backdrop);
        }

        const input = document.getElementById('docs-search-input');
        const resultsEl = document.getElementById('docs-search-results');
        const closeBtn = document.getElementById('docs-search-close');

        function renderResults(q) {
            const term = (q || '').trim().toLowerCase();
            const matched = term
                ? SEARCH_ITEMS.filter(item =>
                    item.title.toLowerCase().includes(term) ||
                    item.desc.toLowerCase().includes(term) ||
                    item.tags.toLowerCase().includes(term))
                : SEARCH_ITEMS;

            if (matched.length === 0) {
                resultsEl.innerHTML = `<div style="padding:18px;color:var(--docs-muted);font-size:0.9rem;">Sin resultados para "${term.replace(/[<>&"]/g, '')}".</div>`;
                return;
            }

            resultsEl.innerHTML = matched.map(item => `
                <a href="${buildDocUrl(item.path)}" class="docs-search-item">
                    <strong>${item.title}</strong>
                    <span>${item.desc}</span>
                </a>
            `).join('');
        }

        function openSearch() {
            backdrop.classList.add('open');
            renderResults(input.value);
            setTimeout(() => input.focus(), 20);
        }

        function closeSearch() {
            backdrop.classList.remove('open');
        }

        document.querySelectorAll('[data-docs-search-open]').forEach(btn => {
            btn.addEventListener('click', openSearch);
        });
        closeBtn.addEventListener('click', closeSearch);
        backdrop.addEventListener('click', (e) => {
            if (e.target === backdrop) closeSearch();
        });
        input.addEventListener('input', () => renderResults(input.value));
        resultsEl.addEventListener('click', closeSearch);

        document.addEventListener('keydown', (e) => {
            if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
                e.preventDefault();
                openSearch();
            } else if (e.key === '/' && document.activeElement?.tagName !== 'INPUT' && document.activeElement?.tagName !== 'TEXTAREA') {
                e.preventDefault();
                openSearch();
            } else if (e.key === 'Escape' && backdrop.classList.contains('open')) {
                closeSearch();
            }
        });
    }

    // Mobile sidebar drawer toggle
    function initMobileSidebar() {
        const btn = document.getElementById('docs-mobile-menu');
        const sidebar = document.querySelector('.docs-sidebar');
        if (btn && sidebar) {
            btn.addEventListener('click', () => {
                sidebar.classList.toggle('open');
            });
        }
    }

    // Rewrite ecosystem links cleanly when accessed on docs.cokistudios.com vs cokistudios.com
    function syncExternalWebLinks() {
        if (window.location.hostname !== 'docs.cokistudios.com') return;
        document.querySelectorAll('[data-web-path]').forEach(el => {
            const p = el.getAttribute('data-web-path').replace(/^\/+/, '');
            el.setAttribute('href', `https://cokistudios.com/${p}`);
        });
    }

    document.addEventListener('DOMContentLoaded', () => {
        initCopyButtons();
        initSearchModal();
        initMobileSidebar();
        syncExternalWebLinks();
    });
})();
