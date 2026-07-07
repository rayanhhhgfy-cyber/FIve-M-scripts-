const el = id => document.getElementById(id);

// State cache
let state = {
    hp: 100, maxHp: 100, armor: 0,
    hunger: 100, thirst: 100, stress: 0, stamina: 100,
    speed: 0, fuel: 100, seatbelt: false,
    street: '', cash: 0, bank: 0,
    job: '', grade: '', voice: '',
    inVehicle: false, time: '', visible: true
};

function updateHUD(d) {
    if (d.hp !== undefined) {
        state.hp = d.hp;
        state.maxHp = d.maxHp || 100;
        const pct = Math.min((state.hp / state.maxHp) * 100, 100);
        el('healthFill').style.width = pct + '%';
        el('healthVal').textContent = Math.floor(state.hp);
    }
    if (d.armor !== undefined) {
        state.armor = d.armor;
        el('armorFill').style.width = Math.min(state.armor, 100) + '%';
        el('armorVal').textContent = Math.floor(state.armor);
        el('statArmor').style.display = state.armor > 0 ? 'flex' : 'none';
    }
    if (d.hunger !== undefined) {
        state.hunger = d.hunger;
        el('hungerFill').style.width = Math.min(state.hunger, 100) + '%';
        el('hungerVal').textContent = Math.floor(state.hunger);
        el('statHunger').style.display = state.hunger < 100 ? 'flex' : 'none';
    }
    if (d.thirst !== undefined) {
        state.thirst = d.thirst;
        el('thirstFill').style.width = Math.min(state.thirst, 100) + '%';
        el('thirstVal').textContent = Math.floor(state.thirst);
        el('statThirst').style.display = state.thirst < 100 ? 'flex' : 'none';
    }
    if (d.stress !== undefined) {
        state.stress = d.stress;
        el('stressFill').style.width = Math.min(state.stress, 100) + '%';
        el('stressVal').textContent = Math.floor(state.stress);
        el('statStress').style.display = state.stress > 0 ? 'flex' : 'none';
    }
    if (d.stamina !== undefined) {
        state.stamina = d.stamina;
        el('staminaFill').style.width = Math.min(state.stamina, 100) + '%';
        el('staminaVal').textContent = Math.floor(state.stamina);
    }
    if (d.speed !== undefined) {
        state.speed = d.speed;
        el('speedValue').textContent = Math.floor(state.speed);
    }
    if (d.fuel !== undefined) {
        state.fuel = d.fuel;
        const pct = Math.min(state.fuel, 100);
        el('fuelFill').style.width = pct + '%';
        el('fuelVal').textContent = Math.floor(pct) + '%';
        // Color-code fuel
        const fill = el('fuelFill');
        if (pct <= 5) fill.style.background = 'linear-gradient(90deg,#ff3b30,#ff6b6b)';
        else if (pct <= 15) fill.style.background = 'linear-gradient(90deg,#f97316,#fb923c)';
        else fill.style.background = 'linear-gradient(90deg,#facc15,#4ade80)';
    }
    if (d.seatbelt !== undefined) {
        state.seatbelt = d.seatbelt;
        const sb = el('seatbeltDisplay');
        if (state.seatbelt) {
            sb.textContent = '✅ BELT ON';
            sb.style.color = '#4ade80';
        } else {
            sb.textContent = '🔴 BELT OFF';
            sb.style.color = '#ff6b6b';
        }
    }
    if (d.street !== undefined) {
        state.street = d.street;
        el('streetDisplay').textContent = state.street;
    }
    if (d.cash !== undefined) {
        state.cash = d.cash;
        el('cashDisplay').textContent = '$' + formatNum(state.cash);
    }
    if (d.bank !== undefined) {
        state.bank = d.bank;
        el('bankDisplay').textContent = '🏦 $' + formatNum(state.bank);
    }
    if (d.job !== undefined) {
        state.job = d.job;
        el('jobDisplay').textContent = state.job || '';
    }
    if (d.grade !== undefined) {
        state.grade = d.grade;
    }
    if (d.voice !== undefined) {
        state.voice = d.voice;
        el('voiceDisplay').textContent = state.voice ? '🎤 ' + state.voice : '';
    }
    if (d.time !== undefined) {
        state.time = d.time;
        el('timeDisplay').textContent = state.time;
    }
    if (d.inVehicle !== undefined) {
        state.inVehicle = d.inVehicle;
        el('vehicleHud').classList.toggle('visible', state.inVehicle);
    }
    if (d.visible !== undefined) {
        state.visible = d.visible;
        el('hudContainer').style.display = state.visible ? 'block' : 'none';
    }

    // Combined job+grade display
    if (d.job || d.grade) {
        const j = state.job || '';
        const g = state.grade || '';
        el('jobDisplay').textContent = j + (g ? ' (' + g + ')' : '');
    }

    // Show/hide top bar based on content
    const topBar = el('topBar');
    const hasContent = state.job || state.cash > 0 || state.bank > 0 || state.time;
    topBar.classList.toggle('visible', hasContent);

    // Show status bars
    el('statusBars').classList.toggle('visible', true);

    // Show street if not empty
    el('bottomStreet').classList.toggle('visible', state.street.length > 0);
}

function formatNum(n) {
    if (n >= 1000000) return (n / 1000000).toFixed(1) + 'M';
    if (n >= 1000) return (n / 1000).toFixed(1) + 'K';
    return Math.floor(n).toString();
}

// Listen for NUI messages
window.addEventListener('message', function(event) {
    const d = event.data;
    if (d.type === 'hudUpdate') {
        updateHUD(d);
    }
});

// Initial show after load
document.addEventListener('DOMContentLoaded', function() {
    el('topBar').classList.add('visible');
    el('statusBars').classList.add('visible');
    el('bottomStreet').classList.add('visible');
    el('vehicleHud').classList.add('visible');
});

// Expose for debug
window.hudState = state;