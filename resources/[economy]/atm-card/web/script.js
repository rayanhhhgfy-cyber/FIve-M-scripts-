let accounts = [];
let selectedAccountId = null;
let atmFee = 2;

window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'open') {
        accounts = data.accounts || [];
        atmFee = data.atmFee || 2;
        document.getElementById('withdraw-fee').textContent = atmFee;

        document.getElementById('account-select').classList.remove('hidden');
        document.getElementById('atm-actions').classList.add('hidden');
        document.getElementById('deposit-form').classList.add('hidden');
        document.getElementById('withdraw-form').classList.add('hidden');
        document.getElementById('status-msg').classList.add('hidden');

        renderAccounts();
    }
});

function renderAccounts() {
    const list = document.getElementById('account-list');
    list.innerHTML = '';

    if (accounts.length === 0) {
        list.innerHTML = '<div style="color:#666;text-align:center;padding:20px;">No accounts found</div>';
        return;
    }

    accounts.forEach(function(acc) {
        const card = document.createElement('div');
        card.className = 'account-card';
        card.innerHTML = `
            <div class="account-name">${escapeHtml(acc.account_name)}</div>
            <div class="account-type">${escapeHtml(acc.account_type)}</div>
            <div class="account-balance">$${formatNumber(acc.balance)}</div>
            <div class="account-iban">${escapeHtml(acc.iban)}</div>
        `;
        card.addEventListener('click', function() {
            selectAccount(acc.id);
        });
        list.appendChild(card);
    });
}

function selectAccount(accountId) {
    selectedAccountId = accountId;
    const acc = accounts.find(function(a) { return a.id === accountId; });
    if (!acc) return;

    document.getElementById('account-select').classList.add('hidden');
    document.getElementById('atm-actions').classList.remove('hidden');

    document.getElementById('account-info').innerHTML = `
        <div class="account-name">${escapeHtml(acc.account_name)}</div>
        <div class="account-balance">Balance: $${formatNumber(acc.balance)}</div>
    `;
}

function backToAccounts() {
    document.getElementById('atm-actions').classList.add('hidden');
    document.getElementById('account-select').classList.remove('hidden');
}

function showDeposit() {
    document.getElementById('atm-actions').classList.add('hidden');
    document.getElementById('deposit-form').classList.remove('hidden');
    document.getElementById('deposit-amount').value = '';
    document.getElementById('deposit-amount').focus();
    hideStatus();
}

function showWithdraw() {
    document.getElementById('atm-actions').classList.add('hidden');
    document.getElementById('withdraw-form').classList.remove('hidden');
    document.getElementById('withdraw-amount').value = '';
    document.getElementById('withdraw-amount').focus();
    hideStatus();
}

function hideForms() {
    document.getElementById('deposit-form').classList.add('hidden');
    document.getElementById('withdraw-form').classList.add('hidden');
    document.getElementById('atm-actions').classList.remove('hidden');
    hideStatus();
}

function confirmDeposit() {
    const amount = parseInt(document.getElementById('deposit-amount').value);
    if (!amount || amount <= 0) return;

    fetch('https://' + GetParentResourceName() + '/deposit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ accountId: selectedAccountId, amount: amount })
    })
    .then(res => res.json())
    .then(function(data) {
        if (data.success && data.accounts) {
            accounts = data.accounts;
            selectAccount(selectedAccountId);
            showStatus('Deposit successful', 'success');
        } else {
            showStatus('Transaction failed', 'error');
        }
    });
}

function confirmWithdraw() {
    const amount = parseInt(document.getElementById('withdraw-amount').value);
    if (!amount || amount <= 0) return;

    fetch('https://' + GetParentResourceName() + '/withdraw', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ accountId: selectedAccountId, amount: amount })
    })
    .then(res => res.json())
    .then(function(data) {
        if (data.success && data.accounts) {
            accounts = data.accounts;
            selectAccount(selectedAccountId);
            showStatus('Withdrawal successful', 'success');
        } else {
            showStatus('Insufficient funds or limit exceeded', 'error');
        }
    });
}

function showStatus(msg, type) {
    const el = document.getElementById('status-msg');
    el.textContent = msg;
    el.className = 'status-msg ' + type;
    el.classList.remove('hidden');
}

function hideStatus() {
    document.getElementById('status-msg').classList.add('hidden');
}

function closeATM() {
    fetch('https://' + GetParentResourceName() + '/close', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        fetch('https://' + GetParentResourceName() + '/escape', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
});

function formatNumber(n) {
    return n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function GetParentResourceName() {
    return 'atm-card';
}
