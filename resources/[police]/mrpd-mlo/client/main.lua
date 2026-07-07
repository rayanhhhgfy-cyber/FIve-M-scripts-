local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local inMRPD = false
local currentInterior = nil

Citizen.CreateThread(function()
    for _, blip in ipairs(Config.MRPD.Blips) do
        local blipHandle = AddBlipForCoord(blip.coords)
        SetBlipSprite(blipHandle, blip.sprite)
        SetBlipColour(blipHandle, blip.color)
        SetBlipScale(blipHandle, blip.scale)
        SetBlipAsShortRange(blipHandle, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(blip.label)
        EndTextCommandSetBlipName(blipHandle)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerData.job = job
end)

local function isOnDuty()
    return playerData.job and playerData.job.type == 'leo' and playerData.job.onduty
end

local function getMyRank()
    if not playerData.job then return 0 end
    return playerData.job.grade.level or 0
end

local function hasAccess(minRank)
    return getMyRank() >= (minRank or 0)
end

Citizen.CreateThread(function()
    while not QBox.Functions.GetPlayerData().citizenid do
        Citizen.Wait(100)
    end
    playerData = QBox.Functions.GetPlayerData()

    for zoneName, zone in pairs(Config.MRPD.Zones) do
        local options = Config.MRPD.TargetOptions[zoneName]
        if options then
            exports.ox_target:addBoxZone({
                coords = zone.coords,
                size = vec3(zone.radius * 2, zone.radius * 2, 4.0),
                rotation = 0,
                debug = false,
                options = {
                    {
                        name = 'mrpd_' .. zoneName:lower(),
                        icon = options.icon,
                        label = options.label,
                        group = options.group,
                        distance = options.distance,
                        canInteract = function()
                            if Config.MRPD.Restrictions.requireDuty and not isOnDuty() then
                                return false, Locale('police.not_on_duty')
                            end
                            if options.minRank and not hasAccess(options.minRank) then
                                return false, Locale('police.rank_too_low')
                            end
                            return hasAccess(options.minRank or 0)
                        end,
                        onSelect = function()
                            TriggerEvent('mrpd:' .. zoneName:lower() .. ':open')
                        end
                    }
                }
            })
        end
    end
end)

local doorStates = {}
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)
        local nearDoor = false
        for _, door in ipairs(Config.MRPD.Building.Doors) do
            local dist = #(pedCoords - door.coords)
            if dist < 25.0 then
                nearDoor = true
                local doorHash = door.model
                if not DoorSystemGetDoorPending(doorHash) then
                    local state = doorStates[doorHash]
                    if state == nil then
                        doorStates[doorHash] = door.locked
                    end
                    DoorSystemSetDoorState(doorHash, doorStates[doorHash] and 1 or 0)
                    DoorSystemSetAutomaticDistance(doorHash, 2.5, false)
                end
            end
            if not nearDoor then
                Citizen.Wait(1000)
            end
        end
    end
end)

RegisterNetEvent('mrpd:door:toggle', function(doorModel)
    local doorHash = tonumber(doorModel)
    if doorStates[doorHash] ~= nil then
        doorStates[doorHash] = not doorStates[doorHash]
        TriggerServerEvent('mrpd:server:syncDoor', doorModel, doorStates[doorHash])
    end
end)

RegisterNetEvent('mrpd:server:syncDoor', function(doorModel, state)
    doorStates[tonumber(doorModel)] = state
end)

RegisterNetEvent('mrpd:armory:open', function()
    if not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    local rank = getMyRank()
    local menuItems = {}
    for _, weapon in ipairs(Config.MRPD.Zones.Armory.weapons) do
        if rank >= weapon.rank then
            table.insert(menuItems, {
                title = weapon.label,
                description = Locale('police.rank_required', weapon.rank),
                onSelect = function()
                    TriggerServerEvent('mrpd:server:removeWeapon', weapon.model)
                end
            })
        end
    end
    if #menuItems > 0 then
        table.insert(menuItems, { title = Locale('police.ammo'), menu = 'ammo_menu' })
        table.insert(menuItems, { title = Locale('police.equipment'), menu = 'equip_menu' })
        Wrappers.ContextMenu({ id = 'armory_menu', title = Locale('police.armory'), menuItems = menuItems })
    end
end)

RegisterNetEvent('mrpd:evidence:open', function()
    if not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    TriggerServerEvent('mrpd:server:getEvidenceItems')
end)

RegisterNetEvent('mrpd:server:getEvidenceItems', function(items)
    local menuItems = {}
    if items and #items > 0 then
        for _, item in ipairs(items) do
            table.insert(menuItems, {
                title = item.label,
                description = item.description or '',
                onSelect = function()
                    TriggerServerEvent('mrpd:server:retrieveEvidence', item.id)
                end
            })
        end
    end
    table.insert(menuItems, {
        title = Locale('police.store_evidence'),
        onSelect = function()
            Wrappers.InputDialog({
                title = Locale('police.evidence_item'),
                inputs = {
                    { type = 'input', label = Locale('police.evidence_label'), name = 'label', required = true },
                    { type = 'textarea', label = Locale('police.evidence_desc'), name = 'description', required = false }
                }
            }, function(values)
                if values then
                    TriggerServerEvent('mrpd:server:storeEvidence', values.label, values.description)
                end
            end)
        end
    })
    Wrappers.ContextMenu({ id = 'evidence_menu', title = Locale('police.evidence_locker'), menuItems = menuItems })
end)

RegisterNetEvent('mrpd:dispatch:open', function()
    if not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    Wrappers.ContextMenu({
        id = 'dispatch_menu',
        title = Locale('police.dispatch'),
        menuItems = {
            { title = Locale('police.active_calls'), onSelect = function() TriggerEvent('police:dispatch:activeCalls') end },
            { title = Locale('police.run_plate'), onSelect = function() TriggerEvent('police:dispatch:plateLookup') end },
            { title = Locale('police.run_name'), onSelect = function() TriggerEvent('police:dispatch:nameLookup') end },
            { title = Locale('police.bolos'), onSelect = function() TriggerEvent('police:dispatch:bolos') end }
        }
    })
end)

RegisterNetEvent('mrpd:garage:open', function()
    if not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    TriggerEvent('police:garage:openMenu')
end)

RegisterNetEvent('mrpd:clockin:open', function()
    local rank = getMyRank()
    Wrappers.ContextMenu({
        id = 'duty_menu',
        title = Locale('police.duty_status'),
        menuItems = {
            {
                title = isOnDuty() and Locale('police.clock_out') or Locale('police.clock_in'),
                onSelect = function()
                    TriggerServerEvent('mrpd:server:toggleDuty')
                end
            },
            {
                title = Locale('police.view_schedule'),
                onSelect = function()
                    TriggerServerEvent('mrpd:server:getSchedule')
                end
            }
        }
    })
end)

RegisterNetEvent('mrpd:cells:open', function()
    if not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    local rank = getMyRank()
    if rank < Config.MRPD.Restrictions.cellsMinRank then
        Wrappers.Notify(Locale('police.rank_too_low'), 'error')
        return
    end
    Wrappers.ContextMenu({
        id = 'cell_menu',
        title = Locale('police.cell_management'),
        menuItems = {
            { title = Locale('police.incarcerate'), onSelect = function() TriggerEvent('police:cells:incarcerate') end },
            { title = Locale('police.release_prisoner'), onSelect = function() TriggerEvent('police:cells:release') end },
            { title = Locale('police.cell_status'), onSelect = function() TriggerServerEvent('mrpd:server:getCellStatus') end }
        }
    })
end)

RegisterNetEvent('mrpd:roof:open', function()
    if not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    Wrappers.ContextMenu({
        id = 'roof_menu',
        title = Locale('police.roof_access'),
        menuItems = {
            { title = Locale('police.deploy_sniper'), onSelect = function() TriggerEvent('police:roof:sniper') end },
            { title = Locale('police.access_helipad'), onSelect = function() SetEntityCoords(PlayerPedId(), 449.0, -981.0, 43.7) end },
            { title = Locale('police.return_inside'), onSelect = function() SetEntityCoords(PlayerPedId(), 440.0, -980.0, 30.0) end }
        }
    })
end)

RegisterNetEvent('police:dispatch:plateLookup', function()
    Wrappers.InputDialog({
        title = Locale('police.plate_lookup'),
        inputs = {
            { type = 'input', label = Locale('police.enter_plate'), name = 'plate', required = true }
        }
    }, function(values)
        if values then
            TriggerServerEvent('police:server:plateLookup', values.plate:upper())
        end
    end)
end)

RegisterNetEvent('police:dispatch:nameLookup', function()
    Wrappers.InputDialog({
        title = Locale('police.name_lookup'),
        inputs = {
            { type = 'input', label = Locale('police.enter_name'), name = 'name', required = true }
        }
    }, function(values)
        if values then
            TriggerServerEvent('police:server:nameLookup', values.name)
        end
    end)
end)

RegisterNetEvent('police:dispatch:bolos', function()
    TriggerServerEvent('police:server:getBolos')
end)

RegisterNetEvent('police:dispatch:activeCalls', function()
    TriggerServerEvent('police:server:getActiveCalls')
end)

RegisterNetEvent('police:cells:incarcerate', function()
    local closestPlayer, closestDist = QBox.Functions.GetClosestPlayer()
    if closestPlayer == -1 or closestDist > 3.0 then
        Wrappers.Notify(Locale('police.no_player_near'), 'error')
        return
    end
    Wrappers.InputDialog({
        title = Locale('police.incarcerate'),
        inputs = {
            { type = 'number', label = Locale('police.sentence_minutes'), name = 'time', required = true, min = 1, max = 480 },
            { type = 'input', label = Locale('police.charges'), name = 'charges', required = true }
        }
    }, function(values)
        if values then
            local playerId = GetPlayerServerId(closestPlayer)
            TriggerServerEvent('police:server:incarcerate', playerId, tonumber(values.time), values.charges)
        end
    end)
end)

RegisterNetEvent('police:cells:release', function()
    Wrappers.InputDialog({
        title = Locale('police.release_prisoner'),
        inputs = {
            { type = 'number', label = Locale('police.cell_number'), name = 'cell', required = true, min = 1, max = Config.MRPD.Zones.Cells.cellCount }
        }
    }, function(values)
        if values then
            TriggerServerEvent('police:server:releasePrisoner', tonumber(values.cell))
        end
    end)
end)

RegisterNetEvent('police:roof:sniper', function()
    Wrappers.ProgressBar({
        label = Locale('police.deploying_sniper'),
        duration = 3000,
        useWhileDead = false,
        canCancel = true
    }, function(cancelled)
        if not cancelled then
            QBox.Functions.GiveItem('weapon_sniperrifle', 1)
            Wrappers.Notify(Locale('police.sniper_deployed'), 'success')
        end
    end)
end)
