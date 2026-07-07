const terminal = document.getElementById('terminal');
const categoriesEl = document.getElementById('categories');
const vehicleList = document.getElementById('vehicleList');
const closeBtn = document.getElementById('closeBtn');

let categories = {};
let selectedCategory = null;

window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'openTerminal') {
        categories = data.categories;
        selectedCategory = null;
        renderCategories();
        vehicleList.innerHTML = '<div class="placeholder">Select a category</div>';
        terminal.style.display = 'block';
    }
    if (data.action === 'closeTerminal') {
        terminal.style.display = 'none';
    }
});

function renderCategories() {
    categoriesEl.innerHTML = '';
    const keys = Object.keys(categories);
    keys.forEach(key => {
        const cat = categories[key];
        const btn = document.createElement('button');
        btn.className = 'cat-btn' + (selectedCategory === key ? ' active' : '');
        btn.textContent = cat.label.toUpperCase();
        btn.addEventListener('click', function() {
            selectedCategory = key;
            renderCategories();
            renderVehicles(key);
        });
        categoriesEl.appendChild(btn);
    });
}

function renderVehicles(key) {
    const cat = categories[key];
    if (!cat) return;
    vehicleList.innerHTML = '';
    cat.vehicles.forEach(v => {
        const item = document.createElement('div');
        item.className = 'vehicle-item';
        const badgeClass = getBadgeClass(v.class || v.category || '');
        const badgeLabel = getBadgeLabel(v.class || v.category || '');
        item.innerHTML = `
            <span class="name"><span class="badge ${badgeClass}">${badgeLabel}</span>${v.label}</span>
            <span class="stats">${v.speed || '?'} MPH · ${v.seats || '?'} SEATS</span>
        `;
        item.addEventListener('click', function() {
            fetch(`https://${GetParentResourceName()}/spawnVehicle`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ model: v.model, category: key })
            });
        });
        vehicleList.appendChild(item);
    });
}

function getBadgeClass(cls) {
    const c = (cls || '').toLowerCase();
    if (c.includes('sport') || c.includes('super')) return 'badge-red';
    if (c.includes('muscle') || c.includes('off')) return 'badge-gold';
    if (c.includes('armor') || c.includes('military')) return 'badge-purple';
    if (c.includes('moto') || c.includes('bike')) return 'badge-cyan';
    return 'badge-blue';
}

function getBadgeLabel(cls) {
    const c = (cls || '').toLowerCase();
    if (c.includes('sport') || c.includes('super')) return 'SPORT';
    if (c.includes('muscle') || c.includes('off')) return 'OFF-ROAD';
    if (c.includes('armor') || c.includes('military')) return 'ARMORED';
    if (c.includes('moto') || c.includes('bike')) return 'MOTO';
    return 'STOCK';
}

closeBtn.addEventListener('click', function() {
    fetch(`https://${GetParentResourceName()}/closeTerminal`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        fetch(`https://${GetParentResourceName()}/closeTerminal`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
});

function GetParentResourceName() {
    return 'secret-bunkers';
}
