local QBox = exports['qbx_core']:GetCoreObject()
local imprisonedPlayers = {}
local activeBreakouts = {}
local breakoutIdCounter = 0
local manhuntActive = false

local function isGuard(src)
    local p = QBox.Functions.GetPlayer(src)
    return p and p.PlayerData.job.name == Config.Prison.guardJob and p.PlayerData.job.onduty
end

local function isAdmin(src)
    local p = QBox.Functions.GetPlayer(src)
    if not p then return false end
    for _, g in ipairs(Config.Prison.adminGroups) do
        if p.PlayerData.group == g then return true end
    end
    return false
end

local function broadcastManhunt(escapedCid, escapedName, lastSeen)
    local players = QBox.Functions.GetPlayers()
    for _, src in ipairs(players) do
        local p = QBox.Functions.GetPlayer(src)
        if p and (isGuard(src) or isAdmin(src)) then
            TriggerClientEvent('ox_lib:notify', src, { type = 'warning', description = 'MANHUNT: ' .. escapedName .. ' escaped from prison! Last seen: ' .. tostring(lastSeen) })
            TriggerClientEvent('prison:manhuntGPS', src, lastSeen)
        end
    end
end

RegisterNetEvent('prison:sentence', function(targetSrc, timeSeconds)
    local src = source
    if not isAdmin(src) and not isGuard(src) then return end
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then return end
    local cid = target.PlayerData.citizenid
    imprisonedPlayers[cid] = {
        src = targetSrc,
        name = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname,
        sentence = timeSeconds,
        remaining = timeSeconds,
        jobsDone = 0,
        contrabandFound = 0,
        entered = os.time(),
    }
    MySQL.insert('INSERT INTO prison_inmates (citizenid, name, sentence, remaining) VALUES (?, ?, ?, ?)', { cid, imprisonedPlayers[cid].name, timeSeconds, timeSeconds })
    TriggerClientEvent('prison:enterPrison', targetSrc, timeSeconds)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = imprisonedPlayers[cid].name .. ' sentenced to ' .. timeSeconds .. 's' })
end)

RegisterNetEvent('prison:doJob', function(jobId)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    local inmate = imprisonedPlayers[cid]
    if not inmate then return end
    local jobDef = nil
    for _, j in ipairs(Config.Prison.inmateJobs) do
        if j.id == jobId then jobDef = j; break end
    end
    if not jobDef then return end
    inmate.jobsDone = inmate.jobsDone + 1
    p.Functions.AddMoney('cash', jobDef.pay)
    inmate.remaining = math.max(0, inmate.remaining - Config.Prison.sentenceReductionPerJob)
    MySQL.update('UPDATE prison_inmates SET remaining = ?, jobs_done = ? WHERE citizenid = ?', { inmate.remaining, inmate.jobsDone, cid })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = jobDef.name .. ' done! +$' .. jobDef.pay .. ', time reduced by ' .. Config.Prison.sentenceReductionPerJob .. 's' })
    if inmate.remaining <= 0 then
        TriggerClientEvent('prison:release', src)
        imprisonedPlayers[cid] = nil
        MySQL.update('UPDATE prison_inmates SET released_at = NOW() WHERE citizenid = ?', { cid })
    end
end)

RegisterNetEvent('prison:smuggleContraband', function(contrabandId)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local contrabandDef = nil
    for _, c in ipairs(Config.Prison.contraband) do
        if c.id == contrabandId then contrabandDef = c; break end
    end
    if not contrabandDef then return end
    if not p.Functions.RemoveMoney('cash', contrabandDef.smugglerPrice) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Need $' .. contrabandDef.smugglerPrice })
        return
    end
    p.Functions.AddItem(contrabandDef.item, 1)
    MySQL.insert('INSERT INTO prison_contraband (citizenid, contraband_type) VALUES (?, ?)', { p.PlayerData.citizenid, contrabandDef.id })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Smuggled ' .. contrabandDef.name .. ' ($' .. contrabandDef.smugglerPrice .. ')' })
end)

RegisterNetEvent('prison:startBreakout', function(methodId)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    local inmate = imprisonedPlayers[cid]
    if not inmate then return end
    local method = Config.Prison.breakout.methods[methodId]
    if not method then return end
    if method.toolRequired then
        local hasTool = p.Functions.GetItemByName(method.toolRequired)
        if not hasTool or hasTool.count < 1 then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Need a ' .. method.toolRequired })
            return
        end
    end
    TriggerClientEvent('prison:breakoutProgress', src, methodId, method.preparation)
end)

RegisterNetEvent('prison:completeBreakout', function(methodId)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local cid = p.PlayerData.citizenid
    local inmate = imprisonedPlayers[cid]
    if not inmate then return end
    local method = Config.Prison.breakout.methods[methodId]
    if not method then return end
    breakoutIdCounter = breakoutIdCounter + 1
    local breakoutId = 'BO-' .. breakoutIdCounter
    local lastSeen = GetEntityCoords(GetPlayerPed(src))
    activeBreakouts[breakoutId] = { citizenid = cid, name = inmate.name, method = methodId, started = os.time(), lastSeen = lastSeen }
    imprisonedPlayers[cid] = nil
    manhuntActive = true
    MySQL.insert('INSERT INTO prison_breakout_attempts (citizenid, method, success) VALUES (?, ?, 1)', { cid, methodId })
    broadcastManhunt(cid, inmate.name, lastSeen)
    TriggerClientEvent('ox_lib:notify', src, { type = 'warning', description = 'You escaped! Manhunt initiated. Stay hidden for ' .. Config.Prison.breakout.manhuntDuration .. 's.' })
    TriggerClientEvent('prison:escaped', src)
    -- end manhunt after duration
    Citizen.SetTimeout(Config.Prison.breakout.manhuntDuration * 1000, function()
        manhuntActive = false
        activeBreakouts[breakoutId] = nil
        broadcastManhunt(cid, inmate.name, lastSeen) -- all clear
    end)
end)

RegisterNetEvent('prison:recapture', function(escapedCid)
    local src = source
    if not isGuard(src) and not isAdmin(src) then return end
    for id, breakout in pairs(activeBreakouts) do
        if breakout.citizenid == escapedCid then
            activeBreakouts[id] = nil
            -- send back to prison
            local target = QBox.Functions.GetPlayerByCitizenId(escapedCid)
            if target then
                imprisonedPlayers[escapedCid] = {
                    src = target.PlayerData.source,
                    name = breakout.name,
                    sentence = 600,
                    remaining = 600,
                    jobsDone = 0,
                    entered = os.time(),
                }
                TriggerClientEvent('prison:enterPrison', target.PlayerData.source, 600)
            end
            TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = breakout.name .. ' recaptured!' })
            return
        end
    end
end)

QBox.Functions.CreateCallback('prison:isImprisoned', function(source, cb)
    local p = QBox.Functions.GetPlayer(source)
    if not p then cb(false) return end
    cb(imprisonedPlayers[p.PlayerData.citizenid] ~= nil)
end)

QBox.Functions.CreateCallback('prison:getRemainingTime', function(source, cb)
    local p = QBox.Functions.GetPlayer(source)
    if not p then cb(0) return end
    local inmate = imprisonedPlayers[p.PlayerData.citizenid]
    cb(inmate and inmate.remaining or 0)
end)

QBox.Functions.CreateCallback('prison:getInmates', function(source, cb)
    local result = {}
    for cid, inmate in pairs(imprisonedPlayers) do
        table.insert(result, { citizenid = cid, name = inmate.name, remaining = inmate.remaining })
    end
    cb(result)
end)

QBox.Commands.Add('sentence', 'Send player to prison', {}, false, function(source, args)
    local targetSrc = tonumber(args[1])
    local time = tonumber(args[2]) or 300
    TriggerEvent('prison:sentence', targetSrc, time)
end)

QBox.Commands.Add('inmates', 'List imprisoned players', {}, false, function(source)
    QBox.Functions.TriggerCallback('prison:getInmates', function(inmates)
        if not inmates or #inmates == 0 then
            TriggerClientEvent('ox_lib:notify', source, { type = 'info', description = 'No inmates' })
            return
        end
        local items = {}
        for _, i in ipairs(inmates) do
            table.insert(items, { title = i.name, description = i.remaining .. 's remaining' })
        end
        TriggerClientEvent('ox_lib:notify', source, { type = 'info', description = #inmates .. ' inmate(s) in prison' })
    end)
end)
