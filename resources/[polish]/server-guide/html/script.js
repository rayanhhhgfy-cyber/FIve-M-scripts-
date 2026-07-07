let data = null;
let activeTab = 0;

window.addEventListener('message', function(event) {
    const msg = event.data;
    if (msg.action === 'open') {
        data = msg.data;
        activeTab = 0;
        applyColors();
        render();
        document.getElementById('modal').style.display = 'flex';
        document.getElementById('overlay').style.display = 'block';
    }
});

document.getElementById('closeBtn').addEventListener('click', close);
document.getElementById('overlay').addEventListener('click', close);
document.addEventListener('keydown', function(e) { if (e.key === 'Escape') close(); });

function close() {
    document.getElementById('modal').style.display = 'none';
    document.getElementById('overlay').style.display = 'none';
    fetch('https://' + GetParentResourceName() + '/closeGuide', { method: 'POST', body: '{}' });
}

function applyColors() {
    const c = data.colors;
    const root = document.documentElement;
    root.style.setProperty('--bg', c.background);
    root.style.setProperty('--card', c.card);
    root.style.setProperty('--accent', c.accent);
    root.style.setProperty('--text', c.text);
    root.style.setProperty('--text-muted', c.textMuted);
    root.style.setProperty('--border', c.border);
    document.getElementById('modal').style.background = c.background;
}

function render() {
    renderTabs();
    renderContent();
}

function renderTabs() {
    const container = document.getElementById('tabs');
    container.innerHTML = '';
    data.tabs.forEach((label, i) => {
        const tab = document.createElement('div');
        tab.className = 'tab' + (i === activeTab ? ' active' : '');
        tab.textContent = label;
        tab.addEventListener('click', function() { activeTab = i; render(); });
        container.appendChild(tab);
    });
}

function renderContent() {
    const container = document.getElementById('content');
    container.innerHTML = '';
    switch (activeTab) {
        case 0: renderRules(container); break;
        case 1: renderKeybinds(container); break;
        case 2: renderStaff(container); break;
    }
}

function renderRules(container) {
    data.rules.forEach(function(rule) {
        const div = document.createElement('div');
        div.className = 'rule-item';
        div.innerHTML = '<div class="rule-title">' + rule.title + '</div><div class="rule-desc">' + rule.desc + '</div>';
        container.appendChild(div);
    });
}

function renderKeybinds(container) {
    data.keybinds.forEach(function(bind) {
        const div = document.createElement('div');
        div.className = 'bind-item';
        div.innerHTML = '<span class="bind-key">' + bind.key + '</span><span class="bind-action">' + bind.action + '</span>';
        container.appendChild(div);
    });
}

function renderStaff(container) {
    data.staff.forEach(function(member) {
        const div = document.createElement('div');
        div.className = 'staff-item';
        div.innerHTML = '<div><div class="staff-role">' + member.role + '</div><div class="staff-name">' + member.name + '</div></div><div class="staff-contact">' + member.contact + '</div>';
        container.appendChild(div);
    });
}
