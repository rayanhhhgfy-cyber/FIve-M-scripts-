let currentOperation = null
let teamMembers = {}

window.addEventListener('message', function(event) {
    const data = event.data
    switch (data.action) {
        case 'openDashboard':
            currentOperation = data.data
            openDashboard()
            break
        case 'updateGPS':
            teamMembers = data.data || {}
            updateTeamDisplay()
            updateMap()
            break
        case 'closeDashboard':
            document.getElementById('opsConsole').className = 'ops-hidden'
            break
    }
})

function openDashboard() {
    showSkeleton(true)
    const el = document.getElementById('opsConsole')
    el.className = 'ops-visible'
    document.getElementById('opsName').textContent = currentOperation.name + ' (#' + currentOperation.id + ')'

    const threatColor = getThreatColor(currentOperation.threat_level)
    const badge = document.getElementById('threatBadge')
    badge.textContent = (currentOperation.threat_level || 'LOW').toUpperCase()
    badge.style.background = threatColor + '15'
    badge.style.border = '1px solid ' + threatColor
    badge.style.color = threatColor

    if (currentOperation.objectives) {
        const lines = currentOperation.objectives.split('\n').filter(l => l.trim())
        const container = document.getElementById('objectivesDisplay')
        container.innerHTML = ''
        lines.forEach(function(text, i) {
            const item = document.createElement('div')
            item.className = 'objective-item'
            item.style.animationDelay = (i * 0.05) + 's'
            item.innerHTML = '<input type="checkbox" class="objective-checkbox"><span class="objective-text">' + escapeHtml(text) + '</span>'
            container.appendChild(item)
        })
        const checked = container.querySelectorAll('.objective-checkbox:checked').length
        const progress = Math.round((checked / lines.length) * 100)
        const pWrap = document.createElement('div')
        pWrap.className = 'objective-progress-wrap'
        pWrap.innerHTML = '<div class="objective-progress-bar"><div class="objective-progress-fill" style="width:' + progress + '%"></div></div><div class="objective-progress-label">' + progress + '% Complete</div>'
        container.appendChild(pWrap)
    }

    if (currentOperation.timeline) {
        try {
            const timeline = typeof currentOperation.timeline === 'string' ? JSON.parse(currentOperation.timeline) : currentOperation.timeline
            if (Array.isArray(timeline) && timeline.length > 0) {
                updateTimeline(timeline)
            }
        } catch(e) {}
    }

    document.getElementById('mapStatus').textContent = 'Receiving GPS data...'
    document.getElementById('teamCount').textContent = '0 agents online'
    document.getElementById('teamCountBadge').textContent = '0'
    document.getElementById('opsStatusBadge').textContent = 'ACTIVE'

    setTimeout(function() { showSkeleton(false) }, 600)
}

function showSkeleton(show) {
    const skelTeam = document.getElementById('teamSkeleton')
    const skelObj = document.getElementById('objSkeleton')
    const teamEmpty = document.getElementById('teamEmpty')
    const objEmpty = document.getElementById('objEmpty')
    if (skelTeam) skelTeam.style.display = show ? 'flex' : 'none'
    if (skelObj) skelObj.style.display = show ? 'flex' : 'none'
    if (teamEmpty) teamEmpty.style.display = 'none'
    if (objEmpty && !currentOperation.objectives) objEmpty.style.display = show ? 'none' : 'block'
}

function closeDashboard() {
    document.getElementById('opsConsole').className = 'ops-hidden'
    fetch('https://' + GetParentResourceName() + '/closeDashboard', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    })
}

function getThreatColor(level) {
    const colors = { low: '#27c93f', medium: '#ffb86b', high: '#ff6b35', critical: '#ff3b3b' }
    return colors[level] || '#27c93f'
}

function updateTeamDisplay() {
    const list = document.getElementById('teamList')
    const teamCount = document.getElementById('teamCount')
    const teamCountBadge = document.getElementById('teamCountBadge')
    const cids = Object.keys(teamMembers)
    teamCount.textContent = cids.length + ' agents online'
    if (teamCountBadge) teamCountBadge.textContent = cids.length

    if (cids.length === 0) {
        setTeamEmpty('No team GPS data')
        return
    }

    document.querySelectorAll('.team-member').forEach(function(m) { m.remove() })
    document.getElementById('teamEmpty').style.display = 'none'

    cids.forEach(function(cid, i) {
        const member = teamMembers[cid]
        const memberEl = document.createElement('div')
        memberEl.className = 'team-member'
        memberEl.style.animationDelay = (i * 0.05) + 's'
        const coords = member.coords ? Math.round(member.coords.x) + ', ' + Math.round(member.coords.y) : 'No GPS'
        memberEl.innerHTML = '<div class="member-dot"></div><div class="member-info"><span class="member-name">' + (member.name || cid) + '</span><span class="member-coords">' + coords + '</span></div><span class="member-status">Online</span>'
        list.appendChild(memberEl)
    })
}

function setTeamEmpty(msg) {
    const empty = document.getElementById('teamEmpty')
    if (empty) {
        empty.textContent = msg
        empty.style.display = 'block'
    }
    document.querySelectorAll('.team-member').forEach(function(m) { m.remove() })
}

function updateMap() {
    const mapGrid = document.getElementById('mapGrid')
    document.querySelectorAll('.map-marker').forEach(function(m) { m.remove() })
    const cids = Object.keys(teamMembers)
    if (cids.length === 0) {
        document.getElementById('mapStatus').textContent = 'Waiting for team GPS data...'
        return
    }
    document.getElementById('mapStatus').textContent = cids.length + ' team members tracked'
    cids.forEach(function(cid) {
        const member = teamMembers[cid]
        if (!member.coords) return
        const marker = document.createElement('div')
        marker.className = 'map-marker'
        marker.title = member.name + ' [' + Math.round(member.coords.x) + ', ' + Math.round(member.coords.y) + ']'
        marker.innerHTML = '<span class="marker-label">' + (member.name ? member.name.charAt(0).toUpperCase() : '?') + '</span>'
        mapGrid.appendChild(marker)
    })
}

function updateTimeline(timeline) {
    const feed = document.getElementById('timelineFeed')
    feed.innerHTML = ''
    timeline.forEach(function(entry, i) {
        const item = document.createElement('div')
        item.className = 'timeline-item'
        item.style.animationDelay = (i * 0.05) + 's'
        const time = new Date((entry.timestamp || 0) * 1000).toLocaleTimeString()
        item.innerHTML = '<div class="timeline-dot"></div><span class="timeline-time">' + time + '</span><span class="timeline-event">' + escapeHtml(entry.event) + '</span>'
        feed.appendChild(item)
    })
}

function addTimelineEvent() {
    if (!currentOperation) return
    const eventText = prompt('Enter timeline event:')
    if (!eventText || eventText.trim() === '') return
    fetch('https://' + GetParentResourceName() + '/addTimelineEvent', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ opId: currentOperation.id, event: eventText })
    })
}

function escapeHtml(str) {
    if (!str) return ''
    return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') { closeDashboard() }
})

function GetParentResourceName() { return 'cid-operations' }
