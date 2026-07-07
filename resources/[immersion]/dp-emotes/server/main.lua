local QBCore = exports['qbx_core']:GetCoreObject()
local activeShared = {}

RegisterNetEvent('dp-emotes:server:playShared', function(target, emoteName)
    local source = source
    if not source or not target then return end
    local emote = Emotes.Shared[emoteName]
    if not emote then return end
    local dist = #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(GetPlayerPed(target)))
    if dist > 3.0 then return end
    activeShared[source] = { target = target, emote = emoteName }
    activeShared[target] = { target = source, emote = emoteName }
    TriggerClientEvent('dp-emotes:client:playShared', source, target, emote, 'initiator')
    TriggerClientEvent('dp-emotes:client:playShared', target, source, emote, 'target')
end)

RegisterNetEvent('dp-emotes:server:cancelShared', function(target)
    local source = source
    if not source then return end
    activeShared[source] = nil
    if activeShared[target] then
        local other = activeShared[target]
        activeShared[target] = nil
        TriggerClientEvent('dp-emotes:client:cancelShared', target)
        TriggerClientEvent('dp-emotes:client:cancelShared', source)
    end
end)

AddEventHandler('playerDropped', function()
    local source = source
    if activeShared[source] then
        local other = activeShared[source].target
        activeShared[other] = nil
        TriggerClientEvent('dp-emotes:client:cancelShared', other)
        activeShared[source] = nil
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[dp-emotes] Emote system initialized. %d emotes, %d walking styles, %d shared emotes.^7',
        #Emotes.List, #Emotes.WalkingStyles, #Emotes.Shared)
end)
