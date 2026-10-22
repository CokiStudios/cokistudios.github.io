/* ═══════════════════════════════════════════════════════════════════════
   🌱 FORKAR COMMUNITY & ECO SUITE
   Weekly Quests, Community Polls, Filter Pills & Forkman Eco Guide
   Coki Studios © 2026
   ═══════════════════════════════════════════════════════════════════════ */

(function () {
    // ── 1. WEEKLY ECO QUESTS STATE ──
    const QUESTS = [
        {
            id: 'quest-majuy-bici',
            title: '🚴 Reto Bici Sabana (Ruta Majuy)',
            desc: 'Recorre 20 km en bicicleta por la ruta Cota - Chía o hacia el Cerro del Majuy.',
            reward: 150,
            badge: 'Explorador del Majuy',
            progress: 14,
            goal: 20,
            unit: 'km'
        },
        {
            id: 'quest-raee-cota',
            title: '🔋 Misión Punto RAEE Alcaldía',
            desc: 'Deposita baterías o cables en desuso en el Punto Limpio de la Alcaldía de Cota.',
            reward: 80,
            badge: 'Escudo Verde',
            progress: 2,
            goal: 3,
            unit: 'depósitos'
        },
        {
            id: 'quest-termo-chia',
            title: '☕ Desafío Termo Cero Residuos',
            desc: 'Pide tu bebida en termo reutilizable en cafeterías aliadas de Cota o Chía.',
            reward: 40,
            badge: 'Héroe Cero Plástico',
            progress: 1,
            goal: 2,
            unit: 'visitas'
        }
    ];

    // ── 2. COMMUNITY PULSE POLL STATE ──
    const POLL_DATA = {
        question: '¿Cuál debería ser la próxima estación Eco Hub en la Sabana de Bogotá?',
        options: [
            { id: 'opt-tabio', text: 'Variante Cota - Tabio / Cajicá', votes: 142 },
            { id: 'opt-rio', text: 'Ciclorruta Río Bogotá (Puente Cota)', votes: 118 },
            { id: 'opt-corpas', text: 'Suba Rural / Vía Corpas Norte', votes: 89 }
        ]
    };

    let userVotedPoll = localStorage.getItem('forkar_poll_vote');

    // ── 3. SABANA REGIONAL LEADERBOARD STATE ──
    const DEFAULT_MUNICIPALITIES = [
        { id: 'cota', name: 'Cota (Centro & Veredas)', co2: 418.5, citizens: 142, streak: '🔥 14 días' },
        { id: 'chia', name: 'Chía (Av. Pradilla & Sindamanoy)', co2: 386.0, citizens: 128, streak: '🔥 11 días' },
        { id: 'bogota', name: 'Bogotá Norte (Suba & Calle 80)', co2: 342.5, citizens: 115, streak: '🌱 9 días' },
        { id: 'cajica', name: 'Cajicá & Variante Tabio', co2: 215.0, citizens: 74, streak: '🌱 7 días' }
    ];

    window.initForkarEnhancements = function () {
        renderEcoQuests();
        renderCommunityPoll();
        renderMunicipalityLeaderboard();
        setupQuickFilters();
        if (document.getElementById('eco-cert-canvas')) {
            window.renderEcoCertificateCanvas();
        }
    };

    function renderEcoQuests() {
        const container = document.getElementById('forkar-quests-list');
        if (!container) return;

        const joinedQuests = JSON.parse(localStorage.getItem('forkar_joined_quests') || '[]');

        container.innerHTML = QUESTS.map(q => {
            const isJoined = joinedQuests.includes(q.id);
            const pct = Math.min(100, Math.round((q.progress / q.goal) * 100));

            return `
                <div class="cs-quest-card">
                    <div style="display:flex; justify-content:space-between; align-items:flex-start; gap:8px;">
                        <div>
                            <div style="font-weight:700; font-size:13.5px; color:var(--text);">${q.title}</div>
                            <div style="font-size:12px; color:var(--text-sub); margin-top:2px; line-height:1.45;">${q.desc}</div>
                        </div>
                        <span style="background:rgba(16,185,129,0.15); color:#10b981; font-weight:800; font-size:11px; padding:3px 7px; border-radius:6px; font-family:'JetBrains Mono',monospace; white-space:nowrap;">+${q.reward} Pts</span>
                    </div>

                    <div style="margin: 10px 0 6px;">
                        <div style="display:flex; justify-content:space-between; font-size:11px; color:var(--text-sub); margin-bottom:4px;">
                            <span>Progreso de la Comunidad</span>
                            <span style="font-family:'JetBrains Mono',monospace; color:#10b981; font-weight:700;">${q.progress}/${q.goal} ${q.unit} (${pct}%)</span>
                        </div>
                        <div class="cs-progress-track">
                            <div style="width:${pct}%; height:100%; background:linear-gradient(90deg, #10b981, #34d399); border-radius:999px;"></div>
                        </div>
                    </div>

                    <div style="display:flex; justify-content:space-between; align-items:center; margin-top:8px;">
                        <span style="font-size:11px; color:#d97706; font-weight:600;">🏅 Badge: ${q.badge}</span>
                        <button class="cs-quest-btn ${isJoined ? 'joined' : ''}" onclick="window.toggleJoinQuest('${q.id}', ${q.reward})">
                            ${isJoined ? '✔ Reto Activo' : '+ Unirme al Reto'}
                        </button>
                    </div>
                </div>
            `;
        }).join('');
    }

    window.toggleJoinQuest = function (questId, reward) {
        let joined = JSON.parse(localStorage.getItem('forkar_joined_quests') || '[]');
        if (joined.includes(questId)) {
            joined = joined.filter(id => id !== questId);
            alert("Has salido del reto.");
        } else {
            joined.push(questId);
            if (window.triggerSoundEffect) window.triggerSoundEffect('powerup');
            if (navigator.vibrate) navigator.vibrate([40, 50, 40]);
            alert(`✔ ¡Te has unido al reto!\nCompleta tu meta semanal para ganar +${reward} Puntos Eco.`);
        }
        localStorage.setItem('forkar_joined_quests', JSON.stringify(joined));
        renderEcoQuests();
    };

    function renderCommunityPoll() {
        const pollContainer = document.getElementById('forkar-poll-box');
        if (!pollContainer) return;

        const totalVotes = POLL_DATA.options.reduce((sum, opt) => sum + opt.votes, 0);

        pollContainer.innerHTML = `
            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
                <span style="font-size:11px; font-weight:800; color:#38bdf8; text-transform:uppercase; letter-spacing:0.5px;">Sondeo de la Comunidad</span>
                <span style="font-size:11px; color:var(--text-sub);">${totalVotes} votos registrados</span>
            </div>
            <div style="font-size:14px; font-weight:700; color:var(--text); margin-bottom:12px; line-height:1.4;">
                ${POLL_DATA.question}
            </div>
            <div style="display:flex; flex-direction:column; gap:8px;">
                ${POLL_DATA.options.map(opt => {
                    const isSelected = userVotedPoll === opt.id;
                    const pct = Math.round((opt.votes / totalVotes) * 100);

                    return `
                        <div class="cs-poll-option ${isSelected ? 'selected' : ''}" onclick="window.votePoll('${opt.id}')">
                            <div style="display:flex; justify-content:space-between; align-items:center; position:relative; z-index:2;">
                                <span style="font-size:13px; font-weight:600; color:var(--text);">${opt.text}</span>
                                <span style="font-size:12px; font-weight:700; font-family:'JetBrains Mono',monospace; color:#38bdf8;">${pct}%</span>
                            </div>
                            <div class="cs-poll-bar" style="width:${pct}%;"></div>
                        </div>
                    `;
                }).join('')}
            </div>
        `;
    }

    window.votePoll = function (optionId) {
        if (userVotedPoll) {
            alert("Ya has votado en este sondeo de la comunidad.");
            return;
        }

        const opt = POLL_DATA.options.find(o => o.id === optionId);
        if (!opt) return;

        opt.votes++;
        userVotedPoll = optionId;
        localStorage.setItem('forkar_poll_vote', optionId);

        if (window.triggerSoundEffect) window.triggerSoundEffect('coin');
        renderCommunityPoll();
    };

    function setupQuickFilters() {
        const filterBtns = document.querySelectorAll('.forkar-filter-pill');
        filterBtns.forEach(btn => {
            btn.addEventListener('click', () => {
                filterBtns.forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                const tag = btn.dataset.tag;
                if (window.filterPostsByTag) {
                    window.filterPostsByTag(tag);
                } else {
                    const searchInput = document.getElementById('search-input');
                    if (searchInput) {
                        if (tag === 'all') {
                            searchInput.value = '';
                        } else if (tag === 'eco') {
                            searchInput.value = 'eco';
                        } else if (tag === 'games') {
                            searchInput.value = 'juego';
                        } else if (tag === 'help') {
                            searchInput.value = 'ayuda';
                        } else if (tag === 'bici') {
                            searchInput.value = 'bici';
                        }
                        searchInput.dispatchEvent(new Event('input'));
                    }
                }
            });
        });
    }

    // ── FORKMAN AI GUIDE RESPONSES ──
    const FORKMAN_KNOWLEDGE = {
        cota_raee: "El Punto RAEE de Cota se encuentra ubicado en la Cra 4 # 12-34 (Sede Alcaldía Municipal). Recibe pilas, computadores en desuso, cables y cargadores.",
        chia_centro: "El centro de acopio Chía Centro está en la Avenida Pradilla # 5-20. Reciben cartón, plásticos PET, aluminio y vidrio limpio.",
        bici_cota: "La ruta recomendada hacia Cota desde Bogotá es por la ciclorruta de la Calle 80 hasta el Puente de Guadua, continuando por la Vía Siberia - Cota.",
        recompensas: "Puedes canjear tus Puntos Eco acumulados en la Eco Rewards Store por café orgánico (50 Pts), kit de semillas nativas (80 Pts) o certificado de siembra en el Majuy (120 Pts)."
    };

    window.askForkman = function (topic) {
        const answer = FORKMAN_KNOWLEDGE[topic] || "Forkman: Recuerda que cada pedalazo y residuo separado cuenta para la sostenibilidad de la Sabana.";
        if (window.triggerSoundEffect) window.triggerSoundEffect('powerup');
        alert(`🤖 Forkman responde:\n\n${answer}`);
    };

    // ── SABANA REGIONAL LEADERBOARD ──
    function getMunicipalities() {
        try {
            const saved = JSON.parse(localStorage.getItem('forkar_sabana_leaderboard') || 'null');
            if (Array.isArray(saved) && saved.length) return saved;
        } catch (e) {}
        return DEFAULT_MUNICIPALITIES;
    }

    function renderMunicipalityLeaderboard() {
        const box = document.getElementById('eco-municipality-leaderboard');
        if (!box) return;

        const munis = getMunicipalities().sort((a, b) => b.co2 - a.co2);
        const maxCo2 = Math.max(...munis.map(m => m.co2), 100);

        box.innerHTML = munis.map((m, idx) => {
            const pct = Math.min(100, Math.round((m.co2 / maxCo2) * 100));
            const medal = idx === 0 ? '🥇' : (idx === 1 ? '🥈' : (idx === 2 ? '🥉' : '🌿'));
            return `
                <div class="cs-muni-card">
                    <div style="display:flex; justify-content:space-between; align-items:center; gap:8px; margin-bottom:6px;">
                        <div style="display:flex; align-items:center; gap:8px;">
                            <span style="font-size:16px;">${medal}</span>
                            <div>
                                <div style="font-size:13px; font-weight:700; color:var(--text);">${m.name}</div>
                                <div style="font-size:11px; color:var(--text-sub);">${m.citizens} eco-ciudadanos • ${m.streak}</div>
                            </div>
                        </div>
                        <div style="text-align:right;">
                            <div style="font-size:13px; font-weight:800; color:#10b981; font-family:'JetBrains Mono',monospace;">${m.co2.toFixed(1)} kg CO₂</div>
                            <button class="cs-quest-btn" style="margin-top:4px; padding:2px 8px; font-size:10px;" onclick="window.pledgeMunicipalityEco('${m.id}')">+ Sumar mi Ruta</button>
                        </div>
                    </div>
                    <div class="cs-progress-track" style="height:5px;">
                        <div style="width:${pct}%; height:100%; background:linear-gradient(90deg, #10b981, #38bdf8);"></div>
                    </div>
                </div>
            `;
        }).join('');
    }

    window.pledgeMunicipalityEco = function (muniId) {
        const munis = getMunicipalities();
        const item = munis.find(m => m.id === muniId);
        if (!item) return;

        item.co2 = Number((item.co2 + 2.5).toFixed(1));
        item.citizens += 1;
        localStorage.setItem('forkar_sabana_leaderboard', JSON.stringify(munis));

        if (window.triggerSoundEffect) window.triggerSoundEffect('coin');
        renderMunicipalityLeaderboard();
        if (window.renderEcoCertificateCanvas) window.renderEcoCertificateCanvas();
    };

    // ── OFFICIAL CARBON CERTIFICATE GENERATOR (CANVAS) ──
    window.renderEcoCertificateCanvas = function () {
        const canvas = document.getElementById('eco-cert-canvas');
        if (!canvas) return;
        const ctx = canvas.getContext('2d');
        const nameInput = document.getElementById('eco-cert-name-input');
        const holderName = (nameInput && nameInput.value.trim()) ? nameInput.value.trim() : 'Ciudadano Eco Sabana';

        const co2Text = document.getElementById('metric-co2')?.textContent || '24.5 kg';
        const ptsText = document.getElementById('metric-points')?.textContent || '120 pts';
        const treesText = document.getElementById('metric-trees')?.textContent || '3';

        // Background gradient
        const grad = ctx.createLinearGradient(0, 0, canvas.width, canvas.height);
        grad.addColorStop(0, '#041310');
        grad.addColorStop(0.5, '#07221c');
        grad.addColorStop(1, '#061527');
        ctx.fillStyle = grad;
        ctx.fillRect(0, 0, canvas.width, canvas.height);

        // Outer & Inner Ornamental Borders
        ctx.strokeStyle = '#10b981';
        ctx.lineWidth = 3;
        ctx.strokeRect(18, 18, canvas.width - 36, canvas.height - 36);
        ctx.strokeStyle = 'rgba(56, 189, 248, 0.35)';
        ctx.lineWidth = 1;
        ctx.strokeRect(26, 26, canvas.width - 52, canvas.height - 52);

        // Header Badge
        ctx.fillStyle = '#10b981';
        ctx.font = 'bold 13px "JetBrains Mono", monospace';
        ctx.textAlign = 'center';
        ctx.fillText('COKI STUDIOS • FORKAR ECO HUB PROGRAM • RED REGIONAL SABANA', canvas.width / 2, 62);

        // Main Title
        ctx.fillStyle = '#f8fafc';
        ctx.font = 'bold 26px "Plus Jakarta Sans", system-ui, sans-serif';
        ctx.fillText('CERTIFICADO DE IMPACTO AMBIENTAL', canvas.width / 2, 102);

        ctx.fillStyle = '#94a3b8';
        ctx.font = '14px "Plus Jakarta Sans", system-ui, sans-serif';
        ctx.fillText('Otorgado oficialmente por movilidad sostenible y reducción verificada de huella a:', canvas.width / 2, 134);

        // Recipient Name
        ctx.fillStyle = '#34d399';
        ctx.font = 'bold 30px "Plus Jakarta Sans", system-ui, sans-serif';
        ctx.fillText(holderName.toUpperCase(), canvas.width / 2, 178);

        // Divider Line
        ctx.strokeStyle = 'rgba(16, 185, 129, 0.4)';
        ctx.beginPath();
        ctx.moveTo(160, 195);
        ctx.lineTo(canvas.width - 160, 195);
        ctx.stroke();

        // Metrics Boxes
        const boxes = [
            { label: 'CO₂ AHORRADO', val: co2Text, color: '#10b981' },
            { label: 'PUNTOS ECO', val: ptsText, color: '#fbbf24' },
            { label: 'ÁRBOLES EQUIV.', val: `${treesText} Árboles`, color: '#38bdf8' }
        ];
        const boxW = 180, boxH = 68, gap = 24;
        const startX = (canvas.width - (boxW * 3 + gap * 2)) / 2;

        boxes.forEach((b, i) => {
            const bx = startX + i * (boxW + gap);
            const by = 216;
            ctx.fillStyle = 'rgba(15, 23, 42, 0.75)';
            ctx.fillRect(bx, by, boxW, boxH);
            ctx.strokeStyle = 'rgba(255,255,255,0.12)';
            ctx.strokeRect(bx, by, boxW, boxH);

            ctx.fillStyle = b.color;
            ctx.font = 'bold 20px "JetBrains Mono", monospace';
            ctx.fillText(b.val, bx + boxW / 2, by + 34);

            ctx.fillStyle = '#94a3b8';
            ctx.font = 'bold 10px "Plus Jakarta Sans", sans-serif';
            ctx.fillText(b.label, bx + boxW / 2, by + 54);
        });

        // Footer Signature & Verification Hash
        const hashSuffix = Math.abs(holderName.split('').reduce((a, c) => ((a << 5) - a) + c.charCodeAt(0), 0)).toString(16).toUpperCase().padStart(8, '0');
        const dateStr = new Date().toISOString().slice(0, 10);
        ctx.fillStyle = '#64748b';
        ctx.font = '11px "JetBrains Mono", monospace';
        ctx.fillText(`HASH: FORKAR-SABANA-${hashSuffix}  •  FECHA: ${dateStr}  •  COTA / CHÍA / BOGOTÁ`, canvas.width / 2, 322);
    };

    window.downloadEcoCertificate = function () {
        window.renderEcoCertificateCanvas();
        const canvas = document.getElementById('eco-cert-canvas');
        if (!canvas) return;
        const link = document.createElement('a');
        link.download = 'Certificado-Forkar-EcoHub-2026.png';
        link.href = canvas.toDataURL('image/png');
        link.click();
        if (window.triggerSoundEffect) window.triggerSoundEffect('powerup');
    };

    window.filterByTrend = function (term) {
        const searchInput = document.getElementById('search-input');
        if (searchInput) {
            searchInput.value = term;
            searchInput.dispatchEvent(new Event('input'));
            searchInput.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
    };

    document.addEventListener('DOMContentLoaded', window.initForkarEnhancements);
})();
