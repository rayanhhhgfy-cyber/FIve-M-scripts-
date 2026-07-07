let activeCalls = [];
let mySrc = null;
let prevCallCount = 0;

window.addEventListener('message', function(event) {
    var d = event.data;
    if (d.action === 'showHud') {
        document.getElementById('dispatchHud').style.display = 'block';
        mySrc = d.source;
        if (d.calls) updateCalls(d.calls);
    }
    if (d.action === 'hideHud') {
        document.getElementById('dispatchHud').style.display = 'none';
    }
    if (d.action === 'updateCalls') {
        if (d.calls) updateCalls(d.calls);
    }
});

function updateCalls(calls) {
    activeCalls = calls || [];
    var container = document.getElementById('hudCalls');
    var countEl = document.getElementById('callsCount');
    countEl.textContent = activeCalls.length;

    var isNewCall = activeCalls.length > prevCallCount;
    prevCallCount = activeCalls.length;

    if (activeCalls.length === 0) {
        container.innerHTML = '<div class="empty-state">No active calls</div>';
        return;
    }

    var sorted = activeCalls.slice().sort(function(a, b) {
        var pa = getPriority(a);
        var pb = getPriority(b);
        if (pa !== pb) return pa - pb;
        return (b.createdAt || 0) - (a.createdAt || 0);
    });

    var html = '';
    for (var i = 0; i < sorted.length; i++) {
        var call = sorted[i];
        var priorityClass = getPriorityClass(call);
        var priorityLabel = getPriorityLabel(call);
        var statusLabel = call.status === 'pending' ? 'PENDING' : call.status === 'dispatched' ? 'DISPATCHED' : 'ON SCENE';
        var callerInfo = call.callerName ? escapeHtml(call.callerName) : 'Anonymous';
        var typeLabel = call.type || call.description || 'Emergency';
        var timeAgo = call.createdAt ? getTimeAgo(call.createdAt) : '';
        var pulseClass = isNewCall ? 'pulse-new' : '';

        html += '<div class="hud-call priority-' + priorityClass + ' ' + pulseClass + '">';
        html += '<div class="hud-call-top">';
        html += '<span class="hud-call-type">#' + call.id + ' ' + escapeHtml(typeLabel) + '</span>';
        html += '<span class="hud-call-priority ' + priorityClass + '">' + priorityLabel + '</span>';
        html += '</div>';
        html += '<div class="hud-call-info">';
        html += '<span>' + escapeHtml(callerInfo) + ' &middot; ' + timeAgo + '</span>';
        html += '<span class="hud-call-location">' + (call.coords ? '\u2302 ' + Math.round(call.coords.x) + ', ' + Math.round(call.coords.y) : '') + '</span>';
        html += '</div>';

        if (call.status === 'pending') {
            html += '<div class="hud-call-actions">';
            html += '<button class="hud-call-btn accept" onclick="acceptCall(' + call.id + ')">Accept</button>';
            html += '<button class="hud-call-btn skip" onclick="skipCall(' + call.id + ')">Skip</button>';
            html += '</div>';
        }

        html += '</div>';
    }
    container.innerHTML = html;

    container.scrollTop = container.scrollHeight;
}

function getPriority(call) {
    if (!call || call.status === 'pending') return 0;
    if (call.status === 'dispatched') return 1;
    return 2;
}

function getPriorityClass(call) {
    if (!call || call.status === 'pending') return 'high';
    if (call.status === 'dispatched') return 'medium';
    return 'low';
}

function getPriorityLabel(call) {
    if (!call || call.status === 'pending') return 'EMERGENCY';
    if (call.status === 'dispatched') return 'DISPATCHED';
    return 'ON SCENE';
}

function getTimeAgo(timestamp) {
    var diff = Math.floor(Date.now() / 1000) - timestamp;
    if (diff < 60) return diff + 's ago';
    var mins = Math.floor(diff / 60);
    if (mins < 60) return mins + 'm ago';
    var hrs = Math.floor(mins / 60);
    return hrs + 'h ago';
}

function acceptCall(callId) {
    fetch('https://dispatch-system/acceptCall', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ callId: callId })
    });
}

function skipCall(callId) {
    fetch('https://dispatch-system/skipCall', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ callId: callId })
    });
}

function sendPanic() {
    fetch('https://dispatch-system/sendPanic', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

var minimized = false;

function toggleMinimize() {
    minimized = !minimized;
    var hud = document.getElementById('dispatchHud');
    var btn = document.getElementById('minimizeBtn');
    if (minimized) {
        hud.classList.add('minimized');
        btn.textContent = '\u25A1';
        btn.title = 'Expand';
    } else {
        hud.classList.remove('minimized');
        btn.textContent = '_';
        btn.title = 'Minimize';
    }
}

function escapeHtml(str) {
    if (!str) return '';
    return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}
