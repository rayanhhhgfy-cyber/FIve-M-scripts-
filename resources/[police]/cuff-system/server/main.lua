local QBox = exports['qbx_core']:GetCoreObject()

local RATE_LIMITS = {}
local function checkRateLimit(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    RATE_LIMITS[key] = RATE_LIMITS[key] or {}
    table.insert(RATE_LIMITS[key], now)
    for i = #RATE_LIMITS[key], 1, -1 do
        if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end
    end
    return #RATE_LIMITS[key] <= maxPerMin
end

local cuffStates = {}

--- @return boolean
local function isAdminOrCuffJob(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return false end
    for _, g in ipairs(Config.CuffSystem.adminGroups) do
        if player.PlayerData.group == g then return true end
    end
    for _, j in ipairs(Config.CuffSystem.allowedCuffJobs) do
        if player.PlayerData.job.name == j then return true end
    end
    return false
end

--- Cuff a player
RegisterNetEvent('cuff:server:cuff', function(targetSrc)
    local src = source
    if not checkRateLimit(src, 'cuff', 20) then return end

    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end

    -- Check distance
    local ped = GetPlayerPed(src)
    local tPed = GetPlayerPed(targetSrc)
    local coords = GetEntityCoords(ped)
    local tCoords = GetEntityCoords(tPed)
    if #(coords - tCoords) > Config.CuffSystem.maxCuffDistance then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Too far' })
        return
    end

    local targetCID = target.PlayerData.citizenid
    local playerCID = player.PlayerData.citizenid

    -- Already cuffed?
    if cuffStates[targetCID] then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Already cuffed' })
        return
    end

    -- Store cuff state
    cuffStates[targetCID] = {
        cuffer = playerCID,
        cufferSrc = src,
        timestamp = os.time(),
    }

    TriggerClientEvent('cuff:client:doCuff', targetSrc, src)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Cuffed ' .. target.PlayerData.charinfo.firstname })
    TriggerClientEvent('ox_lib:notify', targetSrc, { type = 'warning', description = 'You have been cuffed' })
end)

--- Check and show cuff/uncuff menu for target
RegisterNetEvent('cuff:server:checkAndShow', function(targetSrc)
    local src = source
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then return end
    local targetCID = target.PlayerData.citizenid
    local isTargetCuffed = cuffStates[targetCID] ~= nil
    TriggerClientEvent('cuff:client:showMenu', src, targetSrc, isTargetCuffed)
end)

--- Uncuff a player
RegisterNetEvent('cuff:server:uncuff', function(targetSrc)
    local src = source
    if not checkRateLimit(src, 'uncuff', 20) then return end

    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end

    local targetCID = target.PlayerData.citizenid
    local playerCID = player.PlayerData.citizenid

    local cuff = cuffStates[targetCID]
    if not cuff then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not cuffed' })
        return
    end

    -- Only the original cuffer can uncuff freely
    if cuff.cuffer == playerCID then
        cuffStates[targetCID] = nil
        TriggerClientEvent('cuff:client:doUncuff', targetSrc)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Uncuffed ' .. target.PlayerData.charinfo.firstname })
        TriggerClientEvent('ox_lib:notify', targetSrc, { type = 'info', description = 'You have been uncuffed' })
        return
    end

    -- Non-cuffer needs lockpick
    TriggerClientEvent('cuff:client:requestLockpickUncuff', src, targetSrc, targetCID)
end)

--- Lockpick uncuff (called from client after lockpick animation)
RegisterNetEvent('cuff:server:lockpickUncuff', function(targetSrc, targetCID)
    local src = source
    if not checkRateLimit(src, 'lockpickuncuff', 10) then return end

    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    -- Check they have a lockpick
    if not player.Functions.GetItemByName('lockpick') then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Need a lockpick' })
        return
    end

    local cuff = cuffStates[targetCID]
    if not cuff then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not cuffed' })
        return
    end

    -- Check distance
    local ped = GetPlayerPed(src)
    local tPed = GetPlayerPed(targetSrc)
    local coords = GetEntityCoords(ped)
    local tCoords = GetEntityCoords(tPed)
    if #(coords - tCoords) > Config.CuffSystem.maxCuffDistance then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Too far' })
        return
    end

    -- Consume lockpick
    player.Functions.RemoveItem('lockpick', 1)

    -- Success
    cuffStates[targetCID] = nil
    TriggerClientEvent('cuff:client:doUncuff', targetSrc)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Picked the cuffs off' })
    TriggerClientEvent('ox_lib:notify', targetSrc, { type = 'info', description = 'Cuffs picked by someone' })
end)

--- Cuffed player attempts to lockpick car to drive
RegisterNetEvent('cuff:server:lockpickCar', function(vehicleNetId)
    local src = source
    if not checkRateLimit(src, 'cuffdrive', 8) then return end

    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    local playerCID = player.PlayerData.citizenid
    local cuff = cuffStates[playerCID]
    if not cuff then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You are not cuffed' })
        return
    end

    if not player.Functions.GetItemByName('lockpick') then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Need a lockpick' })
        return
    end

    -- Consume lockpick
    player.Functions.RemoveItem('lockpick', 1)

    -- Success — allow vehicle control
    TriggerClientEvent('cuff:client:allowCuffedDrive', src, vehicleNetId)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Hotwired the ignition' })
end)

--- Check if a player is cuffed (export)
exports('IsCuffed', function(citizenid)
    return cuffStates[citizenid] ~= nil
end)

exports('GetCuffer', function(citizenid)
    local cuff = cuffStates[citizenid]
    if cuff then return cuff.cuffer end
    return nil
end)

--- Commands
QBox.Commands.Add('cuff', 'Cuff nearest player', {}, false, function(source, args)
    local src = source
    if not isAdminOrCuffJob(src) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not authorized' })
        return
    end
    local targetSrc = tonumber(args[1])
    if targetSrc then
        TriggerEvent('cuff:server:cuff', targetSrc)
    else
        -- Find nearest player
        local ped = GetPlayerPed(src)
        local coords = GetEntityCoords(ped)
        local nearest = nil
        local nearestDist = Config.CuffSystem.maxCuffDistance
        local players = QBox.Functions.GetPlayers()
        for _, s in ipairs(players) do
            if s ~= src then
                local tPed = GetPlayerPed(s)
                local tCoords = GetEntityCoords(tPed)
                local dist = #(coords - tCoords)
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = s
                end
            end
        end
        if nearest then
            TriggerEvent('cuff:server:cuff', nearest)
        else
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'No player nearby' })
        end
    end
end)

QBox.Commands.Add('uncuff', 'Uncuff a player', {}, false, function(source, args)
    local src = source
    local targetSrc = tonumber(args[1])
    if not targetSrc then
        -- Find nearest cuffed player
        local ped = GetPlayerPed(src)
        local coords = GetEntityCoords(ped)
        local nearest = nil
        local nearestDist = Config.CuffSystem.maxCuffDistance
        local players = QBox.Functions.GetPlayers()
        for _, s in ipairs(players) do
            if s ~= src then
                local tPed = GetPlayerPed(s)
                local tCoords = GetEntityCoords(tPed)
                local dist = #(coords - tCoords)
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = s
                end
            end
        end
        if nearest then targetSrc = nearest end
    end
    if targetSrc then
        TriggerEvent('cuff:server:uncuff', targetSrc)
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Specify a player ID' })
    end
end)

--- Cleanup on disconnect
AddEventHandler('playerDropped', function(reason)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local cid = player.PlayerData.citizenid
    cuffStates[cid] = nil
    -- Also clean up if they were a cuffer
    for k, v in pairs(cuffStates) do
        if v.cuffer == cid then
            cuffStates[k] = nil
        end
    end
end)
