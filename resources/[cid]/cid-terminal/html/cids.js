const RESOURCE = GetParentResourceName();

window.addEventListener('message', function(e) {
    if (e.data.action === 'openTerminal') {
        document.getElementById('cidsContainer').classList.remove('cids-hidden');
        switchTab('dashboard');
        loadDashboard();
    }
});

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') closeTerminal();
});

function closeTerminal() {
    document.getElementById('cidsContainer').classList.add('cids-hidden');
    fetch(`https://${RESOURCE}/closeTerminal`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' });
}

function switchTab(name) {
    document.querySelectorAll('.cids-tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.cids-panel').forEach(p => p.classList.remove('active'));
    document.querySelector(`.cids-tab[data-tab="${name}"]`).classList.add('active');
    document.getElementById(`panel-${name}`).classList.add('active');
    loadTab(name);
}

document.querySelectorAll('.cids-tab').forEach(tab => {
    tab.addEventListener('click', () => switchTab(tab.dataset.tab));
});

function loadTab(name) {
    switch (name) {
        case 'dashboard': loadDashboard(); break;
        case 'staff': loadStaff(); break;
        case 'grades': loadGrades(); break;
        case 'payroll': loadPayrollHistory(); break;
        case 'armory': loadArmory(); break;
        case 'cases': loadCases(); break;
        case 'warrants': loadWarrants(); break;
        case 'bolos': loadBOLOs(); break;
        case 'vehiclespawns': loadVehicleSpawns(); break;
        case 'audit': loadAuditLog(); break;
    }
}

function api(method, data) {
    return fetch(`https://${RESOURCE}/${method}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {})
    }).then(r => r.json());
}

function modal(title, fields, onSubmit) {
    const overlay = document.createElement('div');
    overlay.className = 'cids-modal-overlay';
    overlay.innerHTML = `
        <div class="cids-modal">
            <h3>${title}</h3>
            ${fields.map(f => {
                if (f.type === 'select') {
                    return `<select class="cids-input" id="modal_${f.key}">${f.options.map(o => `<option value="${o.value}">${o.label}</option>`).join('')}</select>`;
                }
                return `<input class="cids-input" id="modal_${f.key}" placeholder="${f.placeholder || f.label}" type="${f.type || 'text'}">`;
            }).join('')}
            <div class="cids-modal-actions">
                <button class="cids-btn primary" id="modalSubmit">Submit</button>
                <button class="cids-btn secondary" id="modalCancel">Cancel</button>
            </div>
        </div>
    `;
    document.body.appendChild(overlay);
    document.getElementById('modalSubmit').onclick = function() {
        const data = {};
        fields.forEach(f => data[f.key] = document.getElementById('modal_' + f.key).value);
        overlay.remove();
        onSubmit(data);
    };
    document.getElementById('modalCancel').onclick = () => overlay.remove();
    overlay.addEventListener('click', (e) => { if (e.target === overlay) overlay.remove(); });
    setTimeout(() => {
        const first = overlay.querySelector('input, select');
        if (first) first.focus();
    }, 100);
}

function toast(msg, type) {
    const container = document.getElementById('toastContainer');
    const el = document.createElement('div');
    el.className = 'toast ' + (type || 'info');
    el.appendChild(document.createTextNode(msg));
    container.appendChild(el);
    setTimeout(() => { if (el.parentNode) el.remove(); }, 3000);
}

function cid(str) { return str && str !== 'null' && str !== 'undefined' ? str : '—'; }
function dateStr(d) { return d ? new Date(d + 'Z').toLocaleDateString() + ' ' + new Date(d + 'Z').toLocaleTimeString([], {hour:'2-digit',minute:'2-digit'}) : '—'; }

function loadDashboard() {
    api('nuiDashboard').then(d => {
        if (!d) return;
        ['Agents', 'Online', 'Cases', 'Ops', 'Bolos', 'Spawns'].forEach(k => {
            const el = document.getElementById('dash' + k);
            if (el) el.textContent = d['total' + k] || d['active' + (k === 'Spawns' ? 'VehicleSpawns' : k)] || d['active' + k] || d[k.toLowerCase()] || 0;
        });
    });
}

function loadStaff() {
    api('nuiGetStaff').then(staff => {
        const tbody = document.getElementById('staffBody');
        if (!staff || !staff.length) { tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;color:rgba(255,255,255,0.12)">No staff found</td></tr>'; return; }
        tbody.innerHTML = staff.map(s => `
            <tr>
                <td>${cid(s.name)} <span style="font-size:10px;color:rgba(255,255,255,0.15)">${cid(s.citizenid)}</span></td>
                <td>${s.job || '—'}</td>
                <td>${s.gradeName || 'Grade ' + s.grade}</td>
                <td><span class="status-badge ${s.onduty ? 'online' : 'offline'}">${s.onduty ? 'On Duty' : 'Offline'}</span></td>
                <td>
                    <button class="cids-btn secondary" style="padding:4px 10px;font-size:10px" onclick="showSetGrade('${s.citizenid}')">Grade</button>
                    <button class="cids-btn danger" style="padding:4px 10px;font-size:10px" onclick="fireStaff('${s.citizenid}')">Fire</button>
                </td>
            </tr>
        `).join('');
    });
}

function showHireDialog() {
    modal('Hire Staff', [
        { key: 'targetCid', label: 'Citizen ID', placeholder: 'e.g. CID00001' },
        { key: 'jobName', label: 'Job', placeholder: 'e.g. cid or police' }
    ], d => {
        api('nuiHireStaff', d).then(r => { if (r.success) { loadStaff(); toast('Staff hired successfully', 'success'); } });
    });
}

function showSetGrade(citizenid) {
    modal('Set Grade for ' + citizenid, [
        { key: 'grade', label: 'Grade (0-10)', placeholder: 'New grade number' }
    ], d => {
        api('nuiSetStaffGrade', { targetCid: citizenid, newGrade: parseInt(d.grade) || 0 }).then(r => { if (r.success) { loadStaff(); toast('Grade updated', 'success'); } });
    });
}

function fireStaff(citizenid) {
    modal('Fire ' + citizenid + '?', [
        { key: 'confirm', label: 'Type CONFIRM to fire', placeholder: 'CONFIRM' }
    ], d => {
        if (d.confirm === 'CONFIRM') {
            api('nuiFireStaff', { targetCid: citizenid }).then(r => { if (r.success) { loadStaff(); toast('Staff fired', 'error'); } });
        }
    });
}

function loadGrades() {
    api('nuiGetGrades').then(grades => {
        const tbody = document.getElementById('gradesBody');
        if (!grades || !grades.length) { tbody.innerHTML = '<tr><td colspan="4" style="text-align:center;color:rgba(255,255,255,0.12)">No grades configured</td></tr>'; return; }
        tbody.innerHTML = grades.map(g => `
            <tr>
                <td>${g.grade}</td>
                <td>${cid(g.label)}</td>
                <td>$${(g.salary || 0).toLocaleString()}</td>
                <td><button class="cids-btn secondary" style="padding:4px 10px;font-size:10px" onclick="editGrade(${g.grade})">Edit</button></td>
            </tr>
        `).join('');
    });
}

function editGrade(grade) {
    const row = document.querySelector(`#gradesBody tr:nth-child(${grade + 1})`);
    const currentLabel = row ? row.cells[1].textContent : '';
    const currentSalary = row ? row.cells[2].textContent.replace(/[$,]/g, '') : '0';
    modal('Edit Grade ' + grade, [
        { key: 'label', label: 'Label', placeholder: 'Grade name' },
        { key: 'salary', label: 'Salary', placeholder: 'Amount' }
    ], d => {
        api('nuiUpdateGrade', { grade: grade, label: d.label, salary: parseInt(d.salary) || 0 }).then(r => { if (r.success) { loadGrades(); toast('Grade updated', 'success'); } });
    });
    setTimeout(() => {
        const el1 = document.getElementById('modal_label'); if (el1) el1.value = currentLabel;
        const el2 = document.getElementById('modal_salary'); if (el2) el2.value = currentSalary;
    }, 150);
}

function triggerPayroll() {
    modal('Run Payroll', [
        { key: 'confirm', label: 'Type PAY to confirm', placeholder: 'PAY' }
    ], d => {
        if (d.confirm === 'PAY') {
            api('nuiTriggerPayroll').then(r => {
                if (r.success) { toast('Payroll complete! Paid ' + r.paid + ' employees.', 'success'); loadPayrollHistory(); }
            });
        }
    });
}

function loadPayrollHistory() {
    api('nuiGetPayrollHistory').then(rows => {
        const tbody = document.getElementById('payrollBody');
        if (!rows || !rows.length) { tbody.innerHTML = '<tr><td colspan="3" style="text-align:center;color:rgba(255,255,255,0.12)">No payroll history</td></tr>'; return; }
        tbody.innerHTML = rows.map(r => `
            <tr><td>${dateStr(r.created_at)}</td><td>${cid(r.performed_by_name)}</td><td>${cid(r.details)}</td></tr>
        `).join('');
    });
}

function loadArmory() {
    api('nuiGetArmory').then(items => {
        const tbody = document.getElementById('armoryBody');
        if (!items || !items.length) { tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:rgba(255,255,255,0.12)">No armory items</td></tr>'; return; }
        tbody.innerHTML = items.map(i => `
            <tr>
                <td>${cid(i.item_name)}</td>
                <td>${cid(i.label)}</td>
                <td><span class="status-badge ${i.rank > 0 ? 'active' : 'online'}">${i.rank > 0 ? 'Rank ' + i.rank : 'All'}</span></td>
                <td>${i.price > 0 ? '$' + i.price : 'Free'}</td>
                <td>${cid(i.category)}</td>
                <td>
                    <button class="cids-btn secondary" style="padding:4px 10px;font-size:10px" onclick="editArmoryItem(${i.id})">Edit</button>
                    <button class="cids-btn danger" style="padding:4px 10px;font-size:10px" onclick="removeArmoryItem(${i.id})">Remove</button>
                </td>
            </tr>
        `).join('');
    });
}

function showAddArmoryItem() {
    modal('Add Armory Item', [
        { key: 'itemName', label: 'Item Name', placeholder: 'e.g. weapon_pistol' },
        { key: 'label', label: 'Label', placeholder: 'e.g. Service Pistol' },
        { key: 'rank', label: 'Min Rank', placeholder: '0 = everyone' },
        { key: 'price', label: 'Price', placeholder: '0 = free' },
        { key: 'category', label: 'Category', placeholder: 'e.g. weapons, ammo, cid' }
    ], d => {
        api('nuiAddArmoryItem', { itemName: d.itemName, label: d.label, rank: parseInt(d.rank) || 0, price: parseInt(d.price) || 0, category: d.category }).then(r => { if (r.success) { loadArmory(); toast('Item added', 'success'); } });
    });
}

function editArmoryItem(id) {
    api('nuiUpdateArmoryItem', { id: id, label: prompt('New label:'), rank: parseInt(prompt('New rank:') || '0'), price: parseInt(prompt('New price:') || '0'), category: prompt('New category:') }).then(r => { if (r.success) { loadArmory(); toast('Item updated', 'success'); } });
}

function removeArmoryItem(id) {
    modal('Remove Item #' + id + '?', [
        { key: 'confirm', label: 'Type REMOVE to confirm', placeholder: 'REMOVE' }
    ], d => {
        if (d.confirm === 'REMOVE') {
            api('nuiRemoveArmoryItem', { id: id }).then(r => { if (r.success) { loadArmory(); toast('Item removed', 'error'); } });
        }
    });
}

function loadCases() {
    api('nuiGetCases').then(cases => {
        const tbody = document.getElementById('casesBody');
        if (!cases || !cases.length) { tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:rgba(255,255,255,0.12)">No cases</td></tr>'; return; }
        tbody.innerHTML = cases.map(c => `
            <tr>
                <td>#${c.id}</td><td>${cid(c.title)}</td><td>${cid(c.assigned_to)}</td>
                <td><span class="status-badge ${c.status === 'open' ? 'active' : 'closed'}">${(c.status || 'open').toUpperCase()}</span></td>
                <td>${dateStr(c.created_at)}</td>
                <td>${c.status !== 'closed' ? '<button class="cids-btn warning" style="padding:4px 10px;font-size:10px" onclick="closeCase(' + c.id + ')">Close</button>' : ''}</td>
            </tr>
        `).join('');
    });
}

function showCreateCase() {
    modal('Create Investigation Case', [
        { key: 'title', label: 'Title', placeholder: 'Case title' },
        { key: 'description', label: 'Description', placeholder: 'Case details' },
        { key: 'assignedTo', label: 'Assigned To (CID)', placeholder: 'Citizen ID of agent' }
    ], d => {
        api('nuiCreateCase', d).then(r => { if (r.success) { loadCases(); toast('Case created', 'success'); } });
    });
}

function closeCase(id) {
    modal('Close Case #' + id + '?', [
        { key: 'confirm', label: 'Type CLOSE to confirm', placeholder: 'CLOSE' }
    ], d => {
        if (d.confirm === 'CLOSE') {
            api('nuiCloseCase', { caseId: id }).then(r => { if (r.success) { loadCases(); toast('Case closed', 'info'); } });
        }
    });
}

function loadWarrants() {
    api('nuiGetWarrants').then(warrants => {
        const tbody = document.getElementById('warrantsBody');
        if (!warrants || !warrants.length) { tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:rgba(255,255,255,0.12)">No warrants</td></tr>'; return; }
        tbody.innerHTML = warrants.map(w => `
            <tr>
                <td>#${w.id}</td><td>${cid(w.target_name)} (${cid(w.target_cid)})</td><td>${cid(w.crime)}</td>
                <td><span class="status-badge ${w.status === 'active' ? 'active' : 'closed'}">${(w.status || 'active').toUpperCase()}</span></td>
                <td>${dateStr(w.created_at)}</td>
                <td>${w.status !== 'closed' ? '<button class="cids-btn warning" style="padding:4px 10px;font-size:10px" onclick="closeWarrant(' + w.id + ')">Close</button>' : ''}</td>
            </tr>
        `).join('');
    });
}

function showIssueWarrant() {
    modal('Issue Arrest Warrant', [
        { key: 'targetName', label: 'Target Name', placeholder: 'Full name' },
        { key: 'targetCid', label: 'Target Citizen ID', placeholder: 'Optional' },
        { key: 'crime', label: 'Crime', placeholder: 'e.g. Grand Theft Auto' }
    ], d => {
        api('nuiIssueWarrant', d).then(r => { if (r.success) { loadWarrants(); toast('Warrant issued', 'success'); } });
    });
}

function closeWarrant(id) {
    modal('Close Warrant #' + id + '?', [
        { key: 'confirm', label: 'Type CLOSE to confirm', placeholder: 'CLOSE' }
    ], d => {
        if (d.confirm === 'CLOSE') {
            api('nuiCloseWarrant', { warrantId: id }).then(r => { if (r.success) { loadWarrants(); toast('Warrant closed', 'info'); } });
        }
    });
}

function loadBOLOs() {
    api('nuiGetBOLOs').then(bolos => {
        const tbody = document.getElementById('bolosBody');
        if (!bolos || !bolos.length) { tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;color:rgba(255,255,255,0.12)">No BOLOs</td></tr>'; return; }
        tbody.innerHTML = bolos.map(b => `
            <tr>
                <td><span class="status-badge active">${(b.type || 'person').toUpperCase()}</span></td>
                <td>${b.plate ? 'Plate: ' + b.plate : cid(b.description)}</td>
                <td>${cid(b.reason)}</td>
                <td><span class="status-badge ${b.active ? 'active' : 'closed'}">${b.active ? 'ACTIVE' : 'REMOVED'}</span></td>
                <td>${b.active ? '<button class="cids-btn danger" style="padding:4px 10px;font-size:10px" onclick="removeBOLO(' + b.id + ')">Remove</button>' : ''}</td>
            </tr>
        `).join('');
    });
}

function showCreateBOLO() {
    modal('Create BOLO', [
        { key: 'type', label: 'Type', type: 'select', options: [{value:'vehicle',label:'Vehicle'},{value:'person',label:'Person'},{value:'plate',label:'Plate'}] },
        { key: 'plate', label: 'Plate (if vehicle)', placeholder: 'Plate number' },
        { key: 'description', label: 'Description', placeholder: 'Vehicle / person description' },
        { key: 'reason', label: 'Reason', placeholder: 'Why BOLO?' }
    ], d => {
        api('nuiCreateBOLO', d).then(r => { if (r.success) { loadBOLOs(); toast('BOLO created', 'success'); } });
    });
}

function removeBOLO(id) {
    modal('Remove BOLO #' + id + '?', [
        { key: 'confirm', label: 'Type REMOVE to confirm', placeholder: 'REMOVE' }
    ], d => {
        if (d.confirm === 'REMOVE') {
            api('nuiRemoveBOLO', { boloId: id }).then(r => { if (r.success) { loadBOLOs(); toast('BOLO removed', 'error'); } });
        }
    });
}

function searchPerson() {
    const query = document.getElementById('personSearchInput').value.trim();
    if (!query) return;
    api('nuiSearchPerson', { query: query }).then(results => {
        const container = document.getElementById('personResults');
        if (!results || !results.length) {
            container.innerHTML = '<div style="color:rgba(255,255,255,0.12);text-align:center;padding:20px">No results found</div>';
            return;
        }
        container.innerHTML = results.map(p => `
            <div class="person-card" onclick="showPersonDetail('${p.citizenid}')" style="animation:fadeInUp 0.2s ease both">
                <div class="name">${cid(p.firstname)} ${cid(p.lastname)}</div>
                <div class="sub">CID: ${cid(p.citizenid)} | Phone: ${cid(p.phone_number)}</div>
            </div>
        `).join('');
    });
}

function showPersonDetail(targetCid) {
    api('nuiGetPersonNotes', { targetCid: targetCid }).then(data => {
        const notes = data.notes || [];
        const records = data.records || [];
        const overlay = document.createElement('div');
        overlay.className = 'cids-modal-overlay';
        overlay.innerHTML = `
            <div class="cids-modal" style="width:500px">
                <h3>Person Details: ${targetCid}</h3>
                <div class="panel-subtitle" style="margin-top:12px">Criminal Record (${records.length})</div>
                ${records.length ? records.map(r => `<div class="record-item">${cid(r.offense)} — Fine: $${(r.fine||0)} — ${dateStr(r.created_at)}</div>`).join('') : '<div style="color:rgba(255,255,255,0.12);font-size:12px">No criminal record</div>'}
                <div class="panel-subtitle" style="margin-top:12px">CID Notes (${notes.length})</div>
                ${notes.length ? notes.map(n => `<div class="note-item">${cid(n.note)}<div class="note-meta">By ${cid(n.flagged_by)} — ${dateStr(n.created_at)}</div></div>`).join('') : '<div style="color:rgba(255,255,255,0.12);font-size:12px">No notes</div>'}
                <div style="margin-top:12px;display:flex;gap:8px">
                    <input class="cids-input" id="newNoteInput" placeholder="Add a note/flag...">
                    <button class="cids-btn primary" onclick="addPersonNote('${targetCid}')">Add Note</button>
                </div>
                <div class="cids-modal-actions" style="margin-top:12px">
                    <button class="cids-btn secondary" onclick="this.closest('.cids-modal-overlay').remove()">Close</button>
                </div>
            </div>
        `;
        document.body.appendChild(overlay);
        window._personTarget = targetCid;
        overlay.addEventListener('click', (e) => { if (e.target === overlay) overlay.remove(); });
    });
}

function addPersonNote(targetCid) {
    const note = document.getElementById('newNoteInput')?.value.trim();
    if (!note) return;
    api('nuiAddPersonNote', { targetCid: targetCid, note: note }).then(r => {
        if (r.success) {
            document.querySelector('.cids-modal-overlay')?.remove();
            showPersonDetail(targetCid);
            toast('Note added', 'success');
        }
    });
}

function loadVehicleSpawns() {
    api('nuiGetVehicleSpawns').then(data => {
        const total = data.total || 0;
        const spawns = data.spawns || [];
        document.getElementById('spawnTotal').textContent = total.toLocaleString();
        const tbody = document.getElementById('spawnBody');
        if (!spawns.length) { tbody.innerHTML = '<tr><td colspan="3" style="text-align:center;color:rgba(255,255,255,0.12)">No vehicles spawned yet</td></tr>'; return; }
        tbody.innerHTML = spawns.map(s => `
            <tr><td>${cid(s.spawner_name)}</td><td>${cid(s.vehicle_label) || cid(s.vehicle_model)}</td><td>${dateStr(s.spawned_at)}</td></tr>
        `).join('');
    });
}

function loadAuditLog() {
    api('nuiGetAuditLog').then(rows => {
        const tbody = document.getElementById('auditBody');
        if (!rows || !rows.length) { tbody.innerHTML = '<tr><td colspan="4" style="text-align:center;color:rgba(255,255,255,0.12)">No audit log entries</td></tr>'; return; }
        tbody.innerHTML = rows.map(r => `
            <tr style="animation:fadeInUp 0.2s ease both"><td>${cid(r.action)}</td><td>${cid(r.details || r.target)}</td><td>${cid(r.performed_by_name)}</td><td>${dateStr(r.created_at)}</td></tr>
        `).join('');
    });
}

function sendAnnouncement() {
    const msg = document.getElementById('announceInput').value.trim();
    if (!msg) return;
    modal('Confirm Announcement', [
        { key: 'confirm', label: 'Type SEND to announce', placeholder: 'SEND' }
    ], d => {
        if (d.confirm === 'SEND') {
            api('nuiSendAnnouncement', { message: msg }).then(r => {
                if (r.success) { document.getElementById('announceInput').value = ''; toast('Announcement sent!', 'success'); }
            });
        }
    });
}

function GetParentResourceName() { return RESOURCE; }
