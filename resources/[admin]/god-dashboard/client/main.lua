local QBox = exports['qbx-core']:GetCoreObject()

GodDashboard = {}

local function isAdmin()
    local group = QBox.Functions.GetPlayerData().group
    if not group then return false end
    for _, g in ipairs(Config.GodDashboard.adminGroups) do
        if group == g then return true end
    end
    return false
end

local function setupNuiCallbacks()
    RegisterNUICallback('godDashboardReady', function(_, cb)
        cb({ admin = isAdmin(), locale = GetConvar('locale', 'en') })
    end)

    RegisterNUICallback('getBunkers', function(_, cb)
        QBox.Functions.TriggerCallback('god-dashboard:getBunkers', function(list)
            cb(list or {})
        end)
    end)

    RegisterNUICallback('teleportToBunker', function(data, cb)
        GodDashboard.TeleportToBunker(data.id)
        cb({ success = true })
    end)

    RegisterNUICallback('deleteBunker', function(data, cb)
        GodDashboard.DeleteBunker(data.id)
        cb({ success = true })
    end)

    RegisterNUICallback('duplicateBunker', function(data, cb)
        GodDashboard.DuplicateBunker(data.id)
        cb({ success = true })
    end)

    RegisterNUICallback('updateBunker', function(data, cb)
        GodDashboard.UpdateBunker(data.id, data.data)
        cb({ success = true })
    end)

    RegisterNUICallback('getObjects', function(_, cb)
        QBox.Functions.TriggerCallback('god-dashboard:getPlacedObjects', function(objects)
            cb(objects or {})
        end)
    end)

    RegisterNUICallback('placeObject', function(data, cb)
        GodDashboard.PlaceObject(data.model)
        cb({ success = true })
    end)

    RegisterNUICallback('deleteObject', function(data, cb)
        GodDashboard.DeletePlacedObject(data.id)
        cb({ success = true })
    end)

    RegisterNUICallback('teleportToObject', function(data, cb)
        GodDashboard.TeleportToObject(data.id)
        cb({ success = true })
    end)

    RegisterNUICallback('getDoors', function(_, cb)
        QBox.Functions.TriggerCallback('god-dashboard:getDoors', function(doors)
            cb(doors or {})
        end)
    end)

    RegisterNUICallback('createDoor', function(data, cb)
        GodDashboard.CreateDoor(data)
        cb({ success = true })
    end)

    RegisterNUICallback('deleteDoor', function(data, cb)
        GodDashboard.DeleteDoor(data.id)
        cb({ success = true })
    end)

    RegisterNUICallback('updateDoorPasscode', function(data, cb)
        GodDashboard.UpdateDoorPasscode(data.id, data.passcode)
        cb({ success = true })
    end)

    RegisterNUICallback('spawnVehicle', function(data, cb)
        GodDashboard.SpawnVehicle(data.model)
        cb({ success = true })
    end)

    RegisterNUICallback('getCommands', function(_, cb)
        QBox.Functions.TriggerCallback('god-dashboard:getCommands', function(commands)
            cb(commands or {})
        end)
    end)

    RegisterNUICallback('getPlayers', function(_, cb)
        QBox.Functions.TriggerCallback('god-dashboard:getPlayers', function(players)
            cb(players or {})
        end)
    end)

    RegisterNUICallback('serverAction', function(data, cb)
        if data.action == 'weather' then
            TriggerServerEvent('god-dashboard:setWeather', data.value)
        elseif data.action == 'time' then
            TriggerServerEvent('god-dashboard:setTime', data.value)
        elseif data.action == 'announce' then
            TriggerServerEvent('god-dashboard:announce', data.value)
        elseif data.action == 'revive' then
            TriggerServerEvent('god-dashboard:revive', data.target)
        elseif data.action == 'clearArea' then
            TriggerServerEvent('god-dashboard:clearArea')
        elseif data.action == 'kickPlayer' then
            TriggerServerEvent('god-dashboard:kickPlayer', data.target, data.reason)
        elseif data.action == 'freezePlayer' then
            TriggerServerEvent('god-dashboard:freezePlayer', data.target)
        elseif data.action == 'teleportToPlayer' then
            TriggerServerEvent('god-dashboard:teleportToPlayer', data.target)
        elseif data.action == 'bringPlayer' then
            TriggerServerEvent('god-dashboard:bringPlayer', data.target)
        end
        cb({ success = true })
    end)

    RegisterNUICallback('closeDashboard', function(_, cb)
        SetNuiFocus(false, false)
        cb({})
    end)
end

local function setupPreviewThread()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            if preview then
                preview.updatePosition()
            end
        end
    end)
end

RegisterNetEvent('god-dashboard:open', function()
    if not isAdmin() then
        Wrappers.Notify('Access denied', 'error')
        return
    end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end)

RegisterNetEvent('god-dashboard:notify', function(msg, type)
    Wrappers.Notify(msg, type or 'info')
end)

QBox.Commands.Add('god', 'Open god admin dashboard', {}, false, function(source)
    TriggerClientEvent('god-dashboard:open', source)
end, { 'admin', 'superadmin', 'god' })

setupNuiCallbacks()
setupPreviewThread()

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    if preview then preview.cleanup() end
    SetNuiFocus(false, false)
end)
