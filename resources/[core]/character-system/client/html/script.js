let characters = [];
let spawnLocations = {};
let spawnMap = {};
let selectedCharacter = null;
let currentCitizenid = null;
let jobSpawns = [];
let map = null;
let mapCanvas = null;
let markers = [];
let selectedLocation = null;
let selectedMarker = null;
let customPin = null;

function $(id) { return document.getElementById(id); }

function showScreen(id) {
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
    $(id).classList.add('active');
    if (id === 'spawn-screen') {
        $('app').classList.add('spawn-mode');
    } else {
        $('app').classList.remove('spawn-mode');
    }
}

function formatDate(dateStr) {
    if (!dateStr) return 'Unknown';
    const d = new Date(dateStr);
    return d.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
}

function getInitials(first, last) {
    return (first ? first[0] : '') + (last ? last[0] : '');
}

/* ── Render character cards ── */
function renderCharacters(chars) {
    const container = $('character-list');
    if (!chars || chars.length === 0) {
        container.innerHTML = `
            <div class="character-empty">
                <div class="empty-icon">👤</div>
                <p>No characters yet. Create your first one!</p>
            </div>
        `;
        return;
    }
    container.innerHTML = chars.map((c, i) => `
        <div class="character-card stagger-${Math.min(i+1,10)}" data-citizenid="${c.citizenid}" data-index="${i}">
            <div class="character-avatar">${getInitials(c.firstname, c.lastname)}</div>
            <div class="character-name">${c.firstname} ${c.lastname}</div>
            <div class="job-badge">${c.job_label || c.gender || 'Citizen'}</div>
            <div class="character-details">
                <div class="detail-row"><span class="detail-icon">👤</span> ${c.gender ? c.gender.charAt(0).toUpperCase() + c.gender.slice(1) : 'Unknown'}</div>
                <div class="detail-row"><span class="detail-icon">📅</span> ${formatDate(c.birthdate)}</div>
                <div class="detail-row"><span class="detail-icon">🆔</span> CID: ${c.citizenid}</div>
                <div class="detail-row"><span class="detail-icon">⏱</span> ${c.played_hours || 0}h played</div>
                <div class="detail-row"><span class="detail-icon">📋</span> Created ${formatDate(c.created_at)}</div>
            </div>
        </div>
    `).join('');

    container.querySelectorAll('.character-card').forEach(card => {
        card.addEventListener('click', function() {
            const cid = this.dataset.citizenid;
            selectedCharacter = chars.find(c => c.citizenid === cid);
            currentCitizenid = cid;
            showSpawnScreen(selectedCharacter);
        });
    });
}

/* ── Generate GTA V map canvas background ── */
function generateMapCanvas() {
    const bounds = spawnMap.bounds || { minX: -3000, maxX: 3000, minY: -3000, maxY: 7000 };
    const mapW = bounds.maxX - bounds.minX;
    const mapH = bounds.maxY - bounds.minY;
    const canvasH = 1800;
    const canvasW = Math.round(canvasH * mapW / mapH);
    const canvas = document.createElement('canvas');
    canvas.width = canvasW;
    canvas.height = canvasH;
    const ctx = canvas.getContext('2d');
    const cx = canvas.width / 2;
    const cy = canvas.height / 2;

    function toCanvas(gtaX, gtaY) {
        return {
            x: ((gtaX - bounds.minX) / mapW) * canvas.width,
            y: (((-gtaY) - bounds.minY) / mapH) * canvas.height,
        };
    }

    // Background gradient
    const grad = ctx.createRadialGradient(cx, cy, 0, cx, cy, Math.max(canvasW, canvasH) * 0.7);
    grad.addColorStop(0, '#161b2e');
    grad.addColorStop(1, '#0d1117');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // Ocean area (south)
    ctx.fillStyle = 'rgba(15, 25, 50, 0.4)';
    ctx.fillRect(0, toCanvas(0, -2800).y, canvas.width, toCanvas(0, -3200).y - toCanvas(0, -2800).y + 100);
    // Western ocean
    ctx.fillRect(0, 0, toCanvas(-2500, 0).x, canvas.height);

    // Alamo Sea
    const alamo = toCanvas(500, 3500);
    ctx.beginPath();
    ctx.arc(alamo.x, alamo.y, 100, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(15, 25, 50, 0.5)';
    ctx.fill();

    // Grid lines
    ctx.strokeStyle = 'rgba(255,255,255,0.03)';
    ctx.lineWidth = 1;
    for (let i = Math.ceil(bounds.minX / 1000) * 1000; i <= bounds.maxX; i += 1000) {
        const p = toCanvas(i, 0);
        ctx.beginPath(); ctx.moveTo(p.x, 0); ctx.lineTo(p.x, canvas.height); ctx.stroke();
    }
    for (let i = Math.ceil(bounds.minY / 1000) * 1000; i <= bounds.maxY; i += 1000) {
        const p = toCanvas(0, i);
        ctx.beginPath(); ctx.moveTo(0, p.y); ctx.lineTo(canvas.width, p.y); ctx.stroke();
    }

    // Simplified highways
    ctx.strokeStyle = 'rgba(255,255,255,0.04)';
    ctx.lineWidth = 3;
    const roads = [
        [[-2000, -500], [2000, -500]],
        [[200, -2500], [200, 2000]],
        [[2000, -1500], [2000, 3000]],
        [[-2500, -2000], [-2000, 2000]],
        [[200, 2000], [-300, 6500]],
        [[-300, 6500], [100, 6424]],
        [[2000, 3000], [1840, 3680]],
    ];
    roads.forEach(seg => {
        const a = toCanvas(seg[0][0], seg[0][1]);
        const b = toCanvas(seg[1][0], seg[1][1]);
        ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke();
    });

    // Zone labels
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    const zones = [
        { x: 200, y: -500, label: 'Los Santos', size: 18 },
        { x: 1840, y: 3680, label: 'Sandy Shores', size: 13 },
        { x: 100, y: 6424, label: 'Paleto Bay', size: 13 },
        { x: 2140, y: 4780, label: 'Grapeseed', size: 11 },
        { x: -2200, y: 3500, label: 'Fort Zancudo', size: 11 },
        { x: 500, y: 5200, label: 'Mt. Chiliad', size: 11 },
        { x: -1040, y: -2750, label: 'LSIA', size: 11 },
    ];
    zones.forEach(z => {
        const p = toCanvas(z.x, z.y);
        ctx.font = `${z.size}px Arial, sans-serif`;
        ctx.fillStyle = 'rgba(255,255,255,0.06)';
        ctx.fillText(z.label, p.x, p.y);
    });

    // Coordinate labels
    ctx.font = '10px monospace';
    ctx.fillStyle = 'rgba(255,255,255,0.08)';
    for (let i = Math.ceil(bounds.minX / 1000) * 1000; i <= bounds.maxX; i += 1000) {
        const px = toCanvas(i, bounds.minY).x;
        ctx.fillText(i + '', px, canvas.height - 8);
    }
    for (let i = Math.ceil(bounds.minY / 1000) * 1000; i <= bounds.maxY; i += 1000) {
        const py = toCanvas(bounds.minX, i).y;
        ctx.fillText(i + '', 8, py);
    }

    return canvas;
}

/* ── Initialize Leaflet Map ── */
function initSpawnMap() {
    if (map) {
        map.remove();
        map = null;
    }
    markers = [];
    selectedLocation = null;
    selectedMarker = null;
    if (customPin) { map.removeLayer(customPin); customPin = null; }

    const bounds = spawnMap.bounds || { minX: -4500, maxX: 4500, minY: -4500, maxY: 4500 };

    map = L.map('spawn-map', {
        crs: L.CRS.Simple,
        minZoom: -2,
        maxZoom: 1,
        zoomSnap: 0.25,
        attributionControl: false,
        zoomControl: false,
        dragging: true,
        scrollWheelZoom: true,
        doubleClickZoom: false,
    });

    // Generate and add canvas background
    mapCanvas = generateMapCanvas();
    const imgBounds = [[bounds.minY, bounds.minX], [bounds.maxY, bounds.maxX]];
    L.imageOverlay(mapCanvas.toDataURL(), imgBounds).addTo(map);

    map.fitBounds(imgBounds);

    // Zoom controls repositioned
    L.control.zoom({ position: 'bottomright' }).addTo(map);

    // Handle map click (click anywhere to spawn)
    map.on('click', function(e) {
        const gtaX = e.latlng.lng;
        const gtaY = -e.latlng.lat;
        selectCustomLocation(gtaX, gtaY);
    });
}

/* ── Add markers to map ── */
function addSpawnMarkers(locations, type) {
    if (!map) return;
    locations.forEach(loc => {
        const gtaY = loc.coords.y;
        const gtaX = loc.coords.x;
        const marker = L.marker([-gtaY, gtaX], {
            icon: L.divIcon({
                className: type === 'job' ? 'spawn-marker-job' : 'spawn-marker-common',
                iconSize: [14, 14],
                iconAnchor: [7, 7],
            }),
            riseOnHover: true,
        });

        marker.bindTooltip(loc.label, {
            className: 'spawn-marker-label',
            direction: 'top',
            offset: [0, -10],
        });

        marker.on('click', function() {
            selectNamedLocation(loc, marker);
        });

        marker.addTo(map);
        markers.push({ data: loc, marker: marker, type: type });
    });
}

/* ── Select a named spawn location ── */
function selectNamedLocation(loc, markerEl) {
    selectedLocation = {
        type: loc.type,
        coords: loc.coords,
        label: loc.label,
    };
    // Remove custom pin if exists
    if (customPin) { map.removeLayer(customPin); customPin = null; }
    // Update marker visuals
    markers.forEach(m => {
        const el = m.marker.getElement();
        if (el) el.classList.remove('selected-marker', 'active');
    });
    if (markerEl) {
        const el = markerEl.getElement();
        if (el) el.classList.add('selected-marker', 'active');
    }
    $('selected-location-info').textContent = '📍 ' + loc.label;
    $('btn-spawn-here').disabled = false;
    $('btn-spawn-here').textContent = 'Spawn at ' + loc.label;
}

/* ── Select custom map coordinates ── */
function selectCustomLocation(gtaX, gtaY) {
    // Remove previous custom pin
    if (customPin) { map.removeLayer(customPin); }
    // Deselect marker highlights
    markers.forEach(m => {
        const el = m.marker.getElement();
        if (el) el.classList.remove('selected-marker', 'active');
    });
    // Add custom pin
    customPin = L.marker([-gtaY, gtaX], {
        icon: L.divIcon({
            className: 'spawn-marker-common selected-marker',
            iconSize: [18, 18],
            iconAnchor: [9, 9],
        }),
    }).addTo(map);

    selectedLocation = {
        type: 'custom',
        coords: { x: gtaX, y: gtaY, z: 0.0 },
        label: 'Custom Location',
    };
    $('selected-location-info').textContent = '📍 Custom (' + Math.round(gtaX) + ', ' + Math.round(gtaY) + ')';
    $('btn-spawn-here').disabled = false;
    $('btn-spawn-here').textContent = 'Spawn Here';
}

/* ── Show spawn screen with map ── */
function showSpawnScreen(char) {
    if (!char) return;
    selectedCharacter = char;
    currentCitizenid = char.citizenid;
    $('spawn-character-name').textContent = `${char.firstname} ${char.lastname}`;
    $('btn-spawn-here').disabled = true;
    $('selected-location-info').textContent = 'Click on the map or a marker to choose';

    showScreen('spawn-screen');

    // Init map
    initSpawnMap();

    // Add common locations
    const common = spawnMap.common || [];
    addSpawnMarkers(common, 'common');

    // Fetch job-specific markers
    fetch('https://' + GetParentResourceName() + '/getJobSpawns', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ citizenid: char.citizenid })
    })
    .then(r => r.json())
    .then(data => {
        jobSpawns = data.jobSpawns || [];
        if (jobSpawns.length > 0) {
            addSpawnMarkers(jobSpawns, 'job');
        }
    })
    .catch(() => {});
}

/* ── Submit spawn selection ── */
function submitSpawn(spawnType, customCoords) {
    const data = { citizenid: currentCitizenid, spawnType: spawnType };
    if (spawnType === 'custom' && customCoords) {
        data.customCoords = customCoords;
    }
    fetch('https://' + GetParentResourceName() + '/selectCharacter', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });
}

/* ── Init ── */
window.addEventListener('DOMContentLoaded', function() {
    showScreen('loading-screen');

    // Character creation form
    $('creation-form').addEventListener('submit', function(e) {
        e.preventDefault();
        const firstname = $('firstname').value.trim();
        const lastname = $('lastname').value.trim();
        const birthdate = $('birthdate').value;
        const gender = $('gender').value;

        if (!firstname || !lastname) {
            $('creation-error').textContent = 'First and last name are required';
            return;
        }
        if (firstname.length < 2 || lastname.length < 2) {
            $('creation-error').textContent = 'Names must be at least 2 characters';
            return;
        }
        if (!birthdate) {
            $('creation-error').textContent = 'Date of birth is required';
            return;
        }
        const bd = new Date(birthdate);
        const today = new Date();
        let age = today.getFullYear() - bd.getFullYear();
        const m = today.getMonth() - bd.getMonth();
        if (m < 0 || (m === 0 && today.getDate() < bd.getDate())) age--;
        if (age < 18) {
            $('creation-error').textContent = 'You must be at least 18 years old';
            return;
        }

        $('creation-error').textContent = '';
        fetch('https://' + GetParentResourceName() + '/createCharacter', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ firstname, lastname, birthdate, gender })
        });
    });

    $('create-new-btn').addEventListener('click', function() {
        $('creation-error').textContent = '';
        $('firstname').value = '';
        $('lastname').value = '';
        $('birthdate').value = '';
        $('gender').value = 'male';
        showScreen('creation-screen');
    });

    $('back-to-selector').addEventListener('click', function() {
        showScreen('selector-screen');
    });

    $('back-to-selector2').addEventListener('click', function() {
        showScreen('selector-screen');
    });

    // Last location button
    $('btn-last-location').addEventListener('click', function() {
        submitSpawn('last');
    });

    // Spawn here button
    $('btn-spawn-here').addEventListener('click', function() {
        if (!selectedLocation) return;
        if (selectedLocation.type === 'custom') {
            submitSpawn('custom', selectedLocation.coords);
        } else {
            submitSpawn(selectedLocation.type);
        }
    });

    // Listen for NUI messages
    window.addEventListener('message', function(event) {
        const data = event.data;

        if (data.type === 'showSelector') {
            characters = data.characters || [];
            spawnLocations = data.spawnLocations || {};
            spawnMap = data.spawnMap || {};
            renderCharacters(characters);
            showScreen('selector-screen');
        }

        if (data.type === 'characterCreated') {
            characters.push(data.character);
            renderCharacters(characters);
            showScreen('selector-screen');
        }

        if (data.type === 'creationFailed') {
            $('creation-error').textContent = data.error || 'Failed to create character';
            showScreen('creation-screen');
        }
    });
});
