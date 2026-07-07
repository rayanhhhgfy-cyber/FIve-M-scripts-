local QBox = exports['qbx-core']:GetCoreObject()
local onboard = false
local vaultOpen = false
local alarmTriggered = false
local alarmPanelsDisabled = 0
local guardsNeutralized = 0

local function hasItem(item) return QBox.Functions.HasItem(item) end

local function canHeist()
    local police = QBox.Functions.GetPlayersFromJob('police')
    if #police < Config.YachtHeist.MinPolice then Wrappers.Notify('Not enough police', 'error') return false end
    return true
end

Citizen.CreateThread(function()
    local y = Config.YachtHeist.Yacht
    exports.ox_target:addBoxZone({
        coords = y.coords, size = vec3(10.0, 10.0, 5.0), rotation = 0, debug = false,
        options = {
            {
                name = 'yacht_board',
                icon = Config.YachtHeist.TargetOptions.sneakOnboard.icon,
                label = Config.YachtHeist.TargetOptions.sneakOnboard.label,
                distance = Config.YachtHeist.TargetOptions.sneakOnboard.distance,
                canInteract = function() return not onboard end,
                onSelect = function() TriggerEvent('yacht:board') end
            },
            {
                name = 'yacht_pickpocket',
                icon = Config.YachtHeist.TargetOptions.pickpocket.icon,
                label = Config.YachtHeist.TargetOptions.pickpocket.label,
                distance = Config.YachtHeist.TargetOptions.pickpocket.distance,
                canInteract = function() return onboard and not alarmTriggered end,
                onSelect = function() TriggerEvent('yacht:pickpocket') end
            }
        }
    })
    for i = 1, Config.YachtHeist.GuestRooms.count do
        exports.ox_target:addBoxZone({
            coords = y.interior + vector3(i * 3.0, 0, 0), size = vec3(2.0, 2.0, 2.0), rotation = 0, debug = false,
            options = {
                {
                    name = 'yacht_room_' .. i,
                    icon = Config.YachtHeist.TargetOptions.searchRoom.icon,
                    label = Config.YachtHeist.TargetOptions.searchRoom.label,
                    distance = Config.YachtHeist.TargetOptions.searchRoom.distance,
                    canInteract = function() return onboard end,
                    onSelect = function() TriggerEvent('yacht:searchRoom', i) end
                }
            }
        })
    end
    for i = 1, Config.YachtHeist.Alarm.panels do
        exports.ox_target:addBoxZone({
            coords = y.interior + vector3(i * 5.0, 3.0, 0), size = vec3(1.0, 1.0, 2.0), rotation = 0, debug = false,
            options = {
                {
                    name = 'yacht_alarm_' .. i,
                    icon = Config.YachtHeist.TargetOptions.disableAlarm.icon,
                    label = Config.YachtHeist.TargetOptions.disableAlarm.label,
                    distance = Config.YachtHeist.TargetOptions.disableAlarm.distance,
                    canInteract = function() return onboard and alarmTriggered and alarmPanelsDisabled < i end,
                    onSelect = function() TriggerEvent('yacht:disableAlarm', i) end
                }
            }
        })
    end
    exports.ox_target:addBoxZone({
        coords = y.vault.coords, size = vec3(2.0, 2.0, 2.0), rotation = 0, debug = false,
        options = {
            {
                name = 'yacht_hack_vault',
                icon = Config.YachtHeist.TargetOptions.hackVault.icon,
                label = Config.YachtHeist.TargetOptions.hackVault.label,
                distance = Config.YachtHeist.TargetOptions.hackVault.distance,
                canInteract = function() return onboard and not vaultOpen end,
                onSelect = function() TriggerEvent('yacht:hackVault') end
            },
            {
                name = 'yacht_crack_safe',
                icon = Config.YachtHeist.TargetOptions.crackSafe.icon,
                label = Config.YachtHeist.TargetOptions.crackSafe.label,
                distance = Config.YachtHeist.TargetOptions.crackSafe.distance,
                canInteract = function() return onboard and vaultOpen end,
                onSelect = function() TriggerEvent('yacht:crackSafe') end
            },
            {
                name = 'yacht_loot_vault',
                icon = Config.YachtHeist.TargetOptions.lootVault.icon,
                label = Config.YachtHeist.TargetOptions.lootVault.label,
                distance = Config.YachtHeist.TargetOptions.lootVault.distance,
                canInteract = function() return onboard and vaultOpen end,
                onSelect = function() TriggerEvent('yacht:lootVault') end
            }
        }
    })
end)

RegisterNetEvent('yacht:board', function()
    if not canHeist() then return end
    onboard = true
    SetEntityCoords(PlayerPedId(), Config.YachtHeist.Yacht.interior)
    Wrappers.Notify('You snuck onto the yacht', 'success')
end)

RegisterNetEvent('yacht:pickpocket', function()
    Wrappers.ProgressBar({ label = 'Pickpocketing guest...', duration = 4000, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('yacht:server:pickpocket')
    end)
end)

RegisterNetEvent('yacht:searchRoom', function(id)
    Wrappers.ProgressBar({ label = 'Searching room...', duration = Config.YachtHeist.GuestRooms.searchTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('yacht:server:searchRoom', id)
    end)
end)

RegisterNetEvent('yacht:disableAlarm', function(id)
    Wrappers.ProgressBar({ label = 'Disabling alarm panel...', duration = 8000, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        alarmPanelsDisabled = alarmPanelsDisabled + 1
        if alarmPanelsDisabled >= Config.YachtHeist.Alarm.panels then alarmTriggered = false end
        Wrappers.Notify('Alarm panel ' .. id .. ' disabled', 'success')
    end)
end)

RegisterNetEvent('yacht:hackVault', function()
    if not hasItem('hacking_device') then Wrappers.Notify('Need a hacking device', 'error') return end
    Wrappers.ProgressBar({ label = 'Hacking vault terminal...', duration = Config.YachtHeist.Vault.hackTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('yacht:server:hackVault')
    end)
end)

RegisterNetEvent('yacht:crackSafe', function()
    Wrappers.ProgressBar({ label = 'Cracking safe...', duration = Config.YachtHeist.Vault.crackTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('yacht:server:crackSafe')
    end)
end)

RegisterNetEvent('yacht:lootVault', function()
    Wrappers.ProgressBar({ label = 'Taking valuables...', duration = 6000, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('yacht:server:lootVault')
    end)
end)

RegisterNetEvent('yacht:client:result', function(data)
    if data.vaultOpen then vaultOpen = true end
    Wrappers.Notify(data.message, data.type or 'success')
end)

RegisterNetEvent('yacht:client:alarm', function()
    alarmTriggered = true
    Wrappers.Notify('Alarm triggered!', 'error')
end)

RegisterNetEvent('yacht:client:policeAlert', function(street)
    Wrappers.Notify('Yacht heist at ' .. street, 'warning')
end)
