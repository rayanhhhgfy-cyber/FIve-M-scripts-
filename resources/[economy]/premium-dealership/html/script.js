let currentData = null
let selectedVehicle = null
let selectedCategory = null
let tradeInValue = 0

window.addEventListener('message', function(event) {
    const data = event.data
    switch (data.action) {
        case 'openShowroom':
            currentData = data.data
            openShowroom()
            break
        case 'testDriveTimer':
            updateTimer(data.time)
            break
        case 'purchaseComplete':
            purchaseComplete(data.plate)
            break
        case 'closeShowroom':
            document.getElementById('showroom').className = 'sr-hidden'
            break
    }
})

function openShowroom() {
    document.getElementById('showroom').className = 'sr-visible'
    document.getElementById('locationLabel').textContent = currentData.locationLabel

    const categoryList = document.getElementById('categoryList')
    categoryList.innerHTML = ''

    const entries = Object.entries(currentData.categories)
    entries.forEach(function(entry, index) {
        const [key, cat] = entry
        const btn = document.createElement('button')
        btn.className = 'cat-btn' + (index === 0 ? ' active' : '')
        btn.style.borderColor = cat.color
        btn.innerHTML = `<span class="cat-name">${cat.label}</span><span class="cat-desc">${cat.description}</span>`
        btn.onclick = function() {
            document.querySelectorAll('.cat-btn').forEach(function(b) { b.className = 'cat-btn' })
            btn.className = 'cat-btn active'
            selectedCategory = key
            showVehicles(key)
        }
        categoryList.appendChild(btn)
        if (index === 0) {
            selectedCategory = key
        }
    })

    if (entries.length > 0) {
        showVehicles(entries[0][0])
    }
}

function showVehicles(categoryKey) {
    const cat = currentData.categories[categoryKey]
    if (!cat) return
    const list = document.getElementById('vehicleList')
    list.innerHTML = ''

    cat.vehicles.forEach(function(v) {
        const card = document.createElement('div')
        card.className = 'vehicle-card'
        card.innerHTML = `
            <div class="vc-preview">
                <div class="vc-badge" style="background: ${cat.color}22; border-color: ${cat.color}; color: ${cat.color};">${cat.label}</div>
                <div class="vc-placeholder">${v.label.charAt(0)}</div>
            </div>
            <div class="vc-info">
                <span class="vc-name">${v.label}</span>
                <span class="vc-price" style="color: ${cat.color};">$${v.price.toLocaleString()}</span>
                <span class="vc-specs">${v.speed} mph | ${v.seats} seats</span>
            </div>
            <div class="vc-actions">
                <button class="vc-btn preview-btn" onclick="previewVehicle('${v.model}')">Preview</button>
                <button class="vc-btn test-btn" onclick="startTestDrive('${v.model}')">Test Drive</button>
                <button class="vc-btn buy-btn" onclick="showPurchase('${categoryKey}', ${JSON.stringify(v).replace(/"/g, "'")})">Buy</button>
            </div>
        `
        list.appendChild(card)
    })
}

function previewVehicle(model) {
    document.getElementById('testDriveTimer').textContent = 'PREVIEW'
    fetch('https://' + GetParentResourceName() + '/previewVehicle', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model: model, locationName: currentData.locationName })
    })
}

function startTestDrive(model) {
    document.getElementById('testDriveTimer').textContent = 'TD: ' + currentData.testDriveDuration + 's'
    fetch('https://' + GetParentResourceName() + '/startTestDrive', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model: model, locationName: currentData.locationName })
    })
}

function updateTimer(seconds) {
    const min = Math.floor(seconds / 60)
    const sec = seconds % 60
    document.getElementById('testDriveTimer').textContent = min + ':' + (sec < 10 ? '0' : '') + sec
    if (seconds <= 0) {
        document.getElementById('testDriveTimer').textContent = 'RETURN'
    }
}

function showPurchase(categoryKey, vehicle) {
    // vehicle comes as escaped string, parse it
    if (typeof vehicle === 'string') {
        vehicle = JSON.parse(vehicle.replace(/'/g, '"').replace(/(\w+):/g, '"$1":'))
    }
    selectedVehicle = vehicle

    const modal = document.getElementById('purchaseModal')
    modal.className = 'modal-visible'

    const body = document.getElementById('purchaseBody')
    const finalPrice = vehicle.price - tradeInValue

    body.innerHTML = `
        <div class="purchase-detail">
            <h3>${vehicle.label}</h3>
            <div class="pd-row"><span>Base Price</span><span>$${vehicle.price.toLocaleString()}</span></div>
            ${tradeInValue > 0 ? `<div class="pd-row pd-tradein"><span>Trade-In Credit</span><span> -$${tradeInValue.toLocaleString()}</span></div>` : ''}
            <div class="pd-row pd-total"><span>Total</span><span>$${finalPrice.toLocaleString()}</span></div>
        </div>
        <div class="purchase-form">
            <label>Custom Plate (${currentData.plateMaxLength} chars max)</label>
            <input type="text" id="plateInput" maxlength="${currentData.plateMaxLength}" placeholder="e.g. K1NG" oninput="checkPlate()">
            <span id="plateStatus" class="plate-status"></span>

            <label>Payment Method</label>
            <select id="paymentSelect" onchange="toggleFinance()">
                <option value="cash">Cash</option>
                <option value="bank">Bank Transfer</option>
                <option value="finance">Finance</option>
            </select>

            <div id="financeOptions" class="finance-options" style="display: none;">
                <label>Finance Term (weeks)</label>
                <select id="financeWeeks">
                    ${currentData.financeOptions.map(function(w) { return '<option value="' + w + '">' + w + ' weeks</option>' }).join('')}
                </select>
            </div>

            <button class="purchase-btn" onclick="confirmPurchase()">Purchase - $${finalPrice.toLocaleString()}</button>
            ${tradeInValue > 0 ? '<button class="remove-tradein-btn" onclick="removeTradeIn()">Remove Trade-In</button>' : ''}
        </div>
    `
}

function toggleFinance() {
    const select = document.getElementById('paymentSelect')
    document.getElementById('financeOptions').style.display = select.value === 'finance' ? 'block' : 'none'
}

function checkPlate() {
    const plate = document.getElementById('plateInput').value.toUpperCase()
    if (plate.length < 2) {
        document.getElementById('plateStatus').textContent = ''
        return
    }
    fetch('https://' + GetParentResourceName() + '/checkPlate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ plate: plate })
    }).then(function(r) { return r.json() }).then(function(data) {
        document.getElementById('plateStatus').textContent = data.available ? 'Plate available' : 'Plate taken'
        document.getElementById('plateStatus').className = 'plate-status ' + (data.available ? 'available' : 'taken')
    })
}

function confirmPurchase() {
    const plate = document.getElementById('plateInput').value.toUpperCase() || ''
    const paymentType = document.getElementById('paymentSelect').value
    const financeWeeks = paymentType === 'finance' ? parseInt(document.getElementById('financeWeeks').value) : 0

    fetch('https://' + GetParentResourceName() + '/purchaseVehicle', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            vehicleData: selectedVehicle,
            plate: plate,
            paymentType: paymentType,
            financeWeeks: financeWeeks,
            tradeInValue: tradeInValue,
        })
    })
    closeModal('purchaseModal')
}

function purchaseComplete() {
    tradeInValue = 0
    selectedVehicle = null
}

function removeTradeIn() {
    tradeInValue = 0
    showPurchase(selectedCategory, selectedVehicle)
}

function showTradeIn() {
    const modal = document.getElementById('tradeInModal')
    modal.className = 'modal-visible'

    fetch('https://' + GetParentResourceName() + '/getOwnedVehicles', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).then(function(r) { return r.json() }).then(function(data) {
        const body = document.getElementById('tradeInBody')
        if (!data.vehicles || data.vehicles.length === 0) {
            body.innerHTML = '<p class="empty-msg">No vehicles in your garage to trade in.</p>'
            return
        }
        let html = '<div class="tradein-list">'
        data.vehicles.forEach(function(v) {
            const md = v.model_data ? JSON.parse(v.model_data) : {}
            const estValue = Math.floor((md.price || 50000) * (parseFloat(currentData.tradeInMultiplier) || 0.65))
            html += `
                <div class="tradein-item" onclick="selectTradeIn('${v.plate}')">
                    <span class="ti-model">${v.model}</span>
                    <span class="ti-plate">${v.plate}</span>
                    <span class="ti-value">Est. $${estValue.toLocaleString()}</span>
                </div>
            `
        })
        html += '</div>'
        body.innerHTML = html
    })
}

function selectTradeIn(plate) {
    fetch('https://' + GetParentResourceName() + '/calcTradeIn', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ plate: plate })
    }).then(function(r) { return r.json() }).then(function(data) {
        tradeInValue = data.value || 0
        closeModal('tradeInModal')
        if (selectedVehicle) {
            showPurchase(selectedCategory, selectedVehicle)
        }
    })
}

function showSell() {
    const modal = document.getElementById('sellModal')
    modal.className = 'modal-visible'

    fetch('https://' + GetParentResourceName() + '/getOwnedVehicles', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).then(function(r) { return r.json() }).then(function(data) {
        const body = document.getElementById('sellBody')
        if (!data.vehicles || data.vehicles.length === 0) {
            body.innerHTML = '<p class="empty-msg">No vehicles to sell.</p>'
            return
        }
        let html = '<div class="tradein-list">'
        data.vehicles.forEach(function(v) {
            const md = v.model_data ? JSON.parse(v.model_data) : {}
            const sellValue = Math.floor((md.price || 50000) * (parseFloat(currentData.tradeInMultiplier) || 0.65))
            html += `
                <div class="tradein-item" onclick="confirmSell('${v.plate}')">
                    <span class="ti-model">${v.model}</span>
                    <span class="ti-plate">${v.plate}</span>
                    <span class="ti-value">Sell for $${sellValue.toLocaleString()}</span>
                </div>
            `
        })
        html += '</div>'
        body.innerHTML = html
    })
}

function confirmSell(plate) {
    if (!confirm('Sell ' + plate + ' to the dealership?')) return
    fetch('https://' + GetParentResourceName() + '/sellVehicle', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ plate: plate })
    })
    closeModal('sellModal')
}

function closeModal(id) {
    document.getElementById(id).className = 'modal-hidden'
}

function closeShowroom() {
    fetch('https://' + GetParentResourceName() + '/closeShowroom', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    })
    fetch('https://' + GetParentResourceName() + '/endTestDrive', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    })
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        closeModal('purchaseModal')
        closeModal('tradeInModal')
        closeModal('sellModal')
    }
})
