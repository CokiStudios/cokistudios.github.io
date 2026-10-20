/* ═══════════════════════════════════════════════════════════════════════
   🛍️ FELTE STORE INTERACTIVE SHOWCASE & SHOPPING BAG
   Currency Converter (COP / USD / EUR) & Eco-Rewards Checkout
   Felte Store & Coki Studios © 2026
   ═══════════════════════════════════════════════════════════════════════ */

(function () {
    const RATES = {
        COP: { rate: 1, symbol: "$", format: (val) => `$${Math.round(val).toLocaleString()} COP` },
        USD: { rate: 0.00025, symbol: "$", format: (val) => `$${(val * 0.00025).toFixed(2)} USD` },
        EUR: { rate: 0.00023, symbol: "€", format: (val) => `€${(val * 0.00023).toFixed(2)} EUR` }
    };

    let currentCurrency = 'COP';
    let cart = JSON.parse(localStorage.getItem('felte_cart') || '[]');

    const PRODUCTS = [
        {
            id: 'shine-console',
            name: 'Consola Shine Handheld (APU Edition)',
            category: 'Hardware & Loop OS',
            basePriceCop: 680000,
            icon: '🎮',
            badge: 'Edición Limitada',
            desc: 'Pantalla OLED 16:9, APU Shine 60Hz/240Hz con Holo Looping OoS nativo.'
        },
        {
            id: 'eco-kit-majuy',
            name: 'Kit Forkar Eco & Reserva Majuy',
            category: 'Sostenibilidad',
            basePriceCop: 85000,
            icon: '🌱',
            badge: 'Eco Verificado',
            desc: 'Camiseta de algodón orgánico y siembra verificada de 1 árbol nativo en Cota.'
        },
        {
            id: 'csms-token',
            name: 'CSMS Hardware Security Token (NFC)',
            category: 'Seguridad Cuántica',
            basePriceCop: 120000,
            icon: '🔐',
            badge: 'E2EE SEP/TEE',
            desc: 'Llave criptográfica de hardware para autenticación CSID y CSMS sin contraseñas.'
        },
        {
            id: 'pro-dev-pack',
            name: 'Felte Pro Developer Bundle',
            category: 'Software & SDK',
            basePriceCop: 190000,
            icon: '⚡',
            badge: 'smiledev Pro',
            desc: 'Compilador XUI 240Hz ultra-low latency, soporte prioritario y módulos Cloud.'
        }
    ];

    window.initFelteStore = function () {
        renderFelteProducts();
        updateCartCount();
    };

    window.setFelteCurrency = function (curr) {
        if (!RATES[curr]) return;
        currentCurrency = curr;
        document.querySelectorAll('.felte-curr-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.curr === curr);
        });
        renderFelteProducts();
        renderCartDrawer();
    };

    function renderFelteProducts() {
        const grid = document.getElementById('felte-products-grid');
        if (!grid) return;

        const f = RATES[currentCurrency].format;

        grid.innerHTML = PRODUCTS.map(p => `
            <div class="cs-felte-card">
                <div style="display:flex; justify-content:space-between; align-items:flex-start;">
                    <span style="font-size:32px;">${p.icon}</span>
                    <span style="font-size:11px; font-weight:700; color:#00f5d4; background:rgba(0,245,212,0.12); padding:3px 8px; border-radius:6px;">${p.badge}</span>
                </div>
                <div style="margin-top:12px;">
                    <span style="font-size:11px; text-transform:uppercase; color:var(--text-sub); font-weight:700;">${p.category}</span>
                    <div style="font-size:16px; font-weight:700; color:var(--text); margin-top:2px;">${p.name}</div>
                    <p style="font-size:12.5px; color:var(--text-sub); line-height:1.5; margin:8px 0;">${p.desc}</p>
                </div>
                <div style="margin-top:auto; display:flex; justify-content:space-between; align-items:center; border-top:1px solid rgba(255,255,255,0.06); padding-top:12px;">
                    <span style="font-size:16px; font-weight:800; color:#38bdf8; font-family:'JetBrains Mono',monospace;">${f(p.basePriceCop)}</span>
                    <button class="cs-felte-add-btn" onclick="window.addToFelteCart('${p.id}')">
                        + Añadir
                    </button>
                </div>
            </div>
        `).join('');
    }

    window.addToFelteCart = function (productId) {
        const prod = PRODUCTS.find(p => p.id === productId);
        if (!prod) return;

        cart.push(prod);
        localStorage.setItem('felte_cart', JSON.stringify(cart));
        updateCartCount();

        if (window.triggerSoundEffect) window.triggerSoundEffect('coin');
        if (navigator.vibrate) navigator.vibrate(50);

        openCartDrawer();
    };

    function updateCartCount() {
        const badges = document.querySelectorAll('.felte-cart-count');
        badges.forEach(b => {
            b.innerText = cart.length;
            b.style.display = cart.length > 0 ? 'inline-flex' : 'none';
        });
    }

    function openCartDrawer() {
        renderCartDrawer();
        const drawer = document.getElementById('felte-cart-modal');
        if (drawer) drawer.classList.add('active');
    }

    window.closeFelteCart = function () {
        const drawer = document.getElementById('felte-cart-modal');
        if (drawer) drawer.classList.remove('active');
    };

    function renderCartDrawer() {
        const itemsList = document.getElementById('felte-cart-items');
        const subtotalEl = document.getElementById('felte-cart-subtotal');
        if (!itemsList || !subtotalEl) return;

        if (cart.length === 0) {
            itemsList.innerHTML = `<div style="text-align:center; padding:30px; color:var(--text-sub);">Tu bolsa de compras está vacía</div>`;
            subtotalEl.innerText = RATES[currentCurrency].format(0);
            return;
        }

        const f = RATES[currentCurrency].format;
        let totalCop = 0;

        itemsList.innerHTML = cart.map((item, idx) => {
            totalCop += item.basePriceCop;
            return `
                <div style="display:flex; justify-content:space-between; align-items:center; padding:10px 0; border-bottom:1px solid rgba(255,255,255,0.06);">
                    <div style="display:flex; align-items:center; gap:10px;">
                        <span style="font-size:20px;">${item.icon}</span>
                        <div>
                            <div style="font-size:13px; font-weight:700; color:var(--text);">${item.name}</div>
                            <div style="font-size:11px; color:#38bdf8; font-family:'JetBrains Mono',monospace;">${f(item.basePriceCop)}</div>
                        </div>
                    </div>
                    <button onclick="window.removeFromFelteCart(${idx})" style="background:none; border:none; color:#f87171; cursor:pointer; font-size:14px;">✕</button>
                </div>
            `;
        }).join('');

        subtotalEl.innerText = f(totalCop);
    }

    window.removeFromFelteCart = function (index) {
        cart.splice(index, 1);
        localStorage.setItem('felte_cart', JSON.stringify(cart));
        updateCartCount();
        renderCartDrawer();
    };

    window.applyEcoDiscount = function () {
        const userPts = parseInt(localStorage.getItem('cs_eco_points') || '0', 10);
        if (userPts < 100) {
            alert("Necesitas al menos 100 Puntos Eco acumulados en Forkar Eco Hub para canjear un 15% de descuento.");
            return;
        }
        alert("✔ ¡Cupón Eco Aplicado! 15% de descuento canjeado con tus Puntos Eco.");
    };

    document.addEventListener('DOMContentLoaded', window.initFelteStore);
})();
