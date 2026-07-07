let locale = 'en';
const vehicleImages = {};

function setLocale(l) {
    locale = l;
    document.documentElement.dir = l === 'ar' ? 'rtl' : 'ltr';
    document.querySelectorAll('[data-en]').forEach(el => {
        el.textContent = el.getAttribute(`data-${l}`);
    });
    document.querySelectorAll('[data-placeholder-en]').forEach(el => {
        el.placeholder = el.getAttribute(`data-placeholder-${l}`);
    });
}

function toast(msg, type = 'info') {
    const c = document.getElementById('toast-container');
    const t = document.createElement('div');
    t.className = `toast ${type}`;
    t.textContent = msg;
    c.appendChild(t);
    setTimeout(() => { t.style.opacity = '0'; setTimeout(() => t.remove(), 300); }, 3000);
}

function handleError(err) {
    console.error(err);
    toast('An error occurred', 'error');
}

function $(id) { return document.getElementById(id); }

// ─── Tab Switching ───
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        btn.classList.add('active');
        $(`tab-${btn.dataset.tab}`).classList.add('active');

        const tab = btn.dataset.tab;
        if (tab === 'bunkers') loadBunkers();
        else if (tab === 'objects') loadObjects();
        else if (tab === 'doors') loadDoors();
        else if (tab === 'commands') loadCommands();
        else if (tab === 'server') loadPlayers();
    });
});

// ─── Init ───
window.addEventListener('DOMContentLoaded', () => {
    fetch(`https://${(window.location.hostname || 'god-dashboard')}/godDashboardReady`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({})
    }).then(r => r.json()).then(data => {
        if (!data.admin) {
            toast('Access denied', 'error');
            setTimeout(() => closeDashboard(), 1000);
            return;
        }
        if (data.locale && data.locale.startsWith('ar')) setLocale('ar');
        loadBunkers();
    }).catch(() => {});
});

document.getElementById('closeBtn').addEventListener('click', closeDashboard);
document.getElementById('langToggle').addEventListener('click', () => setLocale(locale === 'en' ? 'ar' : 'en'));

function closeDashboard() {
    fetch(`https://${(window.location.hostname || 'god-dashboard')}/closeDashboard`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({})
    });
}

// ─── Server Events ───
function serverAction(action, value) {
    fetch(`https://${(window.location.hostname || 'god-dashboard')}/serverAction`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action, value, target: null, reason: null })
    }).then(r => r.json()).catch(handleError);
}

// ─── Bunkers ───
function loadBunkers() {
    fetch(`https://${(window.location.hostname || 'god-dashboard')}/getBunkers`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({})
    }).then(r => r.json()).then(renderBunkers).catch(handleError);
}

function renderBunkers(bunkers) {
    const container = $('bunkerList');
    if (!bunkers || bunkers.length === 0) {
        container.innerHTML = '<div class="data-card"><p style="text-align:center;color:var(--text-dim)">No bunkers found</p></div>';
        return;
    }
    container.innerHTML = bunkers.map(b => `
        <div class="data-card bunker-item" data-label="${b.label.toLowerCase()}">
            <h4>${b.label}</h4>
            <div class="meta">
                <span>🔑 ${b.passcode}</span>
                <span class="badge ${b.locked ? 'locked' : 'unlocked'}">${b.locked ? '🔒 Locked' : '🔓 Unlocked'}</span>
                <span class="badge ${b.interiorType === 'bunker_meth_lab' ? 'meth' : 'standard'}">${b.interiorType === 'bunker_meth_lab' ? '🧪 Meth Lab' : '🏠 Standard'}</span>
            </div>
            <div class="card-actions">
                <button class="btn-primary" onclick="teleportToBunker('${b.id}')"><i class="fas fa-map-marker-alt"></i> ${locale === 'ar' ? 'انتقال' : 'TP'}</button>
                <button class="btn-warning" onclick="duplicateBunker('${b.id}')"><i class="fas fa-copy"></i> ${locale === 'ar' ? 'نسخ' : 'Dup'}</button>
                <button class="btn-danger" onclick="deleteBunker('${b.id}')"><i class="fas fa-trash"></i></button>
            </div>
        </div>
    `).join('');
}

function teleportToBunker(id) {
    fetch(`https://${(window.location.hostname || 'god-dashboard')}/teleportToBunker`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ id })
    }).then(r => r.json()).then(() => toast('Teleported', 'success')).catch(handleError);
}

function deleteBunker(id) {
    if (!confirm(locale === 'ar' ? 'هل أنت متأكد؟' : 'Are you sure?')) return;
    fetch(`https://${(window.location.hostname || 'god-dashboard')}/deleteBunker`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ id })
    }).then(r => r.json()).then(() => { toast('Bunker deleted', 'success'); loadBunkers(); }).catch(handleError);
}

function duplicateBunker(id) {
    fetch(`https://${(window.location.hostname || 'god-dashboard')}/duplicateBunker`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ id })
    }).then(r => r.json()).then(() => { toast('Bunker duplicated', 'success'); loadBunkers(); }).catch(handleError);
}

function filterBunkers() {
    const q = $('bunkerSearch').value.toLowerCase();
    document.querySelectorAll('.bunker-item').forEach(el => {
        el.style.display = el.dataset.label.includes(q) ? 'block' : 'none';
    });
}

// ─── Objects ───
function placeObject(model) {
    if (!model || model.trim() === '') { toast('Enter a model name', 'error'); return; }
    fetch(`https://${(window.location.hostname || 'god-dashboard')}/placeObject`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ model: model.trim() })
    }).then(r => r.json()).then(() => { toast('Placing object...', 'info'); setTimeout(loadObjects, 1000); }).catch(handleError);
}

function loadObjects() {
    fetch(`https://${(window.location.hostname || 'god-dashboard')}/getObjects`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({})
    }).then(r => r.json()).then(renderObjects).catch(handleError);
}

function renderObjects(objects) {
    const container = $('objectList');
    const entries = Object.entries(objects);
    if (entries.length === 0) {
        container.innerHTML = '<div class="data-card"><p style="text-align:center;color:var(--text-dim)">No placed objects</p></div>';
        return;
    }
    container.innerHTML = entries.map(([id, obj]) => `
        <div class="data-card">
            <h4>${obj.model}</h4>
            <div class="meta"><span>ID: ${id}</span></div>
            <div class="card-actions">
                <button class="btn-primary" onclick="teleportToObject('${id}')"><i class="fas fa-map-marker-alt"></i> ${locale === 'ar' ? 'انتقال' : 'TP'}</button>
                <button class="btn-danger" onclick="deleteObject('${id}')"><i class="fas fa-trash"></i></button>
            </div>
        </div>
    `).join('');
}

function teleportToObject(id) {
    fetch(`https://${(window.location.hostname || 'god-dashboard')}/teleportToObject`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ id })
    }).then(r => r.json()).then(() => toast('Teleported', 'success')).catch(handleError);
}

function deleteObject(id) {
    if (!confirm(locale === 'ar' ? 'هل أنت متأكد؟' : 'Are you sure?')) return;
    fetch(`https://${(window.location.hostname || 'god-dashboard')}/deleteObject`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ id })
    }).then(r => r.json()).then(() => { toast('Object deleted', 'success'); loadObjects(); }).catch(handleError);
}

// ─── Doors ───
function loadDoors() {
    fetch(`https://${(window.location.hostname || 'god-dashboard')}/getDoors`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({})
    }).then(r => r.json()).then(renderDoors).catch(handleError);
}

function renderDoors(doors) {
    const container = $('doorList');
    if (!doors || doors.length === 0) {
        container.innerHTML = '<div class="data-card"><p style="text-align:center;color:var(--text-dim)">No passcode doors</p></div>';
        return;
    }
    container.innerHTML = doors.map(d => `
        <div class="data-card door-item" data-label="${(d.label || '').toLowerCase()}">
            <h4>${d.label || 'Door #' + d.id}</h4>
            <div class="meta">
                <span>ID: ${d.id}</span>
                <span class="badge ${d.is_locked ? 'locked' : 'unlocked'}">${d.is_locked ? '🔒 Locked' : '🔓 Unlocked'}</span>
            </div>
            <div class="card-actions">
                <button class="btn-danger" onclick="deleteDoor(${d.id})"><i class="fas fa-trash"></i> ${locale === 'ar' ? 'حذف' : 'Delete'}</button>
            </div>
        </div>
    `).join('');
}

function createDoor() {
    const passcode = prompt(locale === 'ar' ? 'أدخل رمز الباب (3+ أحرف):' : 'Enter door passcode (3+ chars):', '1234');
    if (!passcode || passcode.length < 3) { toast('Invalid passcode', 'error'); return; }
    const label = prompt(locale === 'ar' ? 'اسم الباب:' : 'Door label:', 'Passcode Door');
    fetch(`https://${(window.location.hostname || 'god-dashboard')}/createDoor`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ label: label || 'Passcode Door', passcode, doorModel: null })
    }).then(r => r.json()).then(() => { toast('Door created', 'success'); setTimeout(loadDoors, 500); }).catch(handleError);
}

function deleteDoor(id) {
    if (!confirm(locale === 'ar' ? 'هل أنت متأكد؟' : 'Are you sure?')) return;
    fetch(`https://${(window.location.hostname || 'god-dashboard')}/deleteDoor`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ id })
    }).then(r => r.json()).then(() => { toast('Door deleted', 'success'); loadDoors(); }).catch(handleError);
}

function filterDoors() {
    const q = $('doorSearch').value.toLowerCase();
    document.querySelectorAll('.door-item').forEach(el => {
        el.style.display = el.dataset.label.includes(q) ? 'block' : 'none';
    });
}

// ─── Vehicles ───
const vehicleCategories = [
    { name: 'Super', icon: 'fas fa-rocket', models: ['adder','zentorno','t20','osiris','reaper','nero','pfister811','tempesta','italirsx','vagner'] },
    { name: 'Sports', icon: 'fas fa-car', models: ['elegy2','comet2','banshee','buffalo','carbonizzare','jester','massacro','feltzer2','khamelion','ninef'] },
    { name: 'Muscle', icon: 'fas fa-car-side', models: ['blade','buccaneer','clique','dominator','dukes','gauntlet','hotknife','nightshade','phoenix','sabregt'] },
    { name: 'Off-Road', icon: 'fas fa-truck', models: ['bifta','bf400','blazer','dubsta3','kamacho','mesa3','rancherxl','rebel2','sandking','trophytruck'] },
    { name: 'Bikes', icon: 'fas fa-motorcycle', models: ['akuma','bati','carbonrs','double','hakuchou','pcj','ruffian','sanctus','sovereign','thrust'] },
    { name: 'Emergency', icon: 'fas fa-ambulance', models: ['police','police2','police3','police4','sheriff','ambulance','firetruk','polbike','polmav','predator'] },
    { name: 'Commercial', icon: 'fas fa-truck-moving', models: ['benson','bobcatxl','boxville','mule','packer','phantom','pounder','rubble','stockade','tiptruck'] },
    { name: 'Helicopters', icon: 'fas fa-helicopter', models: ['buzzard','frogger','maverick','seasparrow','supervolito','swift','valkyrie','volatus','savage','hydra'] },
];

function loadVehicles() {
    const container = $('vehicleCategories');
    container.innerHTML = vehicleCategories.map(cat => `
        <div class="category-section" data-cat="${cat.name.toLowerCase()}">
            <div class="category-header"><i class="${cat.icon}"></i> ${cat.name}</div>
            <div class="vehicle-grid">${cat.models.map(m => `
                <div class="vehicle-card" data-model="${m}" onclick="spawnVehicle('${m}')">
                    <img src="https://docs.fivem.net/vehicles/${m}.jpg" onerror="this.src='data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 60%22><rect fill=%22%23333%22 width=%22100%22 height=%2260%22/><text x=%2250%22 y=%2235%22 text-anchor=%22middle%22 fill=%22%23888%22 font-size=%2212%22>${m}</text></svg>'">
                    <div class="vname">${m}</div>
                    <div class="vmodel">${cat.name}</div>
                </div>
            `).join('')}</div>
        </div>
    `).join('');
}

function spawnVehicle(model) {
    fetch(`https://${(window.location.hostname || 'god-dashboard')}/spawnVehicle`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ model })
    }).then(r => r.json()).then(() => toast('Previewing ' + model + '...', 'info')).catch(handleError);
}

function filterVehicles() {
    const q = $('vehicleSearch').value.toLowerCase();
    document.querySelectorAll('.vehicle-card').forEach(el => {
        el.style.display = el.dataset.model.includes(q) ? 'block' : 'none';
    });
    document.querySelectorAll('.category-section').forEach(el => {
        const visible = [...el.querySelectorAll('.vehicle-card')].some(c => c.style.display !== 'none');
        el.style.display = visible ? 'block' : 'none';
    });
}

// ─── Commands ───
function loadCommands() {
    fetch(`https://${(window.location.hostname || 'god-dashboard')}/getCommands`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({})
    }).then(r => r.json()).then(renderCommands).catch(handleError);
}

function renderCommands(commands) {
    const container = $('commandList');
    const stats = $('commandStats');
    if (!commands || commands.length === 0) {
        container.innerHTML = '<div class="data-card"><p style="text-align:center;color:var(--text-dim)">No commands available</p></div>';
        stats.innerHTML = '';
        return;
    }
    const total = commands.length;
    const adminCmds = commands.filter(c => c.adminOnly).length;
    stats.innerHTML = `<span>📋 ${total} ${locale === 'ar' ? 'أمر' : 'commands'}</span><span>🔒 ${adminCmds} ${locale === 'ar' ? 'إدارية' : 'admin'}</span>`;
    container.innerHTML = commands.map(c => `
        <div class="data-card cmd-item" data-name="${c.name.toLowerCase()}" data-desc="${(c.description || '').toLowerCase()}">
            <h4>/${c.name}</h4>
            <p style="font-size:12px;color:var(--text-dim)">${c.description || ''}</p>
            ${c.adminOnly ? '<span class="badge locked" style="margin-top:6px;display:inline-block">🔒 Admin</span>' : ''}
        </div>
    `).join('');
}

function filterCommands() {
    const q = $('commandSearch').value.toLowerCase();
    document.querySelectorAll('.cmd-item').forEach(el => {
        const match = el.dataset.name.includes(q) || el.dataset.desc.includes(q);
        el.style.display = match ? 'block' : 'none';
    });
}

// ─── Server ───
function loadPlayers() {
    fetch(`https://${(window.location.hostname || 'god-dashboard')}/getPlayers`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({})
    }).then(r => r.json()).then(renderPlayers).catch(handleError);
}

function renderPlayers(players) {
    const container = $('playerList');
    if (!players || players.length === 0) {
        container.innerHTML = '<p style="color:var(--text-dim);text-align:center">No players online</p>';
        return;
    }
    container.innerHTML = players.map(p => `
        <div class="player-card player-item" data-name="${p.name.toLowerCase()}">
            <div>
                <div class="pname">${p.name}</div>
                <div class="pmeta">${p.job} | ${p.group || 'user'}</div>
            </div>
            <div class="pactions">
                <button class="btn-primary" onclick="serverActionWithTarget('teleportToPlayer', ${p.src})" title="TP To"><i class="fas fa-arrow-right"></i></button>
                <button class="btn-warning" onclick="serverActionWithTarget('bringPlayer', ${p.src})" title="Bring"><i class="fas fa-arrow-left"></i></button>
                <button class="btn-danger" onclick="kickPlayer(${p.src})" title="Kick"><i class="fas fa-user-slash"></i></button>
            </div>
        </div>
    `).join('');
}

function serverActionWithTarget(action, target) {
    fetch(`https://${(window.location.hostname || 'god-dashboard')}/serverAction`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action, value: null, target, reason: null })
    }).then(r => r.json()).then(() => toast('Action sent', 'success')).catch(handleError);
}

function kickPlayer(target) {
    const reason = prompt(locale === 'ar' ? 'سبب الطرد:' : 'Kick reason:', 'No reason');
    fetch(`https://${(window.location.hostname || 'god-dashboard')}/serverAction`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'kickPlayer', value: null, target, reason: reason || 'No reason' })
    }).then(r => r.json()).then(() => toast('Player kicked', 'success')).catch(handleError);
}

function filterPlayers() {
    const q = $('playerSearch').value.toLowerCase();
    document.querySelectorAll('.player-item').forEach(el => {
        el.style.display = el.dataset.name.includes(q) ? 'flex' : 'none';
    });
}

// ─── Listen for NUI messages ───
window.addEventListener('message', event => {
    const data = event.data;
    if (!data || !data.action) return;
    switch (data.action) {
        case 'open':
            document.getElementById('dashboard').style.display = 'flex';
            break;
        case 'setBunkers':
            renderBunkers(data.bunkers);
            break;
        case 'setObjects':
            renderObjects(data.objects);
            break;
        case 'setDoors':
            renderDoors(data.doors);
            break;
        case 'setCommands':
            renderCommands(data.commands);
            break;
    }
});

// ─── Initialize vehicles on tab show ───
const origVehiclesTab = document.querySelector('.tab-btn[data-tab="vehicles"]');
if (origVehiclesTab) {
    origVehiclesTab.addEventListener('click', () => {
        setTimeout(loadVehicles, 50);
    });
}

document.addEventListener('keydown', e => {
    if (e.key === 'Escape') closeDashboard();
});

loadVehicles();
