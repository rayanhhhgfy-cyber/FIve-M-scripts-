local QBox = exports['qbx_core']:GetCoreObject()

RegisterNetEvent('methlab:failedPasscodeAlert', function(bunkerId)
    local src = source
    local bunker = exports['bunker-builder']:GetBunker(bunkerId)
    if not bunker then return end
    local p = getPlayer(src)
    if not p then return end
    local players = QBox.Functions.GetPlayers()
    for _, id in ipairs(players) do
        local player = QBox.Functions.GetPlayer(id)
        if player and player.PlayerData.job.onduty and isCidJob(player.PlayerData.job.name) then
            TriggerClientEvent('ox_lib:notify', id, {
                type = 'warning',
                description = 'Suspicious activity at ' .. bunker.label .. ' — failed passcode attempts'
            })
            TriggerClientEvent('methlab:securityAlert', id, bunker.entrance.coords, bunker.label)
        end
    end
    exports['discord-logs']:LogCustom(p.PlayerData.citizenid, 'Meth Lab', 'Failed passcode at ' .. bunker.label)
end)

RegisterNetEvent('methlab:attemptHack', function(bunkerId)
    local src = source
    local p = getPlayer(src)
    if not p then return end
    if not rateLimit(src, 'hackBunker', 3) then return end
    local count = QBox.Functions.GetItemCount(p, 'laptop')
    if not count or count < 1 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Need a laptop' })
        return
    end
    local success = math.random() <= 0.40
    exports['discord-logs']:LogCustom(p.PlayerData.citizenid, 'Meth Lab', 'Hack attempt at bunker ' .. bunkerId .. ' - ' .. (success and 'SUCCESS' or 'FAILED'))
    if not success then
        addHeatToBunker(bunkerId, Config.MethLab.heat.failedHack)
    end
    TriggerClientEvent('methlab:hackResult', src, bunkerId, success)
end)

RegisterNetEvent('methlab:purchaseUpgrade', function(bunkerId, upgradeKey)
    local src = source
    local p = getPlayer(src)
    if not p then return end
    if not rateLimit(src, 'buyUpgrade', 2) then return end
    local upgrade = Config.MethLab.upgrades[upgradeKey]
    if not upgrade then return end
    local state = MySQL.single.await('SELECT upgrades_json FROM meth_lab_state WHERE bunker_id = ?', { bunkerId })
    local owned = state and json.decode(state.upgrades_json) or {}
    for _, o in ipairs(owned) do
        if o == upgradeKey then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Already owned' })
            return
        end
    end
    local cash = p.PlayerData.money.cash or 0
    if cash < upgrade.cost then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Need $' .. upgrade.cost })
        return
    end
    p.Functions.RemoveMoney('cash', upgrade.cost)
    table.insert(owned, upgradeKey)
    MySQL.update('UPDATE meth_lab_state SET upgrades_json = ? WHERE bunker_id = ?', { json.encode(owned), bunkerId })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = upgrade.label .. ' installed!' })
    exports['discord-logs']:LogCustom(p.PlayerData.citizenid, 'Meth Lab', 'Purchased upgrade: ' .. upgrade.label .. ' at bunker ' .. bunkerId)
end)

function addHeatToBunker(bunkerId, amount)
    local state = MySQL.single.await('SELECT heat FROM meth_lab_state WHERE bunker_id = ?', { bunkerId })
    local currentHeat = state and state.heat or 0
    local newHeat = math.min(currentHeat + amount, Config.MethLab.heat.maxHeat)
    MySQL.update('UPDATE meth_lab_state SET heat = ? WHERE bunker_id = ?', { newHeat, bunkerId })
    TriggerClientEvent('methlab:updateHeat', -1, newHeat, bunkerId)
    return newHeat
end

function removeHeatFromBunker(bunkerId, amount)
    local state = MySQL.single.await('SELECT heat FROM meth_lab_state WHERE bunker_id = ?', { bunkerId })
    local currentHeat = state and state.heat or 0
    local newHeat = math.max(currentHeat - amount, 0)
    MySQL.update('UPDATE meth_lab_state SET heat = ? WHERE bunker_id = ?', { newHeat, bunkerId })
    TriggerClientEvent('methlab:updateHeat', -1, newHeat, bunkerId)
    return newHeat
end

function getBunkerHeat(bunkerId)
    local state = MySQL.single.await('SELECT heat FROM meth_lab_state WHERE bunker_id = ?', { bunkerId })
    return state and state.heat or 0
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.MethLab.heat.decayInterval * 1000)
        local rows = MySQL.query.await('SELECT bunker_id, heat FROM meth_lab_state WHERE heat > 0')
        for _, row in ipairs(rows or {}) do
            local newHeat = math.max(row.heat - Config.MethLab.heat.decayAmount, 0)
            MySQL.update('UPDATE meth_lab_state SET heat = ? WHERE bunker_id = ?', { newHeat, row.bunker_id })
        end
    end
end)
