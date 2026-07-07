let currentStep = 1;
let interiors = [];
let interiorTypes = [];
let rockPresets = {};
let editingBunkerId = null;
let bunkerData = {
    label: '',
    entranceCoords: { x: 0, y: 0, z: 0 },
    entranceHeading: 0,
    interiorName: '',
    interiorCoords: { x: 0, y: 0, z: 0 },
    interiorHeading: 0,
    interiorType: 'bunker_meth_lab',
    passcode: '2193',
    locked: true,
    cidBypass: true,
    allowedJobs: null,
    minRank: 0,
    vehicleSpawn: null,
    heliSpawn: null,
    rocks: [],
    roofProps: null,
};

window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'openBuilder') {
        interiors = data.interiors || [];
        interiorTypes = data.interiorTypes || [];
        rockPresets = data.rockPresets || {};
        bunkerData = {
            label: '', entranceCoords: { x: 0, y: 0, z: 0 }, entranceHeading: 0,
            interiorName: '', interiorCoords: { x: 0, y: 0, z: 0 }, interiorHeading: 0,
            interiorType: 'bunker_meth_lab', passcode: '2193', locked: true, cidBypass: true,
            allowedJobs: null, minRank: 0, vehicleSpawn: null, heliSpawn: null,
            rocks: [], roofProps: null,
        };
        showStep(1);
        renderRockOptions();
        renderInteriorOptions();
        renderInteriorTypeOptions();
        document.getElementById('app').classList.remove('hidden');
        document.getElementById('editApp').classList.add('hidden');
    }
    if (data.action === 'openEditor') {
        interiors = data.interiors || [];
        interiorTypes = data.interiorTypes || [];
        editingBunkerId = data.bunker.id;
        bunkerData = {
            label: data.bunker.label || '',
            entranceCoords: data.bunker.entranceCoords || { x: 0, y: 0, z: 0 },
            entranceHeading: data.bunker.entranceHeading || 0,
            interiorName: data.bunker.interiorName || '',
            interiorCoords: data.bunker.interiorCoords || { x: 0, y: 0, z: 0 },
            interiorHeading: data.bunker.interiorHeading || 0,
            interiorType: data.bunker.interiorType || 'bunker_meth_lab',
            passcode: data.bunker.passcode || '2193',
            locked: data.bunker.locked !== false,
            cidBypass: data.bunker.cidBypass !== false,
            allowedJobs: data.bunker.allowedJobs || null,
            minRank: data.bunker.minRank || 0,
            rocks: data.bunker.rocks || [],
            roofProps: data.bunker.roofProps || null,
        };
        document.getElementById('app').classList.add('hidden');
        document.getElementById('editApp').classList.remove('hidden');
        renderEditForm();
    }
});

function showStep(n) {
    currentStep = n;
    document.querySelectorAll('.step').forEach((el, i) => {
        el.classList.toggle('active', i + 1 === n);
    });
    document.querySelectorAll('.page').forEach((el, i) => {
        el.classList.toggle('active', i + 1 === n);
    });
    document.getElementById('backBtn').classList.toggle('hidden', n === 1);
    const nextBtn = document.getElementById('nextBtn');
    if (n === 5) {
        nextBtn.textContent = 'Create';
        nextBtn.classList.add('confirm');
    } else {
        nextBtn.textContent = 'Next';
        nextBtn.classList.remove('confirm');
    }
    updateSummary();
}

function nextStep() {
    if (currentStep === 1) {
        const label = document.getElementById('bunkerLabel').value.trim();
        if (!label) { alert('Enter a bunker name'); return; }
        bunkerData.label = label;
        showStep(2);
    } else if (currentStep === 2) {
        if (!bunkerData.entranceCoords.x && !bunkerData.entranceCoords.y) { alert('Capture entrance coords first'); return; }
        if (bunkerData.rocks.length === 0) { alert('Select a rock cover preset'); return; }
        showStep(3);
    } else if (currentStep === 3) {
        if (!bunkerData.interiorName) { alert('Select an interior type'); return; }
        if (!bunkerData.interiorCoords.x && !bunkerData.interiorCoords.y) { alert('Capture interior spawn coords'); return; }
        showStep(4);
    } else if (currentStep === 4) {
        showStep(5);
    } else if (currentStep === 5) {
        confirmSave();
    }
}

function prevStep() {
    if (currentStep > 1) showStep(currentStep - 1);
}

function renderRockOptions() {
    const container = document.getElementById('rockOptions');
    container.innerHTML = '';
    for (const [key, preset] of Object.entries(rockPresets)) {
        const btn = document.createElement('div');
        btn.className = 'rock-btn';
        btn.textContent = preset.label;
        btn.dataset.key = key;
        btn.onclick = function() {
            document.querySelectorAll('.rock-btn').forEach(b => b.classList.remove('selected'));
            this.classList.add('selected');
            bunkerData.rocks = JSON.parse(JSON.stringify(preset.rocks));
        };
        container.appendChild(btn);
    }
}

function renderInteriorOptions() {
    const container = document.getElementById('interiorList');
    container.innerHTML = '';
    interiors.forEach(function(interior) {
        const btn = document.createElement('div');
        btn.className = 'interior-btn';
        btn.textContent = interior.label;
        btn.dataset.name = interior.name;
        btn.onclick = function() {
            document.querySelectorAll('.interior-btn').forEach(b => b.classList.remove('selected'));
            this.classList.add('selected');
            bunkerData.interiorName = interior.name;
        };
        container.appendChild(btn);
    });
}

function renderInteriorTypeOptions() {
    const container = document.getElementById('interiorTypeList');
    if (!container) return;
    container.innerHTML = '';
    interiorTypes.forEach(function(type) {
        const btn = document.createElement('div');
        btn.className = 'interior-btn';
        btn.textContent = type.label;
        btn.dataset.name = type.name;
        btn.onclick = function() {
            document.querySelectorAll('#interiorTypeList .interior-btn').forEach(b => b.classList.remove('selected'));
            this.classList.add('selected');
            bunkerData.interiorType = type.name;
        };
        container.appendChild(btn);
    });
}

function captureEntrance() {
    fetch('https://' + GetParentResourceName() + '/getPlayerCoords', {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({})
    }).then(function(r) { return r.json(); }).then(function(data) {
        if (data && data.coords) {
            bunkerData.entranceCoords = data.coords;
            bunkerData.entranceHeading = data.heading || 0;
            document.getElementById('entranceCoords').textContent =
                'X: ' + data.coords.x.toFixed(2) + ' Y: ' + data.coords.y.toFixed(2) + ' Z: ' + data.coords.z.toFixed(2);
        }
    });
}

function captureInterior() {
    fetch('https://' + GetParentResourceName() + '/getPlayerCoords', {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({})
    }).then(function(r) { return r.json(); }).then(function(data) {
        if (data && data.coords) {
            bunkerData.interiorCoords = data.coords;
            bunkerData.interiorHeading = data.heading || 0;
            document.getElementById('interiorCoords').textContent =
                'X: ' + data.coords.x.toFixed(2) + ' Y: ' + data.coords.y.toFixed(2) + ' Z: ' + data.coords.z.toFixed(2);
        }
    });
}

function toggleLock() {
    const checked = document.getElementById('lockToggle').checked;
    document.getElementById('passcodeInput').style.opacity = checked ? '1' : '0.4';
}

function updateSummary() {
    document.getElementById('summaryLabel').textContent = bunkerData.label || '-';
    document.getElementById('summaryEntrance').textContent =
        bunkerData.entranceCoords.x ? 'X:' + bunkerData.entranceCoords.x.toFixed(1) + ' Y:' + bunkerData.entranceCoords.y.toFixed(1) : '-';
    document.getElementById('summaryInterior').textContent =
        bunkerData.interiorName || '-';
    document.getElementById('summaryInteriorType').textContent = interiorTypes.find(function(t) { return t.name === bunkerData.interiorType; })?.label || bunkerData.interiorType || '-';
    const passcodeInput = document.getElementById('bunkerPasscode');
    document.getElementById('summaryPasscode').textContent = passcodeInput ? passcodeInput.value || '2193' : '2193';
    document.getElementById('summaryLocked').textContent = document.getElementById('lockToggle').checked ? 'Yes' : 'No';
    document.getElementById('summaryCidBypass').textContent = document.getElementById('cidBypassToggle').checked ? 'Yes (on duty only)' : 'No';
}

function confirmSave() {
    bunkerData.passcode = document.getElementById('bunkerPasscode') ? document.getElementById('bunkerPasscode').value.trim() || '2193' : '2193';
    bunkerData.locked = document.getElementById('lockToggle').checked;
    bunkerData.cidBypass = document.getElementById('cidBypassToggle').checked;
    bunkerData.roofProps = document.getElementById('roofToggle').checked ? [
        { model: 'prop_rock_4_b', coords: { x: 0, y: -3, z: 0 }, heading: 0, slideDir: { x: 0, y: 0, z: 6 } },
        { model: 'prop_rock_4_c', coords: { x: 3, y: 0, z: 0 }, heading: 90, slideDir: { x: 0, y: 0, z: 6 } },
        { model: 'prop_rock_3_b', coords: { x: -3, y: 0, z: -0.5 }, heading: 180, slideDir: { x: 0, y: 0, z: 6 } },
    ] : null;

    fetch('https://' + GetParentResourceName() + '/saveBunker', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(bunkerData)
    }).then(function() {
        document.getElementById('app').classList.add('hidden');
    });
}

function cancel() {
    fetch('https://' + GetParentResourceName() + '/cancelBuilder', {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({})
    }).then(function() {
        document.getElementById('app').classList.add('hidden');
    });
}

function renderEditForm() {
    const container = document.getElementById('editFields');
    let interiorOpts = '';
    interiors.forEach(function(i) { interiorOpts += '<option value="' + i.name + '"' + (i.name === bunkerData.interiorName ? ' selected' : '') + '>' + i.label + '</option>'; });
    let typeOpts = '';
    interiorTypes.forEach(function(t) { typeOpts += '<option value="' + t.name + '"' + (t.name === bunkerData.interiorType ? ' selected' : '') + '>' + t.label + '</option>'; });
    container.innerHTML = `
        <div style="margin-bottom:12px;">
            <label style="font-size:13px;color:var(--text-muted);display:block;margin-bottom:4px;">Label</label>
            <input type="text" id="editLabel" class="input" value="` + escapeHtml(bunkerData.label) + `" maxlength="64">
        </div>
        <div style="margin-bottom:12px;">
            <label style="font-size:13px;color:var(--text-muted);display:block;margin-bottom:4px;">Interior IPL</label>
            <select id="editInterior" class="input" style="width:100%;">` + interiorOpts + `</select>
        </div>
        <div style="margin-bottom:12px;">
            <label style="font-size:13px;color:var(--text-muted);display:block;margin-bottom:4px;">Interior Type</label>
            <select id="editInteriorType" class="input" style="width:100%;">` + typeOpts + `</select>
        </div>
        <div style="margin-bottom:12px;">
            <label style="font-size:13px;color:var(--text-muted);display:block;margin-bottom:4px;">Passcode</label>
            <input type="text" id="editPasscode" class="input" value="` + escapeHtml(bunkerData.passcode) + `" maxlength="10">
        </div>
        <div style="display:flex;align-items:center;gap:12px;margin-bottom:12px;">
            <label style="font-size:13px;display:flex;align-items:center;gap:6px;cursor:pointer;">
                <input type="checkbox" id="editLocked" ` + (bunkerData.locked ? 'checked' : '') + `>
                Locked
            </label>
            <label style="font-size:13px;display:flex;align-items:center;gap:6px;cursor:pointer;">
                <input type="checkbox" id="editCidBypass" ` + (bunkerData.cidBypass ? 'checked' : '') + `>
                CID bypass (on duty)
            </label>
        </div>
        <div style="margin-bottom:12px;">
            <label style="font-size:13px;color:var(--text-muted);display:block;margin-bottom:4px;">Entrance Coords</label>
            <div class="coord-display glass" style="font-size:12px;">
                X: ` + (bunkerData.entranceCoords.x || 0).toFixed(2) + ` Y: ` + (bunkerData.entranceCoords.y || 0).toFixed(2) + ` Z: ` + (bunkerData.entranceCoords.z || 0).toFixed(2) + `
            </div>
        </div>
        <div style="margin-bottom:12px;">
            <label style="font-size:13px;color:var(--text-muted);display:block;margin-bottom:4px;">Interior Coords</label>
            <div class="coord-display glass" style="font-size:12px;">
                X: ` + (bunkerData.interiorCoords.x || 0).toFixed(2) + ` Y: ` + (bunkerData.interiorCoords.y || 0).toFixed(2) + ` Z: ` + (bunkerData.interiorCoords.z || 0).toFixed(2) + `
            </div>
        </div>
        <button class="btn btn-sm btn-primary" onclick="captureEditCoords()" style="margin-bottom:12px;width:100%;">Capture Current Position as Entrance</button>
    `;
}

function escapeHtml(str) {
    return str.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function captureEditCoords() {
    fetch('https://' + GetParentResourceName() + '/getPlayerCoords', {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({})
    }).then(function(r) { return r.json(); }).then(function(data) {
        if (data && data.coords) {
            bunkerData.entranceCoords = data.coords;
            bunkerData.entranceHeading = data.heading || 0;
            renderEditForm();
        }
    });
}

function saveEdit() {
    bunkerData.label = document.getElementById('editLabel').value.trim() || bunkerData.label;
    bunkerData.interiorName = document.getElementById('editInterior').value;
    bunkerData.interiorType = document.getElementById('editInteriorType').value;
    bunkerData.passcode = document.getElementById('editPasscode').value.trim() || '2193';
    bunkerData.locked = document.getElementById('editLocked').checked;
    bunkerData.cidBypass = document.getElementById('editCidBypass').checked;
    fetch('https://' + GetParentResourceName() + '/updateBunker', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: editingBunkerId, data: bunkerData })
    }).then(function() {
        document.getElementById('editApp').classList.add('hidden');
    });
}

function closeEdit() {
    fetch('https://' + GetParentResourceName() + '/cancelBuilder', {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({})
    }).then(function() {
        document.getElementById('editApp').classList.add('hidden');
    });
}
