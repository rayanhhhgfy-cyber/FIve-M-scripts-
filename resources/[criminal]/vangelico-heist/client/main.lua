local QBox = exports['qbx-core']:GetCoreObject()
local smashedCases = {}
local lootedCases = {}
local alarmDisabled = false
local heistActive = false

local function hasItem(item) return QBox.Functions.HasItem(item) end

local function canHeist()
    local police = QBox.Functions.GetPlayersFromJob('police')
    if #police < Config.VangelicoHeist.MinPolice then Wrappers.Notify('Not enough police', 'error') return false end
    return true
end

Citizen.CreateThread(function()
    local l = Config.VangelicoHeist.Location
    for i, c in ipairs(Config.VangelicoHeist.GlassCases) do
        exports.ox_target:addBoxZone({
            coords = c.coords, size = vec3(1.2, 1.2, 1.5), rotation = 0, debug = false,
            options = {{
                name = 'vang_smash_' .. i,
                icon = Config.VangelicoHeist.TargetOptions.smashCase.icon,
                label = c.label .. ' - ' .. Config.VangelicoHeist.TargetOptions.smashCase.label,
                distance = Config.VangelicoHeist.TargetOptions.smashCase.distance,
                canInteract = function() return not smashedCases[i] end,
                onSelect = function() TriggerEvent('vang:smash', i) end
            }, {
                name = 'vang_loot_' .. i,
                icon = Config.VangelicoHeist.TargetOptions.lootCase.icon,
                label = c.label .. ' - ' .. Config.VangelicoHeist.TargetOptions.lootCase.label,
                distance = Config.VangelicoHeist.TargetOptions.lootCase.distance,
                canInteract = function() return smashedCases[i] and not lootedCases[i] end,
                onSelect = function() TriggerEvent('vang:loot', i) end
            }}
        })
    end
    for j = 1, Config.VangelicoHeist.Alarm.panels do
        exports.ox_target:addBoxZone({
            coords = l.coords + vector3(j * 3.0, 0, 2.0), size = vec3(1.0, 1.0, 2.0), rotation = 0, debug = false,
            options = {{
                name = 'vang_alarm_' .. j,
                icon = Config.VangelicoHeist.TargetOptions.disableAlarm.icon,
                label = Config.VangelicoHeist.TargetOptions.disableAlarm.label .. ' ' .. j,
                distance = Config.VangelicoHeist.TargetOptions.disableAlarm.distance,
                canInteract = function() return not alarmDisabled end,
                onSelect = function() TriggerEvent('vang:disableAlarm', j) end
            }}
        })
    end
end)

RegisterNetEvent('vang:smash', function(i)
    if not canHeist() then return end
    if not hasItem(Config.VangelicoHeist.RequiredItems.hammer) then Wrappers.Notify('Need a hammer', 'error') return end
    local c = Config.VangelicoHeist.GlassCases[i]
    Wrappers.ProgressBar({ label = 'Smashing ' .. c.label .. '...', duration = Config.VangelicoHeist.Smash.time, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        smashedCases[i] = true
        heistActive = true
        PlaySoundFrontend(-1, 'Glass_Smash', 'DLC_HEIST_FLEECA_SOUNDSET', true)
        Wrappers.Notify('Case smashed! Grab the loot', 'success')
    end)
end)

RegisterNetEvent('vang:loot', function(i)
    local c = Config.VangelicoHeist.GlassCases[i]
    Wrappers.ProgressBar({ label = 'Taking ' .. c.item .. '...', duration = c.time, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('vang:server:loot', i)
    end)
end)

RegisterNetEvent('vang:disableAlarm', function(j)
    if not hasItem(Config.VangelicoHeist.RequiredItems.hackingDevice) then Wrappers.Notify('Need hacking device', 'error') return end
    Wrappers.ProgressBar({ label = 'Disabling alarm panel...', duration = Config.VangelicoHeist.Alarm.disableTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        alarmDisabled = true
        Wrappers.Notify('Alarm disabled', 'success')
    end)
end)

RegisterNetEvent('vang:client:lootResult', function(data)
    lootedCases[data.id] = true
    Wrappers.Notify('Got ' .. data.item .. ' worth $' .. data.value, 'success')
end)

RegisterNetEvent('vang:client:policeAlert', function(street)
    Wrappers.Notify('Jewelry heist at ' .. street, 'warning')
end)
