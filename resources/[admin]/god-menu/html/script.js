const weatherList = ['CLEAR','EXTRASUNNY','CLOUDS','OVERCAST','RAIN','THUNDER','SMOG','FOGGY','SNOW','BLIZZARD','HALLOWEEN','NEUTRAL'];
const itemList = [
    'pistol_ammo','rifle_ammo','shotgun_ammo','smg_ammo',
    'armor','handcuffs','lockpick','radio','phone','id_card',
    'weapon_pistol','weapon_smg','weapon_assaultrifle','weapon_carbinerifle',
    'weapon_pumpshotgun','weapon_stungun','weapon_nightstick','weapon_bat',
    'weapon_knife','weapon_sniperrifle','weapon_heavypistol',
];

let teleportPresets = [];
let players = [];
let noclipOn = false;
let spectateOn = false;

window.addEventListener('message', function(e) {
    const data = e.data;
    if (data.action === 'open') {
        document.body.style.display = 'block';
        if (data.config) {
            if (data.config.weatherList) {
                renderWeather(data.config.weatherList);
            }
            if (data.config.teleportPresets) {
                teleportPresets = data.config.teleportPresets;
                renderTeleportPresets(data.config.teleportPresets);
            }
            if (data.config.itemList) {
                populateItemSelects(data.config.itemList);
            } else {
                populateItemSelects(itemList);
            }
        } else {
            renderWeather(weatherList);
            populateItemSelects(itemList);
        }
        refreshPlayers();
    } else if (data.action === 'close') {
        document.body.style.display = 'none';
    }
});

// Navigation
document.querySelectorAll('.nav-item').forEach(item => {
    item.addEventListener('click', function() {
        document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
        this.classList.add('active');
        document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
        document.getElementById('tab-' + this.dataset.tab).classList.add('active');
    });
});

// Close
document.getElementById('closeBtn').addEventListener('click', () => {
    fetch('https://' + GetParentResourceName() + '/godClose', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
    document.body.style.display = 'none';
});

// ESC close
document.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
        fetch('https://' + GetParentResourceName() + '/godClose', {
            method: 'POST', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
        document.body.style.display = 'none';
    }
});

// Player search
document.getElementById('playerSearch')?.addEventListener('input', function() {
    renderPlayerTable(players, this.value.toLowerCase());
});

// ==================== PLAYERS ====================
async function refreshPlayers() {
    players = await fetchNui('godGetPlayers', {});
    renderPlayerTable(players, '');
    document.getElementById('playerCount').textContent = players.length;
}

function renderPlayerTable(list, search) {
    const tbody = document.getElementById('playerList');
    if (!tbody) return;
    let filtered = list;
    if (search) {
        filtered = list.filter(p =>
            String(p.id).includes(search) ||
            p.name.toLowerCase().includes(search)
        );
    }
    tbody.innerHTML = filtered.map(p => `
        <tr>
            <td>${p.id}</td>
            <td>${escapeHtml(p.name)}</td>
            <td>${p.cid}</td>
            <td>${p.ping}</td>
            <td class="actions">
                <button class="btn btn-danger" onclick="doKick(${p.id})">Kick</button>
                <button class="btn btn-danger" onclick="doBan(${p.id})">Ban</button>
                <button class="btn btn-info" onclick="doFreeze(${p.id})">Fr</button>
                <button class="btn btn-info" onclick="doTeleportToMe(${p.id})">TP</button>
                <button class="btn btn-primary" onclick="doTeleportToPlayer(${p.id})">Go</button>
                <button class="btn btn-warning" onclick="doSlap(${p.id})">Slap</button>
                <button class="btn btn-success" onclick="doRevive(${p.id})">Rev</button>
                <button class="btn btn-success" onclick="doHeal(${p.id})">Heal</button>
                <button class="btn btn-primary" onclick="doArmor(${p.id})">Armor</button>
                <button class="btn btn-ghost" onclick="doWarn(${p.id})">Warn</button>
                <button class="btn btn-ghost" onclick="doSetJob(${p.id})">Job</button>
                <button class="btn btn-ghost" onclick="doSetGroup(${p.id})">Grp</button>
                <button class="btn btn-ghost" onclick="doSetStat(${p.id})">Stats</button>
                <button class="btn btn-info" onclick="showPlayerDetails(${p.id})">Det</button>
            </td>
        </tr>
    `).join('');
}

function doKick(id) {
    const reason = prompt('Kick reason:');
    fetchNui('godKickPlayer', { id, reason: reason || 'No reason' });
}

function doBan(id) {
    const reason = prompt('Ban reason:');
    fetchNui('godBanPlayer', { id, reason: reason || 'No reason' });
}

function doFreeze(id) {
    fetchNui('godFreezePlayer', { id, state: true });
    setTimeout(() => fetchNui('godFreezePlayer', { id, state: false }), 30000);
}

function doTeleportToMe(id) {
    fetchNui('godTeleportToMe', { id });
}

function doTeleportToPlayer(id) {
    fetchNui('godTeleportToPlayer', { id });
}

function doSlap(id) {
    fetchNui('godSlapPlayer', { id });
}

function doRevive(id) {
    fetchNui('godRevivePlayer', { id });
}

function doHeal(id) {
    fetchNui('godHealPlayer', { id });
}

function doArmor(id) {
    fetchNui('godGiveArmor', { id, amount: 100 });
}

function doAll(action) {
    if (action === 'revive') fetchNui('godReviveAll', {});
}

// ==================== VEHICLES ====================
function spawnVehicle() {
    const model = document.getElementById('vehicleModel').value;
    if (!model) return;
    fetchNui('godSpawnVehicle', { model });
    document.getElementById('vehicleModel').value = '';
}

function fixVehicle() { fetchNui('godFixVehicle', {}); }
function deleteVehicle() { fetchNui('godDeleteVehicle', {}); }

// ==================== ITEMS ====================
function populateItemSelects(list) {
    const html = list.map(i => `<option value="${i}">${i}</option>`).join('');
    const s1 = document.getElementById('itemSelect');
    const s2 = document.getElementById('allItemSelect');
    if (s1) s1.innerHTML = html;
    if (s2) s2.innerHTML = html;
}

function giveItem() {
    const id = document.getElementById('itemPlayerId').value;
    const item = document.getElementById('itemSelect').value;
    const count = document.getElementById('itemCount').value;
    if (!id || !item) return;
    fetchNui('godGiveItem', { id: parseInt(id), item, count: parseInt(count) });
}

function giveCustomItem() {
    const id = document.getElementById('customItemPlayerId').value;
    const item = document.getElementById('customItemName').value;
    const count = document.getElementById('customItemCount').value;
    if (!id || !item) return;
    fetchNui('godGiveItem', { id: parseInt(id), item, count: parseInt(count) });
}

function giveAllItem() {
    const item = document.getElementById('allItemSelect').value;
    const count = document.getElementById('allItemCount').value;
    if (!item) return;
    fetchNui('godGiveAllItem', { item, count: parseInt(count) });
}

// ==================== MONEY ====================
function giveMoney() {
    const id = document.getElementById('moneyPlayerId').value;
    const amount = document.getElementById('moneyAmount').value;
    const type = document.getElementById('moneyType').value;
    if (!id || !amount) return;
    fetchNui('godGiveMoney', { id: parseInt(id), amount: parseInt(amount), type });
}

// ==================== WEATHER ====================
function renderWeather(list) {
    const grid = document.getElementById('weatherGrid');
    if (!grid) return;
    grid.innerHTML = list.map(w => `
        <div class="weather-item" onclick="setWeather('${w}')">${w}</div>
    `).join('');
}

function setWeather(weather) {
    fetchNui('godSetWeather', { weather });
}

// ==================== TIME ====================
function setTime() {
    const hour = document.getElementById('timeHour').value;
    const minute = document.getElementById('timeMinute').value;
    fetchNui('godSetTime', { hour: parseInt(hour), minute: parseInt(minute || 0) });
}

function setTimePreset(h, m) {
    document.getElementById('timeHour').value = h;
    document.getElementById('timeMinute').value = m;
    fetchNui('godSetTime', { hour: h, minute: m });
}

// ==================== TELEPORT ====================
function renderTeleportPresets(list) {
    const grid = document.getElementById('tpPresets');
    if (!grid) return;
    grid.innerHTML = list.map(l => `
        <div class="preset-loc" onclick="teleportPreset(${l.coords.x}, ${l.coords.y}, ${l.coords.z})">
            ${escapeHtml(l.name)}
        </div>
    `).join('');
}

function teleportCoords() {
    const x = parseFloat(document.getElementById('tpX').value);
    const y = parseFloat(document.getElementById('tpY').value);
    const z = parseFloat(document.getElementById('tpZ').value);
    if (isNaN(x) || isNaN(y) || isNaN(z)) return;
    fetchNui('godTeleport', { x, y, z });
}

function teleportPreset(x, y, z) {
    fetchNui('godTeleport', { x, y, z });
}

function teleportWaypoint() {
    fetchNui('godTeleportWaypoint', {});
}

// ==================== SERVER ====================
function sendAnnounce() {
    const msg = document.getElementById('announceMsg').value;
    if (!msg) return;
    fetchNui('godAnnounce', { message: msg });
    document.getElementById('announceMsg').value = '';
}

function clearArea() { fetchNui('godClearArea', {}); }
function reviveAll() { fetchNui('godReviveAll', {}); }

// ==================== TOOLS ====================
async function toggleNoclip() {
    const res = await fetchNui('godNoclip', {});
    noclipOn = res.noclip;
    document.getElementById('noclipStatus').textContent = noclipOn ? 'On' : 'Off';
    document.getElementById('noclipStatus').style.color = noclipOn ? '#32ff64' : 'rgba(255,255,255,0.3)';
}

function promptSpectate() {
    const id = prompt('Player ID to spectate:');
    if (id && parseInt(id)) {
        fetchNui('godSpectate', { id: parseInt(id) });
        spectateOn = true;
        document.getElementById('spectateStatus').textContent = 'On';
        document.getElementById('spectateStatus').style.color = '#0096ff';
    }
}

function stopSpectate() {
    fetchNui('godSpectate', {});
    spectateOn = false;
    document.getElementById('spectateStatus').textContent = 'Off';
    document.getElementById('spectateStatus').style.color = 'rgba(255,255,255,0.3)';
}

// ==================== UTILITIES ====================
async function fetchNui(event, data) {
    const resp = await fetch('https://' + GetParentResourceName() + '/' + event, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });
    return await resp.json();
}

function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}

// ==================== NEW EXPANDED FEATURES ====================

// --- Player: Set Job ---
function doSetJob(id) {
    const job = prompt('Enter job name for player ' + id + ':');
    if (!job) return;
    const grade = prompt('Enter grade (0-12, default 0):');
    fetchNui('godSetJob', { id, job, grade: parseInt(grade || 0) });
}

// --- Player: Set Group ---
function doSetGroup(id) {
    const group = prompt('Enter admin group (admin/superadmin/god) for player ' + id + ':');
    if (!group) return;
    fetchNui('godSetGroup', { id, group });
}

// --- Player: Set Stats ---
function doSetStat(id) {
    const statType = prompt('Enter stat type (health/armor/hunger/thirst) for player ' + id + ':');
    if (!statType) return;
    const value = parseInt(prompt('Enter value for ' + statType + ':'));
    if (isNaN(value)) return;
    fetchNui('godSetPlayerStat', { id, statType, value });
}

// --- Player: Show Details Modal ---
async function showPlayerDetails(id) {
    const details = await fetchNui('godGetPlayerDetails', { id });
    if (!details || !details.citizenid) {
        alert('No details available for player ' + id);
        return;
    }
    document.getElementById('detailsTitle').textContent = 'Player ' + id + ' - ' + escapeHtml(details.citizenid);
    let html = '<div class="detail-section"><h4>Job</h4>';
    html += '<div class="detail-row"><span class="label">Job</span><span class="value">' + escapeHtml(details.job.label || details.job.name) + '</span></div>';
    html += '<div class="detail-row"><span class="label">Grade</span><span class="value">' + (details.job.grade || 0) + '</span></div>';
    html += '<div class="detail-row"><span class="label">Duty</span><span class="value">' + (details.job.onduty ? 'Yes' : 'No') + '</span></div>';
    html += '</div>';
    html += '<div class="detail-section"><h4>Group</h4>';
    html += '<div class="detail-row"><span class="label">Admin Group</span><span class="value">' + escapeHtml(details.group || 'user') + '</span></div>';
    html += '</div>';
    html += '<div class="detail-section"><h4>Money</h4>';
    html += '<div class="detail-row"><span class="label">Cash</span><span class="value">$' + (details.money.cash || 0) + '</span></div>';
    html += '<div class="detail-row"><span class="label">Bank</span><span class="value">$' + (details.money.bank || 0) + '</span></div>';
    html += '</div>';
    html += '<div class="detail-section"><h4>Stats</h4>';
    html += '<div class="detail-row"><span class="label">Health</span><span class="value">' + (details.metadata.health || '?') + '</span></div>';
    html += '<div class="detail-row"><span class="label">Armor</span><span class="value">' + (details.metadata.armor || 0) + '</span></div>';
    html += '<div class="detail-row"><span class="label">Hunger</span><span class="value">' + (details.metadata.hunger || 0) + '</span></div>';
    html += '<div class="detail-row"><span class="label">Thirst</span><span class="value">' + (details.metadata.thirst || 0) + '</span></div>';
    html += '</div>';
    html += '<div class="detail-section"><h4>Inventory (' + details.inventory.length + ' items)</h4>';
    if (details.inventory.length === 0) {
        html += '<div class="detail-row"><span class="value" style="color:rgba(255,255,255,0.3)">Empty</span></div>';
    } else {
        details.inventory.forEach(item => {
            html += '<div class="detail-inv-item"><span class="inv-name">' + escapeHtml(item.label) + ' (' + escapeHtml(item.name) + ')</span><span class="inv-count">x' + item.count + '</span></div>';
        });
    }
    html += '</div>';
    document.getElementById('detailsBody').innerHTML = html;
    document.getElementById('detailsModal').style.display = 'flex';
}

function closeDetails() {
    document.getElementById('detailsModal').style.display = 'none';
}

// --- Vehicles: Give to Garage ---
function giveCarToGarage() {
    const id = parseInt(document.getElementById('garagePlayerId').value);
    const model = document.getElementById('garageVehicleModel').value;
    if (!id || !model) return;
    fetchNui('godGiveCarToGarage', { id, model });
    document.getElementById('garagePlayerId').value = '';
    document.getElementById('garageVehicleModel').value = '';
}

// --- Vehicles: Transfer Ownership ---
function transferVehicle() {
    const plate = document.getElementById('transferPlate').value;
    const newOwnerId = parseInt(document.getElementById('transferNewOwner').value);
    if (!plate || !newOwnerId) return;
    fetchNui('godTransferVehicle', { plate, newOwnerId });
    document.getElementById('transferPlate').value = '';
    document.getElementById('transferNewOwner').value = '';
}

// --- Server: Kill All ---
function killAll() {
    if (confirm('Kill ALL players?')) fetchNui('godKillAll', {});
}

// --- Server: Freeze All ---
function freezeAll() {
    if (confirm('Freeze ALL players for 30 seconds?')) {
        fetchNui('godFreezeAll', { state: true });
        setTimeout(() => fetchNui('godFreezeAll', { state: false }), 30000);
    }
}

// --- Server: Teleport All to Me ---
function teleportAllToMe() {
    if (confirm('Teleport ALL players to you?')) fetchNui('godTeleportAllToMe', {});
}

// --- Server: Give All Money ---
function giveAllMoney() {
    const amount = parseInt(document.getElementById('allMoneyAmount').value);
    const type = document.getElementById('allMoneyType').value;
    if (!amount) return;
    if (confirm('Give $' + amount + ' ' + type + ' to ALL players?')) {
        fetchNui('godGiveAllMoney', { amount, type });
    }
}

// --- Server: Set All Job ---
function setAllJob() {
    const job = document.getElementById('allJobName').value;
    const grade = parseInt(document.getElementById('allJobGrade').value) || 0;
    if (!job) return;
    if (confirm('Set ALL players to job ' + job + ' grade ' + grade + '?')) {
        fetchNui('godSetAllJob', { job, grade });
    }
}

// --- Player: Warn ---
function doWarn(id) {
    const message = prompt('Warning message for player ' + id + ':');
    if (!message) return;
    fetchNui('godWarnPlayer', { id, message });
}

// --- Vehicles: Spawn for Player ---
function spawnVehicleForPlayer() {
    const id = parseInt(document.getElementById('spawnForPlayerId').value);
    const model = document.getElementById('spawnForPlayerModel').value;
    if (!id || !model) return;
    fetchNui('godSpawnVehicleForPlayer', { id, model });
    document.getElementById('spawnForPlayerId').value = '';
    document.getElementById('spawnForPlayerModel').value = '';
}

// --- Server: Restart Countdown ---
function restartCountdown() {
    const mins = prompt('Minutes until restart:');
    if (!mins || !parseInt(mins)) return;
    if (confirm('Send restart warning for ' + mins + ' minutes to ALL players?')) {
        fetchNui('godRestartCountdown', { minutes: parseInt(mins) });
    }
}

// --- Extended doAll ---
function doAll(action) {
    if (action === 'revive') fetchNui('godReviveAll', {});
    else if (action === 'kill') killAll();
    else if (action === 'freeze') freezeAll();
    else if (action === 'tpToMe') teleportAllToMe();
}

// ==================== DOOR MANAGEMENT ====================
let doorsData = [];
let editingDoorId = null;
let jobList = [];

async function loadJobList() {
    jobList = await fetchNui('godGetJobList', {}) || [];
}

function onLockTypeChange() {
    const type = document.getElementById('doorLockType').value;
    document.getElementById('doorPasscodeGroup').style.display = type === 'passcode' ? 'block' : 'none';
    document.getElementById('doorJobGroup').style.display = type === 'job' ? 'block' : 'none';
}

function renderJobCheckboxes() {
    const container = document.getElementById('doorJobCheckboxes');
    container.innerHTML = '';
    jobList.forEach(j => {
        const label = document.createElement('label');
        const cb = document.createElement('input');
        cb.type = 'checkbox';
        cb.value = j.name;
        cb.className = 'job-check-item';
        label.appendChild(cb);
        label.appendChild(document.createTextNode(j.label + ' (' + j.name + ')'));
        container.appendChild(label);
    });
}

function renderDoors() {
    const container = document.getElementById('doorList');
    const skeleton = document.getElementById('doorSkeleton');
    skeleton.style.display = 'none';
    if (!doorsData || doorsData.length === 0) {
        container.innerHTML = '<div class="glass-card"><p style="text-align:center;color:var(--text-muted,rgba(255,255,255,0.4))">No managed doors yet. Use "Detect Current Door" or "Add Manually".</p></div>';
        return;
    }
    container.innerHTML = doorsData.map(d => {
        const typeBadge = d.lock_type === 'permanent' ? 'door-badge-permanent' : d.lock_type === 'passcode' ? 'door-badge-passcode' : 'door-badge-job';
        const typeLabel = d.lock_type === 'permanent' ? 'Permanent' : d.lock_type === 'passcode' ? 'Passcode' : 'Job';
        const stateBadge = d.is_locked ? 'door-badge-locked' : 'door-badge-unlocked';
        const stateLabel = d.is_locked ? 'Locked' : 'Unlocked';
        const jobsStr = d.allowed_jobs && d.allowed_jobs.length > 0 ? d.allowed_jobs.join(', ') : '';
        return `<div class="door-card">
            <div class="door-card-header">
                <span class="door-card-title">${escapeHtml(d.label)}</span>
                <span><span class="door-badge ${typeBadge}">${typeLabel}</span> <span class="door-badge ${stateBadge}">${stateLabel}</span></span>
            </div>
            <div class="door-card-meta">
                <span>Model: ${d.door_model || 'N/A'}</span>
                <span>Coords: ${Math.round(d.coords.x)}, ${Math.round(d.coords.y)}, ${Math.round(d.coords.z)}</span>
                ${jobsStr ? '<span>Jobs: ' + escapeHtml(jobsStr) + '</span>' : ''}
            </div>
            <div class="door-card-actions">
                <button class="btn btn-sm" onclick="toggleDoor(${d.id})">${d.is_locked ? '🔓 Unlock' : '🔒 Lock'}</button>
                <button class="btn btn-sm" onclick="editDoor(${d.id})">✏️ Edit</button>
                <button class="btn btn-sm btn-danger" onclick="deleteDoor(${d.id})">🗑️ Delete</button>
            </div>
        </div>`;
    }).join('');
}

async function refreshDoors() {
    document.getElementById('doorSkeleton').style.display = 'block';
    doorsData = await fetchNui('godGetManagedDoors', {}) || [];
    renderDoors();
}

async function detectCurrentDoor() {
    fetchNui('godClearDoorHighlight', {});
    const result = await fetchNui('godDetectNearestDoor', {});
    if (result.found) {
        document.getElementById('doorModelInput').value = result.model;
    } else {
        document.getElementById('doorModelInput').value = '';
    }
    document.getElementById('doorX').value = result.coords.x.toFixed(2);
    document.getElementById('doorY').value = result.coords.y.toFixed(2);
    document.getElementById('doorZ').value = result.coords.z.toFixed(2);
    document.getElementById('doorHeading').value = (result.heading || 0).toFixed(2);
    showDoorSetup(null);
}

function showDoorSetup(existingDoor) {
    editingDoorId = existingDoor ? existingDoor.id : null;
    document.getElementById('doorModalTitle').textContent = existingDoor ? 'Edit Door Lock' : 'Add Door Lock';
    document.getElementById('doorLabel').value = existingDoor ? existingDoor.label : '';
    document.getElementById('doorModelInput').value = existingDoor ? (existingDoor.door_model || '') : '';
    document.getElementById('doorX').value = existingDoor ? existingDoor.coords.x.toFixed(2) : '';
    document.getElementById('doorY').value = existingDoor ? existingDoor.coords.y.toFixed(2) : '';
    document.getElementById('doorZ').value = existingDoor ? existingDoor.coords.z.toFixed(2) : '';
    document.getElementById('doorHeading').value = existingDoor ? (existingDoor.heading || 0).toFixed(2) : '';
    document.getElementById('doorLockType').value = existingDoor ? existingDoor.lock_type : 'permanent';
    document.getElementById('doorPasscode').value = '';
    onLockTypeChange();
    // If edit, restore job checkboxes
    if (existingDoor && existingDoor.lock_type === 'job' && existingDoor.allowed_jobs) {
        setTimeout(() => {
            document.querySelectorAll('.job-check-item').forEach(cb => {
                cb.checked = existingDoor.allowed_jobs.includes(cb.value);
            });
        }, 100);
    }
    document.getElementById('doorModal').style.display = 'flex';
}

function closeDoorModal() {
    document.getElementById('doorModal').style.display = 'none';
    editingDoorId = null;
    fetchNui('godClearDoorHighlight', {});
}

async function saveDoor() {
    const label = document.getElementById('doorLabel').value.trim();
    const doorModel = document.getElementById('doorModelInput').value.trim();
    const x = parseFloat(document.getElementById('doorX').value);
    const y = parseFloat(document.getElementById('doorY').value);
    const z = parseFloat(document.getElementById('doorZ').value);
    const heading = parseFloat(document.getElementById('doorHeading').value) || 0;
    const lockType = document.getElementById('doorLockType').value;
    const passcode = document.getElementById('doorPasscode').value.trim();
    const allowedJobs = [];
    document.querySelectorAll('.job-check-item:checked').forEach(cb => allowedJobs.push(cb.value));

    if (!label || isNaN(x) || isNaN(y) || isNaN(z)) {
        alert('Please fill in label and valid coordinates.');
        return;
    }
    if (lockType === 'passcode' && (!passcode || !/^\d+$/.test(passcode))) {
        alert('Please enter a numeric passcode.');
        return;
    }
    if (lockType === 'job' && allowedJobs.length === 0) {
        alert('Please select at least one job.');
        return;
    }

    const data = { label, doorModel, coords: { x, y, z }, heading, lockType, passcode, allowedJobs };
    if (editingDoorId) {
        data.doorId = editingDoorId;
        await fetchNui('godUpdateManagedDoor', data);
    } else {
        await fetchNui('godCreateDoorLock', data);
    }
    closeDoorModal();
    setTimeout(refreshDoors, 500);
}

async function toggleDoor(id) {
    await fetchNui('godToggleManagedDoor', { doorId: id });
    setTimeout(refreshDoors, 300);
}

async function editDoor(id) {
    const door = doorsData.find(d => d.id === id);
    if (!door) return;
    showDoorSetup(door);
}

async function deleteDoor(id) {
    if (!confirm('Delete this door lock permanently?')) return;
    await fetchNui('godDeleteManagedDoor', { doorId: id });
    setTimeout(refreshDoors, 300);
}

function lockAllDoors() {
    if (!confirm('Lock ALL managed doors?')) return;
    fetchNui('godLockAllDoors', {});
    setTimeout(refreshDoors, 500);
}

function unlockAllDoors() {
    if (!confirm('Unlock ALL managed doors?')) return;
    fetchNui('godUnlockAllDoors', {});
    setTimeout(refreshDoors, 500);
}

// ==================== BAN MANAGEMENT ====================
let bansData = [];
let banDuration = 3600;

function renderBanTable(list) {
    const tbody = document.getElementById('banList');
    const skeleton = document.getElementById('banSkeleton');
    skeleton.style.display = 'none';
    document.getElementById('banTotalCount').textContent = list.length;
    if (!list || list.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;color:rgba(255,255,255,0.3);padding:20px">No active bans.</td></tr>';
        return;
    }
    tbody.innerHTML = list.map(b => `<tr>
        <td style="font-weight:600">${escapeHtml(b.player_name || 'Unknown')}</td>
        <td style="font-size:11px;font-family:monospace">${escapeHtml(b.identifier || '')}</td>
        <td>${escapeHtml(b.reason || 'None')}</td>
        <td>${escapeHtml(b.banner || 'Unknown')}</td>
        <td>${b.duration === -1 ? 'Permanent' : formatDuration(b.duration)}</td>
        <td><span class="${b.remaining === 'Permanent' ? 'text-gold' : b.remaining === 'Expired' ? 'text-muted' : ''}">${b.remaining}</span></td>
        <td><button class="btn btn-sm btn-success" onclick="unbanPlayer(${b.id})">Unban</button></td>
    </tr>`).join('');
}

async function refreshBanList() {
    document.getElementById('banSkeleton').style.display = 'block';
    bansData = await fetchNui('godGetActiveBans', {}) || [];
    renderBanTable(bansData);
}

document.getElementById('banSearch')?.addEventListener('input', function() {
    const q = this.value.toLowerCase();
    if (!q) { renderBanTable(bansData); return; }
    const filtered = bansData.filter(b =>
        (b.player_name && b.player_name.toLowerCase().includes(q)) ||
        (b.identifier && b.identifier.toLowerCase().includes(q))
    );
    renderBanTable(filtered);
});

// Duration selector
document.addEventListener('click', function(e) {
    if (e.target.classList.contains('ban-dur-btn')) {
        document.querySelectorAll('.ban-dur-btn').forEach(b => b.classList.remove('active'));
        e.target.classList.add('active');
        banDuration = parseInt(e.target.dataset.dur);
    }
});

function formatDuration(seconds) {
    if (seconds <= 0) return 'Permanent';
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    const parts = [];
    if (days > 0) parts.push(days + 'd');
    if (hours > 0) parts.push(hours + 'h');
    if (mins > 0) parts.push(mins + 'm');
    return parts.join(' ') || '1m';
}

function showBanModal() {
    document.getElementById('banModalTitle').textContent = 'Ban Player';
    document.getElementById('banReason').value = '';
    document.querySelectorAll('.ban-dur-btn').forEach(b => b.classList.remove('active'));
    document.querySelector('.ban-dur-btn[data-dur="3600"]')?.classList.add('active');
    banDuration = 3600;
    document.getElementById('banCustomDuration').value = '';
    // Populate player select
    const sel = document.getElementById('banPlayerSelect');
    sel.innerHTML = '<option value="">-- Select player --</option>' +
        players.map(p => `<option value="${p.id}">#${p.id} - ${escapeHtml(p.name)}</option>`).join('');
    document.getElementById('banModal').style.display = 'flex';
}

function closeBanModal() {
    document.getElementById('banModal').style.display = 'none';
}

async function executeBan() {
    const sel = document.getElementById('banPlayerSelect');
    const id = parseInt(sel.value);
    const reason = document.getElementById('banReason').value.trim();
    const customDur = parseInt(document.getElementById('banCustomDuration').value);
    const dur = customDur > 0 ? customDur : banDuration;
    if (!id) { alert('Select a player.'); return; }
    if (!reason) { alert('Enter a reason.'); return; }
    const playerName = sel.options[sel.selectedIndex].text;
    if (!confirm(`Ban ${playerName}?\nReason: ${reason}\nDuration: ${formatDuration(dur)}`)) return;
    await fetchNui('godExecuteBan', { id, reason, duration: dur });
    closeBanModal();
    setTimeout(refreshBanList, 500);
}

async function unbanPlayer(banId) {
    if (!confirm('Unban this player?')) return;
    await fetchNui('godExecuteUnban', { banId });
    setTimeout(refreshBanList, 300);
}

// Load bans tab on click
document.querySelectorAll('.nav-item[data-tab="bans"]').forEach(el => {
    el.addEventListener('click', function() {
        refreshBanList();
    });
});

// Also add ban button from player table
function doBan(id) {
    showBanModal();
    setTimeout(() => {
        const sel = document.getElementById('banPlayerSelect');
        const opt = sel.querySelector(`option[value="${id}"]`);
        if (opt) sel.value = id;
    }, 100);
}

// ==================== INVENTORY VIEWER ====================
let invAllItems = [];
let invCurrentPlayerId = null;
let invSelectedItemIdx = null;

async function refreshInvPlayerList() {
    const players = await fetchNui('godGetPlayers', {});
    const sel = document.getElementById('invPlayerSelect');
    sel.innerHTML = '<option value="">-- Select player --</option>' +
        players.map(p => `<option value="${p.id}">#${p.id} - ${escapeHtml(p.name)} (${p.cid})</option>`).join('');
    if (players.length > 0 && !invCurrentPlayerId) {
        sel.value = players[0].id;
        loadPlayerInv(players[0].id);
    }
}

document.getElementById('invPlayerSelect')?.addEventListener('change', function() {
    if (this.value) loadPlayerInv(parseInt(this.value));
    else { document.getElementById('invGrid').innerHTML = ''; document.getElementById('invPlayerInfo').style.display = 'none'; }
});

document.getElementById('invSearch')?.addEventListener('input', function() {
    renderInvGrid(invAllItems, document.querySelector('.inv-cat.active')?.dataset.cat || 'all', this.value.toLowerCase());
});

// Category switching
document.querySelectorAll('.inv-cat').forEach(el => {
    el.addEventListener('click', function() {
        document.querySelectorAll('.inv-cat').forEach(c => c.classList.remove('active'));
        this.classList.add('active');
        renderInvGrid(invAllItems, this.dataset.cat, (document.getElementById('invSearch')?.value || '').toLowerCase());
    });
});

async function loadPlayerInv(playerId) {
    invCurrentPlayerId = playerId;
    document.getElementById('invSkeleton').style.display = 'block';
    document.getElementById('invGrid').innerHTML = '';
    const details = await fetchNui('godGetPlayerDetails', { id: playerId });
    document.getElementById('invSkeleton').style.display = 'none';
    if (!details || !details.inventory) {
        document.getElementById('invGrid').innerHTML = '<div class="inv-empty">Could not load inventory for this player.</div>';
        return;
    }
    document.getElementById('invPlayerInfo').style.display = 'block';
    document.getElementById('invPlayerName').textContent = GetPlayerName ? GetPlayerName(playerId) : 'Player ' + playerId;
    document.getElementById('invPlayerCid').textContent = details.citizenid || '';
    document.getElementById('invPlayerJob').textContent = details.job ? (details.job.label || details.job.name) : '?';
    document.getElementById('invPlayerGroup').textContent = details.group || 'user';
    document.getElementById('invPlayerCash').textContent = '$' + (details.money.cash || 0).toLocaleString();
    document.getElementById('invPlayerBank').textContent = '$' + (details.money.bank || 0).toLocaleString();
    document.getElementById('invItemCount').textContent = details.inventory.length;
    invAllItems = details.inventory || [];
    renderInvGrid(invAllItems, 'all', '');
}

function renderInvGrid(items, category, search) {
    const grid = document.getElementById('invGrid');
    let filtered = items;
    if (category && category !== 'all') filtered = filtered.filter(i => i.category === category);
    if (search) filtered = filtered.filter(i => i.label.toLowerCase().includes(search) || i.name.toLowerCase().includes(search));
    if (filtered.length === 0) {
        grid.innerHTML = '<div class="inv-empty">No items found' + (search ? ' matching "' + escapeHtml(search) + '"' : '') + '.</div>';
        return;
    }
    grid.innerHTML = filtered.map((item, idx) => {
        const idxOrig = invAllItems.indexOf(item);
        const isWeapon = item.category === 'weapons';
        const isAttachment = item.category === 'attachments';
        const isAmmo = item.category === 'ammo';
        const isClothing = item.category === 'clothing';
        let cardClass = 'inv-card';
        if (isWeapon) cardClass += ' inv-card-weapon';
        else if (isAttachment) cardClass += ' inv-card-attachment';
        else if (isAmmo) cardClass += ' inv-card-ammo';
        else if (isClothing) cardClass += ' inv-card-clothing';
        let icon = '📦';
        if (isWeapon) icon = '🔫';
        else if (isAttachment) icon = '🔧';
        else if (isAmmo) icon = '🔴';
        else if (isClothing) icon = '👕';
        const durabilityHtml = item.durability != null
            ? `<div class="inv-card-durability"><div class="fill ${item.durability > 0.6 ? 'good' : item.durability > 0.3 ? 'ok' : 'bad'}" style="width:${Math.round(item.durability * 100)}%"></div></div>`
            : '';
        const compsHtml = item.components && item.components.length > 0
            ? '<div class="inv-card-comp-chips">' + item.components.map(c => '<span class="inv-card-comp-chip">' + escapeHtml(c.label) + '</span>').join('') + '</div>'
            : '';
        const serialHtml = item.serial
            ? '<div class="inv-card-serial">#' + escapeHtml(item.serial) + '</div>'
            : '';
        return `<div class="${cardClass}" onclick="showInvItemDetail(${idxOrig})">
            <div class="inv-card-slot">#${item.slot || '?'}</div>
            <div class="inv-card-icon">${icon}</div>
            <div class="inv-card-name" title="${escapeHtml(item.label)}">${escapeHtml(item.label)}</div>
            <div class="inv-card-count">x${item.count}</div>
            ${durabilityHtml}${compsHtml}${serialHtml}
        </div>`;
    }).join('');
}

function showInvItemDetail(idx) {
    const item = invAllItems[idx];
    if (!item) return;
    invSelectedItemIdx = idx;
    document.getElementById('invItemModalTitle').textContent = escapeHtml(item.label);
    const icon = item.category === 'weapons' ? '🔫' : item.category === 'attachments' ? '🔧' : item.category === 'ammo' ? '🔴' : '📦';
    let html = `<div class="inv-detail-section"><h4>${escapeHtml(item.name)}</h4>`;
    html += `<div class="inv-detail-row"><span class="label">Slot</span><span class="value">#${item.slot || '?'}</span></div>`;
    html += `<div class="inv-detail-row"><span class="label">Count</span><span class="value">x${item.count}</span></div>`;
    html += `<div class="inv-detail-row"><span class="label">Category</span><span class="value">${item.category}</span></div>`;
    if (item.weight) html += `<div class="inv-detail-row"><span class="label">Weight</span><span class="value">${item.weight}g</span></div>`;
    if (item.durability != null) {
        const pct = Math.round(item.durability * 100);
        html += `<div class="inv-detail-row"><span class="label">Condition</span><span class="value">${pct}%</span></div>`;
    }
    if (item.ammo != null) html += `<div class="inv-detail-row"><span class="label">Ammo</span><span class="value">${item.ammo}</span></div>`;
    if (item.ammotype) html += `<div class="inv-detail-row"><span class="label">Ammo Type</span><span class="value">${escapeHtml(item.ammotype)}</span></div>`;
    if (item.serial) html += `<div class="inv-detail-row"><span class="label">Serial</span><span class="value" style="font-family:monospace">${escapeHtml(item.serial)}</span></div>`;
    html += '</div>';
    if (item.components && item.components.length > 0) {
        html += '<div class="inv-detail-section"><h4>Components</h4>';
        html += '<div class="inv-detail-comps">' + item.components.map(c => '<span class="inv-detail-comp">' + escapeHtml(c.label) + '</span>').join('') + '</div>';
        html += '</div>';
    }
    if (item.description) {
        html += '<div class="inv-detail-section"><h4>Description</h4>';
        html += '<div class="inv-detail-desc">' + escapeHtml(item.description) + '</div></div>';
    }
    document.getElementById('invItemModalBody').innerHTML = html;
    document.getElementById('invItemRemoveBtn').style.display = 'inline-block';
    document.getElementById('invItemModal').style.display = 'flex';
}

function closeInvItemModal() {
    document.getElementById('invItemModal').style.display = 'none';
    invSelectedItemIdx = null;
}

async function removeInvItem() {
    if (invSelectedItemIdx == null || invCurrentPlayerId == null) return;
    const item = invAllItems[invSelectedItemIdx];
    if (!item) return;
    if (!confirm('Remove x' + item.count + ' ' + item.label + ' from player?')) return;
    await fetchNui('godRemoveItem', { id: invCurrentPlayerId, item: item.name, count: item.count });
    closeInvItemModal();
    setTimeout(() => loadPlayerInv(invCurrentPlayerId), 300);
}

// Load inventory tab on click
document.querySelectorAll('.nav-item[data-tab="inventory"]').forEach(el => {
    el.addEventListener('click', function() {
        refreshInvPlayerList();
    });
});

// Load doors when nav-item is clicked
document.querySelectorAll('.nav-item[data-tab="doors"]').forEach(el => {
    el.addEventListener('click', function() {
        loadJobList().then(() => {
            renderJobCheckboxes();
            refreshDoors();
        });
    });
});

// Load doors on NUI open message
window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'switchTab' && data.tab === 'doors') {
        loadJobList().then(() => {
            renderJobCheckboxes();
            refreshDoors();
        });
    }
});

// ==================== ZONE MANAGEMENT ====================
let zonesData = [];
let editingZoneId = null;
let editingZoneItemsZoneId = null;
const zoneTypeLabels = {
    armory: 'Armory', shop: 'Shop', storage: 'Storage',
    wardrobe: 'Wardrobe', duty: 'Duty', garage: 'Garage'
};

function renderZoneCheckboxes() {
    const container = document.getElementById('zoneJobCheckboxes');
    container.innerHTML = '';
    jobList.forEach(j => {
        const label = document.createElement('label');
        const cb = document.createElement('input');
        cb.type = 'checkbox';
        cb.value = j.name;
        cb.className = 'job-check-item';
        label.appendChild(cb);
        label.appendChild(document.createTextNode(j.label + ' (' + j.name + ')'));
        container.appendChild(label);
    });
}

function renderZones() {
    const container = document.getElementById('zoneList');
    const skeleton = document.getElementById('zoneSkeleton');
    skeleton.style.display = 'none';
    if (!zonesData || zonesData.length === 0) {
        container.innerHTML = '<div class="glass-card"><p style="text-align:center;color:var(--text-muted,rgba(255,255,255,0.4))">No zones yet. Create one to get started.</p></div>';
        return;
    }
    container.innerHTML = zonesData.map(z => {
        const typeLabel = zoneTypeLabels[z.zone_type] || z.zone_type;
        const jobsStr = z.allowed_jobs && z.allowed_jobs.length > 0 ? z.allowed_jobs.join(', ') : 'Everyone';
        const activeBadge = z.is_active ? 'door-badge-unlocked' : 'door-badge-locked';
        const activeLabel = z.is_active ? 'Active' : 'Inactive';
        const dutyStr = z.require_duty ? 'Duty required' : 'No duty req.';
        return `<div class="door-card">
            <div class="door-card-header">
                <span class="door-card-title">${escapeHtml(z.name)}</span>
                <span><span class="door-badge door-badge-job">${typeLabel}</span> <span class="door-badge ${activeBadge}">${activeLabel}</span></span>
            </div>
            <div class="door-card-meta">
                <span>Coords: ${Math.round(z.coords.x)}, ${Math.round(z.coords.y)}, ${Math.round(z.coords.z)}</span>
                <span>Jobs: ${escapeHtml(jobsStr)}</span>
                <span>Grade: ${z.min_grade} | ${dutyStr}</span>
            </div>
            <div class="door-card-actions">
                <button class="btn btn-sm" onclick="toggleZoneActive(${z.id}, ${z.is_active ? 0 : 1})">${z.is_active ? 'Deactivate' : 'Activate'}</button>
                <button class="btn btn-sm" onclick="editZone(${z.id})">✏️ Edit</button>
                <button class="btn btn-sm" onclick="manageZoneItems(${z.id}, '${escapeHtml(z.name)}')">📦 Items</button>
                <button class="btn btn-sm btn-danger" onclick="deleteZone(${z.id})">🗑️ Delete</button>
            </div>
        </div>`;
    }).join('');
}

async function refreshZones() {
    document.getElementById('zoneSkeleton').style.display = 'block';
    zonesData = await fetchNui('godGetAllZones', {}) || [];
    zonesData.forEach(z => {
        if (typeof z.coords === 'string') z.coords = JSON.parse(z.coords);
        if (typeof z.allowed_jobs === 'string') z.allowed_jobs = JSON.parse(z.allowed_jobs);
    });
    renderZones();
}

async function detectCurrentPosition() {
    const result = await fetchNui('godGetCurrentPosition', {});
    document.getElementById('zoneX').value = result.x.toFixed(2);
    document.getElementById('zoneY').value = result.y.toFixed(2);
    document.getElementById('zoneZ').value = result.z.toFixed(2);
    showZoneSetup(null);
}

function showZoneSetup(existingZone) {
    editingZoneId = existingZone ? existingZone.id : null;
    document.getElementById('zoneModalTitle').textContent = existingZone ? 'Edit Zone' : 'Create Zone';
    document.getElementById('zoneName').value = existingZone ? existingZone.name : '';
    document.getElementById('zoneType').value = existingZone ? existingZone.zone_type : 'armory';
    document.getElementById('zoneX').value = existingZone ? existingZone.coords.x.toFixed(2) : '';
    document.getElementById('zoneY').value = existingZone ? existingZone.coords.y.toFixed(2) : '';
    document.getElementById('zoneZ').value = existingZone ? existingZone.coords.z.toFixed(2) : '';
    document.getElementById('zoneRadius').value = existingZone ? existingZone.radius : 2.0;
    document.getElementById('zoneMinGrade').value = existingZone ? existingZone.min_grade : 0;
    document.getElementById('zoneRequireDuty').checked = existingZone ? existingZone.require_duty == 1 : false;
    document.getElementById('zoneIsActive').checked = existingZone ? existingZone.is_active == 1 : true;
    // Restore job checkboxes
    setTimeout(() => {
        document.querySelectorAll('#zoneJobCheckboxes .job-check-item').forEach(cb => {
            cb.checked = existingZone && existingZone.allowed_jobs && existingZone.allowed_jobs.includes(cb.value);
        });
    }, 100);
    document.getElementById('zoneModal').style.display = 'flex';
}

function closeZoneModal() {
    document.getElementById('zoneModal').style.display = 'none';
    editingZoneId = null;
}

async function saveZone() {
    const name = document.getElementById('zoneName').value.trim();
    const zoneType = document.getElementById('zoneType').value;
    const x = parseFloat(document.getElementById('zoneX').value);
    const y = parseFloat(document.getElementById('zoneY').value);
    const z = parseFloat(document.getElementById('zoneZ').value);
    const radius = parseFloat(document.getElementById('zoneRadius').value) || 2.0;
    const minGrade = parseInt(document.getElementById('zoneMinGrade').value) || 0;
    const requireDuty = document.getElementById('zoneRequireDuty').checked ? 1 : 0;
    const isActive = document.getElementById('zoneIsActive').checked ? 1 : 0;
    const allowedJobs = [];
    document.querySelectorAll('#zoneJobCheckboxes .job-check-item:checked').forEach(cb => allowedJobs.push(cb.value));
    if (!name || isNaN(x) || isNaN(y) || isNaN(z)) {
        alert('Please fill in name and valid coordinates.');
        return;
    }
    const data = { name, zoneType, coords: { x, y, z }, radius, allowedJobs, minGrade, requireDuty, isActive };
    if (editingZoneId) {
        data.zoneId = editingZoneId;
        await fetchNui('godUpdateZone', data);
    } else {
        await fetchNui('godCreateZone', data);
    }
    closeZoneModal();
    setTimeout(refreshZones, 500);
}

async function editZone(id) {
    const zone = zonesData.find(z => z.id === id);
    if (!zone) return;
    showZoneSetup(zone);
}

async function deleteZone(id) {
    if (!confirm('Delete this zone permanently?')) return;
    await fetchNui('godDeleteZone', { zoneId: id });
    setTimeout(refreshZones, 300);
}

async function toggleZoneActive(id, active) {
    await fetchNui('godToggleZone', { zoneId: id, active: active == 1 });
    setTimeout(refreshZones, 300);
}

// ---- Zone Items Management ----
let zoneItemsData = [];

async function manageZoneItems(zoneId, zoneName) {
    editingZoneItemsZoneId = zoneId;
    document.getElementById('zoneItemsModalTitle').textContent = 'Items for: ' + zoneName;
    document.getElementById('zoneNewItemName').value = '';
    document.getElementById('zoneNewItemLabel').value = '';
    document.getElementById('zoneNewItemPrice').value = '0';
    document.getElementById('zoneNewItemMinRank').value = '0';
    document.getElementById('zoneNewItemCurrency').value = 'money';
    document.getElementById('zoneNewItemCategory').value = 'general';
    await refreshZoneItems();
    document.getElementById('zoneItemsModal').style.display = 'flex';
}

function closeZoneItemsModal() {
    document.getElementById('zoneItemsModal').style.display = 'none';
    editingZoneItemsZoneId = null;
}

async function refreshZoneItems() {
    if (!editingZoneItemsZoneId) return;
    zoneItemsData = await fetchNui('godGetZoneItems', { zoneId: editingZoneItemsZoneId }) || [];
    renderZoneItems();
}

function renderZoneItems() {
    const container = document.getElementById('zoneItemsList');
    if (!zoneItemsData || zoneItemsData.length === 0) {
        container.innerHTML = '<div class="glass-card"><p style="text-align:center;color:var(--text-muted,rgba(255,255,255,0.4))">No items yet. Add one above.</p></div>';
        return;
    }
    container.innerHTML = zoneItemsData.map(item => {
        const priceStr = item.price === 0 ? 'FREE' : '$' + item.price;
        const currencyStr = item.currency === 'black_money' ? ' (BM)' : '';
        return `<div class="door-card" style="margin-bottom:6px">
            <div class="door-card-header">
                <span class="door-card-title">${escapeHtml(item.label)}</span>
                <span class="door-badge door-badge-passcode">${escapeHtml(item.item_name)}</span>
            </div>
            <div class="door-card-meta">
                <span>Price: ${priceStr}${currencyStr}</span>
                <span>Min Rank: ${item.min_rank}</span>
                <span>Category: ${escapeHtml(item.category)}</span>
            </div>
            <div class="door-card-actions">
                <button class="btn btn-sm btn-danger" onclick="removeZoneItem(${item.id})">🗑️ Remove</button>
            </div>
        </div>`;
    }).join('');
}

async function addZoneItem() {
    if (!editingZoneItemsZoneId) return;
    const itemName = document.getElementById('zoneNewItemName').value.trim();
    const label = document.getElementById('zoneNewItemLabel').value.trim();
    const price = parseInt(document.getElementById('zoneNewItemPrice').value) || 0;
    const minRank = parseInt(document.getElementById('zoneNewItemMinRank').value) || 0;
    const currency = document.getElementById('zoneNewItemCurrency').value;
    const category = document.getElementById('zoneNewItemCategory').value;
    if (!itemName || !label) {
        alert('Enter item name and label.');
        return;
    }
    await fetchNui('godAddZoneItem', { zoneId: editingZoneItemsZoneId, itemName, label, price, minRank, currency, category });
    document.getElementById('zoneNewItemName').value = '';
    document.getElementById('zoneNewItemLabel').value = '';
    setTimeout(refreshZoneItems, 300);
}

async function removeZoneItem(itemId) {
    if (!confirm('Remove this item from the zone?')) return;
    await fetchNui('godRemoveZoneItem', { itemId });
    setTimeout(refreshZoneItems, 300);
}

// Load zones when nav-item is clicked
document.querySelectorAll('.nav-item[data-tab="zones"]').forEach(el => {
    el.addEventListener('click', function() {
        loadJobList().then(() => {
            renderZoneCheckboxes();
            refreshZones();
        });
    });
});

// Load zones on NUI open message
window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'switchTab' && data.tab === 'zones') {
        loadJobList().then(() => {
            renderZoneCheckboxes();
            refreshZones();
        });
    }
});

// ==================== GARAGE VIEWER ====================
let garageData = [];
let garagePlayerCid = '';

function loadGarageByCid() {
    const cid = document.getElementById('garageCitizenId').value.trim();
    if (!cid) { alert('Enter a CitizenID'); return; }
    loadPlayerGarage(cid);
}

async function loadPlayerGarage(citizenid) {
    garagePlayerCid = citizenid;
    document.getElementById('garageSkeleton').style.display = 'block';
    document.getElementById('garageList').innerHTML = '';
    garageData = await fetchNui('godGetPlayerGarage', { citizenid }) || [];
    document.getElementById('garageSkeleton').style.display = 'none';
    document.getElementById('garagePlayerInfo').style.display = 'block';
    document.getElementById('garagePlayerLabel').textContent = 'Vehicles for: ' + citizenid;
    document.getElementById('garageVehicleCount').textContent = garageData.length;
    const stored = garageData.filter(v => v.status === 'stored').length;
    const out = garageData.filter(v => v.status === 'out').length;
    const impounded = garageData.filter(v => v.status === 'impounded').length;
    document.getElementById('garageStoredCount').textContent = stored;
    document.getElementById('garageOutCount').textContent = out;
    document.getElementById('garageImpoundedCount').textContent = impounded;
    renderGarageGrid();
}

function renderGarageGrid() {
    const grid = document.getElementById('garageList');
    if (!garageData || garageData.length === 0) {
        grid.innerHTML = '<div class="garage-empty">No vehicles found for this player.</div>';
        return;
    }
    grid.innerHTML = garageData.map(v => {
        const statusClass = v.status === 'stored' ? 'stored' : v.status === 'out' ? 'out' : 'impounded';
        const statusLabel = v.status === 'stored' ? 'Stored' : v.status === 'out' ? 'Out' : 'Impounded';
        const metaParts = [];
        metaParts.push('Fuel: ' + (v.fuel || '?') + '%');
        if (v.status === 'impounded' && v.impound_reason) metaParts.push('Reason: ' + escapeHtml(v.impound_reason));
        const spawnBtn = v.status === 'stored'
            ? `<button class="btn btn-sm btn-primary" onclick="garageSpawn('${escapeHtml(v.plate)}', '${escapeHtml(v.citizenid)}')">Spawn</button>`
            : '';
        const impoundBtn = v.status !== 'impounded'
            ? `<button class="btn btn-sm btn-warning" onclick="garageImpound('${escapeHtml(v.plate)}', '${escapeHtml(v.citizenid)}')">Impound</button>`
            : `<button class="btn btn-sm btn-success" onclick="garageRelease('${escapeHtml(v.plate)}')">Release</button>`;
        return `<div class="garage-card">
            <div class="garage-card-header">
                <div>
                    <div class="garage-card-model">${escapeHtml(v.model)}</div>
                    <div class="garage-card-plate">${escapeHtml(v.plate)}</div>
                </div>
                <span class="garage-card-status ${statusClass}">${statusLabel}</span>
            </div>
            <div class="garage-card-meta">${metaParts.join(' | ')}</div>
            <div class="garage-card-actions">
                ${spawnBtn}
                <button class="btn btn-sm btn-danger" onclick="garageDelete('${escapeHtml(v.plate)}')">Delete</button>
                ${impoundBtn}
            </div>
        </div>`;
    }).join('');
}

async function garageSpawn(plate, citizenid) {
    await fetchNui('godAdminSpawnPlayerVehicle', { citizenid, plate });
    setTimeout(() => loadPlayerGarage(garagePlayerCid), 500);
}

async function garageDelete(plate) {
    if (!confirm('Delete vehicle ' + plate + ' from database?')) return;
    await fetchNui('godAdminDeletePlayerVehicle', { plate });
    setTimeout(() => loadPlayerGarage(garagePlayerCid), 300);
}

async function garageImpound(plate, citizenid) {
    const reason = prompt('Impound reason:');
    if (!reason) return;
    await fetchNui('godAdminImpoundVehicle', { citizenid, plate, reason });
    setTimeout(() => loadPlayerGarage(garagePlayerCid), 300);
}

async function garageRelease(plate) {
    if (!confirm('Release ' + plate + ' from impound?')) return;
    await fetchNui('godAdminReleaseImpound', { plate });
    setTimeout(() => loadPlayerGarage(garagePlayerCid), 300);
}

// Load garage tab on click
document.querySelectorAll('.nav-item[data-tab="garage"]').forEach(el => {
    el.addEventListener('click', function() {
        document.getElementById('garageCitizenId').value = '';
        document.getElementById('garagePlayerInfo').style.display = 'none';
        document.getElementById('garageList').innerHTML = '<div class="garage-empty">Enter a CitizenID above to view vehicles.</div>';
    });
});

// Enter key on garage search
document.getElementById('garageCitizenId')?.addEventListener('keydown', function(e) {
    if (e.key === 'Enter') loadGarageByCid();
});

// ==================== STAFF MANAGEMENT ====================
let staffData = [];

async function refreshStaffList() {
    document.getElementById('staffSkeleton').style.display = 'block';
    staffData = await fetchNui('godGetOnlineStaff', {}) || [];
    document.getElementById('staffSkeleton').style.display = 'none';
    document.getElementById('staffOnlineCount').textContent = staffData.length + ' online';
    renderStaffGrid();
}

function renderStaffGrid() {
    const grid = document.getElementById('staffGrid');
    if (!staffData || staffData.length === 0) {
        grid.innerHTML = '<div class="garage-empty">No staff online.</div>';
        return;
    }
    const myGroup = staffData.find(s => s.id === parseInt(GetPlayerId ? GetPlayerId() : -1))?.group || 'user';
    const myRank = { user: 0, admin: 1, superadmin: 2, god: 3 }[myGroup] || 0;
    grid.innerHTML = staffData.map(s => {
        const badgeClass = 'staff-group-' + s.group;
        const badgeLabel = s.group.charAt(0).toUpperCase() + s.group.slice(1);
        const canManage = myRank > ({ user: 0, admin: 1, superadmin: 2, god: 3 }[s.group] || 0) || myGroup === 'god';
        const promoteOpts = ['admin', 'superadmin', 'god']
            .filter(g => {
                const gRank = { admin: 1, superadmin: 2, god: 3 }[g] || 0;
                if (myGroup !== 'god' && gRank >= myRank) return false;
                return g !== s.group;
            })
            .map(g => `<button class="btn btn-sm btn-primary" onclick="staffSetGroup(${s.id}, '${g}')" ${!canManage ? 'disabled' : ''}>${g}</button>`)
            .join('');
        return `<div class="staff-card">
            <div class="staff-card-header">
                <div class="staff-avatar">&#128100;</div>
                <div>
                    <div class="staff-name">${escapeHtml(s.name)}</div>
                    <div class="staff-cid">${escapeHtml(s.citizenid)}</div>
                </div>
                <span class="staff-group-badge ${badgeClass}" style="margin-left:auto">${badgeLabel}</span>
            </div>
            <div class="staff-card-meta">
                <span>ID: ${s.id}</span>
                <span>Online: ${s.connected}</span>
            </div>
            <div class="staff-card-actions">
                ${canManage ? promoteOpts : '<span style="font-size:11px;color:rgba(255,255,255,0.3)">Cannot manage</span>'}
                <button class="btn btn-sm btn-ghost" onclick="viewStaffLog('${escapeHtml(s.citizenid)}', '${escapeHtml(s.name)}')">Log</button>
            </div>
        </div>`;
    }).join('');
}

async function staffSetGroup(id, group) {
    if (!confirm('Change this staff member to ' + group + '?')) return;
    await fetchNui('godSetStaffGroup', { id, group });
    setTimeout(refreshStaffList, 300);
}

async function viewStaffLog(citizenid, name) {
    const logs = await fetchNui('godGetStaffActionLog', { citizenid, limit: 50 }) || [];
    document.getElementById('staffLogTitle').textContent = 'Action Log - ' + name;
    let html = '';
    if (logs.length === 0) {
        html = '<div class="staff-log-empty">No actions logged.</div>';
    } else {
        html = '<table class="staff-log-table"><thead><tr><th>Action</th><th>Target</th><th>Date</th></tr></thead><tbody>';
        logs.forEach(l => {
            html += `<tr><td>${escapeHtml(l.action)}</td><td>${escapeHtml(l.target || '')}</td><td style="font-size:10px">${l.created_at || ''}</td></tr>`;
        });
        html += '</tbody></table>';
    }
    document.getElementById('staffLogBody').innerHTML = html;
    document.getElementById('staffLogModal').style.display = 'flex';
}

function closeStaffLogModal() {
    document.getElementById('staffLogModal').style.display = 'none';
}

// Load staff tab on click
document.querySelectorAll('.nav-item[data-tab="staff"]').forEach(el => {
    el.addEventListener('click', function() {
        refreshStaffList();
    });
});

// Load staff on NUI open
window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'switchTab' && data.tab === 'staff') {
        refreshStaffList();
    }
});

// ==================== REPORT QUEUE ====================
let reportsData = [];
let reportBadgeInterval = null;

function renderReports() {
    const container = document.getElementById('reportList');
    const skeleton = document.getElementById('reportSkeleton');
    skeleton.style.display = 'none';
    const openCount = reportsData.filter(r => r.status === 'open').length;
    const handlingCount = reportsData.filter(r => r.status === 'handling').length;
    document.getElementById('reportOpenCount').textContent = openCount;
    document.getElementById('reportHandlingCount').textContent = handlingCount;
    const badge = document.getElementById('reportBadge');
    if (openCount > 0) {
        badge.textContent = openCount;
        badge.style.display = 'inline-block';
    } else {
        badge.style.display = 'none';
    }
    if (reportsData.length === 0) {
        container.innerHTML = '<div class="report-empty">No open reports.</div>';
        return;
    }
    container.innerHTML = reportsData.map(r => {
        const statusClass = r.status === 'open' ? 'open' : 'handling';
        const statusLabel = r.status === 'open' ? 'Open' : 'Handling';
        const handlerInfo = r.handlerName ? ' | Staff: ' + escapeHtml(r.handlerName) : '';
        const acceptBtn = r.status === 'open'
            ? `<button class="btn btn-sm btn-primary" onclick="acceptReport(${r.id})">Accept</button>`
            : '';
        return `<div class="report-card ${statusClass}">
            <div class="report-card-header">
                <span class="report-card-id">#${r.id}</span>
                <span class="report-card-status ${statusClass}">${statusLabel}</span>
            </div>
            <div class="report-card-player">${escapeHtml(r.playerName)}</div>
            <div class="report-card-reason">${escapeHtml(r.reason)}</div>
            <div class="report-card-meta">CID: ${escapeHtml(r.citizenid)}${handlerInfo}</div>
            <div class="report-card-actions">
                ${acceptBtn}
                <button class="btn btn-sm btn-success" onclick="closeReport(${r.id})">Close</button>
            </div>
        </div>`;
    }).join('');
}

async function refreshReports() {
    document.getElementById('reportSkeleton').style.display = 'block';
    reportsData = await fetchNui('godGetReports', {}) || [];
    renderReports();
}

async function acceptReport(id) {
    await fetchNui('godAcceptReport', { reportId: id });
    setTimeout(refreshReports, 200);
}

async function closeReport(id) {
    const resolution = prompt('Resolution for report #' + id + ':');
    if (!resolution) return;
    await fetchNui('godCloseReport', { reportId: id, resolution });
    setTimeout(refreshReports, 200);
}

// Live push handlers
window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'newReport') {
        const exists = reportsData.find(r => r.id === data.report.id);
        if (!exists) reportsData.push(data.report);
        renderReports();
    } else if (data.action === 'updateReport') {
        const idx = reportsData.findIndex(r => r.id === data.report.id);
        if (idx >= 0) reportsData[idx] = data.report;
        renderReports();
    } else if (data.action === 'removeReport') {
        reportsData = reportsData.filter(r => r.id !== data.reportId);
        renderReports();
    } else if (data.action === 'switchTab' && data.tab === 'reports') {
        refreshReports();
    }
});

// Load reports tab on click
document.querySelectorAll('.nav-item[data-tab="reports"]').forEach(el => {
    el.addEventListener('click', function() {
        refreshReports();
    });
});
