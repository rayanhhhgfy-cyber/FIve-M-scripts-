let currentFloors = [];
let currentFloor = null;

window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'openElevator') {
        currentFloors = data.floors || [];
        currentFloor = data.currentFloor || null;
        renderFloors();
        updateStatus(data.currentFloor, data.direction, data.doors);
        document.getElementById('layout').style.display = 'block';
    }
    if (data.action === 'updateElevator') {
        updateStatus(data.floor, data.direction, data.doors);
    }
});

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') closeElevator();
});

function updateStatus(floor, direction, doors) {
    const floorNum = document.getElementById('floorNumber');
    const floorLabel = document.getElementById('floorLabel');
    const dirText = document.getElementById('directionText');
    const doorStatus = document.getElementById('doorStatus');

    if (floor) {
        floorNum.textContent = floor.name || floor;
        floorLabel.textContent = floor.label || '';
        floorNum.classList.remove('changing');
        void floorNum.offsetWidth;
        floorNum.classList.add('changing');
    }

    if (direction === 'up') {
        dirText.textContent = '▲ ASCENDING';
        dirText.className = 'direction mono';
    } else if (direction === 'down') {
        dirText.textContent = '▼ DESCENDING';
        dirText.className = 'direction mono';
    } else {
        dirText.textContent = '— IDLE';
        dirText.className = 'direction mono idle';
    }

    if (doors === 'open') {
        doorStatus.textContent = 'DOORS: OPEN';
        doorStatus.className = 'door-status mono opening';
    } else {
        doorStatus.textContent = 'DOORS: CLOSED';
        doorStatus.className = 'door-status mono';
    }

    renderFloors();
}

function renderFloors() {
    const list = document.getElementById('floorList');
    if (!list) return;
    let html = '';
    for (const floor of currentFloors) {
        const isCurrent = currentFloor && (floor.name === currentFloor.name || floor.name === currentFloor);
        const isLocked = floor.minRank > 0;
        html += `
            <button class="floor-btn ${isCurrent ? 'current' : ''}" onclick="selectFloor('${floor.name}', '${floor.label}')">
                <span>${floor.label}</span>
                <span class="floor-num">${floor.name.toUpperCase()}</span>
            </button>
        `;
    }
    list.innerHTML = html;
}

function selectFloor(name, label) {
    fetch('https://' + GetParentResourceName() + '/selectFloor', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ floor: name, label: label })
    }).then(res => res.json()).then(data => {
        if (data === 'ok' || data.result === 'ok') {
            document.getElementById('layout').style.display = 'none';
        }
    });
}

function closeElevator() {
    fetch('https://' + GetParentResourceName() + '/closeElevator', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
    document.getElementById('layout').style.display = 'none';
}

function GetParentResourceName() { return 'fib-building'; }
