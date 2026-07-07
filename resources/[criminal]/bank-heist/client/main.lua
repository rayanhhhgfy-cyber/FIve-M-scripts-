local QBox = exports['qbx-core']:GetCoreObject()
local heistPhases = {}
local drillDurability = {}

local function hasItem(item) return QBox.Functions.HasItem(item) end

local function canHeist()
    local police = QBox.Functions.GetPlayersFromJob('police')
    if #police < Config.BankHeist.MinPolice then Wrappers.Notify('Not enough police', 'error') return false end
    return true
end

Citizen.CreateThread(function()
    for i, bank in ipairs(Config.BankHeist.Banks) do
        exports.ox_target:addBoxZone({
            coords = bank.coords, size = vec3(4.0, 4.0, 3.0), rotation = 0, debug = false,
            options = {{
                name = 'bank_thermite_' .. i,
                icon = Config.BankHeist.TargetOptions.thermite.icon,
                label = Config.BankHeist.TargetOptions.thermite.label,
                distance = Config.BankHeist.TargetOptions.thermite.distance,
                canInteract = function() return not heistPhases[i] or heistPhases[i] < 1 end,
                onSelect = function() TriggerEvent('bank:thermite', i) end
            }, {
                name = 'bank_drill_' .. i,
                icon = Config.BankHeist.TargetOptions.drill.icon,
                label = Config.BankHeist.TargetOptions.drill.label,
                distance = Config.BankHeist.TargetOptions.drill.distance,
                canInteract = function() return heistPhases[i] == 1 end,
                onSelect = function() TriggerEvent('bank:drill', i) end
            }, {
                name = 'bank_vault_' .. i,
                icon = Config.BankHeist.TargetOptions.vault.icon,
                label = Config.BankHeist.TargetOptions.vault.label,
                distance = Config.BankHeist.TargetOptions.vault.distance,
                canInteract = function() return heistPhases[i] == 2 end,
                onSelect = function() TriggerEvent('bank:lootVault', i) end
            }}
        })
    end
end)

RegisterNetEvent('bank:thermite', function(id)
    if not canHeist() then return end
    if not hasItem(Config.BankHeist.RequiredItems.thermite) then Wrappers.Notify('You need thermite', 'error') return end
    Wrappers.ProgressBar({ label = 'Burning through door...', duration = Config.BankHeist.Thermite.time, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('bank:server:thermite', id)
    end)
end)

RegisterNetEvent('bank:drill', function(id)
    if not hasItem(Config.BankHeist.RequiredItems.drill) then Wrappers.Notify('You need a drill', 'error') return end
    Wrappers.ProgressBar({ label = 'Drilling vault door...', duration = Config.BankHeist.Drill.time, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('bank:server:drill', id)
    end)
end)

RegisterNetEvent('bank:lootVault', function(id)
    Wrappers.ProgressBar({ label = 'Looting vault...', duration = Config.BankHeist.Vault.time, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('bank:server:lootVault', id)
    end)
end)

RegisterNetEvent('bank:client:phaseUpdate', function(id, phase)
    heistPhases[id] = phase
    if phase == 1 then Wrappers.Notify('Thermite placed! Now drill the vault', 'success')
    elseif phase == 2 then Wrappers.Notify('Vault door drilled! Loot it', 'success')
    elseif phase == 3 then Wrappers.Notify('Vault looted! Get away clean', 'success') end
end)

RegisterNetEvent('bank:client:lootResult', function(data)
    Wrappers.Notify('Stole $' .. data.cash .. ' and valuables!', 'success')
end)

RegisterNetEvent('bank:client:policeAlert', function(street)
    Wrappers.Notify('Bank robbery at ' .. street, 'warning')
end)
