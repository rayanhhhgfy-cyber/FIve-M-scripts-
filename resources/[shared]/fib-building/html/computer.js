window.addEventListener('message', function(event) {
    if (event.data.action === 'openComputer') {
        document.getElementById('monitor').style.display = 'flex';
        document.getElementById('terminalBody').scrollTop = 0;
        document.getElementById('cmdInput').value = '';
        document.getElementById('cmdInput').focus();
    }
});

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') closeComputer();
    if (e.key === 'Enter') {
        const input = document.getElementById('cmdInput');
        if (input && document.activeElement === input) {
            executeCommand(input.value.trim());
            input.value = '';
        }
    }
});

function executeCommand(cmd) {
    if (!cmd) return;
    appendLine('> ' + cmd, 'accent');

    fetch('https://' + GetParentResourceName() + '/runCommand', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ command: cmd })
    }).then(res => res.json()).then(data => {
        if (data.clear) {
            document.getElementById('terminalBody').innerHTML = '';
            return;
        }
        if (data.exit) return;
        if (data.lines) {
            for (const line of data.lines) {
                appendLine(line);
            }
        }
        document.getElementById('terminalBody').scrollTop = document.getElementById('terminalBody').scrollHeight;
    });
}

function appendLine(text, cls) {
    const body = document.getElementById('terminalBody');
    const div = document.createElement('div');
    div.className = 'line' + (cls ? ' ' + cls : '');
    div.textContent = text;
    body.appendChild(div);
    body.scrollTop = body.scrollHeight;
}

function closeComputer() {
    fetch('https://' + GetParentResourceName() + '/closeComputer', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
    document.getElementById('monitor').style.display = 'none';
}

function GetParentResourceName() { return 'fib-building'; }
