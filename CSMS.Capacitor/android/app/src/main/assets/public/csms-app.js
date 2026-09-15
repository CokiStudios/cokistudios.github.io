const SUPABASE_URL = "https://cmkumxprmmhuinxfppxl.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ";

const supabase = window.supabase ? window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY) : null;

// DOM Elements
const viewRooms = document.getElementById('view-rooms');
const viewChat = document.getElementById('view-chat');
const roomsList = document.getElementById('rooms-list');
const messagesList = document.getElementById('messages-list');
const headerTitle = document.getElementById('header-title');
const headerSubtitle = document.getElementById('header-subtitle');
const btnBack = document.getElementById('btn-back');
const btnNewGroup = document.getElementById('btn-new-group');
const btnSendMsg = document.getElementById('btn-send-msg');
const inputMsg = document.getElementById('input-msg');

const modalCreateGroup = document.getElementById('modal-create-group');
const btnCancelGroup = document.getElementById('btn-cancel-group');
const btnSubmitGroup = document.getElementById('btn-submit-group');
const inputGroupName = document.getElementById('input-group-name');

let currentRoom = null;
let pollTimer = null;

// ── FETCH ROOMS ──
async function fetchRooms() {
  roomsList.innerHTML = '<div class="loading-spinner">Cargando salas CSMS...</div>';
  try {
    const { data, error } = await supabase
      .from('chat_rooms')
      .select('*')
      .order('created_at', { ascending: false });

    if (error || !data || data.length === 0) {
      renderRooms([
        { id: 'csms-global', name: '💬 Comunidad Coki Studios Global', is_group: true },
        { id: 'csms-eco', name: '🌿 Eco Hub Cota & Cundinamarca', is_group: true }
      ]);
    } else {
      renderRooms(data);
    }
  } catch (e) {
    console.warn('Error fetching rooms:', e);
  }
}

function renderRooms(rooms) {
  roomsList.innerHTML = '';
  rooms.forEach(room => {
    const card = document.createElement('div');
    card.className = 'room-card';
    const initials = (room.name || 'CS').substring(0, 2).toUpperCase();
    card.innerHTML = `
      <div class="room-avatar">${initials}</div>
      <div class="room-info">
        <div class="room-name">${escapeHtml(room.name)}</div>
        <div class="room-desc">${room.is_group ? 'Grupo de Chat CSMS' : 'Mensaje Directo'}</div>
      </div>
      <div class="chevron">→</div>
    `;
    card.onclick = () => openRoom(room);
    roomsList.appendChild(card);
  });
}

// ── OPEN ROOM ──
function openRoom(room) {
  currentRoom = room;
  headerTitle.textContent = room.name;
  headerSubtitle.textContent = 'Sincronizado en tiempo real';
  btnBack.classList.remove('hidden');
  btnNewGroup.classList.add('hidden');

  viewRooms.classList.add('hidden');
  viewChat.classList.remove('hidden');

  fetchMessages(room.id);

  if (pollTimer) clearInterval(pollTimer);
  pollTimer = setInterval(() => {
    if (currentRoom && currentRoom.id === room.id) {
      fetchMessages(room.id, true);
    }
  }, 3000);
}

function closeRoom() {
  currentRoom = null;
  if (pollTimer) clearInterval(pollTimer);
  headerTitle.textContent = 'CSMS Capacitor';
  headerSubtitle.textContent = 'Coki Messaging Service Sincronizado';
  btnBack.classList.add('hidden');
  btnNewGroup.classList.remove('hidden');

  viewChat.classList.add('hidden');
  viewRooms.classList.remove('hidden');
}

// ── FETCH MESSAGES ──
async function fetchMessages(roomId, isBackground = false) {
  if (!isBackground) {
    messagesList.innerHTML = '<div class="loading-spinner">Cargando mensajes...</div>';
  }
  try {
    const { data, error } = await supabase
      .from('chat_messages')
      .select('*')
      .eq('room_id', roomId)
      .order('created_at', { ascending: true });

    if (error || !data || data.length === 0) {
      if (!isBackground) {
        messagesList.innerHTML = `
          <div class="msg-wrapper msg-other">
            <div class="msg-bubble">
              ¡Bienvenido al canal CSMS sincronizado!
              <div class="msg-time">Ahora</div>
            </div>
          </div>
        `;
      }
    } else {
      renderMessages(data);
    }
  } catch (e) {
    console.warn('Error fetching messages:', e);
  }
}

function renderMessages(messages) {
  const isScrolledToBottom = messagesList.scrollHeight - messagesList.clientHeight <= messagesList.scrollTop + 50;
  messagesList.innerHTML = '';
  
  messages.forEach(msg => {
    const isMine = msg.sender_id === 'my-user';
    const wrapper = document.createElement('div');
    wrapper.className = `msg-wrapper ${isMine ? 'msg-mine' : 'msg-other'}`;
    const time = new Date(msg.created_at || Date.now()).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    wrapper.innerHTML = `
      <div class="msg-bubble">
        <div>${escapeHtml(msg.content)}</div>
        <div class="msg-time">${time}</div>
      </div>
    `;
    messagesList.appendChild(wrapper);
  });

  if (isScrolledToBottom) {
    messagesList.scrollTop = messagesList.scrollHeight;
  }
}

// ── SEND MESSAGE ──
async function sendMessage() {
  const content = inputMsg.value.trim();
  if (!content || !currentRoom) return;

  inputMsg.value = '';

  try {
    await supabase
      .from('chat_messages')
      .insert({
        room_id: currentRoom.id,
        content: content,
        sender_id: 'my-user'
      });

    fetchMessages(currentRoom.id);
  } catch (e) {
    console.warn('Error sending msg:', e);
  }
}

// ── CREATE GROUP ──
async function createGroup() {
  const name = inputGroupName.value.trim();
  if (!name) return;

  try {
    const { data, error } = await supabase
      .from('chat_rooms')
      .insert({ name: name, is_group: true })
      .select()
      .single();

    if (!error) {
      inputGroupName.value = '';
      modalCreateGroup.classList.add('hidden');
      fetchRooms();
    }
  } catch (e) {
    alert('Error al crear grupo');
  }
}

function escapeHtml(str) {
  return String(str || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

// ── EVENT LISTENERS ──
btnBack.onclick = closeRoom;
btnNewGroup.onclick = () => modalCreateGroup.classList.remove('hidden');
btnCancelGroup.onclick = () => modalCreateGroup.classList.add('hidden');
btnSubmitGroup.onclick = createGroup;
btnSendMsg.onclick = sendMessage;

inputMsg.onkeydown = (e) => {
  if (e.key === 'Enter') sendMessage();
};

// Initial load
fetchRooms();
