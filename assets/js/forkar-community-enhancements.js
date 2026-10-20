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

    window.initForkarEnhancements = function () {
        renderEcoQuests();
        renderCommunityPoll();
        setupQuickFilters();
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
                            <span style="font-family:'JetBrains Mono',monospace; color:#34d399; font-weight:700;">${q.progress}/${q.goal} ${q.unit} (${pct}%)</span>
                        </div>
                        <div style="width:100%; height:6px; background:rgba(255,255,255,0.06); border-radius:999px; overflow:hidden;">
                            <div style="width:${pct}%; height:100%; background:linear-gradient(90deg, #10b981, #34d399); border-radius:999px;"></div>
                        </div>
                    </div>

                    <div style="display:flex; justify-content:space-between; align-items:center; margin-top:8px;">
                        <span style="font-size:11px; color:#f59e0b; font-weight:600;">🏅 Badge: ${q.badge}</span>
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

    document.addEventListener('DOMContentLoaded', window.initForkarEnhancements);
})();
