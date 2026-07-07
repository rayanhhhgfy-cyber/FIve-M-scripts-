let activeBugs = []
let historyLog = []

window.addEventListener('message', function(event) {
    const data = event.data
    switch (data.action) {
        case 'openConsole':
            document.getElementById('console').className = 'console-visible'
            break
        case 'closeConsole':
            document.getElementById('console').className = 'console-hidden'
            break
        case 'updateBugs':
            activeBugs = data.data || []
            updateBugDisplay()
            break
    }
})

function closeConsole() {
    document.getElementById('console').className = 'console-hidden'
    fetch('https://' + GetParentResourceName() + '/closeConsole', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    })
}

function updateBugDisplay() {
    const feedGrid = document.getElementById('feedGrid')
    const bugBody = document.getElementById('bugTableBody')
    const gpsList = document.getElementById('gpsList')
    const bugCount = document.getElementById('bugCount')
    document.getElementById('lastUpdate').textContent = 'Updated: ' + new Date().toLocaleTimeString()

    const cameras = activeBugs.filter(b => b.bug_type === 'surveillance_camera')
    const audioBugs = activeBugs.filter(b => b.bug_type === 'audio_bug')
    const gpsTrackers = activeBugs.filter(b => b.bug_type === 'gps_tracker')

    bugCount.textContent = activeBugs.length + ' Active (' + cameras.length + ' Cam, ' + audioBugs.length + ' Aud, ' + gpsTrackers.length + ' GPS)'

    if (document.getElementById('gpsCount')) {
        document.getElementById('gpsCount').textContent = gpsTrackers.length + ' active'
    }

    if (activeBugs.length === 0) {
        feedGrid.innerHTML = '<div class="feed-empty">No active surveillance bugs deployed.</div>'
    } else {
        feedGrid.innerHTML = ''
        activeBugs.forEach(function(bug) {
            const feedCard = document.createElement('div')
            feedCard.className = 'feed-card'
            const typeLabel = bug.bug_type === 'surveillance_camera' ? 'Camera' : bug.bug_type === 'audio_bug' ? 'Audio' : 'GPS'
            const coords = '[' + Math.round(bug.pos_x) + ', ' + Math.round(bug.pos_y) + ']'

            let feedContent = ''
            if (bug.bug_type === 'surveillance_camera') {
                feedContent = '<div class="feed-feed camera-feed"><div class="feed-scanlines"></div><span class="feed-label">LIVE FEED</span></div>'
            } else if (bug.bug_type === 'audio_bug') {
                feedContent = '<div class="feed-feed audio-feed"><div class="audio-waveform">' + Array(12).fill(0).map(function() { return '<div class="audio-bar"></div>' }).join('') + '</div></div>'
            } else {
                feedContent = '<div class="feed-feed gps-feed"><span class="gps-coord-line">Lat: ' + bug.pos_x.toFixed(4) + '</span><span class="gps-coord-line">Lon: ' + bug.pos_y.toFixed(4) + '</span></div>'
            }

            feedCard.innerHTML = `
                <div class="feed-header">
                    <span class="feed-type-badge type-${bug.bug_type.replace('_', '-')}">${typeLabel}</span>
                    <span class="feed-id">#${bug.id}</span>
                    <button class="feed-deactivate" onclick="deactivateBug(${bug.id})">✕</button>
                </div>
                ${feedContent}
                <div class="feed-info">
                    <span><span class="status-dot"></span>${coords}</span>
                    <span>${getDurationRemaining(bug.placed_at, bug.expires_at)}</span>
                </div>
            `
            feedGrid.appendChild(feedCard)
        })
    }

    bugBody.innerHTML = ''
    if (activeBugs.length === 0) {
        bugBody.innerHTML = '<tr><td colspan="6" class="empty-row">No bugs deployed</td></tr>'
    } else {
        activeBugs.forEach(function(bug) {
            const tr = document.createElement('tr')
            const remaining = getDurationRemaining(bug.placed_at, bug.expires_at)
            tr.innerHTML = `
                <td><span class="mono">#${bug.id}</span></td>
                <td><span class="type-badge badge-${bug.bug_type.replace('_', '-')}">${bug.bug_type.replace('_', ' ')}</span></td>
                <td>${Math.round(bug.pos_x)}, ${Math.round(bug.pos_y)}</td>
                <td>${remaining}</td>
                <td>${bug.placed_by}</td>
                <td><button class="deactivate-btn" onclick="deactivateBug(${bug.id})">Deactivate</button></td>
            `
            bugBody.appendChild(tr)
        })
    }

    gpsList.innerHTML = ''
    if (gpsTrackers.length === 0) {
        gpsList.innerHTML = '<p class="gps-empty">No active GPS trackers.</p>'
    } else {
        gpsTrackers.forEach(function(t) {
            const gpsItem = document.createElement('div')
            gpsItem.className = 'gps-item'
            gpsItem.innerHTML = `
                <div class="gps-dot"></div>
                <span class="gps-coords">[${t.pos_x.toFixed(2)}, ${t.pos_y.toFixed(2)}]</span>
                <span class="gps-status">Active</span>
            `
            gpsList.appendChild(gpsItem)
        })
    }
}

function getDurationRemaining(placedAt, expiresAt) {
    const now = Math.floor(Date.now() / 1000)
    const remaining = expiresAt - now
    if (remaining <= 0) return 'Expired'
    const hours = Math.floor(remaining / 3600)
    const minutes = Math.floor((remaining % 3600) / 60)
    if (hours > 24) {
        const days = Math.floor(hours / 24)
        return days + 'd ' + (hours % 24) + 'h'
    }
    return hours + 'h ' + minutes + 'm'
}

function deactivateBug(bugId) {
    fetch('https://' + GetParentResourceName() + '/deactivateBug', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ bugId: bugId })
    })
}

document.querySelectorAll('.tab').forEach(function(tab) {
    tab.addEventListener('click', function() {
        document.querySelectorAll('.tab').forEach(function(t) { t.className = 'tab' })
        this.className = 'tab active'
        document.querySelectorAll('.tab-content').forEach(function(tc) { tc.className = 'tab-content' })
        document.getElementById('tab-' + this.dataset.tab).className = 'tab-content active'
    })
})

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' || e.key === 'u') {
        closeConsole()
    }
})



function clearHistory() {
    historyLog = []
    document.getElementById('historyFeed').innerHTML = '<div class="history-empty">No surveillance history recorded.</div>'
}

function addHistory(action, detail) {
    historyLog.unshift({ action: action, detail: detail, time: new Date().toLocaleTimeString() })
    const feed = document.getElementById('historyFeed')
    if (historyLog.length === 0) {
        feed.innerHTML = '<div class="history-empty">No surveillance history recorded.</div>'
        return
    }
    feed.innerHTML = ''
    historyLog.forEach(function(entry) {
        const item = document.createElement('div')
        item.className = 'history-item'
        item.innerHTML = `
            <span class="history-icon">◈</span>
            <div>
                <div class="history-action">${entry.action}</div>
                <div class="history-detail">${entry.detail}</div>
            </div>
            <span class="history-time">${entry.time}</span>
        `
        feed.appendChild(item)
    })
}
