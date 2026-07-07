local QBox = exports['qbx-core']:GetCoreObject()

local RATE_LIMITS = {}
local function checkRateLimit(src, a, m)
    local k = src .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('cid:server:toggleDuty', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or p.PlayerData.job.name ~= 'cid' then return end
    p.Functions.SetJobDuty(not p.PlayerData.job.onduty)
    Wrappers.Notify(src, p.PlayerData.job.onduty and Locale('cid.now_on_duty') or Locale('cid.now_off_duty'), 'success')
end)

RegisterNetEvent('cid:server:takeEquipment', function(item)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not p.PlayerData.job.onduty then Wrappers.Notify(src, Locale('cid.not_on_duty'), 'error') return end
    local ammoTypes = { ['ammo-9'] = 60, ['ammo-rifle'] = 60, ['ammo-rifle2'] = 60, ['ammo-shotgun'] = 30, ['ammo-sniper'] = 20, ['ammo-heavysniper'] = 10 }
    local count = ammoTypes[item] or 1
    p.Functions.AddItem(item, count)
    Wrappers.Notify(src, Locale('cid.equipment_taken'), 'success')
    exports['discord-logs']:LogCustom(src, 'CID Equipment', 'Took ' .. item .. ' x' .. count)
end)

RegisterNetEvent('cid:server:createCase', function(title, description, caseType)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not p.PlayerData.job.onduty then return end
    MySQL.insert('INSERT INTO cid_cases (title, description, type, status, assigned_to, created_by, created_at) VALUES (?, ?, ?, ?, ?, ?, NOW())',
        { title, description, caseType, 'open', p.PlayerData.citizenid, p.PlayerData.citizenid }, function(id)
        TriggerClientEvent('cid:client:caseCreated', src, id)
        exports['discord-logs']:LogCustom(src, 'CID Case', 'Created case #' .. id .. ': ' .. title)
    end)
end)

RegisterNetEvent('cid:server:getCases', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.query('SELECT * FROM cid_cases ORDER BY created_at DESC LIMIT 50', {}, function(r)
        TriggerClientEvent('cid:client:showCases', src, r or {})
    end)
end)

RegisterNetEvent('cid:server:interrogate', function(targetId)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not p.PlayerData.job.onduty then return end
    local t = QBox.Functions.GetPlayer(targetId)
    if not t then Wrappers.Notify(src, Locale('cid.player_not_found'), 'error') return end
    Wrappers.Notify(src, Locale('cid.interrogation_started', t.PlayerData.charinfo.firstname .. ' ' .. t.PlayerData.charinfo.lastname), 'info')
    TriggerClientEvent('cid:client:interrogationLight', targetId, true)
    exports['discord-logs']:LogCustom(src, 'CID Interrogation', 'Interrogating ' .. t.PlayerData.charinfo.firstname .. ' ' .. t.PlayerData.charinfo.lastname)
end)

RegisterNetEvent('cid:server:getTeamStatus', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    local online = QBox.Functions.GetPlayers()
    local msg = Locale('cid.team_status_header')
    for _, sid in ipairs(online) do
        local pl = QBox.Functions.GetPlayer(sid)
        if pl and pl.PlayerData.job.name == 'cid' then
            msg = msg .. '\n' .. pl.PlayerData.charinfo.firstname .. ' ' .. pl.PlayerData.charinfo.lastname .. ' [' .. (pl.PlayerData.job.onduty and Locale('cid.on_duty') or Locale('cid.off_duty')) .. ']'
        end
    end
    Wrappers.Notify(src, msg, 'info')
end)

RegisterNetEvent('cid:server:getFootage', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.query('SELECT * FROM surveillance_footage ORDER BY timestamp DESC LIMIT 20', {}, function(r)
        if r and #r > 0 then
            local msg = Locale('cid.footage_header')
            for _, f in ipairs(r) do
                msg = msg .. '\n' .. f.label .. ' - ' .. f.timestamp
            end
            Wrappers.Notify(src, msg, 'info')
        else
            Wrappers.Notify(src, Locale('cid.no_footage'), 'info')
        end
    end)
end)
