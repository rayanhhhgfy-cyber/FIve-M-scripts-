local QBox = exports['qbx-core']:GetCoreObject()
local collectedFines = {}

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

RegisterNetEvent('fines:server:issue', function(targetId, fineId, amount, label, reason)
    local src = source
    if not checkRateLimit(src, 'issueFine', 30) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player or not player.PlayerData.job.onduty then
        Wrappers.Notify(src, Locale('police.not_on_duty'), 'error')
        return
    end
    local target = QBox.Functions.GetPlayer(targetId)
    if not target then
        Wrappers.Notify(src, Locale('police.player_not_found'), 'error')
        return
    end
    local finalAmount = amount
    MySQL.insert('INSERT INTO fines (citizenid, issued_by, fine_id, label, amount, reason, date) VALUES (?, ?, ?, ?, ?, ?, NOW())',
        { target.PlayerData.citizenid, player.PlayerData.citizenid, fineId, label, finalAmount, reason or '' })
    if not collectedFines[target.PlayerData.citizenid] then
        collectedFines[target.PlayerData.citizenid] = 0
    end
    collectedFines[target.PlayerData.citizenid] = collectedFines[target.PlayerData.citizenid] + finalAmount
    TriggerClientEvent('fines:client:paymentResult', src, true, label, finalAmount)
    TriggerClientEvent('fines:client:notifyFine', targetId, label, finalAmount, player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname)
    exports['discord-logs']:LogCustom(src, 'Fine Issued', label .. ' $' .. finalAmount .. ' to ' .. target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname)
end)

QBox.Functions.CreateCallback('fines:server:getOutstandingFines', function(source, cb)
    local player = QBox.Functions.GetPlayer(source)
    if not player then cb(0) return end
    MySQL.query('SELECT SUM(amount) as total FROM fines WHERE citizenid = ? AND paid = 0',
        { player.PlayerData.citizenid }, function(result)
        cb(result and result[1] and result[1].total or 0)
    end)
end)

RegisterNetEvent('fines:server:payFine', function(fineId)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    MySQL.query('SELECT * FROM fines WHERE id = ? AND citizenid = ? AND paid = 0',
        { fineId, player.PlayerData.citizenid }, function(result)
        if result and #result > 0 then
            local fine = result[1]
            if player.Functions.RemoveMoney('bank', fine.amount) then
                MySQL.update('UPDATE fines SET paid = 1, paid_date = NOW() WHERE id = ?', { fineId })
                collectedFines[player.PlayerData.citizenid] = (collectedFines[player.PlayerData.citizenid] or 0) - fine.amount
                Wrappers.Notify(src, Locale('police.fine_paid', fine.amount), 'success')
            else
                Wrappers.Notify(src, Locale('police.insufficient_funds'), 'error')
            end
        end
    end)
end)
