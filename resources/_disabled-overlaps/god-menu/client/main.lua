local isOwner = false
local menuOpen = false
local noclipActive = false
local spectateTarget = nil

local function checkOwner(cb)
    lib.callback('god:server:checkOwner', false, function(ok)
        if ok then isOwner = true end
        cb(ok)
    end)
end

RegisterCommand(Config.GodMenu.command, function()
    checkOwner(function(ok)
        if not ok then
            Wrappers.Notify('God Menu', 'Access denied', 'error')
            return
        end
        toggleMenu()
    end)
end)

RegisterKeyMapping('+' .. Config.GodMenu.command, 'Open God Menu', 'keyboard', Config.GodMenu.keybind)
RegisterCommand('+godmenu', function()
    checkOwner(function(ok)
        if not ok then return end
        toggleMenu()
    end)
end)

function toggleMenu()
    if menuOpen then
        menuOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
    else
        menuOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', config = Config.GodMenu })
    end
end

-- Player ID above heads on third-eye
if Config.GodMenu.showPlayerIdsOnTarget then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            local ped = PlayerPedId()
            local isTargeting = IsControlPressed(0, 24) or IsControlPressed(0, 47)
            if not isTargeting then
                isTargeting = IsControlPressed(0, 38)
            end
            if isTargeting then
                local coords = GetEntityCoords(ped)
                local closest = nil
                local closestDist = 10.0
                local players = GetActivePlayers()
                for _, p in ipairs(players) do
                    local target = GetPlayerPed(p)
                    if target ~= ped then
                        local tCoords = GetEntityCoords(target)
                        local dist = #(coords - tCoords)
                        if dist < closestDist then
                            local _, _, _, x, y, z = GetStreetNameAtCoord(tCoords.x, tCoords.y, tCoords.z)
                            local los = HasEntityClearLosToEntity(ped, target, 17)
                            if los then
                                closestDist = dist
                                closest = p
                            end
                        end
                    end
                end
                if closest ~= nil then
                    local target = GetPlayerPed(closest)
                    local tCoords = GetEntityCoords(target)
                    local heading = GetEntityHeading(target)
                    local offset = GetOffsetFromEntityInWorldCoords(target, 0.0, 0.0, 1.2)
                    local src = GetPlayerServerId(closest)
                    local name = GetPlayerName(closest)
                    local dist = math.floor(#(coords - tCoords))
                    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(offset.x, offset.y, offset.z)
                    if onScreen then
                        SetTextScale(0.0, 0.35)
                        SetTextFont(4)
                        SetTextProportional(1)
                        SetTextColour(255, 215, 0, 255)
                        SetTextOutline()
                        SetTextEntry('STRING')
                        SetTextCentre(true)
                        AddTextComponentString('ID: ' .. src .. ' | ' .. name)
                        DrawText(sx, sy)
                        SetTextScale(0.0, 0.25)
                        SetTextFont(4)
                        SetTextColour(255, 255, 255, 180)
                        SetTextOutline()
                        SetTextEntry('STRING')
                        SetTextCentre(true)
                        AddTextComponentString(dist .. 'm')
                        DrawText(sx, sy + 0.025)
                    end
                end
            end
            Citizen.Wait(100)
        end
    end)
end

-- NUI Callbacks
RegisterNUICallback('godGetPlayers', function(_, cb)
    local players = lib.callback.await('god:server:getPlayers', false)
    cb(players or {})
end)

RegisterNUICallback('godKickPlayer', function(data, cb)
    TriggerServerEvent('god:server:kickPlayer', data.id, data.reason)
    cb({})
end)

RegisterNUICallback('godBanPlayer', function(data, cb)
    TriggerServerEvent('god:server:banPlayer', data.id, data.reason)
    cb({})
end)

RegisterNUICallback('godFreezePlayer', function(data, cb)
    TriggerServerEvent('god:server:freezePlayer', data.id, data.state)
    cb({})
end)

RegisterNUICallback('godTeleportToMe', function(data, cb)
    TriggerServerEvent('god:server:teleportToMe', data.id)
    cb({})
end)

RegisterNUICallback('godTeleportToPlayer', function(data, cb)
    TriggerServerEvent('god:server:teleportToPlayer', data.id)
    cb({})
end)

RegisterNUICallback('godSlapPlayer', function(data, cb)
    TriggerServerEvent('god:server:slapPlayer', data.id)
    cb({})
end)

RegisterNUICallback('godRevivePlayer', function(data, cb)
    TriggerServerEvent('god:server:revivePlayer', data.id)
    cb({})
end)

RegisterNUICallback('godHealPlayer', function(data, cb)
    TriggerServerEvent('god:server:healPlayer', data.id)
    cb({})
end)

RegisterNUICallback('godGiveArmor', function(data, cb)
    TriggerServerEvent('god:server:giveArmor', data.id, data.amount)
    cb({})
end)

RegisterNUICallback('godGiveMoney', function(data, cb)
    TriggerServerEvent('god:server:giveMoney', data.id, data.amount, data.type)
    cb({})
end)

RegisterNUICallback('godGiveItem', function(data, cb)
    TriggerServerEvent('god:server:giveItem', data.id, data.item, data.count)
    cb({})
end)

RegisterNUICallback('godGiveAllItem', function(data, cb)
    TriggerServerEvent('god:server:giveAllItem', data.item, data.count)
    cb({})
end)

RegisterNUICallback('godSpawnVehicle', function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    QBCore = exports['qbx_core']:GetCoreObject()
    QBCore.Functions.SpawnVehicle(data.model, function(veh)
        if veh and DoesEntityExist(veh) then
            SetVehicleOnGroundProperly(veh)
            SetEntityInvincible(veh, false)
            SetVehicleEngineOn(veh, true, true, false)
            TaskWarpPedIntoVehicle(ped, veh, -1)
            SetVehicleNumberPlateText(veh, 'GOD')
            Wrappers.Notify('God Menu', 'Spawned ' .. data.model, 'success')
        end
    end, coords, heading, true, false)
    cb({})
end)

RegisterNUICallback('godFixVehicle', function(_, cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh and DoesEntityExist(veh) then
        SetVehicleFixed(veh)
        SetVehicleDirtLevel(veh, 0)
        SetVehicleEngineOn(veh, true, true, false)
        Wrappers.Notify('God Menu', 'Vehicle fixed', 'success')
    end
    cb({})
end)

RegisterNUICallback('godDeleteVehicle', function(_, cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh and DoesEntityExist(veh) then
        DeleteEntity(veh)
        Wrappers.Notify('God Menu', 'Vehicle deleted', 'success')
    end
    cb({})
end)

RegisterNUICallback('godSetWeather', function(data, cb)
    TriggerServerEvent('god:server:setWeather', data.weather)
    cb({})
end)

RegisterNUICallback('godSetTime', function(data, cb)
    TriggerServerEvent('god:server:setTime', data.hour, data.minute)
    cb({})
end)

RegisterNUICallback('godTeleport', function(data, cb)
    local ped = PlayerPedId()
    SetEntityCoords(ped, data.x, data.y, data.z, false, false, false, false)
    Wrappers.Notify('God Menu', 'Teleported', 'success')
    cb({})
end)

RegisterNUICallback('godTeleportWaypoint', function(_, cb)
    local ped = PlayerPedId()
    local waypoint = GetFirstBlipInfoId(8)
    if DoesBlipExist(waypoint) then
        local cx, cy = GetBlipInfoIdCoord(waypoint)
        local _, z = GetGroundZFor_3dCoord(cx, cy, 100.0, false)
        SetEntityCoords(ped, cx, cy, z + 2.0, false, false, false, false)
        Wrappers.Notify('God Menu', 'Teleported to waypoint', 'success')
    else
        Wrappers.Notify('God Menu', 'Set a waypoint first', 'error')
    end
    cb({})
end)

RegisterNUICallback('godAnnounce', function(data, cb)
    TriggerServerEvent('god:server:announce', data.message)
    cb({})
end)

RegisterNUICallback('godNoclip', function(_, cb)
    noclipActive = not noclipActive
    if noclipActive then
        local ped = PlayerPedId()
        SetEntityInvincible(ped, true)
        SetPlayerInvincible(PlayerId(), true)
        FreezeEntityPosition(ped, true)
        Wrappers.Notify('God Menu', 'Noclip enabled', 'success')
        Citizen.CreateThread(function()
            while noclipActive do
                Citizen.Wait(0)
                local ped = PlayerPedId()
                local speed = 2.0
                if IsControlPressed(0, 21) then speed = 6.0 end
                local up = IsControlPressed(0, 22)
                local down = IsControlPressed(0, 36)
                local coords = GetEntityCoords(ped)
                local _, _, z = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
                SetEntityCoords(ped, coords.x, coords.y, z + 0.5, false, false, false, false)
                FreezeEntityPosition(ped, true)
                SetEntityVisible(ped, false, false)
                local cam = GetGameplayCamCoord()
                local rot = GetGameplayCamRot(2)
                local forward = vector3(
                    -math.sin(rot.z * math.pi / 180.0) * math.cos(rot.x * math.pi / 180.0),
                    math.cos(rot.z * math.pi / 180.0) * math.cos(rot.x * math.pi / 180.0),
                    math.sin(rot.x * math.pi / 180.0)
                )
                local newPos = coords + forward * speed
                if up then newPos = newPos + vector3(0, 0, speed) end
                if down then newPos = newPos - vector3(0, 0, speed) end
                SetEntityCoords(ped, newPos.x, newPos.y, newPos.z, false, false, false, false)
            end
        end)
    else
        local ped = PlayerPedId()
        SetEntityInvincible(ped, false)
        SetPlayerInvincible(PlayerId(), false)
        FreezeEntityPosition(ped, false)
        SetEntityVisible(ped, true, false)
        Wrappers.Notify('God Menu', 'Noclip disabled', 'info')
    end
    cb({ noclip = noclipActive })
end)

RegisterNUICallback('godSpectate', function(data, cb)
    if data.id then
        local target = GetPlayerFromServerId(data.id)
        if target ~= -1 then
            spectateTarget = target
            local targetPed = GetPlayerPed(target)
            NetworkSetInSpectatorMode(true, targetPed)
            Wrappers.Notify('God Menu', 'Spectating ' .. data.id, 'info')
        end
    else
        NetworkSetInSpectatorMode(false, nil)
        spectateTarget = nil
        Wrappers.Notify('God Menu', 'Spectate ended', 'info')
    end
    cb({})
end)

RegisterNUICallback('godReviveAll', function(_, cb)
    TriggerServerEvent('god:server:reviveAll')
    cb({})
end)

RegisterNUICallback('godClearArea', function(_, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicles = GetGamePool('CVehicle')
    for _, v in ipairs(vehicles) do
        local vCoords = GetEntityCoords(v)
        if #(coords - vCoords) < 50.0 then
            DeleteEntity(v)
        end
    end
    local peds = GetGamePool('CPed')
    for _, p in ipairs(peds) do
        if not IsPedAPlayer(p) then
            local pCoords = GetEntityCoords(p)
            if #(coords - pCoords) < 50.0 then
                DeleteEntity(p)
            end
        end
    end
    Wrappers.Notify('God Menu', 'Area cleared within 50m', 'success')
    cb({})
end)

RegisterNUICallback('godGetServerInfo', function(_, cb)
    cb({
        players = GetNumPlayerIndices(),
        maxPlayers = Config.GodMenu.teleportPresets and 64 or 32,
        weather = 'N/A',
        time = 'N/A',
    })
end)

RegisterNUICallback('godClose', function(_, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    cb({})
end)

-- Client event handlers from server
RegisterNetEvent('god:client:freeze', function(state)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, state)
    SetPlayerControl(PlayerId(), not state)
end)

RegisterNetEvent('god:client:teleportTo', function(coords)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
end)

RegisterNetEvent('god:client:revive', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    TriggerEvent('hospital:client:Revive', coords)
    if exports['qbx_medical'] then
        exports['qbx_medical']:RevivePed(ped, coords)
    end
    SetEntityHealth(ped, 200)
end)

RegisterNetEvent('god:client:heal', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 200)
    ClearPedBloodDamage(ped)
    ResetPedMovementClipset(ped, 0)
end)

RegisterNetEvent('god:client:setArmor', function(amount)
    SetPedArmour(PlayerPedId(), amount)
end)

RegisterNetEvent('god:client:setWeather', function(weather)
    ClearWeatherTypePersist()
    SetWeatherTypeNowPersist(weather)
    SetWeatherTypeNow(weather)
end)

RegisterNetEvent('god:client:setTime', function(hour, minute)
    NetworkOverrideClockTime(hour, minute, 0)
end)

RegisterNetEvent('god:client:announce', function(message)
    TriggerEvent('chat:addMessage', {
        color = { 255, 215, 0 },
        multiline = true,
        args = { 'SERVER', message }
    })
    QBCore.Functions.Notify(message, 'info', 10000)
end)

RegisterNetEvent('god:client:setStat', function(statType, value)
    local ped = PlayerPedId()
    if statType == 'health' then
        SetEntityHealth(ped, value)
    elseif statType == 'armor' then
        SetPedArmour(ped, value)
    end
end)

RegisterNetEvent('god:client:kill', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 0)
end)

--- ============ NEW NUI CALLBACKS ============

RegisterNUICallback('godSetJob', function(data, cb)
    TriggerServerEvent('god:server:setJob', data.id, data.job, data.grade)
    cb({})
end)

RegisterNUICallback('godSetGroup', function(data, cb)
    TriggerServerEvent('god:server:setGroup', data.id, data.group)
    cb({})
end)

RegisterNUICallback('godSetPlayerStat', function(data, cb)
    TriggerServerEvent('god:server:setPlayerStat', data.id, data.statType, data.value)
    cb({})
end)

RegisterNUICallback('godGiveCarToGarage', function(data, cb)
    TriggerServerEvent('god:server:giveCarToGarage', data.id, data.model)
    cb({})
end)

RegisterNUICallback('godTransferVehicle', function(data, cb)
    TriggerServerEvent('god:server:transferVehicle', data.plate, data.newOwnerId)
    cb({})
end)

RegisterNUICallback('godKillAll', function(_, cb)
    TriggerServerEvent('god:server:killAll')
    cb({})
end)

RegisterNUICallback('godFreezeAll', function(data, cb)
    TriggerServerEvent('god:server:freezeAll', data.state)
    cb({})
end)

RegisterNUICallback('godTeleportAllToMe', function(_, cb)
    TriggerServerEvent('god:server:teleportAllToMe')
    cb({})
end)

RegisterNUICallback('godGiveAllMoney', function(data, cb)
    TriggerServerEvent('god:server:giveAllMoney', data.amount, data.type)
    cb({})
end)

RegisterNUICallback('godSetAllJob', function(data, cb)
    TriggerServerEvent('god:server:setAllJob', data.job, data.grade)
    cb({})
end)

RegisterNUICallback('godGetPlayerDetails', function(data, cb)
    local details = lib.callback.await('god:server:getPlayerDetails', false, data.id)
    cb(details or {})
end)

RegisterNUICallback('godRemoveItem', function(data, cb)
    TriggerServerEvent('god:server:removeItem', data.id, data.item, data.count)
    cb({})
end)

RegisterNUICallback('godGetJobList', function(_, cb)
    local jobs = lib.callback.await('god:server:getJobList', false)
    cb(jobs or {})
end)

RegisterNUICallback('godWarnPlayer', function(data, cb)
    TriggerServerEvent('god:server:warnPlayer', data.id, data.message)
    cb({})
end)

RegisterNUICallback('godSpawnVehicleForPlayer', function(data, cb)
    TriggerServerEvent('god:server:spawnVehicleForPlayer', data.id, data.model)
    cb({})
end)

RegisterNUICallback('godRestartCountdown', function(data, cb)
    TriggerServerEvent('god:server:restartCountdown', data.minutes)
    cb({})
end)

RegisterNetEvent('god:client:spawnVehicleForPlayer', function(vehicleModel)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    QBCore = exports['qbx_core']:GetCoreObject()
    QBCore.Functions.SpawnVehicle(vehicleModel, function(veh)
        if veh and DoesEntityExist(veh) then
            SetVehicleOnGroundProperly(veh)
            SetEntityInvincible(veh, false)
            SetVehicleEngineOn(veh, true, true, false)
            TaskWarpPedIntoVehicle(ped, veh, -1)
            Wrappers.Notify('God Menu', 'Admin spawned ' .. vehicleModel .. ' for you', 'success')
        end
    end, coords, heading, true, false)
end)

--- ==================== MANAGED DOORS ====================
local managedDoorZones = {}
local doorHighlightEntity = nil

-- NUI: get all managed doors
RegisterNUICallback('godGetManagedDoors', function(_, cb)
    local doors = lib.callback.await('god:server:getManagedDoors', false)
    cb(doors or {})
end)

-- NUI: create door lock
RegisterNUICallback('godCreateDoorLock', function(data, cb)
    if not data then cb({}) return end
    TriggerServerEvent('god:server:createDoorLock', data.label, data.doorModel, data.coords, data.heading, data.lockType, data.passcode, data.allowedJobs)
    cb({})
end)

-- NUI: update door lock
RegisterNUICallback('godUpdateManagedDoor', function(data, cb)
    if not data then cb({}) return end
    TriggerServerEvent('god:server:updateManagedDoor', data.doorId, data.label, data.lockType, data.passcode, data.allowedJobs)
    cb({})
end)

-- NUI: delete door lock
RegisterNUICallback('godDeleteManagedDoor', function(data, cb)
    if not data then cb({}) return end
    TriggerServerEvent('god:server:deleteManagedDoor', data.doorId)
    cb({})
end)

-- NUI: toggle door lock
RegisterNUICallback('godToggleManagedDoor', function(data, cb)
    if not data then cb({}) return end
    TriggerServerEvent('god:server:toggleManagedDoor', data.doorId)
    cb({})
end)

-- NUI: lock all
RegisterNUICallback('godLockAllDoors', function(_, cb)
    TriggerServerEvent('god:server:lockAllManagedDoors')
    cb({})
end)

-- NUI: unlock all
RegisterNUICallback('godUnlockAllDoors', function(_, cb)
    TriggerServerEvent('god:server:unlockAllManagedDoors')
    cb({})
end)

-- NUI: detect nearest door
RegisterNUICallback('godDetectNearestDoor', function(_, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local objects = GetGamePool('CObject')
    local nearestDist = 5.0
    local nearestObj = nil
    for _, obj in ipairs(objects) do
        local objCoords = GetEntityCoords(obj)
        local dist = #(coords - objCoords)
        if dist < nearestDist then
            local model = GetEntityModel(obj)
            if model and model ~= 0 then
                nearestDist = dist
                nearestObj = obj
            end
        end
    end
    if nearestObj then
        local objCoords = GetEntityCoords(nearestObj)
        local objModel = GetEntityModel(nearestObj)
        -- Highlight it
        if doorHighlightEntity then
            SetEntityDrawOutline(doorHighlightEntity, false)
        end
        doorHighlightEntity = nearestObj
        SetEntityDrawOutline(nearestObj, true)
        SetEntityDrawOutlineColor(nearestObj, 0, 255, 255, 200)
        cb({ found = true, model = tostring(objModel), coords = { x = objCoords.x, y = objCoords.y, z = objCoords.z }, heading = heading })
    else
        if doorHighlightEntity then
            SetEntityDrawOutline(doorHighlightEntity, false)
            doorHighlightEntity = nil
        end
        cb({ found = false, coords = { x = coords.x, y = coords.y, z = coords.z }, heading = heading })
    end
end)

-- NUI: clear door highlight
RegisterNUICallback('godClearDoorHighlight', function(_, cb)
    if doorHighlightEntity then
        SetEntityDrawOutline(doorHighlightEntity, false)
        doorHighlightEntity = nil
    end
    cb({})
end)

--- ==================== BAN MANAGEMENT ====================
RegisterNUICallback('godGetActiveBans', function(_, cb)
    local bans = lib.callback.await('god:server:getActiveBans', false)
    cb(bans or {})
end)

RegisterNUICallback('godSearchBans', function(data, cb)
    local bans = lib.callback.await('god:server:searchBans', false, data.query)
    cb(bans or {})
end)

RegisterNUICallback('godExecuteBan', function(data, cb)
    TriggerServerEvent('god:server:executeBan', data.id, data.reason, data.duration)
    cb({})
end)

RegisterNUICallback('godExecuteUnban', function(data, cb)
    TriggerServerEvent('god:server:executeUnban', data.banId)
    cb({})
end)

--- ==================== REPORT QUEUE ====================
RegisterNUICallback('godGetReports', function(_, cb)
    local reports = lib.callback.await('god:server:getReports', false)
    cb(reports or {})
end)

RegisterNUICallback('godAcceptReport', function(data, cb)
    TriggerServerEvent('god:server:acceptReport', data.reportId)
    cb({})
end)

RegisterNUICallback('godCloseReport', function(data, cb)
    TriggerServerEvent('god:server:closeReport', data.reportId, data.resolution)
    cb({})
end)

-- Live push events
RegisterNetEvent('god:client:newReport', function(report)
    SendNUIMessage({ action = 'newReport', report = report })
end)

RegisterNetEvent('god:client:updateReport', function(report)
    SendNUIMessage({ action = 'updateReport', report = report })
end)

RegisterNetEvent('god:client:removeReport', function(reportId)
    SendNUIMessage({ action = 'removeReport', reportId = reportId })
end)

--- ==================== STAFF MANAGEMENT ====================
RegisterNUICallback('godGetOnlineStaff', function(_, cb)
    local staff = lib.callback.await('god:server:getOnlineStaff', false)
    cb(staff or {})
end)

RegisterNUICallback('godSetStaffGroup', function(data, cb)
    TriggerServerEvent('god:server:setStaffGroup', data.id, data.group)
    cb({})
end)

RegisterNUICallback('godGetStaffActionLog', function(data, cb)
    local logs = lib.callback.await('god:server:getStaffActionLog', false, data.citizenid, data.limit or 50)
    cb(logs or {})
end)

--- ==================== VEHICLE GARAGE VIEWER ====================
RegisterNUICallback('godGetPlayerGarage', function(data, cb)
    local vehicles = lib.callback.await('god:server:getPlayerGarage', false, data.citizenid)
    cb(vehicles or {})
end)

RegisterNUICallback('godAdminSpawnPlayerVehicle', function(data, cb)
    TriggerServerEvent('god:server:adminSpawnPlayerVehicle', data.citizenid, data.plate)
    cb({})
end)

RegisterNUICallback('godAdminDeletePlayerVehicle', function(data, cb)
    TriggerServerEvent('god:server:adminDeletePlayerVehicle', data.plate)
    cb({})
end)

RegisterNUICallback('godAdminImpoundVehicle', function(data, cb)
    TriggerServerEvent('god:server:adminImpoundVehicle', data.citizenid, data.plate, data.reason)
    cb({})
end)

RegisterNUICallback('godAdminReleaseImpound', function(data, cb)
    TriggerServerEvent('god:server:adminReleaseImpound', data.plate)
    cb({})
end)

-- Door sync receiver
RegisterNetEvent('god:client:syncDoor', function(doorId, locked)
    local doorData = managedDoorZones[doorId]
    if doorData and doorData.door_model and doorData.door_model ~= '' then
        local modelHash = tonumber(doorData.door_model)
        if modelHash then
            DoorSystemSetDoorState(modelHash, locked and 1 or 0, false, false)
        end
    end
end)

-- Add door zone
RegisterNetEvent('god:client:addDoorZone', function(door)
    if not door or not door.coords then return end
    managedDoorZones[door.id] = door
    local typeLabel = door.lock_type == 'permanent' and '🔒 Locked' or (door.lock_type == 'passcode' and '🔑 Passcode' or '👔 Job')
    local icon = door.lock_type == 'permanent' and 'fas fa-lock' or 'fas fa-door-open'
    local options = {{
        name = 'managed_door_' .. door.id,
        label = door.label .. ' (' .. typeLabel .. ')',
        icon = icon,
        canInteract = function() return door.lock_type ~= 'permanent' end,
        onSelect = function()
            if door.lock_type == 'passcode' then
                local input = lib.inputDialog('Door: ' .. door.label, { { type = 'input', label = 'Enter passcode', password = true, icon = 'key' } })
                if not input or not input[1] then return end
                local ok = lib.callback.await('god:server:verifyDoorPasscode', false, door.id, input[1])
                if ok then
                    TriggerServerEvent('god:server:interactManagedDoor', door.id)
                else
                    Wrappers.Notify('Door Lock', 'Wrong passcode', 'error')
                end
            elseif door.lock_type == 'job' then
                TriggerServerEvent('god:server:interactManagedDoor', door.id)
            end
        end
    }}
    exports.ox_target:addBoxZone({
        coords = vec3(door.coords.x, door.coords.y, door.coords.z),
        size = vec3(1.5, 1.5, 2.5),
        rotation = door.heading or 0,
        debug = false,
        options = options
    })
end)

-- Update door zone
RegisterNetEvent('god:client:updateDoorZone', function(door)
    if not door or not managedDoorZones[door.id] then return end
    managedDoorZones[door.id] = door
end)

-- Remove door zone
RegisterNetEvent('god:client:removeDoorZone', function(doorId)
    if not doorId then return end
    managedDoorZones[doorId] = nil
end)

-- Open Doors tab
RegisterNetEvent('god:client:openDoorsTab', function()
    SendNUIMessage({ action = 'open', config = Config.GodMenu })
    SendNUIMessage({ action = 'switchTab', tab = 'doors' })
    menuOpen = true
end)

-- Spawn a garage vehicle for the player (called from server)
RegisterNetEvent('god:client:spawnGarageVehicle', function(plate)
    QBCore = exports['qbx_core']:GetCoreObject()
    QBCore.Functions.SpawnVehicle(plate, function(veh)
        if veh and DoesEntityExist(veh) then
            SetVehicleOnGroundProperly(veh)
            SetEntityInvincible(veh, false)
            SetVehicleEngineOn(veh, true, true, false)
            TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
            Wrappers.Notify('God Menu', 'Spawned garage vehicle ' .. plate, 'success')
        end
    end, nil, nil, true, false)
end)

-- /dooradmin command
RegisterCommand('dooradmin', function()
    checkOwner(function(ok)
        if not ok then
            Wrappers.Notify('Door Admin', 'Access denied', 'error')
            return
        end
        if menuOpen then
            SetNuiFocus(false, false)
            menuOpen = false
        end
        menuOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', config = Config.GodMenu })
        Citizen.Wait(100)
        SendNUIMessage({ action = 'switchTab', tab = 'doors' })
    end)
end, false)

-- Load all managed door zones on start
Citizen.CreateThread(function()
    Citizen.Wait(3000)
    local doors = lib.callback.await('god:server:getManagedDoors', false)
    for _, door in ipairs(doors or {}) do
        TriggerEvent('god:client:addDoorZone', door)
    end
end)

--- ==================== ZONE MANAGEMENT NUI CALLBACKS ====================

RegisterNUICallback('godGetAllZones', function(_, cb)
    local zones = lib.callback.await('admin-zones:server:getAllZones', false)
    cb(zones or {})
end)

RegisterNUICallback('godGetCurrentPosition', function(_, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    cb({ x = coords.x, y = coords.y, z = coords.z })
end)

RegisterNUICallback('godCreateZone', function(data, cb)
    if not data then cb({}) return end
    TriggerServerEvent('admin-zones:server:createZone', data.name, data.zoneType, data.coords, data.radius, data.allowedJobs, data.minGrade, data.requireDuty)
    cb({})
end)

RegisterNUICallback('godUpdateZone', function(data, cb)
    if not data then cb({}) return end
    TriggerServerEvent('admin-zones:server:updateZone', data.zoneId, data.name, data.zoneType, data.coords, data.radius, data.allowedJobs, data.minGrade, data.requireDuty, data.isActive)
    cb({})
end)

RegisterNUICallback('godDeleteZone', function(data, cb)
    if not data then cb({}) return end
    TriggerServerEvent('admin-zones:server:deleteZone', data.zoneId)
    cb({})
end)

RegisterNUICallback('godToggleZone', function(data, cb)
    if not data then cb({}) return end
    TriggerServerEvent('admin-zones:server:toggleZone', data.zoneId, data.active)
    cb({})
end)

RegisterNUICallback('godGetZoneItems', function(data, cb)
    if not data then cb({}) return end
    local items = lib.callback.await('admin-zones:server:getZoneItems', false, data.zoneId)
    cb(items or {})
end)

RegisterNUICallback('godAddZoneItem', function(data, cb)
    if not data then cb({}) return end
    TriggerServerEvent('admin-zones:server:addZoneItem', data.zoneId, data.itemName, data.label, data.price, data.minRank, data.currency, data.category)
    cb({})
end)

RegisterNUICallback('godRemoveZoneItem', function(data, cb)
    if not data then cb({}) return end
    TriggerServerEvent('admin-zones:server:removeZoneItem', data.itemId)
    cb({})
end)

--- Open Zones tab from external trigger
RegisterNetEvent('god:client:openZonesTab', function()
    SendNUIMessage({ action = 'open', config = Config.GodMenu })
    SendNUIMessage({ action = 'switchTab', tab = 'zones' })
    menuOpen = true
end)

-- /zoneadmin command
RegisterCommand('zoneadmin', function()
    checkOwner(function(ok)
        if not ok then
            Wrappers.Notify('Zone Admin', 'Access denied', 'error')
            return
        end
        if menuOpen then
            SetNuiFocus(false, false)
            menuOpen = false
        end
        menuOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', config = Config.GodMenu })
        Citizen.Wait(100)
        SendNUIMessage({ action = 'switchTab', tab = 'zones' })
    end)
end, false)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if noclipActive then
        local ped = PlayerPedId()
        SetEntityInvincible(ped, false)
        SetPlayerInvincible(PlayerId(), false)
        FreezeEntityPosition(ped, false)
        SetEntityVisible(ped, true, false)
        noclipActive = false
    end
    if spectateTarget then
        NetworkSetInSpectatorMode(false, nil)
        spectateTarget = nil
    end
    if menuOpen then
        SetNuiFocus(false, false)
        menuOpen = false
    end
end)
