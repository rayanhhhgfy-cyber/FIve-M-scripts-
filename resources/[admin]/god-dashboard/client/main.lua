local QBox = exports['qbx_core']:GetCoreObject()

GodDashboard = {}

local function isAdmin()
    local group = QBox.Functions.GetPlayerData().group
    if not group then return false end
    for _, g in ipairs(Config.GodDashboard.adminGroups) do
        if group == g then return true end
    end
    return false
end

local noclipActive = false
local spectateTarget = nil

local function setupNuiCallbacks()
    RegisterNUICallback('godDashboardReady', function(_, cb)
        cb({ admin = isAdmin(), locale = GetConvar('locale', 'en') })
    end)

    RegisterNUICallback('toggleNoclip', function(_, cb)
        if not isAdmin() then cb({ noclip = false }) return end
        noclipActive = not noclipActive
        local ped = PlayerPedId()
        if noclipActive then
            SetEntityInvincible(ped, true)
            SetPlayerInvincible(PlayerId(), true)
            FreezeEntityPosition(ped, true)
            Wrappers.Notify('Noclip enabled', 'success')
            Citizen.CreateThread(function()
                while noclipActive do
                    Citizen.Wait(0)
                    local pPed = PlayerPedId()
                    local speed = 2.0
                    if IsControlPressed(0, 21) then speed = 6.0 end
                    local up = IsControlPressed(0, 22)
                    local down = IsControlPressed(0, 36)
                    local coords = GetEntityCoords(pPed)
                    FreezeEntityPosition(pPed, true)
                    SetEntityVisible(pPed, false, false)
                    local rot = GetGameplayCamRot(2)
                    local forward = vector3(
                        -math.sin(rot.z * math.pi / 180.0) * math.cos(rot.x * math.pi / 180.0),
                        math.cos(rot.z * math.pi / 180.0) * math.cos(rot.x * math.pi / 180.0),
                        math.sin(rot.x * math.pi / 180.0)
                    )
                    local newPos = coords + forward * speed
                    if up then newPos = newPos + vector3(0, 0, speed) end
                    if down then newPos = newPos - vector3(0, 0, speed) end
                    SetEntityCoords(pPed, newPos.x, newPos.y, newPos.z, false, false, false, false)
                end
            end)
        else
            SetEntityInvincible(ped, false)
            SetPlayerInvincible(PlayerId(), false)
            FreezeEntityPosition(ped, false)
            SetEntityVisible(ped, true, false)
            Wrappers.Notify('Noclip disabled', 'info')
        end
        cb({ noclip = noclipActive })
    end)

    RegisterNUICallback('toggleSpectate', function(data, cb)
        if not isAdmin() then cb({ spectating = false }) return end
        if data.id then
            local target = GetPlayerFromServerId(data.id)
            if target ~= -1 then
                spectateTarget = target
                local targetPed = GetPlayerPed(target)
                NetworkSetInSpectatorMode(true, targetPed)
                Wrappers.Notify('Spectating player ' .. data.id, 'info')
            end
        else
            NetworkSetInSpectatorMode(false, nil)
            spectateTarget = nil
            Wrappers.Notify('Spectate ended', 'info')
        end
        cb({ spectating = spectateTarget ~= nil })
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
        elseif data.action == 'giveMoney' then
            TriggerServerEvent('god-dashboard:giveMoney', data.target, data.amount, data.moneyType)
        elseif data.action == 'giveAllMoney' then
            TriggerServerEvent('god-dashboard:giveAllMoney', data.amount, data.moneyType)
        elseif data.action == 'giveItem' then
            TriggerServerEvent('god-dashboard:giveItem', data.target, data.item, data.count)
        elseif data.action == 'spawnItem' then
            TriggerServerEvent('god-dashboard:spawnItem', data.target, data.item, data.count)
        elseif data.action == 'giveAllItem' then
            TriggerServerEvent('god-dashboard:giveAllItem', data.item, data.count)
        elseif data.action == 'removeItem' then
            TriggerServerEvent('god-dashboard:removeItem', data.target, data.item, data.count)
        elseif data.action == 'slapPlayer' then
            TriggerServerEvent('god-dashboard:slapPlayer', data.target)
        elseif data.action == 'healPlayer' then
            TriggerServerEvent('god-dashboard:healPlayer', data.target)
        elseif data.action == 'giveArmor' then
            TriggerServerEvent('god-dashboard:giveArmor', data.target, data.amount)
        elseif data.action == 'warnPlayer' then
            TriggerServerEvent('god-dashboard:warnPlayer', data.target, data.reason)
        elseif data.action == 'setJob' then
            TriggerServerEvent('god-dashboard:setJob', data.target, data.job, data.grade)
        elseif data.action == 'setGroup' then
            TriggerServerEvent('god-dashboard:setGroup', data.target, data.group)
        elseif data.action == 'setPlayerStat' then
            TriggerServerEvent('god-dashboard:setPlayerStat', data.target, data.statType, data.value)
        elseif data.action == 'setAllJob' then
            TriggerServerEvent('god-dashboard:setAllJob', data.job, data.grade)
        elseif data.action == 'giveCarToGarage' then
            TriggerServerEvent('god-dashboard:giveCarToGarage', data.target, data.vehicle)
        elseif data.action == 'transferVehicle' then
            TriggerServerEvent('god-dashboard:transferVehicle', data.plate, data.target)
        elseif data.action == 'killAll' then
            TriggerServerEvent('god-dashboard:killAll')
        elseif data.action == 'freezeAll' then
            TriggerServerEvent('god-dashboard:freezeAll', data.state)
        elseif data.action == 'teleportAllToMe' then
            TriggerServerEvent('god-dashboard:teleportAllToMe')
        elseif data.action == 'reviveAll' then
            TriggerServerEvent('god-dashboard:reviveAll')
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

RegisterCommand('+god', function()
    TriggerEvent('god-dashboard:open')
end, false)
RegisterCommand('-god', function() end, false)
RegisterKeyMapping('+god', 'Open God Admin Dashboard', 'keyboard', 'F6')

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

RegisterCommand('+god', function()
    TriggerServerEvent('god-dashboard:checkAndOpen')
end, false)

RegisterCommand('-god', function() end, false)

RegisterKeyMapping('+god', 'Open God Admin Dashboard', 'keyboard', 'F6')


--- Ported Client Actions ---
local isNoclip = false
RegisterNetEvent('god-dashboard:client:toggleNoclip', function()
    isNoclip = not isNoclip
    local ped = PlayerPedId()
    SetEntityVisible(ped, not isNoclip, false)
    SetEntityCollision(ped, not isNoclip, not isNoclip)
    SetPlayerInvincible(PlayerId(), isNoclip)
    exports['ox_lib']:notify({ type = 'info', description = 'Noclip ' .. (isNoclip and 'enabled' or 'disabled') })
end)

RegisterNetEvent('god-dashboard:client:spectate', function(targetServerId)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetServerId))
    if DoesEntityExist(targetPed) then
        NetworkSetInSpectatorMode(true, targetPed)
        exports['ox_lib']:notify({ type = 'info', description = 'Spectating ID ' .. targetServerId })
    end
end)

RegisterNetEvent('god-dashboard:client:slap', function()
    local ped = PlayerPedId()
    ApplyForceToEntity(ped, 1, 0.0, 10.0, 10.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
    SetEntityHealth(ped, math.max(100, GetEntityHealth(ped) - 10))
end)

RegisterNetEvent('god-dashboard:client:setArmor', function(amount)
    SetPedArmour(PlayerPedId(), amount or 100)
end)

RegisterNetEvent('god-dashboard:client:kill', function()
    SetEntityHealth(PlayerPedId(), 0)
end)

RegisterNetEvent('god-dashboard:client:freeze', function()
    local ped = PlayerPedId()
    local frozen = IsEntityPositionFrozen(ped)
    FreezeEntityPosition(ped, not frozen)
end)
