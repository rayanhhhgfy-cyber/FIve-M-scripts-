let garageData = null

window.addEventListener('message', function(event) {
    const data = event.data
    if (data.action === 'openGarage') {
        garageData = data.data
        document.getElementById('garage-ui').style.display = 'flex'
        document.getElementById('garage-title').textContent = garageData.garageName
        const badge = document.getElementById('garage-type-badge')
        badge.textContent = garageData.garageType
        if (garageData.garageType === 'impound') {
            badge.style.background = 'rgba(255, 50, 50, 0.15)'
            badge.style.color = '#ff3232'
        } else if (garageData.garageType === 'public') {
            badge.style.background = 'rgba(0, 200, 100, 0.15)'
            badge.style.color = '#00c864'
        } else {
            badge.style.background = 'rgba(0, 150, 255, 0.15)'
            badge.style.color = '#4a9eff'
        }
        loadVehicles()
    }
})

function loadVehicles() {
    fetch('https://' + GetParentResourceName() + '/garageGetVehicles', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).then(res => res.json()).then(vehicles => {
        renderVehicles(vehicles)
    })
}

function renderVehicles(vehicles) {
    const container = document.getElementById('vehicle-list')
    container.innerHTML = ''

    const stats = document.getElementById('garage-stats')

    if (garageData.garageType === 'impound') {
        stats.textContent = 'Impounded Vehicles'
        if (!vehicles || vehicles.length === 0) {
            container.innerHTML = '<div class="vehicle-empty">No impounded vehicles</div>'
            return
        }
        for (const v of vehicles) {
            const card = document.createElement('div')
            card.className = 'vehicle-card'
            card.innerHTML = '<div class="vehicle-info"><span class="vehicle-model">' + v.model + '</span><span class="vehicle-plate">' + v.plate + '</span><span class="vehicle-state state-impounded">Impounded' + (v.reason ? ' - ' + v.reason : '') + '</span></div><div class="vehicle-actions"><button class="veh-action-btn impound-btn" data-plate="' + v.plate + '" data-fee="' + (v.fee || 0) + '">Retrieve $' + (v.fee || 0) + '</button></div>'
            card.querySelector('.veh-action-btn').addEventListener('click', function() {
                fetch('https://' + GetParentResourceName() + '/garageRetrieveImpound', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ plate: this.dataset.plate })
                }).then(res => res.json()).then(result => {
                    if (result.success) {
                        loadVehicles()
                    }
                })
            })
            container.appendChild(card)
        }
        return
    }

    const stored = vehicles ? vehicles.filter(v => v.state === 'stored').length : 0
    const maxSlots = garageData.slots || '?'
    stats.textContent = 'Stored: ' + stored + ' / ' + maxSlots + ' | Total: ' + (vehicles ? vehicles.length : 0)

    if (!vehicles || vehicles.length === 0) {
        container.innerHTML = '<div class="vehicle-empty">No vehicles found</div>'
        return
    }

    for (const v of vehicles) {
        const card = document.createElement('div')
        card.className = 'vehicle-card'

        let stateClass = 'state-stored'
        let stateLabel = 'Stored'
        if (v.state === 'out') {
            stateClass = 'state-out'
            stateLabel = 'Out'
        } else if (v.state === 'impounded') {
            stateClass = 'state-impounded'
            stateLabel = 'Impounded'
        }

        let actionsHTML = ''
        if (v.state === 'stored') {
            actionsHTML += '<button class="veh-action-btn spawn-btn" data-plate="' + v.plate + '"><i class="fas fa-car"></i> Spawn</button>'
        }
        if (v.state === 'out') {
            actionsHTML += '<button class="veh-action-btn track-btn" data-plate="' + v.plate + '"><i class="fas fa-location-dot"></i> Track</button>'
        }

        card.innerHTML = '<div class="vehicle-info"><span class="vehicle-model">' + v.model + '</span><span class="vehicle-plate">' + v.plate + '</span><span class="vehicle-state ' + stateClass + '">' + stateLabel + '</span></div><div class="vehicle-actions">' + actionsHTML + '</div>'

        const spawnBtn = card.querySelector('.spawn-btn')
        if (spawnBtn) {
            spawnBtn.addEventListener('click', function() {
                fetch('https://' + GetParentResourceName() + '/garageSpawnVehicle', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ plate: this.dataset.plate })
                }).then(res => res.json()).then(result => {
                    if (result.success) {
                        loadVehicles()
                    }
                })
            })
        }

        const trackBtn = card.querySelector('.track-btn')
        if (trackBtn) {
            trackBtn.addEventListener('click', function() {
                fetch('https://' + GetParentResourceName() + '/garageTrackVehicle', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ plate: this.dataset.plate })
                })
            })
        }

        container.appendChild(card)
    }
}

document.getElementById('garage-store-btn').addEventListener('click', function() {
    fetch('https://' + GetParentResourceName() + '/garageStoreVehicle', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).then(res => res.json()).then(result => {
        if (result.success) {
            loadVehicles()
        }
    })
})

document.getElementById('garage-close').addEventListener('click', function() {
    fetch('https://' + GetParentResourceName() + '/garageClose', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    })
})

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        fetch('https://' + GetParentResourceName() + '/garageClose', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        })
    }
})

function GetParentResourceName() {
    return window.location.hostname
}
