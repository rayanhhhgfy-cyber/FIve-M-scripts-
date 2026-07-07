local QBox = exports['qbx_core']:GetCoreObject()

local dragSessions = {}

local function getPlayerGroup(src)
    local p = QBox.Functions.GetPlayer(src)
    if not p then return nil end
    local group = p.PlayerData.group
    local job = p.PlayerData.job and p.PlayerData.job.name or ''
    if group == 'god' or group == 'superadmin' or group == 'admin' then return 'admin' end
    for _, g in ipairs(Config.Drag.policeGroups) do
        if job == g then return 'police' end
    end
    for _, g in ipairs(Config.Drag.emsGroups) do
        if job == g then return 'ems' end
    end
    return nil
end

local function canDragTarget(dragger, target)
    local cuffed = exports['cuff-system']:IsCuffed(target)
    if cuffed then return true end
    local downed = exports['wasabi-ambulance']:IsPlayerDown(target)
    if downed then return true end
    return false
end

RegisterNetEvent('drag:server:startDrag', function(targetSrc)
    local src = source
    local role = getPlayerGroup(src)
    if not role then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You cannot drag players' })
        return
    end
    if not canDragTarget(src, targetSrc) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'This player cannot be dragged' })
        return
    end
    dragSessions[src] = { target = targetSrc }
    dragSessions[targetSrc] = { dragger = src }
    TriggerClientEvent('drag:client:startDrag', src, targetSrc)
    TriggerClientEvent('drag:client:beingDragged', targetSrc, src)
    TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'Dragging player — press E to release' })
end)

RegisterNetEvent('drag:server:stopDrag', function()
    local src = source
    local session = dragSessions[src]
    if not session then return end
    local target = session.target
    if target then
        TriggerClientEvent('drag:client:stopDrag', target)
        TriggerClientEvent('drag:client:stopBeingDragged', target)
        dragSessions[target] = nil
    end
    TriggerClientEvent('drag:client:stopDrag', src)
    dragSessions[src] = nil
end)

RegisterNetEvent('drag:server:forceIntoVehicle', function(targetSrc, vehicleNetId, seat)
    local src = source
    local role = getPlayerGroup(src)
    if not role then return end
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then return end
    TriggerClientEvent('drag:client:forceIntoVehicle', targetSrc, vehicleNetId, seat or -2)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Forced player into vehicle' })
    TriggerClientEvent('drag:client:stopDrag', src)
    TriggerClientEvent('drag:client:stopBeingDragged', targetSrc)
    dragSessions[src] = nil
    dragSessions[targetSrc] = nil
end)

RegisterNetEvent('drag:server:forceOutOfVehicle', function(targetSrc)
    local src = source
    local role = getPlayerGroup(src)
    if not role then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You cannot drag players' })
        return
    end
    local target = QBox.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Target not found' })
        return
    end
    TriggerClientEvent('drag:client:forceOutOfVehicle', targetSrc, src)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Pulled player out of vehicle' })
end)

AddEventHandler('playerDropped', function()
    local src = source
    local session = dragSessions[src]
    if session then
        local target = session.target
        if target then
            TriggerClientEvent('drag:client:stopBeingDragged', target)
            dragSessions[target] = nil
        end
        if session.dragger then
            TriggerClientEvent('drag:client:stopDrag', session.dragger)
            dragSessions[session.dragger] = nil
        end
    end
    dragSessions[src] = nil
end)
