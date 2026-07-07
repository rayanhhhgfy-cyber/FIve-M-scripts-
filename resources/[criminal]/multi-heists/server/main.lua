local QBox = exports['qbx_core']:GetCoreObject()
local activeHeists = {}
local heistCooldowns = {}
local bankTruckTimer = nil
local bankTruckActive = false

local function isPoliceOnline()
    local count = 0
    local players = QBox.Functions.GetPlayers()
    for _, src in ipairs(players) do
        local player = QBox.Functions.GetPlayer(src)
        if player and (player.PlayerData.job.name == 'police' or player.PlayerData.job.type == 'leo') and player.PlayerData.job.onduty then
            count = count + 1
        end
    end
    return count
end

local function alertPolice(coords, title, message, blipTime)
    local players = QBox.Functions.GetPlayers()
    for _, src in ipairs(players) do
        local player = QBox.Functions.GetPlayer(src)
        if player and (player.PlayerData.job.name == 'police' or player.PlayerData.job.type == 'leo') and player.PlayerData.job.onduty then
            TriggerClientEvent('ox_lib:notify', src, { type = 'warning', description = message, duration = 8000 })
            TriggerClientEvent('multi-heists:policeAlert', src, coords, title, blipTime or 60)
        end
    end
end

lib.callback.register('multi-heists:startHeist', function(source, heistId)
    local heistConfig = Config.Heists.heists[heistId]
    if not heistConfig then return { success = false, message = 'Invalid heist' } end

    local player = QBox.Functions.GetPlayer(source)
    if not player then return { success = false, message = 'Player not found' } end

    if activeHeists[heistId] then
        return { success = false, message = 'This heist is already active' }
    end

    if heistCooldowns[heistId] and os.time() - heistCooldowns[heistId] < heistConfig.cooldown then
        local remaining = heistConfig.cooldown - (os.time() - heistCooldowns[heistId])
        return { success = false, message = 'Heist on cooldown. ' .. math.ceil(remaining / 60) .. 'm remaining' }
    end

    if isPoliceOnline() < Config.Heists.requiredPolice then
        return { success = false, message = 'Not enough police online (' .. Config.Heists.requiredPolice .. ' required)' }
    end

    for _, item in ipairs(heistConfig.requiredItems) do
        if exports.ox_inventory:Search(source, 'count', item) == 0 then
            return { success = false, message = 'Missing required item: ' .. item }
        end
    end

    activeHeists[heistId] = {
        startedBy = source,
        startTime = os.time(),
        currentPhase = 0,
        phaseStartTime = os.time(),
        participants = { [source] = true },
        state = 'running',
    }

    return { success = true, message = 'Heist started!' }
end)

lib.callback.register('multi-heists:getHeistState', function(source, heistId)
    local heist = activeHeists[heistId]
    if not heist then return nil end
    local heistConfig = Config.Heists.heists[heistId]
    return {
        currentPhase = heist.currentPhase,
        phases = heistConfig.phases,
        phaseStartTime = heist.phaseStartTime,
        state = heist.state,
    }
end)

RegisterNetEvent('multi-heists:completePhase', function(heistId)
    local src = source
    local heist = activeHeists[heistId]
    if not heist then return end
    if not heist.participants[src] then return end

    local heistConfig = Config.Heists.heists[heistId]
    heist.currentPhase = heist.currentPhase + 1
    heist.phaseStartTime = os.time()

    if heistConfig.policeAlertPhase and heist.currentPhase == heistConfig.policeAlertPhase and heist.currentPhase > 0 then
        alertPolice(heistConfig.locations.entry, heistConfig.label, 'Heist in progress at ' .. heistConfig.label .. '!', 120)
    end

    if heist.currentPhase >= #heistConfig.phases then
        heist.state = 'completed'
        local totalLoot = math.random(heistConfig.lootMin, heistConfig.lootMax)
        local participantList = {}
        for s, _ in pairs(heist.participants) do
            table.insert(participantList, s)
        end

        for _, s in ipairs(participantList) do
            local p = QBox.Functions.GetPlayer(s)
            if p then
                local share = math.floor(totalLoot / #participantList)
                local valuePerItem = math.random(heistConfig.lootReward.min, heistConfig.lootReward.max)
                exports.ox_inventory:AddItem(s, heistConfig.lootReward.name, 1, {
                    value = valuePerItem,
                    source = heistConfig.label,
                    time = os.time(),
                })
                TriggerClientEvent('ox_lib:notify', s, { type = 'success', description = 'Heist complete! Your share: $' .. valuePerItem, duration = 10000 })
            end
        end

        alertPolice(heistConfig.locations.entry, heistConfig.label, 'Heist completed at ' .. heistConfig.label .. ' — suspects fleeing!', 90)
        heistCooldowns[heistId] = os.time()
        activeHeists[heistId] = nil
        return
    end

    TriggerClientEvent('multi-heists:nextPhase', -1, heistId, heist.currentPhase)
end)

RegisterNetEvent('multi-heists:failHeist', function(heistId)
    local src = source
    local heist = activeHeists[heistId]
    if not heist then return end

    heist.state = 'failed'
    alertPolice(Config.Heists.heists[heistId].locations.entry, Config.Heists.heists[heistId].label, 'Heist failed at ' .. Config.Heists.heists[heistId].label .. ' — suspects fleeing!', 60)

    for s, _ in pairs(heist.participants) do
        local p = QBox.Functions.GetPlayer(s)
        if p then
            exports.ox_inventory:RemoveItem(s, 'heist_loot', 1)
            TriggerClientEvent('ox_lib:notify', s, { type = 'error', description = 'Heist failed! All loot lost.', duration = 8000 })
        end
    end

    heistCooldowns[heistId] = os.time()
    activeHeists[heistId] = nil
end)

RegisterNetEvent('multi-heists:joinHeist', function(heistId)
    local src = source
    local heist = activeHeists[heistId]
    if not heist then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'No active heist to join' })
        return
    end

    local heistConfig = Config.Heists.heists[heistId]
    if #heist.participants >= heistConfig.maxParticipants then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Heist is full (' .. heistConfig.maxParticipants .. ' max)' })
        return
    end

    heist.participants[src] = true
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Joined ' .. heistConfig.label .. ' heist!' })
end)

--- Bank Truck spawning
CreateThread(function()
    while true do
        Wait(60000)
        if not bankTruckActive then
            local min, max = Config.Heists.heists['banktruck'].spawnInterval.min, Config.Heists.heists['banktruck'].spawnInterval.max
            local wait = math.random(min, max)
            Wait(wait * 1000)

            local route = Config.Heists.heists['banktruck'].locations.routes[math.random(#Config.Heists.heists['banktruck'].locations.routes)]
            bankTruckActive = true

            local players = QBox.Functions.GetPlayers()
            for _, src in ipairs(players) do
                if not (QBox.Functions.GetPlayer(src) and (QBox.Functions.GetPlayer(src).PlayerData.job.name == 'police' or QBox.Functions.GetPlayer(src).PlayerData.job.type == 'leo')) then
                    TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'An armored bank truck is on the move! Track it and make your move.', duration = 15000 })
                    TriggerClientEvent('multi-heists:bankTruckSpawned', src, route)
                end
            end
        end
    end
end)

lib.callback.register('multi-heists:isBankTruckActive', function()
    return bankTruckActive
end)

RegisterNetEvent('multi-heists:bankTruckLooted', function()
    bankTruckActive = false
end)

--- Cleanup on player drop
AddEventHandler('playerDropped', function()
    local src = source
    for heistId, heist in pairs(activeHeists) do
        if heist.participants[src] then
            heist.participants[src] = nil
        end
        if heist.startedBy == src then
            alertPolice(Config.Heists.heists[heistId].locations.entry, Config.Heists.heists[heistId].label, 'Heist leader disconnected!', 30)
            activeHeists[heistId] = nil
        end
    end
end)
