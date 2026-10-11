/**
 * ═══════════════════════════════════════════════════════════════
 * 🌌 XTRAPS DYNAMIC ENGINE v2.5 — Web Architecture
 * Precision Dual Bezier Curves (Wave 1 & Wave 2)
 * Ported directly from XtrapsBackground.swift & Shine OS Core
 * ═══════════════════════════════════════════════════════════════
 */

(function () {
    'use strict';

    function createXtrapsSVG() {
        const svgNS = 'http://www.w3.org/2000/svg';
        const svg = document.createElementNS(svgNS, 'svg');
        svg.setAttribute('class', 'xtraps-svg-layer');
        svg.setAttribute('viewBox', '0 0 1000 600');
        svg.setAttribute('preserveAspectRatio', 'none');
        svg.setAttribute('aria-hidden', 'true');

        svg.innerHTML = `
            <defs>
                <!-- Wave 1 Gradient: Cyan -> Indigo -> Purple -->
                <linearGradient id="xtrapsGrad1" x1="0%" y1="0%" x2="100%" y2="0%">
                    <stop offset="0%" stop-color="#38bdf8" stop-opacity="0.45" />
                    <stop offset="50%" stop-color="#6366f1" stop-opacity="1.0" />
                    <stop offset="100%" stop-color="#c084fc" stop-opacity="0.6" />
                </linearGradient>

                <!-- Wave 2 Gradient: Radiant Pink -> Deep Indigo -> Sky Cyan -->
                <linearGradient id="xtrapsGrad2" x1="0%" y1="0%" x2="100%" y2="0%">
                    <stop offset="0%" stop-color="#ec4899" stop-opacity="0.35" />
                    <stop offset="55%" stop-color="#8b5cf6" stop-opacity="0.85" />
                    <stop offset="100%" stop-color="#38bdf8" stop-opacity="1.0" />
                </linearGradient>

                <!-- Glow Filter -->
                <filter id="xtrapsGlow" x="-20%" y="-20%" width="140%" height="140%">
                    <feGaussianBlur stdDeviation="6" result="blur" />
                    <feMerge>
                        <feMergeNode in="blur" />
                        <feMergeNode in="SourceGraphic" />
                    </feMerge>
                </filter>
            </defs>

            <!-- Wave 1: Starts top-left (0.16h), dips to valley (0.45w, 0.58h) & (0.82w, 0.62h), rises to (1w, 0.13h) -->
            <path class="xtraps-path-wave1"
                  d="M 0 96 C 150 96, 300 210, 450 348 C 580 456, 700 468, 820 372 C 900 300, 960 168, 1000 78"
                  stroke="url(#xtrapsGrad1)"
                  stroke-width="2.6"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  filter="url(#xtrapsGlow)"
                  fill="none" />

            <!-- Wave 2: Starts mid-left (0.43h), arches gently (0.55w, 0.32h), shoots up steeply to (1w, 0) -->
            <path class="xtraps-path-wave2"
                  d="M 0 258 C 150 222, 350 192, 550 192 C 720 192, 830 252, 880 204 C 930 132, 970 48, 1000 0"
                  stroke="url(#xtrapsGrad2)"
                  stroke-width="2.8"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  filter="url(#xtrapsGlow)"
                  fill="none" />
        `;

        return svg;
    }

    function initXtraps() {
        const containers = document.querySelectorAll('.xtraps-bg');
        containers.forEach((container) => {
            if (!container.querySelector('.xtraps-svg-layer')) {
                container.appendChild(createXtrapsSVG());
            }
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initXtraps);
    } else {
        initXtraps();
    }

    window.initXtraps = initXtraps;
})();
