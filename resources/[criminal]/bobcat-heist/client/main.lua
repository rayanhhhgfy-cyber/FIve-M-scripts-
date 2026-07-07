local QBox = exports['qbx-core']:GetCoreObject()
local gatesOpened = {}
local looted = {}
local camerasDisabled = 0
local heistActive = false

local function hasItem(item) return QBox.Functions.HasItem(item) end

local function canHeist()
    local police = QBox.Functions.GetPlayersFromJob('police')
    if #police < Config.BobcatHeist.MinPolice then Wrappers.Notify('Not enough police', 'error') return false end
    return true
end

Citizen.CreateThread(function()
    local l = Config.BobcatHeist.Location
    for i, gate in ipairs(Config.BobcatHeist.Gates) do
        exports.ox_target:addBoxZone({
            coords = gate.coords, size = vec3(3.0, 3.0, 3.0), rotation = 0, debug = false,
            options = {{
                name = 'bobcat_gate_' .. i,
                icon = Config.BobcatHeist.TargetOptions.gate.icon,
                label = gate.label .. ' - ' .. Config.BobcatHeist.TargetOptions.gate.label,
                distance = Config.BobcatHeist.TargetOptions.gate.distance,
                canInteract = function() return not gatesOpened[i] end,
                onSelect = function() TriggerEvent('bobcat:burnGate', i) end
            }}
        })
    end
    for j, loot in ipairs(Config.BobcatHeist.Lootables) do
        exports.ox_target:addBoxZone({
            coords = loot.coords, size = vec3(1.5, 1.5, 2.0), rotation = 0, debug = false,
            options = {{
                name = 'bobcat_loot_' .. j,
                icon = Config.BobcatHeist.TargetOptions.loot.icon,
                label = loot.label,
                distance = Config.BobcatHeist.TargetOptions.loot.distance,
                canInteract = function() return heistActive and not looted[j] end,
                onSelect = function() TriggerEvent('bobcat:loot', j) end
            }}
        })
    end
    for k = 1, Config.BobcatHeist.Security.cameras do
        exports.ox_target:addBoxZone({
            coords = l.coords + vector3(k * 2.0, 2.0, 3.0), size = vec3(1.0, 1.0, 1.5), rotation = 0, debug = false,
            options = {{
                name = 'bobcat_camera_' .. k,
                icon = Config.BobcatHeist.TargetOptions.camera.icon,
                label = Config.BobcatHeist.TargetOptions.camera.label,
                distance = Config.BobcatHeist.TargetOptions.camera.distance,
                canInteract = function() return camerasDisabled < k end,
                onSelect = function() TriggerEvent('bobcat:disableCamera', k) end
            }}
        })
    end
end)

RegisterNetEvent('bobcat:burnGate', function(i)
    if not canHeist() then return end
    local gate = Config.BobcatHeist.Gates[i]
    if not hasItem(gate.requiredItem) then Wrappers.Notify('Need ' .. gate.requiredItem, 'error') return end
    Wrappers.ProgressBar({ label = 'Burning through ' .. gate.label .. '...', duration = gate.time, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('bobcat:server:burnGate', i)
    end)
end)

RegisterNetEvent('bobcat:disableCamera', function(k)
    if not hasItem(Config.BobcatHeist.RequiredItems.hackingDevice) then Wrappers.Notify('Need hacking device', 'error') return end
    Wrappers.ProgressBar({ label = 'Disabling camera...', duration = Config.BobcatHeist.Security.cameraTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        camerasDisabled = camerasDisabled + 1
        Wrappers.Notify('Camera ' .. k .. ' disabled', 'success')
    end)
end)

RegisterNetEvent('bobcat:loot', function(j)
    local loot = Config.BobcatHeist.Lootables[j]
    Wrappers.ProgressBar({ label = 'Looting ' .. loot.label .. '...', duration = loot.time, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('bobcat:server:loot', j)
    end)
end)

RegisterNetEvent('bobcat:client:gateOpened', function(i)
    gatesOpened[i] = true
    heistActive = true
    Wrappers.Notify('Gate ' .. i .. ' opened!', 'success')
end)

RegisterNetEvent('bobcat:client:lootResult', function(data)
    looted[data.id] = true
    Wrappers.Notify('Looted ' .. data.label .. ' - $' .. data.cash, 'success')
end)

RegisterNetEvent('bobcat:client:policeAlert', function(street)
    Wrappers.Notify('Bobcat heist near ' .. street, 'warning')
end)
