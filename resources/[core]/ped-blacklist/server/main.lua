local violationLog = {}

function IsModelBlacklisted(modelHash)
    local modelName = GetEntityModel(modelHash)
    local modelNameLower = string.lower(modelName)
    if Config.BlacklistedPeds[modelNameLower] then
        return true, 'ped'
    end
    if Config.BlacklistedVehicles[modelNameLower] then
        return true, 'vehicle'
    end
    if Config.BlacklistedWeapons[modelNameLower] then
        return true, 'weapon'
    end
    return false, nil
end

local function IsJobAllowed(source, modelNameLower, modelType)
    local player = exports['qbx_core']:GetPlayer(source)
    if not player then return false end
    local jobName = player.PlayerData.job.name
    for job, allowed in pairs(Config.AllowedJobs) do
        if jobName == job then
            local list = allowed[modelType .. 's']
            if list then
                for _, allowedModel in ipairs(list) do
                    if modelNameLower == allowedModel then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function HandleViolation(source, modelName, modelType)
    if not Config.Blacklist.logAttempts then return end
    local playerName = GetPlayerName(source)
    local msg = string.format('[BLACKLIST] %s (%s) tried to spawn %s: %s', playerName, source, modelType, modelName)
    print('^1' .. msg .. '^7')
    if not violationLog[source] then
        violationLog[source] = {}
    end
    table.insert(violationLog[source], { model = modelName, type = modelType, time = GetGameTimer() })
    if Config.Blacklist.kickOnViolation then
        DropPlayer(source, Config.Blacklist.warningMessage)
    end
    TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = Config.Blacklist.warningMessage })
end

RegisterNetEvent('ped-blacklist:server:checkModel', function(modelHash)
    local source = source
    if not source or not modelHash then return end
    local isBlacklisted, modelType = IsModelBlacklisted(modelHash)
    if not isBlacklisted then return end
    local modelName = GetEntityModel(modelHash)
    local modelNameLower = string.lower(modelName)
    if IsJobAllowed(source, modelNameLower, modelType) then return end
    HandleViolation(source, modelName, modelType)
end)

RegisterNetEvent('ped-blacklist:server:checkSpawn', function(modelName)
    local source = source
    if not source or not modelName then return end
    local modelNameLower = string.lower(modelName)
    if Config.BlacklistedPeds[modelNameLower] then
        HandleViolation(source, modelName, 'ped')
    end
end)

RegisterNetEvent('ped-blacklist:server:checkVehicleSpawn', function(vehicleName)
    local source = source
    if not source or not vehicleName then return end
    local vehicleNameLower = string.lower(vehicleName)
    if Config.BlacklistedVehicles[vehicleNameLower] then
        if IsJobAllowed(source, vehicleNameLower, 'vehicle') then return end
        HandleViolation(source, vehicleName, 'vehicle')
    end
end)

RegisterNetEvent('ped-blacklist:server:checkWeapon', function(weaponName)
    local source = source
    if not source or not weaponName then return end
    local weaponNameLower = string.lower(weaponName)
    if Config.BlacklistedWeapons[weaponNameLower] then
        HandleViolation(source, weaponName, 'weapon')
    end
end)

lib.callback.register('ped-blacklist:server:getViolations', function(source, target)
    if not IsPlayerAceAllowed(source, Config.Blacklist.adminAce) then return {} end
    return violationLog[target] or {}
end)

lib.callback.register('ped-blacklist:server:clearViolations', function(source, target)
    if not IsPlayerAceAllowed(source, Config.Blacklist.adminAce) then return false end
    violationLog[target] = nil
    return true
end)

RegisterCommand('checkmodel', function(source, args)
    if source == 0 then return end
    if not IsPlayerAceAllowed(source, Config.Blacklist.adminAce) then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = Locales['no_permission'] })
        return
    end
    if not args[1] then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Usage: /checkmodel [modelName]' })
        return
    end
    local modelName = args[1]
    local isPeds = Config.BlacklistedPeds[modelName]
    local isVehicles = Config.BlacklistedVehicles[modelName]
    local isWeapons = Config.BlacklistedWeapons[modelName]
    local msg = string.format('%s: %s', modelName, (isPeds or isVehicles or isWeapons) and 'BLACKLISTED' or 'ALLOWED')
    TriggerClientEvent('ox_lib:notify', source, { type = (isPeds or isVehicles or isWeapons) and 'error' or 'success', description = msg })
end, true)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[ped-blacklist] Model blacklist active. %d peds, %d vehicles, %d weapons blocked.^7',
        #Config.BlacklistedPeds, #Config.BlacklistedVehicles, #Config.BlacklistedWeapons)
end)

exports('IsModelBlacklisted', IsModelBlacklisted)
exports('GetViolations', function(source) return violationLog[source] end)
