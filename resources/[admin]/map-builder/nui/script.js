let currentMode = 'simple';
let activeTab = 'catalog';
let selectedPropModel = null;
let propDatabase = [];

// Simple/Advanced Modes Toggle
function setMode(mode) {
    currentMode = mode;
    document.querySelectorAll('.mode-btn').forEach(btn => btn.classList.remove('active'));
    document.getElementById('btn-' + mode).classList.add('active');

    // In Simple Mode, disable advanced tabs/controls
    if (mode === 'simple') {
        document.getElementById('toggle-align').classList.add('active');
        document.getElementById('toggle-freeze').classList.add('active');
    }

    postNUI('setBuilderMode', { mode: mode });
}

// Sidebar Tab Switcher
function switchTab(tabId) {
    activeTab = tabId;
    document.querySelectorAll('.nav-tab').forEach(tab => btnActive(tab, tab.getAttribute('data-tab') === tabId));
    document.querySelectorAll('.tab-content').forEach(content => btnActive(content, content.id === 'tab-' + tabId));
}

function btnActive(el, active) {
    if (active) el.classList.add('active');
    else el.classList.remove('active');
}

// Fetch props database on window load
window.addEventListener('load', () => {
    fetch('prop_db.json')
        .then(response => response.json())
        .then(data => {
            propDatabase = data;
            renderProps(data);
        });
});

// Render cards dynamically
function renderProps(props) {
    const list = document.getElementById('prop-list');
    list.innerHTML = '';

    props.forEach(p => {
        const card = document.createElement('div');
        card.className = 'prop-card';
        if (selectedPropModel === p.model) card.classList.add('selected');
        card.onclick = () => selectProp(p.model, card);

        card.innerHTML = `
            <div class="prop-icon"><i class="fa-solid fa-cube"></i></div>
            <div class="prop-name">${p.name}</div>
            <div class="prop-model">${p.model}</div>
        `;
        list.appendChild(card);
    });
}

function selectProp(model, cardEl) {
    selectedPropModel = model;
    document.querySelectorAll('.prop-card').forEach(card => card.classList.remove('selected'));
    cardEl.classList.add('selected');

    postNUI('selectCatalogProp', { model: model });
}

// Filters & Search logic
function filterCategory(category) {
    document.querySelectorAll('.cat-filter').forEach(btn => btnActive(btn, false));
    event.target.classList.add('active');

    if (category === 'all') {
        renderProps(propDatabase);
    } else {
        const filtered = propDatabase.filter(p => p.category === category);
        renderProps(filtered);
    }
}

// Search catalog props
function searchProps() {
    const query = document.getElementById('prop-search').value.toLowerCase();
    const filtered = propDatabase.filter(p => p.name.toLowerCase().includes(query) || p.model.toLowerCase().includes(query));
    renderProps(filtered);
}

function triggerEyedropper() {
    postNUI('eyedropperSelect', {});
}

// Dynamic lighting inputs updater
function updateLightType() {
    const lType = document.getElementById('light-type').value;
    postNUI('updateLightSettings', { type: lType });
}

function updateLightColor() {
    const color = document.getElementById('light-color').value;
    postNUI('updateLightSettings', { color: color });
}

function updateLightIntensity(val) {
    document.getElementById('val-intensity').innerText = val;
    postNUI('updateLightSettings', { intensity: parseFloat(val) });
}

function updateLightRange(val) {
    document.getElementById('val-range').innerText = val + 'm';
    postNUI('updateLightSettings', { range: parseFloat(val) });
}

function updateLightFlicker() {
    const flicker = document.getElementById('light-flicker').checked;
    postNUI('updateLightSettings', { flicker: flicker });
}

function commitLight() {
    postNUI('commitLight', {});
}

// Script Logic Bindings UI builder
function updateLogicFields() {
    const lType = document.getElementById('logic-type').value;
    const container = document.getElementById('dynamic-logic-fields');
    container.innerHTML = '';

    if (lType === 'none') return;

    if (lType === 'trash') {
        container.innerHTML = `
            <div class="control-group">
                <label>Loot Table ID / Preset</label>
                <select id="field-trash-preset">
                    <option value="default">Default City Trash Preset</option>
                    <option value="industrial">Rare Industrial Junk</option>
                </select>
            </div>
        `;
    } else if (lType === 'garage') {
        container.innerHTML = `
            <div class="control-group">
                <label>Spawn Coordinates (JSON format)</label>
                <input type="text" id="field-garage-spawn" value='{"x": 120.0, "y": -750.0, "z": 45.0, "h": 90.0}'>
            </div>
            <div class="control-group">
                <label>Allowed Vehicles (comma separated)</label>
                <input type="text" id="field-garage-allowed" placeholder="e.g. adder, zentorno, t20">
            </div>
            <div class="control-group">
                <label>Blacklisted / Hidden Vehicles (comma separated)</label>
                <input type="text" id="field-garage-blacklisted" placeholder="e.g. sultan, carbonizzare">
            </div>
        `;
    } else if (lType === 'stash') {
        container.innerHTML = `
            <div class="control-group">
                <label>Slots count</label>
                <input type="number" id="field-stash-slots" value="50">
            </div>
            <div class="control-group">
                <label>Weight limit (grams)</label>
                <input type="number" id="field-stash-weight" value="100000">
            </div>
        `;
    } else if (lType === 'door') {
        container.innerHTML = `
            <div class="control-group">
                <label>Require keycard to open?</label>
                <input type="checkbox" id="field-door-keycard">
            </div>
            <div class="control-group">
                <label>Keycard Item Name</label>
                <input type="text" id="field-door-item" value="keycard_level_1">
            </div>
            <div class="control-group">
                <label>Lockpickable?</label>
                <input type="checkbox" id="field-door-pick" checked>
            </div>
        `;
    } else if (lType === 'custom') {
        container.innerHTML = `
            <div class="control-group">
                <label>Teleport Coordinates (JSON format)</label>
                <input type="text" id="field-custom-tele" placeholder='{"x": 110.0, "y": -740.0, "z": 42.0}'>
            </div>
            <div class="control-group">
                <label>Event Name Trigger</label>
                <input type="text" id="field-custom-event" placeholder="e.g. police:client:OpenVault">
            </div>
            <div class="control-group">
                <label>Is Server Event?</label>
                <input type="checkbox" id="field-custom-is-server">
            </div>
        `;
    }
}

let activeLogicConfiguration = null;

function commitLogicBinding() {
    const lType = document.getElementById('logic-type').value;
    if (lType === 'none') {
        activeLogicConfiguration = null;
        postNUI('notify', { text: 'Removed logic bindings from placement' });
        return;
    }

    let config = { type: lType, data: {} };
    if (lType === 'trash') {
        config.data.preset = document.getElementById('field-trash-preset').value;
    } else if (lType === 'garage') {
        config.data.spawnPoint = JSON.parse(document.getElementById('field-garage-spawn').value);

        const allowedStr = document.getElementById('field-garage-allowed').value;
        config.data.allowedVehicles = allowedStr ? allowedStr.split(',').map(s => s.trim()) : null;

        const blacklistedStr = document.getElementById('field-garage-blacklisted').value;
        config.data.blacklistedVehicles = blacklistedStr ? blacklistedStr.split(',').map(s => s.trim()) : null;
    } else if (lType === 'stash') {
        config.data.slots = parseInt(document.getElementById('field-stash-slots').value);
        config.data.weight = parseInt(document.getElementById('field-stash-weight').value);
    } else if (lType === 'door') {
        config.data.requireKeycard = document.getElementById('field-door-keycard').checked;
        config.data.keycardItem = document.getElementById('field-door-item').value;
        config.data.lockpickable = document.getElementById('field-door-pick').checked;
    } else if (lType === 'custom') {
        const teleVal = document.getElementById('field-custom-tele').value;
        config.data.teleportCoords = teleVal ? JSON.parse(teleVal) : null;
        config.data.triggerEvent = document.getElementById('field-custom-event').value;
        config.data.isServerEvent = document.getElementById('field-custom-is-server').checked;
    }

    activeLogicConfiguration = config;
    postNUI('notify', { text: 'Script Logic Configured! Ready to place.' });
}

// Placements & toggles
function placeSelectedProp() {
    postNUI('placeProp', { logic: activeLogicConfiguration });
}

let collisionState = true;
let normalAlignState = true;
let freezeState = true;

function toggleCollision() {
    collisionState = !collisionState;
    btnActive(document.getElementById('toggle-collision'), collisionState);
    postNUI('toggleCollision', { state: collisionState });
}

function toggleAlign() {
    normalAlignState = !normalAlignState;
    btnActive(document.getElementById('toggle-align'), normalAlignState);
    postNUI('toggleAlign', { state: normalAlignState });
}

function toggleFreeze() {
    freezeState = !freezeState;
    btnActive(document.getElementById('toggle-freeze'), freezeState);
    postNUI('toggleFreeze', { state: freezeState });
}

function setGridSnap(val) {
    postNUI('setGridSnap', { value: parseFloat(val) });
}

// Prefab saving
function saveAsPrefab() {
    const name = document.getElementById('prefab-name').value;
    if (!name) return;
    postNUI('savePrefab', { name: name });
}

function exportMap(format) {
    postNUI('exportMap', { format: format });
}

// Message Listener from Lua Client
window.addEventListener('message', (event) => {
    const data = event.data;
    if (data.action === 'openBuilder') {
        document.getElementById('builder-container').classList.remove('hidden');
    } else if (data.action === 'closeBuilder') {
        document.getElementById('builder-container').classList.add('hidden');
    } else if (data.action === 'updateMeasure') {
        document.getElementById('measure-val').innerText = data.distance.toFixed(2) + 'm';
    }
});

// Post messaging helper
function postNUI(endpoint, payload) {
    fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(payload)
    });
}
