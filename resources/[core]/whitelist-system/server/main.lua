local QBox = exports['qbx_core']:GetCoreObject()

local function isAdmin(src)
    local player = QBox.Functions.GetPlayer(src)
    if not player then return false end
    for _, g in ipairs(Config.Whitelist.adminGroups) do
        if player.PlayerData.group == g then return true end
    end
    return false
end

local function sendWebhook(title, description, color)
    if Config.Whitelist.discordWebhook and Config.Whitelist.discordWebhook ~= '' then
        PerformHttpRequest(Config.Whitelist.discordWebhook, function() end, 'POST', json.encode({
            embeds = { { title = title, description = description, color = color or 3092790 } }
        }), { ['Content-Type'] = 'application/json' })
    end
end

--- Check whitelist on connection
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    if not Config.Whitelist.enabled then return end
    local src = source
    local license = QBox.Functions.GetIdentifier(src)
    if not license then return end

    -- Bypass for admin groups
    local player = QBox.Functions.GetPlayer(src)
    if player then
        for _, g in ipairs(Config.Whitelist.bypassGroups) do
            if player.PlayerData.group == g then return end
        end
    end

    deferrals.defer()
    Citizen.Wait(100)

    local row = MySQL.single.await('SELECT status FROM whitelist WHERE license = ?', { license })
    if row then
        if row.status == 'approved' then
            deferrals.done()
            return
        elseif row.status == 'pending' then
            deferrals.done('Your application is still under review')
            return
        elseif row.status == 'rejected' then
            deferrals.done('Your whitelist application was rejected')
            return
        end
    end

    -- Not in whitelist — auto-apply
    if Config.Whitelist.requireApplication then
        MySQL.insert('INSERT INTO whitelist (license, name, status) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE name = VALUES(name)', { license, name, 'pending' })
        deferrals.done('You are not whitelisted. Your application has been submitted for review.')
        sendWebhook('New Whitelist Application', name .. ' (' .. license .. ') has applied', 16753920)
    else
        deferrals.done('You are not whitelisted. Contact staff to be added.')
    end
end)

--- Approve whitelist
RegisterNetEvent('whitelist:server:approve', function(targetSrc)
    local src = source
    if not isAdmin(src) then return end
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end
    local license = QBox.Functions.GetIdentifier(targetSrc)
    MySQL.update('UPDATE whitelist SET status = ? WHERE license = ?', { 'approved', license })
    sendWebhook('Whitelist Approved', target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname .. ' was approved', 3066993)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Approved' })
end)

--- Reject whitelist
RegisterNetEvent('whitelist:server:reject', function(targetSrc, reason)
    local src = source
    if not isAdmin(src) then return end
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
        return
    end
    local license = QBox.Functions.GetIdentifier(src)
    MySQL.update('UPDATE whitelist SET status = ? WHERE license = ?', { 'rejected', license })
    sendWebhook('Whitelist Rejected', target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname .. ': ' .. (reason or 'No reason'), 15158332)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Rejected: ' .. (reason or 'No reason') })
end)

--- Check if player is whitelisted
QBox.Functions.CreateCallback('whitelist:server:getPending', function(source, cb)
    if not isAdmin(source) then cb({}) return end
    local rows = MySQL.query.await('SELECT license, name, created_at FROM whitelist WHERE status = ?', { 'pending' })
    cb(rows or {})
end)

--- Add license manually
RegisterNetEvent('whitelist:server:add', function(license, name)
    local src = source
    if not isAdmin(src) then return end
    MySQL.insert('INSERT INTO whitelist (license, name, status) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE status = VALUES(status)', { license, name or 'Manual', 'approved' })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Added to whitelist' })
end)

QBox.Commands.Add('whitelistapprove', 'Approve a player whitelist by server ID', {}, false, function(source, args)
    local target = tonumber(args[1])
    if target then TriggerEvent('whitelist:server:approve', target) end
end)

QBox.Commands.Add('whitelistreject', 'Reject a player whitelist by server ID', {}, false, function(source, args)
    local target = tonumber(args[1])
    local reason = table.concat(args, ' ', 2)
    if target then TriggerEvent('whitelist:server:reject', target, reason) end
end)

QBox.Commands.Add('whitelistadd', 'Add a license to whitelist', {}, false, function(source, args)
    local license = args[1]
    local name = args[2]
    if license then TriggerEvent('whitelist:server:add', license, name) end
end)
