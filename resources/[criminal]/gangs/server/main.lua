local QBox = exports['qbx-core']:GetCoreObject()
local rateLimits = {}
local pendingInvites = {}

local function isRateLimited(src, key, limit, window)
    if not rateLimits[src] then rateLimits[src] = {} end
    local now = os.time()
    if not rateLimits[src][key] then rateLimits[src][key] = 0 end
    if now - rateLimits[src][key] < window then return true end
    rateLimits[src][key] = now
    return false
end

local function getGangData(gangName)
    local result = MySQL.single.await('SELECT * FROM gangs WHERE name = ?', { gangName })
    return result
end

local function getGangMembers(gangName)
    local result = MySQL.query.await('SELECT citizenid, gang_grade FROM players WHERE gang = ?', { gangName })
    return result
end

local function getPlayerGang(citizenid)
    local result = MySQL.single.await('SELECT gang, gang_grade FROM players WHERE citizenid = ?', { citizenid })
    return result
end

RegisterNetEvent('gangs:server:createGang', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    if isRateLimited(src, 'create_gang', 1, Config.GangCreation.cooldown) then
        return Wrappers.Notify(src, 'You must wait before creating another gang', 'error')
    end
    local current = getPlayerGang(player.PlayerData.citizenid)
    if current and current.gang then
        return Wrappers.Notify(src, 'Leave your current gang first', 'error')
    end
    local input = ox_lib:inputDialog(src, 'Create Gang', {
        { type = 'input', label = 'Gang Name', required = true, min = 3, max = 32 },
        { type = 'select', label = 'Label (optional)', options = Config.GangLabels }
    })
    if not input then return end
    local gangName = input[1]
    local existing = getGangData(gangName)
    if existing then
        return Wrappers.Notify(src, 'That gang name is already taken', 'error')
    end
    local money = player.Functions.GetMoney('bank')
    if money < Config.GangCreation.cost then
        return Wrappers.Notify(src, 'You need $' .. Config.GangCreation.cost, 'error')
    end
    player.Functions.RemoveMoney('bank', Config.GangCreation.cost)
    MySQL.insert('INSERT INTO gangs (name, label, leader, created_at) VALUES (?, ?, ?, NOW())', {
        gangName, input[2] or gangName, player.PlayerData.citizenid
    })
    MySQL.update('UPDATE players SET gang = ?, gang_grade = 4 WHERE citizenid = ?', {
        gangName, player.PlayerData.citizenid
    })
    TriggerClientEvent('gangs:client:setGang', src, gangName, 4)
    Wrappers.Notify(src, 'You are now the leader of ' .. gangName, 'success')
    exports['discord-logs']:sendLog('gang_created', {
        message = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname .. ' created gang ' .. gangName,
        color = 'green'
    })
end)

RegisterNetEvent('gangs:server:requestJoin', function(gangName)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local current = getPlayerGang(player.PlayerData.citizenid)
    if current and current.gang then
        return Wrappers.Notify(src, 'Leave your current gang first', 'error')
    end
    local gang = getGangData(gangName)
    if not gang then
        return Wrappers.Notify(src, 'That gang does not exist', 'error')
    end
    local members = getGangMembers(gangName)
    local canInvite = false
    for _, member in ipairs(members) do
        if member.citizenid == player.PlayerData.citizenid then
            canInvite = true
            break
        end
    end
    if not canInvite then
        local leaderData = MySQL.single.await('SELECT citizenid FROM gangs WHERE name = ?', { gangName })
        if leaderData then
            TriggerClientEvent('gangs:client:joinRequest', leaderData.citizenid, player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname, src)
            Wrappers.Notify(src, 'The gang leader has been notified', 'inform')
        end
    end
end)

RegisterNetEvent('gangs:server:inviteNearest', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local gang = getPlayerGang(player.PlayerData.citizenid)
    if not gang or not gang.gang then
        return Wrappers.Notify(src, 'You are not in a gang', 'error')
    end
    local coords = GetEntityCoords(GetPlayerPed(src))
    local nearest = nil
    local nearestDist = 5.0
    for _, otherSrc in ipairs(GetPlayers()) do
        if otherSrc ~= src then
            local otherPed = GetPlayerPed(otherSrc)
            local otherCoords = GetEntityCoords(otherPed)
            local dist = #(coords - otherCoords)
            if dist < nearestDist then
                local otherPlayer = QBox.Functions.GetPlayer(otherSrc)
                if otherPlayer then
                    local otherGang = getPlayerGang(otherPlayer.PlayerData.citizenid)
                    if not otherGang or not otherGang.gang then
                        nearest = otherSrc
                        nearestDist = dist
                    end
                end
            end
        end
    end
    if not nearest then
        return Wrappers.Notify(src, 'No eligible players nearby', 'error')
    end
    pendingInvites[nearest] = { gang = gang.gang, inviter = src }
    local inviterName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    TriggerClientEvent('gangs:client:invitePrompt', nearest, inviterName)
end)

RegisterNetEvent('gangs:server:acceptInvite', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local invite = pendingInvites[src]
    if not invite then
        return Wrappers.Notify(src, 'You have no pending invites', 'error')
    end
    local current = getPlayerGang(player.PlayerData.citizenid)
    if current and current.gang then
        pendingInvites[src] = nil
        return Wrappers.Notify(src, 'Leave your current gang first', 'error')
    end
    MySQL.update('UPDATE players SET gang = ?, gang_grade = 0 WHERE citizenid = ?', {
        invite.gang, player.PlayerData.citizenid
    })
    TriggerClientEvent('gangs:client:setGang', src, invite.gang, 0)
    Wrappers.Notify(src, 'You joined ' .. invite.gang, 'success')
    pendingInvites[src] = nil
end)

RegisterNetEvent('gangs:server:leaveGang', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local gang = getPlayerGang(player.PlayerData.citizenid)
    if not gang or not gang.gang then
        return Wrappers.Notify(src, 'You are not in a gang', 'error')
    end
    if gang.gang_grade >= 4 then
        local members = getGangMembers(gang.gang)
        local otherLeaders = 0
        for _, member in ipairs(members) do
            if member.grade >= 4 and member.citizenid ~= player.PlayerData.citizenid then
                otherLeaders = otherLeaders + 1
            end
        end
        if otherLeaders == 0 then
            MySQL.update('UPDATE players SET gang = NULL, gang_grade = NULL WHERE gang = ?', { gang.gang })
            MySQL.execute('DELETE FROM gangs WHERE name = ?', { gang.gang })
            TriggerClientEvent('gangs:client:setGang', src, nil, 0)
            Wrappers.Notify(src, 'Your gang has been disbanded', 'inform')
            return
        end
    end
    MySQL.update('UPDATE players SET gang = NULL, gang_grade = NULL WHERE citizenid = ?', {
        player.PlayerData.citizenid
    })
    TriggerClientEvent('gangs:client:setGang', src, nil, 0)
    Wrappers.Notify(src, 'You left your gang', 'inform')
end)

RegisterNetEvent('gangs:server:memberAction', function(targetCid, action)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local gang = getPlayerGang(player.PlayerData.citizenid)
    if not gang or gang.gang_grade < 3 then
        return Wrappers.Notify(src, 'You cannot manage members', 'error')
    end
    if action == 'kick' then
        MySQL.update('UPDATE players SET gang = NULL, gang_grade = NULL WHERE citizenid = ?', { targetCid })
        local targetPlayer = QBox.Functions.GetPlayerByCitizenId(targetCid)
        if targetPlayer then
            TriggerClientEvent('gangs:client:setGang', targetPlayer.PlayerData.source, nil, 0)
            Wrappers.Notify(targetPlayer.PlayerData.source, 'You were kicked from the gang', 'inform')
        end
    elseif action == 'promote' then
        local targetGang = MySQL.single.await('SELECT gang, gang_grade FROM players WHERE citizenid = ?', { targetCid })
        if targetGang and targetGang.gang == gang.gang and targetGang.gang_grade < 4 then
            MySQL.update('UPDATE players SET gang_grade = gang_grade + 1 WHERE citizenid = ?', { targetCid })
        end
    elseif action == 'demote' then
        local targetGang = MySQL.single.await('SELECT gang, gang_grade FROM players WHERE citizenid = ?', { targetCid })
        if targetGang and targetGang.gang == gang.gang and targetGang.gang_grade > 0 then
            MySQL.update('UPDATE players SET gang_grade = gang_grade - 1 WHERE citizenid = ?', { targetCid })
        end
    end
end)

RegisterNetEvent('gangs:server:getPlayerGang', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local gang = getPlayerGang(player.PlayerData.citizenid)
    if gang and gang.gang then
        TriggerClientEvent('gangs:client:setGang', src, gang.gang, gang.gang_grade)
    end
end)

RegisterNetEvent('gangs:server:getGangInfo', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local gangData = getPlayerGang(player.PlayerData.citizenid)
    if not gangData or not gangData.gang then return end
    local gang = getGangData(gangData.gang)
    if not gang then return end
    local members = getGangMembers(gangData.gang)
    local info = 'Gang: ' .. gang.label .. '\nLeader: ' .. gang.leader .. '\nMembers: ' .. #members
    TriggerClientEvent('gangs:client:receiveInfo', src, info)
end)

RegisterNetEvent('gangs:server:getMembers', function()
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local gangData = getPlayerGang(player.PlayerData.citizenid)
    if not gangData or not gangData.gang then return end
    local members = getGangMembers(gangData.gang)
    local memberList = {}
    for _, member in ipairs(members) do
        local memberPlayer = QBox.Functions.GetPlayerByCitizenId(member.citizenid)
        local name = 'Unknown'
        if memberPlayer then
            name = memberPlayer.PlayerData.charinfo.firstname .. ' ' .. memberPlayer.PlayerData.charinfo.lastname
        end
        memberList[#memberList + 1] = { citizenid = member.citizenid, name = name, grade = member.gang_grade }
    end
    TriggerClientEvent('gangs:client:showMembers', src, memberList)
end)

RegisterNetEvent('gangs:server:validateStashAccess', function(stashData)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local gang = getPlayerGang(player.PlayerData.citizenid)
    if not gang or not gang.gang then
        return Wrappers.Notify(src, 'You are not in a gang', 'error')
    end
    if gang.gang_grade >= 1 then
        stashData.id = 'gang_stash_' .. gang.gang
        stashData.owner = gang.gang
        TriggerClientEvent('gangs:client:openStash', src, stashData)
    end
end)

QBox:CreateCallback('gangs:server:getPlayerGangData', function(source, cb)
    local player = QBox.Functions.GetPlayer(source)
    if not player then return cb(nil) end
    local gang = getPlayerGang(player.PlayerData.citizenid)
    cb(gang)
end)

AddEventHandler('playerDropped', function()
    local src = source
    rateLimits[src] = nil
    pendingInvites[src] = nil
end)
