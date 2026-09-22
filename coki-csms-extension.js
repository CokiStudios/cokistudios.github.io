// ══════════════════════════════════════════════════════════════════
// 💬 CSMS EXTENSION FOR FORKAR (PC & DESKTOP SUITE)
// Widget flotante de mensajería en tiempo real integrado en Forkar
// Coki Studios Messenger Service (CSMS)
// ══════════════════════════════════════════════════════════════════

import { supabase } from './coki-auth.js';

// Canales canónicos públicos de la comunidad
const CSMS_CHANNELS = [
    { id: '00000000-0000-4000-8000-000000000001', name: 'Comunidad Global', icon: '💬', desc: 'Charla general de Coki Studios' },
    { id: '00000000-0000-4000-8000-000000000003', name: 'Forkar Carpooling & Rutas', icon: '🚗', desc: 'Rutas, viajes y comunidad Forkar' },
    { id: '00000000-0000-4000-8000-000000000002', name: 'Eco Hub & Sostenibilidad', icon: '🌿', desc: 'Reciclaje y proyectos verdes' }
];

let activeRoomId = CSMS_CHANNELS[0].id;
let currentUser = null;
let unreadCount = 0;
let isDrawerOpen = false;
let realtimeChannel = null;

export async function initCSMSExtension() {
    // Evitar inyecciones duplicadas
    if (document.getElementById('coki-csms-container')) return;

    // Obtener sesión actual
    const { data: { user } } = await supabase.auth.getUser();
    currentUser = user;

    injectCSMSStyles();
    injectCSMSDOM();
    bindEvents();
    subscribeRealtime();
    loadMessages(activeRoomId);

    // Escuchar cambios de autenticación para actualizar identidad
    supabase.auth.onAuthStateChange((_event, session) => {
        currentUser = session?.user || null;
        updateUserUI();
    });
}

function injectCSMSStyles() {
    const style = document.createElement('style');
    style.id = 'coki-csms-styles';
    style.textContent = `
        #coki-csms-container {
            position: fixed;
            bottom: 24px;
            right: 24px;
            z-index: 9998;
            font-family: 'Outfit', sans-serif;
        }

        /* ── Botón Flotante (Launcher) ── */
        .csms-fab {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 10px 18px 10px 14px;
            background: linear-gradient(135deg, #6366f1, #4f46e5);
            color: #ffffff;
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 999px;
            box-shadow: 0 10px 25px -5px rgba(99, 102, 241, 0.5), 0 0 0 1px rgba(255, 255, 255, 0.1);
            cursor: pointer;
            transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
            user-select: none;
        }
        .csms-fab:hover {
            transform: translateY(-2px) scale(1.02);
            box-shadow: 0 15px 30px -5px rgba(99, 102, 241, 0.65);
        }
        .csms-fab-icon {
            width: 28px;
            height: 28px;
            display: flex;
            align-items: center;
            justify-content: center;
            background: rgba(255, 255, 255, 0.15);
            border-radius: 50%;
        }
        .csms-fab-title {
            font-size: 14px;
            font-weight: 700;
            letter-spacing: 0.2px;
        }
        .csms-fab-badge {
            display: none;
            background: #ef4444;
            color: white;
            font-size: 11px;
            font-weight: 800;
            padding: 2px 7px;
            border-radius: 999px;
            margin-left: 2px;
            box-shadow: 0 0 10px rgba(239, 68, 68, 0.6);
            animation: csms-pulse 2s infinite;
        }
        .csms-status-dot {
            width: 8px;
            height: 8px;
            background: #10b981;
            border-radius: 50%;
            box-shadow: 0 0 8px #10b981;
        }

        /* ── Mini Drawer Flotante ── */
        .csms-drawer {
            display: none;
            position: absolute;
            bottom: calc(100% + 14px);
            right: 0;
            width: 380px;
            height: 540px;
            background: rgba(13, 17, 23, 0.94);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            border: 1px solid rgba(255, 255, 255, 0.12);
            border-radius: 20px;
            box-shadow: 0 25px 60px -15px rgba(0, 0, 0, 0.7), 0 0 0 1px rgba(255, 255, 255, 0.05);
            flex-direction: column;
            overflow: hidden;
            animation: csms-appear 0.25s cubic-bezier(0.16, 1, 0.3, 1);
        }
        .csms-drawer.open {
            display: flex;
        }

        /* Header */
        .csms-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 14px 18px;
            background: rgba(255, 255, 255, 0.03);
            border-bottom: 1px solid rgba(255, 255, 255, 0.07);
        }
        .csms-header-info {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .csms-header-title {
            font-size: 14px;
            font-weight: 700;
            color: #f1f5f9;
        }
        .csms-header-subtitle {
            font-size: 11px;
            color: #94a3b8;
        }
        .csms-header-actions {
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .csms-btn-icon {
            background: transparent;
            border: none;
            color: #94a3b8;
            cursor: pointer;
            padding: 6px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.2s;
        }
        .csms-btn-icon:hover {
            color: #ffffff;
            background: rgba(255, 255, 255, 0.08);
        }

        /* Selector de Canales */
        .csms-channels-bar {
            display: flex;
            gap: 6px;
            padding: 8px 14px;
            background: rgba(0, 0, 0, 0.2);
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
            overflow-x: auto;
        }
        .csms-channels-bar::-webkit-scrollbar {
            height: 4px;
        }
        .csms-channel-pill {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 5px 10px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 600;
            background: rgba(255, 255, 255, 0.04);
            color: #94a3b8;
            border: 1px solid transparent;
            cursor: pointer;
            white-space: nowrap;
            transition: all 0.2s;
        }
        .csms-channel-pill:hover {
            color: #f1f5f9;
            background: rgba(255, 255, 255, 0.08);
        }
        .csms-channel-pill.active {
            background: rgba(99, 102, 241, 0.2);
            color: #818cf8;
            border-color: rgba(99, 102, 241, 0.4);
        }

        /* Lista de Mensajes */
        .csms-messages-body {
            flex: 1;
            padding: 16px;
            overflow-y: auto;
            display: flex;
            flex-direction: column;
            gap: 12px;
        }
        .csms-messages-body::-webkit-scrollbar {
            width: 6px;
        }
        .csms-messages-body::-webkit-scrollbar-thumb {
            background: rgba(255, 255, 255, 0.15);
            border-radius: 4px;
        }

        .csms-msg-item {
            display: flex;
            gap: 10px;
            font-size: 13px;
            line-height: 1.4;
        }
        .csms-msg-avatar {
            width: 32px;
            height: 32px;
            border-radius: 50%;
            background: rgba(99, 102, 241, 0.2);
            color: #818cf8;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            font-size: 12px;
            flex-shrink: 0;
            overflow: hidden;
        }
        .csms-msg-avatar img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }
        .csms-msg-bubble {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.06);
            padding: 8px 12px;
            border-radius: 12px;
            max-width: 82%;
            color: #f1f5f9;
        }
        .csms-msg-item.me {
            flex-direction: row-reverse;
        }
        .csms-msg-item.me .csms-msg-bubble {
            background: linear-gradient(135deg, #4f46e5, #4338ca);
            border-color: rgba(255, 255, 255, 0.15);
            color: #ffffff;
        }
        .csms-msg-author {
            font-size: 11px;
            font-weight: 700;
            color: #818cf8;
            margin-bottom: 3px;
        }
        .csms-msg-item.me .csms-msg-author {
            display: none;
        }
        .csms-msg-time {
            font-size: 10px;
            color: #64748b;
            margin-top: 4px;
            text-align: right;
        }
        .csms-msg-item.me .csms-msg-time {
            color: rgba(255, 255, 255, 0.6);
        }

        /* Input y Envío */
        .csms-input-box {
            padding: 12px 14px;
            background: rgba(255, 255, 255, 0.02);
            border-top: 1px solid rgba(255, 255, 255, 0.07);
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .csms-input {
            flex: 1;
            padding: 10px 14px;
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 12px;
            color: #ffffff;
            font-size: 13px;
            font-family: inherit;
            outline: none;
            transition: border-color 0.2s;
        }
        .csms-input:focus {
            border-color: #6366f1;
        }
        .csms-btn-send {
            background: #6366f1;
            color: white;
            border: none;
            border-radius: 10px;
            width: 36px;
            height: 36px;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.2s;
        }
        .csms-btn-send:hover {
            background: #4f46e5;
            transform: scale(1.05);
        }

        /* Botón de Chat en Post Cards */
        .post-csms-quick-btn {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            background: rgba(99, 102, 241, 0.1);
            color: #818cf8;
            border: 1px solid rgba(99, 102, 241, 0.2);
            padding: 4px 9px;
            border-radius: 8px;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            margin-left: auto;
        }
        .post-csms-quick-btn:hover {
            background: rgba(99, 102, 241, 0.25);
            border-color: rgba(99, 102, 241, 0.4);
            color: #ffffff;
        }

        @keyframes csms-appear {
            from { opacity: 0; transform: translateY(12px) scale(0.97); }
            to { opacity: 1; transform: translateY(0) scale(1); }
        }
        @keyframes csms-pulse {
            0%, 100% { transform: scale(1); opacity: 1; }
            50% { transform: scale(1.15); opacity: 0.9; }
        }
    `;
    document.head.appendChild(style);
}

function injectCSMSDOM() {
    const container = document.createElement('div');
    container.id = 'coki-csms-container';

    container.innerHTML = `
        <!-- Mini Drawer Flotante -->
        <div class="csms-drawer" id="csms-drawer">
            <!-- Header -->
            <div class="csms-header">
                <div class="csms-header-info">
                    <div class="csms-status-dot"></div>
                    <div>
                        <div class="csms-header-title" id="csms-active-room-title">💬 Comunidad Global</div>
                        <div class="csms-header-subtitle">CSMS en vivo para Forkar PC</div>
                    </div>
                </div>
                <div class="csms-header-actions">
                    <a href="messenger" target="_blank" class="csms-btn-icon" title="Abrir CSMS en pantalla completa">
                        <svg width="15" height="15" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"/></svg>
                    </a>
                    <button class="csms-btn-icon" id="csms-close-btn" title="Cerrar (Esc)">
                        <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                    </button>
                </div>
            </div>

            <!-- Selector de Canales Canónicos -->
            <div class="csms-channels-bar">
                ${CSMS_CHANNELS.map((ch, idx) => `
                    <button class="csms-channel-pill ${idx === 0 ? 'active' : ''}" data-room-id="${ch.id}" title="${ch.desc}">
                        <span>${ch.icon}</span>
                        <span>${ch.name}</span>
                    </button>
                `).join('')}
            </div>

            <!-- Cuerpo de Mensajes -->
            <div class="csms-messages-body" id="csms-messages-body">
                <div style="text-align:center; color:#94a3b8; font-size:12px; margin-top:20px;">Cargando mensajes en tiempo real...</div>
            </div>

            <!-- Input Box -->
            <div class="csms-input-box">
                <input type="text" id="csms-chat-input" class="csms-input" placeholder="Escribe un mensaje en la comunidad..." autocomplete="off">
                <button id="csms-send-btn" class="csms-btn-send" title="Enviar mensaje">
                    <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"/></svg>
                </button>
            </div>
        </div>

        <!-- Botón Lanzador Flotante (FAB) -->
        <div class="csms-fab" id="csms-fab" title="Abrir CSMS Messenger (Ctrl+M)">
            <div class="csms-fab-icon">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path></svg>
            </div>
            <span class="csms-fab-title">CSMS Chat</span>
            <div class="csms-status-dot"></div>
            <span class="csms-fab-badge" id="csms-badge">0</span>
        </div>
    `;

    document.body.appendChild(container);
}

function bindEvents() {
    const fab = document.getElementById('csms-fab');
    const drawer = document.getElementById('csms-drawer');
    const closeBtn = document.getElementById('csms-close-btn');
    const input = document.getElementById('csms-chat-input');
    const sendBtn = document.getElementById('csms-send-btn');
    const badge = document.getElementById('csms-badge');

    fab.addEventListener('click', () => {
        isDrawerOpen = !isDrawerOpen;
        drawer.classList.toggle('open', isDrawerOpen);
        if (isDrawerOpen) {
            unreadCount = 0;
            badge.style.display = 'none';
            input.focus();
            scrollChatToBottom();
        }
    });

    closeBtn.addEventListener('click', () => {
        isDrawerOpen = false;
        drawer.classList.remove('open');
    });

    // Enviar al pulsar Enter
    input.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    });

    sendBtn.addEventListener('click', sendMessage);

    // Atajo global Ctrl+M o Cmd+M para abrir/cerrar
    document.addEventListener('keydown', (e) => {
        if ((e.ctrlKey || e.metaKey) && (e.key === 'm' || e.key === 'M')) {
            e.preventDefault();
            fab.click();
        }
        if (e.key === 'Escape' && isDrawerOpen) {
            isDrawerOpen = false;
            drawer.classList.remove('open');
        }
    });

    // Pestañas de canales
    document.querySelectorAll('.csms-channel-pill').forEach(pill => {
        pill.addEventListener('click', () => {
            document.querySelectorAll('.csms-channel-pill').forEach(p => p.classList.remove('active'));
            pill.classList.add('active');
            activeRoomId = pill.dataset.roomId;
            const channelInfo = CSMS_CHANNELS.find(c => c.id === activeRoomId);
            document.getElementById('csms-active-room-title').textContent = `${channelInfo?.icon || '💬'} ${channelInfo?.name || 'Canal'}`;
            loadMessages(activeRoomId);
        });
    });

    // Exponer función global para abrir chat desde cualquier post de Forkar
    window.openCSMSChat = (targetUserId, targetName, targetAvatar) => {
        if (!isDrawerOpen) {
            fab.click();
        }
        input.value = `@${targetName.replace(/\s+/g, '')} `;
        input.focus();
    };
}

async function loadMessages(roomId) {
    const container = document.getElementById('csms-messages-body');
    container.innerHTML = `<div style="text-align:center; color:#94a3b8; font-size:12px; margin-top:20px;">Cargando mensajes...</div>`;

    const { data: messages, error } = await supabase
        .from('chat_messages')
        .select('*')
        .eq('room_id', roomId)
        .order('created_at', { ascending: true })
        .limit(40);

    if (error) {
        container.innerHTML = `<div style="text-align:center; color:#ef4444; font-size:12px; margin-top:20px;">Error al cargar mensajes: ${error.message}</div>`;
        return;
    }

    if (!messages || messages.length === 0) {
        container.innerHTML = `
            <div style="text-align:center; color:#94a3b8; font-size:12px; margin-top:30px;">
                <p>👋 ¡Sé el primero en enviar un mensaje en este canal de Forkar!</p>
            </div>
        `;
        return;
    }

    container.innerHTML = messages.map(renderMessageItem).join('');
    scrollChatToBottom();
}

function renderMessageItem(msg) {
    const isMe = currentUser && msg.sender_id === currentUser.id;
    const authorName = msg.author_name || 'Usuario';
    const initials = authorName.substring(0, 2).toUpperCase();
    const time = formatTime(msg.created_at);

    return `
        <div class="csms-msg-item ${isMe ? 'me' : ''}">
            <div class="csms-msg-avatar">
                ${msg.author_avatar ? `<img src="${msg.author_avatar}" alt="${authorName}">` : initials}
            </div>
            <div class="csms-msg-bubble">
                ${!isMe ? `<div class="csms-msg-author">${authorName}</div>` : ''}
                <div class="csms-msg-text">${escapeHtml(msg.content)}</div>
                <div class="csms-msg-time">${time}</div>
            </div>
        </div>
    `;
}

async function sendMessage() {
    const input = document.getElementById('csms-chat-input');
    const content = input.value.trim();
    if (!content) return;

    if (!currentUser) {
        alert('Debes iniciar sesión en Forkar para enviar mensajes en CSMS.');
        return;
    }

    input.value = '';
    const authorName = currentUser.user_metadata?.full_name || currentUser.email?.split('@')[0] || 'Usuario Forkar';
    const authorAvatar = currentUser.user_metadata?.avatar_url || null;

    // Enviar a Supabase
    const { error } = await supabase
        .from('chat_messages')
        .insert([{
            room_id: activeRoomId,
            sender_id: currentUser.id,
            content: content,
            author_name: authorName,
            author_avatar: authorAvatar
        }]);

    if (error) {
        alert('Error al enviar mensaje: ' + error.message);
    }
}

function subscribeRealtime() {
    if (realtimeChannel) {
        supabase.removeChannel(realtimeChannel);
    }

    realtimeChannel = supabase
        .channel('csms-forkar-global')
        .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'chat_messages' }, (payload) => {
            const newMsg = payload.new;
            if (newMsg.room_id === activeRoomId) {
                const container = document.getElementById('csms-messages-body');
                // Si estaba el mensaje vacío, limpiarlo
                if (container.innerText.includes('Sé el primero')) {
                    container.innerHTML = '';
                }
                container.insertAdjacentHTML('beforeend', renderMessageItem(newMsg));
                scrollChatToBottom();
            }

            // Si el drawer está cerrado, mostrar notificación e incrementar badge
            if (!isDrawerOpen) {
                unreadCount++;
                const badge = document.getElementById('csms-badge');
                badge.textContent = unreadCount > 9 ? '9+' : unreadCount;
                badge.style.display = 'inline-block';
            }
        })
        .subscribe();
}

function scrollChatToBottom() {
    const container = document.getElementById('csms-messages-body');
    if (container) {
        container.scrollTop = container.scrollHeight;
    }
}

function formatTime(dateStr) {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function updateUserUI() {
    // Si se requiere adaptar algo según el usuario logueado
}
