local QBox = exports['qbx-core']:GetCoreObject()

local noclipActive = false
local godmodeActive = false
local invisibleActive = false
local frozen = false

RegisterNetEvent('admin:openMenu', function()
    local options = {}
    local categories = {
        { title = Locale('admin_menu.noclip'), onSelect = function() TriggerServerEvent('admin:noclip') end },
        { title = Locale('admin_menu.godmode'), onSelect = function() TriggerServerEvent('admin:godmode') end },
        { title = Locale('admin_menu.invisible'), onSelect = function() TriggerServerEvent('admin:invisible') end },
        { title = Locale('admin_menu.freeze'), onSelect = function()
            local input = Wrappers.InputDialog({ title = Locale('admin_menu.freeze'), label = Locale('admin_menu.reason'), placeholder = 'Player ID', type = 'number' })
            if input then TriggerServerEvent('admin:freeze', input) end
        end },
        { title = Locale('admin_menu.revive'), onSelect = function()
            local input = Wrappers.InputDialog({ title = Locale('admin_menu.revive'), label = 'Player ID', placeholder = 'Leave blank for self', type = 'number' })
            TriggerServerEvent('admin:revive', input or 0)
        end },
        { title = Locale('admin_menu.teleport'), onSelect = function()
            local input = Wrappers.InputDialog({ title = Locale('admin_menu.teleport'), label = 'X, Y, Z or Player ID', placeholder = 'x,y,z', type = 'input' })
            if input then
                local x, y, z = input:match('([%d.-]+),([%d.-]+),([%d.-]+)')
                if x then
                    TriggerServerEvent('admin:teleport', { x = tonumber(x), y = tonumber(y), z = tonumber(z) })
                else
                    TriggerServerEvent('admin:teleport', { target = tonumber(input) })
                end
            end
        end },
        { title = Locale('admin_menu.spawn_vehicle'), onSelect = function()
            local input = Wrappers.InputDialog({ title = Locale('admin_menu.spawn_vehicle'), label = 'Model', placeholder = 'adder', type = 'input' })
            if input then TriggerServerEvent('admin:spawnVehicle', input) end
        end },
        { title = Locale('admin_menu.kick'), onSelect = function()
            local input = Wrappers.InputDialog({ title = Locale('admin_menu.kick'), label = Locale('admin_menu.reason'), placeholder = 'ID Reason', type = 'input' })
            if input then
                local id, reason = input:match('(%d+)%s+(.+)')
                if id then TriggerServerEvent('admin:kick', { target = tonumber(id), reason = reason }) end
            end
        end },
        { title = Locale('admin_menu.ban'), onSelect = function()
            local input = Wrappers.InputDialog({ title = Locale('admin_menu.ban'), label = Locale('admin_menu.reason'), placeholder = 'ID Reason', type = 'input' })
            if input then
                local id, reason = input:match('(%d+)%s+(.+)')
                if id then TriggerServerEvent('admin:ban', { target = tonumber(id), reason = reason }) end
            end
        end },
    }
    Wrappers.ContextMenu({ id = 'admin_menu', title = Locale('admin_menu.title'), options = categories })
end)

RegisterNetEvent('admin:toggleNoclip', function()
    noclipActive = not noclipActive
    local ped = PlayerPedId()
    if noclipActive then
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
    else
        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
    end
    Wrappers.Notify(noclipActive and 'Noclip ON' or 'Noclip OFF', 'info')
    CreateThread(function()
        while noclipActive do
            local ped = PlayerPedId()
            local camRot = GetGameplayCamRot()
            local coords = GetEntityCoords(ped)
            local forward = GetCamForwardVector()
            local speed = 1.0
            if IsControlPressed(0, 21) then speed = 5.0 end
            if IsControlPressed(0, 32) then
                coords = coords + forward * speed
            end
            if IsControlPressed(0, 33) then
                coords = coords - forward * speed
            end
            if IsControlPressed(0, 34) then
                coords = coords + vector3(0.0, 0.0, speed)
            end
            if IsControlPressed(0, 35) then
                coords = coords - vector3(0.0, 0.0, speed)
            end
            SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
            Wait(0)
        end
    end)
end)

RegisterNetEvent('admin:toggleGodmode', function()
    godmodeActive = not godmodeActive
    local ped = PlayerPedId()
    SetEntityInvincible(ped, godmodeActive)
    SetPlayerInvincible(PlayerId(), godmodeActive)
    SetEntityProofs(ped, godmodeActive, godmodeActive, godmodeActive, godmodeActive, godmodeActive, godmodeActive, godmodeActive, godmodeActive)
    Wrappers.Notify(godmodeActive and 'Godmode ON' or 'Godmode OFF', 'info')
end)

RegisterNetEvent('admin:toggleInvisible', function()
    invisibleActive = not invisibleActive
    local ped = PlayerPedId()
    SetEntityVisible(ped, not invisibleActive, false)
    NetworkSetEntityInvisibleToPlayer(ped, PlayerId(), invisibleActive)
    SetEntityLocallyInvisible(ped)
    Wrappers.Notify(invisibleActive and 'Invisible ON' or 'Invisible OFF', 'info')
end)

RegisterNetEvent('admin:toggleFreeze', function()
    frozen = not frozen
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, frozen)
    Wrappers.Notify(frozen and 'Frozen' or 'Unfrozen', 'info')
end)

RegisterNetEvent('admin:revivePlayer', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    SetEntityHealth(ped, 200)
    ClearPedTasks(ped)
    ClearPedTasksImmediately(ped)
    DoScreenFadeIn(500)
    Wrappers.Notify(Locale('admin_menu.revive'), 'success')
end)

RegisterNetEvent('admin:teleportTo', function(coords)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    Wrappers.Notify(Locale('admin_menu.teleport'), 'success')
end)

RegisterNetEvent('admin:spawnVehicle', function(model)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    local attempts = 0
    while not HasModelLoaded(modelHash) and attempts < 50 do
        Wait(100)
        attempts = attempts + 1
    end
    if HasModelLoaded(modelHash) then
        local veh = CreateVehicle(modelHash, coords.x + 3.0, coords.y + 3.0, coords.z, heading, true, true)
        SetPedIntoVehicle(ped, veh, -1)
        SetModelAsNoLongerNeeded(modelHash)
        Wrappers.Notify(Locale('admin_menu.spawn_vehicle'), 'success')
    else
        Wrappers.Notify('Failed to spawn vehicle', 'error')
    end
end)

RegisterNetEvent('admin:banned', function(reason)
    Wrappers.Notify('You have been banned: ' .. reason, 'error')
end)
