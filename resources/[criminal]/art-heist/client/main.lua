local QBox = exports['qbx-core']:GetCoreObject()
local isHeisting = false
local laserDisarmed = {}
local paintingsTaken = 0
local heistActive = false

local function hasItem(item) return QBox.Functions.HasItem(item) end

local function canHeist()
    if isHeisting then Wrappers.Notify('Already busy', 'error') return false end
    local police = QBox.Functions.GetPlayersFromJob('police')
    if #police < Config.ArtHeist.MinPolice then Wrappers.Notify('Not enough police', 'error') return false end
    return true
end

Citizen.CreateThread(function()
    for i, loc in ipairs(Config.ArtHeist.Locations) do
        exports.ox_target:addBoxZone({
            coords = loc.coords, size = vec3(5.0, 5.0, 3.0), rotation = 0, debug = false,
            options = {{
                name = 'art_hack_panel_' .. i,
                icon = Config.ArtHeist.TargetOptions.hackPanel.icon,
                label = Config.ArtHeist.TargetOptions.hackPanel.label,
                distance = Config.ArtHeist.TargetOptions.hackPanel.distance,
                canInteract = function() return not heistActive end,
                onSelect = function() TriggerEvent('art:hackPanel', i) end
            }}
        })
        for j, painting in ipairs(Config.ArtHeist.Paintings) do
            exports.ox_target:addBoxZone({
                coords = loc.coords + vector3(j * 2.0, 0, 1.0), size = vec3(1.0, 1.0, 2.0), rotation = 0, debug = false,
                options = {{
                    name = 'art_painting_' .. i .. '_' .. j,
                    icon = Config.ArtHeist.TargetOptions.removePainting.icon,
                    label = Config.ArtHeist.TargetOptions.removePainting.label .. ' - ' .. painting.name,
                    distance = Config.ArtHeist.TargetOptions.removePainting.distance,
                    canInteract = function() return heistActive and laserDisarmed[j] end,
                    onSelect = function() TriggerEvent('art:takePainting', i, j) end
                }, {
                    name = 'art_laser_' .. i .. '_' .. j,
                    icon = Config.ArtHeist.TargetOptions.disableLaser.icon,
                    label = Config.ArtHeist.TargetOptions.disableLaser.label,
                    distance = Config.ArtHeist.TargetOptions.disableLaser.distance,
                    canInteract = function() return heistActive and not laserDisarmed[j] end,
                    onSelect = function() TriggerEvent('art:disarmLaser', j) end
                }}
            })
        end
    end
end)

RegisterNetEvent('art:hackPanel', function(id)
    if not canHeist() or not hasItem(Config.ArtHeist.RequiredItems.hackingDevice) then
        Wrappers.Notify('You need a Hacking Device', 'error') return
    end
    isHeisting = true
    Wrappers.ProgressBar({ label = 'Hacking security panel...', duration = Config.ArtHeist.HackingTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then isHeisting = false return end
        TriggerServerEvent('art:server:hackPanel', id)
    end)
end)

RegisterNetEvent('art:disarmLaser', function(section)
    if not hasItem(Config.ArtHeist.RequiredItems.wireCutters) then Wrappers.Notify('You need Wire Cutters', 'error') return end
    Wrappers.ProgressBar({ label = 'Disarming laser grid...', duration = Config.ArtHeist.LaserDisarmTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        laserDisarmed[section] = true
        Wrappers.Notify('Laser section ' .. section .. ' disarmed', 'success')
    end)
end)

RegisterNetEvent('art:takePainting', function(locId, paintingId)
    if not hasItem(Config.ArtHeist.RequiredItems.drillingTool) then Wrappers.Notify('You need a Drill', 'error') return end
    Wrappers.ProgressBar({ label = 'Removing painting...', duration = Config.ArtHeist.DrillTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('art:server:takePainting', locId, paintingId)
    end)
end)

RegisterNetEvent('art:client:hackSuccess', function(id)
    heistActive = true
    isHeisting = false
    Wrappers.Notify('Security bypassed, you have ' .. Config.ArtHeist.Escape.timeout .. 's', 'success')
end)

RegisterNetEvent('art:client:paintingTaken', function(data)
    paintingsTaken = paintingsTaken + 1
    Wrappers.Notify('Took ' .. data.name .. ' worth $' .. data.value, 'success')
end)

RegisterNetEvent('art:client:heistComplete', function(total)
    heistActive = false
    isHeisting = false
    Wrappers.Notify('Heist complete! Stole ' .. total .. ' paintings', 'success')
end)

RegisterNetEvent('art:client:policeAlert', function(street)
    Wrappers.Notify('Art heist at ' .. street, 'warning')
end)
