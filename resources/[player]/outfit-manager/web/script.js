let currentOutfits = [];
let pendingDeleteIndex = -1;

window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'open') {
        currentOutfits = data.outfits || [];
        renderOutfits();
    }
});

function renderOutfits() {
    const list = document.getElementById('outfit-list');
    const empty = document.getElementById('empty-state');

    list.innerHTML = '';

    if (currentOutfits.length === 0) {
        empty.classList.remove('hidden');
        return;
    }

    empty.classList.add('hidden');

    currentOutfits.forEach(function(outfit, index) {
        const item = document.createElement('div');
        item.className = 'outfit-item';

        const dateStr = outfit.createdAt
            ? new Date(outfit.createdAt * 1000).toLocaleDateString()
            : 'Unknown';

        const slotStr = outfit.slot ? 'Slot ' + outfit.slot : '';

        item.innerHTML = `
            <div class="outfit-info">
                <span class="outfit-name">${escapeHtml(outfit.name)}</span>
                ${slotStr ? '<span class="outfit-slot">' + slotStr + '</span>' : ''}
                <span class="outfit-date">Saved ${dateStr}</span>
            </div>
            <div class="outfit-actions">
                <button class="btn btn-red btn-sm" onclick="event.stopPropagation(); confirmDeleteOutfit(${index})">Delete</button>
            </div>
        `;

        item.addEventListener('click', function() {
            loadOutfit(index);
        });

        list.appendChild(item);
    });
}

function loadOutfit(index) {
    fetch('https://' + GetParentResourceName() + '/loadOutfit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ index: index })
    })
    .then(res => res.json())
    .then(data => {
        if (data.success) {
            showNotification('Outfit loaded: ' + data.name, 'success');
        }
    });
}

function confirmDeleteOutfit(index) {
    pendingDeleteIndex = index;
    document.getElementById('confirm-modal').classList.remove('hidden');
    document.getElementById('confirmDeleteBtn').onclick = function() {
        executeDelete();
    };
}

function closeModal() {
    document.getElementById('confirm-modal').classList.add('hidden');
    pendingDeleteIndex = -1;
}

function executeDelete() {
    const index = pendingDeleteIndex;
    closeModal();

    fetch('https://' + GetParentResourceName() + '/deleteOutfit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ index: index })
    })
    .then(res => res.json())
    .then(data => {
        if (data.success && data.outfits) {
            currentOutfits = data.outfits;
            renderOutfits();
            showNotification('Outfit deleted', 'info');
        }
    });
}

function showSaveDialog() {
    document.getElementById('save-dialog').classList.remove('hidden');
    document.getElementById('outfit-name').value = '';
    setTimeout(function() {
        document.getElementById('outfit-name').focus();
    }, 100);
}

function hideSaveDialog() {
    document.getElementById('save-dialog').classList.add('hidden');
}

function confirmSave() {
    const name = document.getElementById('outfit-name').value.trim();
    if (!name) return;

    const spinner = document.getElementById('saveSpinner');
    spinner.classList.remove('hidden');

    fetch('https://' + GetParentResourceName() + '/saveOutfit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: name })
    })
    .then(res => res.json())
    .then(data => {
        spinner.classList.add('hidden');
        hideSaveDialog();
        if (data.success && data.outfits) {
            currentOutfits = data.outfits;
            renderOutfits();
            showNotification('Outfit saved: ' + name, 'success');
        } else {
            showNotification(data.msg || 'Failed to save outfit', 'error');
        }
    });
}

function closePanel() {
    fetch('https://' + GetParentResourceName() + '/close', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        if (!document.getElementById('confirm-modal').classList.contains('hidden')) {
            closeModal();
            return;
        }
        fetch('https://' + GetParentResourceName() + '/escape', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
});

function showNotification(msg, type) {
    const body = JSON.stringify({
        type: type === 'success' ? 'success' : type === 'error' ? 'error' : 'info',
        title: 'Outfit Manager',
        description: msg
    });
    fetch('https://cfx-notification/ox_lib:notify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: body
    }).catch(function() {});
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function GetParentResourceName() {
    return 'outfit-manager';
}
