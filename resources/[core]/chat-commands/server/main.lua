-- Server-side chat commands handle routing messages to nearby players
local QBox = exports['qbx_core']:GetCoreObject()

RegisterNetEvent('chat:server:sendMe', function(msg)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player or not msg then return end
    local name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local players = QBox.Functions.GetPlayers()
    for _, s in ipairs(players) do
        local tPed = GetPlayerPed(s)
        local tCoords = GetEntityCoords(tPed)
        if #(coords - tCoords) <= Config.ChatCommands.range.me then
            TriggerClientEvent('chat:addMessage', s, { args = { '* ' .. name .. ' ' .. msg }, color = { 255, 180, 180 } })
        end
    end
end)

RegisterNetEvent('chat:server:sendDo', function(msg)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player or not msg then return end
    local name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local players = QBox.Functions.GetPlayers()
    for _, s in ipairs(players) do
        local tPed = GetPlayerPed(s)
        local tCoords = GetEntityCoords(tPed)
        if #(coords - tCoords) <= Config.ChatCommands.range['do'] then
            TriggerClientEvent('chat:addMessage', s, { args = { '* ' .. name .. ' *', '', msg }, color = { 200, 200, 255 } })
        end
    end
end)

RegisterNetEvent('chat:server:sendTry', function(msg)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player or not msg then return end
    local name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local success = math.random(2) == 1
    local result = success and '++ Success' or '-- Fail'
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local players = QBox.Functions.GetPlayers()
    for _, s in ipairs(players) do
        local tPed = GetPlayerPed(s)
        local tCoords = GetEntityCoords(tPed)
        if #(coords - tCoords) <= Config.ChatCommands.range.try then
            TriggerClientEvent('chat:addMessage', s, { args = { '* ' .. name .. ' tries to ' .. msg .. ' *', '* ' .. result .. ' *' }, color = { 255, 255, 180 } })
        end
    end
end)

RegisterNetEvent('chat:server:sendOOC', function(msg)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player or not msg then return end
    local name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local players = QBox.Functions.GetPlayers()
    for _, s in ipairs(players) do
        local tPed = GetPlayerPed(s)
        local tCoords = GetEntityCoords(tPed)
        if #(coords - tCoords) <= Config.ChatCommands.range.ooc then
            TriggerClientEvent('chat:addMessage', s, { args = { 'OOC | ' .. name .. ': ' .. msg }, color = { 180, 180, 180 } })
        end
    end
end)

RegisterNetEvent('chat:server:sendB', function(msg)
    local src = source
    local player = QBox.Functions.GetPlayer(src)
    if not player or not msg then return end
    local name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    TriggerClientEvent('chat:addMessage', -1, { args = { '(( ' .. name .. ': ' .. msg .. ' ))' }, color = { 150, 150, 150 } })
end)
