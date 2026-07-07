local QBox = exports['qbx-core']:GetCoreObject()
local activeBugFeeds = {}

local function generateBugId()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local id = 'BUG-'
    for i = 1, 8 do
        id = id .. chars:sub(math.random(#chars), math.random(#chars))
    end
    return id
end

--- Deploy a surveillance bug
RegisterNetEvent('svb:server:deployBug', function(bugType, coords, heading)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    local bugConfig = Config.SurveillanceBugs.BugTypes[bugType]
    if not bugConfig then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Invalid bug type' })
        return
    end

    -- Check max active bugs
    MySQL.query('SELECT COUNT(*) as count FROM cid_surveillance_bugs WHERE placed_by = ? AND active = TRUE', {
        player.PlayerData.citizenid
    }, function(result)
        local count = (result and result[1] and result[1].count) or 0
        if count >= Config.SurveillanceBugs.MaxActiveBugsPerPlayer then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Maximum active bugs reached (' .. Config.SurveillanceBugs.MaxActiveBugsPerPlayer .. ')' })
            return
        end

        local placedAt = os.time()
        local expiresAt = bugConfig.duration > 0 and (placedAt + bugConfig.duration) or (placedAt + 31536000)

        MySQL.insert('INSERT INTO cid_surveillance_bugs (bug_type, pos_x, pos_y, pos_z, heading, placed_by, placed_at, expires_at, active, feed_data) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            bugType, coords.x, coords.y, coords.z, heading or 0, player.PlayerData.citizenid, placedAt, expiresAt, true, '{}'
        }, function(bugId)
            TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = bugConfig.label .. ' deployed successfully' })
            local pCoords = GetEntityCoords(GetPlayerPed(src))
            TriggerEvent('svb:server:logActivity', player.PlayerData.citizenid, 'deploy', 'Deployed ' .. bugConfig.label .. ' at ' .. tostring(coords.x) .. ', ' .. tostring(coords.y))
        end)
    end)
end)

--- Get active bugs for the surveillance console
QBox.Functions.CreateCallback('svb:server:getActiveBugs', function(source, cb)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then cb({}) return end

    MySQL.query('SELECT * FROM cid_surveillance_bugs WHERE active = TRUE ORDER BY placed_at DESC', function(bugs)
        cb(bugs or {})
    end)
end)

--- Deactivate a bug
RegisterNetEvent('svb:server:deactivateBug', function(bugId)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    MySQL.update('UPDATE cid_surveillance_bugs SET active = FALSE WHERE id = ?', { bugId })
    if activeBugFeeds[bugId] then
        activeBugFeeds[bugId] = nil
    end
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Bug deactivated' })
end)

--- Expiry cleanup thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        MySQL.query('SELECT id, bug_type, pos_x, pos_y, pos_z FROM cid_surveillance_bugs WHERE active = TRUE AND expires_at <= ?', { os.time() }, function(expired)
            if expired and #expired > 0 then
                for _, bug in ipairs(expired) do
                    MySQL.update('UPDATE cid_surveillance_bugs SET active = FALSE WHERE id = ?', { bug.id })
                    TriggerEvent('svb:server:logActivity', 'system', 'expire', bug.bug_type .. ' expired at ' .. tostring(bug.pos_x))
                end
            end
        end)
    end
end)

--- Feed data update (simulated - camera captures)
RegisterNetEvent('svb:server:updateFeed', function(bugId, feedData)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end

    local feedJson = json.encode(feedData)
    MySQL.update('UPDATE cid_surveillance_bugs SET feed_data = ? WHERE id = ?', { feedJson, bugId })
end)

--- Activity logging
RegisterNetEvent('svb:server:logActivity', function(cid, action, details)
    -- Log to a table or just console for now
    -- Could also log to admin_logs or a specific svb_logs table
end)
