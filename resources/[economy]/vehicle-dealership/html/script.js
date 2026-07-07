let dealershipData = null
let selectedCategory = null
let selectedVehicle = null
let playerVehicles = []

window.addEventListener('message', function(event) {
    const data = event.data
    if (data.action === 'openDealership') {
        dealershipData = data.data
        document.getElementById('dealership-ui').style.display = 'flex'
        updateMoney(data.data.playerMoney)
        renderCategories()
        if (dealershipData.categories.length > 0) {
            selectCategory(dealershipData.categories[0])
        }
        loadPlayerVehicles()
    }
    if (data.action === 'updateMoney') {
        updateMoney(data.money)
    }
})

function updateMoney(money) {
    if (!money) return
    const cash = money.cash || 0
    const bank = money.bank || 0
    document.getElementById('dealer-cash').textContent = 'Cash: $' + cash.toLocaleString()
    document.getElementById('dealer-bank').textContent = 'Bank: $' + bank.toLocaleString()
}

function renderCategories() {
    const container = document.getElementById('dealer-categories')
    container.innerHTML = ''
    for (const cat of dealershipData.categories) {
        const label = dealershipData.categoryLabels[cat] || cat
        const btn = document.createElement('button')
        btn.className = 'dealer-cat-btn' + (cat === selectedCategory ? ' active' : '')
        btn.dataset.cat = cat
        btn.textContent = label
        btn.addEventListener('click', function() { selectCategory(cat) })
        container.appendChild(btn)
    }
}

function selectCategory(cat) {
    selectedCategory = cat
    selectedVehicle = null
    document.querySelectorAll('.dealer-cat-btn').forEach(el => el.classList.remove('active'))
    const btn = document.querySelector('.dealer-cat-btn[data-cat="' + cat + '"]')
    if (btn) btn.classList.add('active')
    document.getElementById('dealer-detail').classList.add('hidden')
    document.getElementById('dealer-grid').classList.remove('hidden')
    renderVehicles(cat)
}

function renderVehicles(cat) {
    const grid = document.getElementById('dealer-grid')
    grid.innerHTML = ''
    const vehicles = dealershipData.vehicles[cat] || []
    if (vehicles.length === 0) {
        grid.innerHTML = '<div style="text-align:center;padding:40px 0;color:rgba(255,255,255,0.25);font-size:14px;">No vehicles in this category</div>'
        return
    }
    for (const v of vehicles) {
        const div = document.createElement('div')
        div.className = 'dealer-vehicle-item'
        div.innerHTML = '<div class="veh-item-left"><span class="veh-item-name">' + v.model.toUpperCase() + '</span><span class="veh-item-price">$' + v.price.toLocaleString() + '</span></div><div><span class="veh-item-stock">' + v.stock + ' in stock</span></div>'
        div.addEventListener('click', function() { showVehicleDetail(cat, v) })
        grid.appendChild(div)
    }
}

function showVehicleDetail(cat, v) {
    selectedVehicle = v
    document.getElementById('dealer-grid').classList.add('hidden')
    const detail = document.getElementById('dealer-detail')
    detail.classList.remove('hidden')

    document.getElementById('dealer-detail-name').textContent = v.model.toUpperCase()
    document.getElementById('dealer-detail-desc').textContent = v.description || ''
    document.getElementById('dealer-detail-price').textContent = '$' + v.price.toLocaleString()
    document.getElementById('dealer-detail-stock').textContent = 'Stock: ' + v.stock

    const financePrice = v.financingPrice || Math.floor(v.price * 1.15)
    const downPayment = Math.floor(financePrice * 0.2)
    const weekly = Math.floor(financePrice / 20)
    document.getElementById('dealer-detail-finance').textContent = 'Finance: $' + downPayment.toLocaleString() + ' down, $' + weekly.toLocaleString() + '/week x 20 weeks (Total: $' + financePrice.toLocaleString() + ')'

    const cashBtn = document.getElementById('dealer-buy-cash')
    const bankBtn = document.getElementById('dealer-buy-bank')
    const financeBtn = document.getElementById('dealer-buy-finance')

    cashBtn.onclick = function() { buyVehicle(cat, v, 'cash') }
    bankBtn.onclick = function() { buyVehicle(cat, v, 'bank') }
    financeBtn.onclick = function() { buyVehicle(cat, v, 'finance') }

    document.getElementById('dealer-preview').onclick = function() {
        fetch('https://' + GetParentResourceName() + '/dealershipPreview', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ model: v.model })
        })
    }

    document.getElementById('dealer-testdrive').onclick = function() {
        fetch('https://' + GetParentResourceName() + '/dealershipTestDrive', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ model: v.model })
        })
    }
}

function buyVehicle(cat, v, paymentType) {
    fetch('https://' + GetParentResourceName() + '/dealershipBuy', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ category: cat, model: v.model, paymentType: paymentType })
    }).then(res => res.json()).then(result => {
        if (result.success) {
            document.getElementById('dealer-detail').classList.add('hidden')
            document.getElementById('dealer-grid').classList.remove('hidden')
            loadPlayerVehicles()
        }
    })
}

function loadPlayerVehicles() {
    fetch('https://' + GetParentResourceName() + '/dealershipGetPlayerVehicles', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).then(res => res.json()).then(vehicles => {
        playerVehicles = vehicles || []
        const select = document.getElementById('dealer-sell-select')
        select.innerHTML = '<option value="">-- Select vehicle to sell --</option>'
        for (const v of playerVehicles) {
            if (v.financed == 0 || v.financed === false) {
                const opt = document.createElement('option')
                opt.value = v.plate
                opt.textContent = v.model + ' [' + v.plate + ']'
                select.appendChild(opt)
            }
        }
    })
}

document.getElementById('dealer-detail-back').addEventListener('click', function() {
    document.getElementById('dealer-detail').classList.add('hidden')
    document.getElementById('dealer-grid').classList.remove('hidden')
})

document.getElementById('dealer-close').addEventListener('click', function() {
    fetch('https://' + GetParentResourceName() + '/dealershipClose', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    })
})

document.querySelector('.dealer-collapsible').addEventListener('click', function() {
    const content = document.getElementById('dealer-sell-content')
    content.classList.toggle('hidden')
    const icon = this.querySelector('i')
    icon.className = content.classList.contains('hidden') ? 'fas fa-chevron-down' : 'fas fa-chevron-up'
})

document.getElementById('dealer-sell-btn').addEventListener('click', function() {
    const select = document.getElementById('dealer-sell-select')
    const plate = select.value
    if (!plate) return
    fetch('https://' + GetParentResourceName() + '/dealershipSell', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ plate: plate })
    }).then(res => res.json()).then(result => {
        if (result.success) {
            loadPlayerVehicles()
        }
    })
})

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        if (!document.getElementById('dealer-detail').classList.contains('hidden')) {
            document.getElementById('dealer-detail').classList.add('hidden')
            document.getElementById('dealer-grid').classList.remove('hidden')
        } else {
            fetch('https://' + GetParentResourceName() + '/dealershipClose', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            })
        }
    }
})

function GetParentResourceName() {
    return window.location.hostname
}
