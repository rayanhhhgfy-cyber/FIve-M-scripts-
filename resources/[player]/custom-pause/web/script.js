// THEME: pause-overlay
const overlay = document.getElementById('pauseOverlay');
const bg = document.getElementById('pauseBg');
const identityEl = document.getElementById('pauseIdentity');
const statsEl = document.getElementById('pauseStats');
const jobEl = document.getElementById('pauseJob');
const financesEl = document.getElementById('pauseFinances');
const serverEl = document.getElementById('pauseServer');
const actionsEl = document.getElementById('pauseActions');
const bindingsEl = document.getElementById('pauseBindings');
const eomEl = document.getElementById('pauseEom');

const wIcons = { EXTRASUNNY:'☀️',CLEAR:'🌤',CLOUDS:'☁️',SMOG:'🌫',FOGGY:'🌫',OVERCAST:'☁️',RAIN:'🌧',THUNDER:'⛈',CLEARING:'🌤',NEUTRAL:'🌥',SNOW:'❄️',BLIZZARD:'🌨',SNOWLIGHT:'🌨',XMAS:'🎄',HALLOWEEN:'🎃' };

let waitingForBind = null;

window.addEventListener('message', function(event) {
    const d = event.data;
    if (d.action === 'openPause') {
        overlay.classList.add('open');
        bg.classList.add('open');
        renderPause(d);
    }
    if (d.action === 'closePause') {
        overlay.classList.remove('open');
        bg.classList.remove('open');
    }
    if (d.action === 'bindComplete') {
        waitingForBind = null;
        document.getElementById('bindIndicator').style.display = 'none';
        renderBindings(d.bindings || getBindingsFromDOM());
    }
    if (d.action === 'bindTimedOut') {
        waitingForBind = null;
        document.getElementById('bindIndicator').style.display = 'none';
    }
});

function renderPause(d) {
    const p = d.player || {};
    const s = d.server || {};
    const a = d.actions || {};
    const st = d.stats || {};
    const binds = d.bindings || [];
    const branding = document.getElementById('pauseBranding');
    if (branding) branding.textContent = p.name || 'Unknown';

    // THEME: identity section
    if (identityEl) {
        identityEl.innerHTML = `
            <div class="pause-row"><span class="pause-label">Name</span><span class="pause-value">${p.name||'Unknown'}</span></div>
            <div class="pause-row"><span class="pause-label">Citizen ID</span><span class="pause-value blue">${p.citizenid||'—'}</span></div>
            <div class="pause-row"><span class="pause-label">Phone</span><span class="pause-value">${p.phone||'—'}</span></div>
            <div class="pause-row"><span class="pause-label">Playtime</span><span class="pause-value">${formatPlaytime(st.playTime||0)}</span></div>
        `;
    }

    // THEME: player stats card
    if (statsEl) {
        const health = st.health || 100;
        const armor = st.armor || 0;
        statsEl.innerHTML = `
            <div class="mini-stat"><span class="stat-val" style="color:var(--accent-red)">♥</span> <span class="stat-val">${health}%</span> <span style="margin-left:8px;color:rgba(255,255,255,0.3)">|</span> <span class="stat-val" style="color:var(--accent-blue-light)">🛡</span> <span class="stat-val">${armor}%</span></div>
            <div class="mini-stat"><span>💵 Cash</span> <span class="stat-val green">$${((p.money&&p.money.cash)||0).toLocaleString()}</span></div>
            <div class="mini-stat"><span>🏦 Bank</span> <span class="stat-val blue">$${((p.money&&p.money.bank)||0).toLocaleString()}</span></div>
        `;
    }

    // THEME: employment section
    if (jobEl) {
        const onduty = a.onduty;
        jobEl.innerHTML = `
            <div class="pause-row"><span class="pause-label">Job</span><span class="pause-value">${p.job&&p.job.name||'Unemployed'}</span></div>
            <div class="pause-row"><span class="pause-label">Grade</span><span class="pause-value">${p.job&&p.job.label||p.job&&p.job.grade||'—'}</span></div>
            <div class="pause-row"><span class="pause-label">Status</span><span class="pause-value ${onduty?'duty-on green':'red'}">${onduty?'● On Duty':'○ Off Duty'}</span></div>
            <div class="pause-row"><span class="pause-label">Pay</span><span class="pause-value">$${(p.job&&p.job.payment)||0}/10min</span></div>
        `;
    }

    // THEME: finances section
    if (financesEl) {
        financesEl.innerHTML = `
            <div class="pause-row"><span class="pause-label">Cash</span><span class="pause-value green">$${((p.money&&p.money.cash)||0).toLocaleString()}</span></div>
            <div class="pause-row"><span class="pause-label">Bank</span><span class="pause-value blue">$${((p.money&&p.money.bank)||0).toLocaleString()}</span></div>
            <div class="pause-row"><span class="pause-label">Total</span><span class="pause-value">$${(((p.money&&p.money.cash)||0)+((p.money&&p.money.bank)||0)).toLocaleString()}</span></div>
        `;
    }

    // THEME: server info bar
    if (serverEl) {
        serverEl.innerHTML = `
            <div class="pause-row"><span class="pause-label">Players</span><span class="pause-value">${s.players||0}<span style="color:var(--accent-cyan);margin-left:4px;font-size:10px">online</span></span></div>
            <div class="pause-row"><span class="pause-label">Time</span><span class="pause-value">${String(s.hour||0).padStart(2,'0')}:${String(s.minute||0).padStart(2,'0')}</span></div>
            <div class="pause-row"><span class="pause-label">Weather</span><span class="pause-value">${wIcons[s.weather]||''} ${s.weather||'—'}</span></div>
            <div class="pause-row"><span class="pause-label">Uptime</span><span class="pause-value">${s.uptime||'—'}</span></div>
            ${s.resourceCount ? `<div class="pause-row"><span class="pause-label">Resources</span><span class="pause-value">${s.resourceCount}</span></div>` : ''}
        `;
    }

    // THEME: actions section
    if (actionsEl) {
        const dutyLabel = a.onduty ? 'Go Off Duty' : 'Go On Duty';
        const dutyCls = a.onduty ? 'warning' : 'success';
        actionsEl.innerHTML = `
            <button class="pause-btn ${dutyCls}" onclick="toggleDuty()">${dutyLabel}</button>
            <button class="pause-btn secondary" onclick="resumeGame()" style="margin-top:6px">Resume Game</button>
        `;
    }

    // THEME: employee of the month section
    if (eomEl) {
        const eomData = d.eom || { name: 'TBD', stats: '—', initials: '?' };
        eomEl.innerHTML = `
            <div class="eom-card">
                <div class="eom-avatar">${eomData.initials||'?'}</div>
                <div class="eom-info">
                    <div class="eom-name">${eomData.name||'No Data'}</div>
                    <div class="eom-meta">⭐ ${eomData.stats||'Top performer stats coming soon'}</div>
                </div>
            </div>
        `;
    }

    // THEME: key bindings section
    if (bindingsEl) {
        renderBindings(binds);
    }
}

function renderBindings(binds) {
    if (!bindingsEl) return;
    let html = '';
    for (const b of binds) {
        html += `
            <div class="bind-row" onclick="startRebind('${b.name}')">
                <span class="bind-label">${b.label}</span>
                <span class="bind-key" id="bind_${b.name}">${b.key}</span>
            </div>
        `;
    }
    html += `<div class="bind-indicator" id="bindIndicator">Press a key to rebind...</div>`;
    html += `<button class="pause-btn secondary" onclick="resetBindings()" style="margin-top:6px;width:100%">Reset All</button>`;
    bindingsEl.innerHTML = html;
}

function getBindingsFromDOM() {
    const binds = [];
    const rows = document.querySelectorAll('.bind-row');
    for (const row of rows) {
        const name = row.getAttribute('onclick')?.match(/'([^']+)'/)?.[1];
        const label = row.querySelector('.bind-label')?.textContent;
        const key = row.querySelector('.bind-key')?.textContent;
        if (name) binds.push({ name, label, key });
    }
    return binds;
}

function startRebind(name) {
    if (waitingForBind) return;
    waitingForBind = name;
    document.getElementById('bindIndicator').style.display = 'block';
    fetch(`https://${GetParentResourceName()}/startRebind`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ binding: name })
    });
}

function resetBindings() {
    fetch(`https://${GetParentResourceName()}/resetBindings`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).then(res => res.json()).then(data => {
        if (data.bindings) renderBindings(data.bindings);
    });
}

function toggleDuty() {
    fetch(`https://${GetParentResourceName()}/pauseToggleDuty`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' });
}

function resumeGame() {
    waitingForBind = null;
    fetch(`https://${GetParentResourceName()}/pauseResume`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' });
}

function formatPlaytime(seconds) {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    return h + 'h ' + m + 'm';
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' && overlay.classList.contains('open')) {
        resumeGame();
    }
});
