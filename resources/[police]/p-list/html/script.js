let officers = [];
let officerList = document.getElementById('officer-list');
let countBadge = document.getElementById('count-badge');

window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'open') {
        document.body.style.display = 'flex';
    } else if (data.action === 'updateList') {
        officers = data.officers || [];
        render();
    }
});

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        fetch('https://' + GetParentResourceName() + '/close', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
        document.body.style.display = 'none';
    }
});

function render() {
    countBadge.textContent = officers.length;

    if (officers.length === 0) {
        officerList.innerHTML = '<div class="empty">No officers currently on duty</div>';
        return;
    }

    let html = '';
    for (const off of officers) {
        const jobClass = getJobClass(off.job);
        const hasRadio = off.radio != null && off.radio > 0;
        html += `
            <div class="officer-card">
                <div class="left">
                    <div class="name">${escapeHtml(off.name)}</div>
                    <div class="job-row">
                        <span class="job-badge ${jobClass}">${escapeHtml(off.job)}</span>
                        ${escapeHtml(off.gradeName || 'Officer')}
                    </div>
                </div>
                <div class="right">
                    ${hasRadio ? `<div class="radio-freq">CH ${off.radio}</div>` : `<div class="radio-none">No Radio</div>`}
                    <div><span class="status-dot on"></span><span style="font-size:var(--font-size-xs);color:rgba(255,255,255,0.35)">ON DUTY</span></div>
                </div>
            </div>
        `;
    }
    officerList.innerHTML = html;
}

function getJobClass(job) {
    const name = (job || '').toLowerCase();
    if (name.includes('cid')) return 'job-cid';
    if (name.includes('sheriff')) return 'job-sheriff';
    if (name.includes('state')) return 'job-statepolice';
    return 'job-police';
}

function escapeHtml(str) {
    if (!str) return '';
    return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function GetParentResourceName() {
    return 'p-list';
}
