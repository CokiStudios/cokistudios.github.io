/* ═══════════════════════════════════════════════════════════════════════
   🌱 FORKAR ECO HUB — RADAR DE LA SABANA & IMPACT CALCULATOR
   Sostenibilidad Regional (Cota • Chía • Bogotá • Majuy)
   Coki Studios © 2026
   ═══════════════════════════════════════════════════════════════════════ */

(function () {
    const STATIONS = [
        {
            id: "cota-central",
            name: "Punto Verde Parque Principal (Cota)",
            town: "Cota",
            type: "Reciclaje & Compost",
            coords: "4.8105° N, 74.1018° W",
            meta: "Separación de plásticos, papel, cartón y compostaje comunitario.",
            points: 40,
            icon: "♻️"
        },
        {
            id: "cota-bici",
            name: "Estación Bici Cota Sostenible (Vía Siberia)",
            town: "Cota",
            type: "Movilidad Activa",
            coords: "4.7950° N, 74.1200° W",
            meta: "Ruta ciclista Cota - Suba y Siberia. Préstamo verde y mantenimiento.",
            points: 50,
            icon: "🚲"
        },
        {
            id: "cota-raee",
            name: "Punto RAEE Electrónicos (Alcaldía de Cota)",
            town: "Cota",
            type: "Residuos Eléctricos",
            coords: "4.8112° N, 74.1025° W",
            meta: "Disposición segura de baterías, cables y hardware informático.",
            points: 60,
            icon: "🔋"
        },
        {
            id: "chia-centro",
            name: "Centro de Acopio Chía Centro (Av. Pradilla)",
            town: "Chía",
            type: "Acopio Masivo",
            coords: "4.8612° N, 74.0580° W",
            meta: "Punto principal de materiales aprovechables y vidrio retornable.",
            points: 45,
            icon: "📦"
        },
        {
            id: "chia-campus",
            name: "Eco Estación Universitaria (Chía Norte)",
            town: "Chía",
            type: "Campus Verde",
            coords: "4.8720° N, 74.0450° W",
            meta: "Punto de movilidad eléctrica y compostaje estudiantil.",
            points: 50,
            icon: "🎓"
        },
        {
            id: "bogota-portal80",
            name: "Hub Intermodal Portal 80 / Cll 80 (Bogotá)",
            town: "Bogotá",
            type: "Conexión Sabana",
            coords: "4.7090° N, 74.1105° W",
            meta: "Intercambio modal Bici / TransMilenio / Intermunicipal a Cota.",
            points: 55,
            icon: "🚍"
        },
        {
            id: "bogota-suba",
            name: "Punto Limpio Portal Suba / Corpas (Bogotá)",
            town: "Bogotá",
            type: "Ruta Suba-Cota",
            coords: "4.7550° N, 74.0920° W",
            meta: "Conexión ciclista Suba - Chía y Cota por el Río Bogotá.",
            points: 50,
            icon: "🌿"
        }
    ];

    // CO2 Factor: ~0.192 kg CO2 per km compared to standard urban car
    const CO2_FACTOR = 0.192;
    // Tree equivalent: ~22 kg CO2 absorbed per year per tree in Andean forest (Cerro del Majuy)
    const TREE_FACTOR = 22.0;

    let userEcoPoints = parseInt(localStorage.getItem('cs_eco_points') || '120', 10);

    window.initEcoRadar = function () {
        renderStationsList();
        updateEcoScoreDisplay();
        updateEcoCalculator(15); // Default 15 km
    };

    function updateEcoScoreDisplay() {
        const scoreEl = document.getElementById('eco-user-points');
        if (scoreEl) scoreEl.innerText = userEcoPoints.toLocaleString();
    }

    window.updateEcoCalculator = function (km) {
        km = parseFloat(km) || 0;
        const kmLabel = document.getElementById('eco-calc-km-label');
        const co2El = document.getElementById('eco-calc-co2');
        const pointsEl = document.getElementById('eco-calc-points');
        const treesEl = document.getElementById('eco-calc-trees');

        if (kmLabel) kmLabel.innerText = `${km} km / semana`;

        // Calculate weekly savings
        const co2SavedKg = (km * CO2_FACTOR).toFixed(2);
        // Annual projection
        const annualCo2Kg = (km * 52 * CO2_FACTOR);
        const treesEquiv = (annualCo2Kg / TREE_FACTOR).toFixed(1);
        const pointsEarned = Math.round(km * 8);

        if (co2El) co2El.innerText = `${co2SavedKg} kg CO₂`;
        if (pointsEl) pointsEl.innerText = `+${pointsEarned} Pts`;
        if (treesEl) treesEl.innerText = `🌲 ${treesEquiv} árboles`;
    };

    function renderStationsList() {
        const container = document.getElementById('eco-stations-grid');
        if (!container) return;

        container.innerHTML = STATIONS.map(st => `
            <div class="cs-station-card" id="station-${st.id}">
                <div style="display:flex; justify-content:space-between; align-items:flex-start;">
                    <div style="display:flex; align-items:center; gap:10px;">
                        <span style="font-size:24px;">${st.icon}</span>
                        <div>
                            <div style="font-weight:700; font-size:14px; color:var(--text);">${st.name}</div>
                            <span style="font-size:11px; color:#10b981; font-weight:700; text-transform:uppercase;">${st.town} • ${st.type}</span>
                        </div>
                    </div>
                    <span style="background:rgba(16,185,129,0.15); color:#10b981; font-weight:700; font-size:12px; padding:3px 8px; border-radius:6px; font-family:'JetBrains Mono',monospace;">+${st.points} Pts</span>
                </div>
                <p style="font-size:12px; color:var(--text-sub); margin:8px 0; line-height:1.5;">${st.meta}</p>
                <div style="display:flex; justify-content:space-between; align-items:center; border-top:1px solid rgba(255,255,255,0.06); padding-top:8px;">
                    <span style="font-size:11px; color:#64748b; font-family:'JetBrains Mono',monospace;">${st.coords}</span>
                    <button class="cs-station-validate-btn" onclick="window.validateStationArrival('${st.id}', ${st.points}, '${st.name}')">
                        Validar Llegada (QR/NFC)
                    </button>
                </div>
            </div>
        `).join('');
    }

    window.validateStationArrival = function (stationId, points, stationName) {
        // Haptic feedback if supported
        if (navigator.vibrate) navigator.vibrate([40, 60, 40]);

        // Play confirmation sound
        if (window.triggerSoundEffect) window.triggerSoundEffect('coin');

        userEcoPoints += points;
        localStorage.setItem('cs_eco_points', userEcoPoints.toString());
        updateEcoScoreDisplay();

        const card = document.getElementById(`station-${stationId}`);
        if (card) {
            card.style.borderColor = '#10b981';
            card.style.background = 'rgba(16, 185, 129, 0.12)';
        }

        alert(`✔ ¡Validación Exitosa!\n\nLlegada verificada en: ${stationName}\nHas recibido +${points} Puntos Eco en tu cuenta CS ID.`);
    };

    document.addEventListener('DOMContentLoaded', window.initEcoRadar);
})();
