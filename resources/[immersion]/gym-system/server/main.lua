local QBCore = exports['qbx_core']:GetCoreObject()
local playerGymData = {}

local function InitializeGymData(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    local metadata = player.PlayerData.metadata
    playerGymData[source] = {
        strength = metadata.strength or 0,
        gymStamina = metadata.gym_stamina or 0,
        dailyGain = metadata.gym_daily_gain or 0,
        lastWorkout = metadata.gym_last_workout or 0,
        dirty = false
    }
    return playerGymData[source]
end

local function GetGymData(source)
    if not playerGymData[source] then
        InitializeGymData(source)
    end
    return playerGymData[source]
end

local function SaveGymData(source)
    local data = playerGymData[source]
    if not data or not data.dirty then return end
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    player.Functions.SetMetaData('strength', data.strength)
    player.Functions.SetMetaData('gym_stamina', data.gymStamina)
    player.Functions.SetMetaData('gym_daily_gain', data.dailyGain)
    player.Functions.SetMetaData('gym_last_workout', data.lastWorkout)
    data.dirty = false
end

local function PerformRep(source, equipmentName)
    local data = GetGymData(source)
    if not data then return false, 'Not found' end
    local equipment = Config.Equipment[equipmentName]
    if not equipment then return false, 'Invalid equipment' end
    if data.strength < equipment.minStrength then
        return false, 'Need strength level ' .. equipment.minStrength
    end
    if data.gymStamina < equipment.staminaCost then
        return false, 'Too exhausted. Rest before continuing.'
    end
    local now = os.time()
    if now - data.lastWorkout < Config.Gym.cooldownBetweenSets / 1000 then
        return false, 'Rest between sets!'
    end
    local dailyGain = data.dailyGain or 0
    if dailyGain >= Config.Gym.maxDailyGain then
        return false, 'Daily training limit reached'
    end
    local strengthGain = (equipment.strengthGain or 0) * Config.Gym.xpMultiplier
    local staminaGain = (equipment.staminaGain or 0) * Config.Gym.xpMultiplier
    data.strength = math.min(Config.Gym.maxStrength, data.strength + strengthGain)
    data.gymStamina = math.max(0, data.gymStamina - equipment.staminaCost)
    if staminaGain > 0 then
        data.gymStamina = math.min(Config.Gym.maxStamina, data.gymStamina + staminaGain)
    end
    data.dailyGain = dailyGain + strengthGain
    data.lastWorkout = now
    data.dirty = true
    SaveGymData(source)
    local meleeMult = Config.StrengthEffects.meleeMultiplier.min + (data.strength / Config.Gym.maxStrength) * (Config.StrengthEffects.meleeMultiplier.max - Config.StrengthEffects.meleeMultiplier.min)
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = string.format('Rep complete! Strength: %.1f | Melee: %.1fx', data.strength, meleeMult)
    })
    return true, data.strength
end

lib.callback.register('gym-system:server:getGymData', function(source)
    return GetGymData(source)
end)

lib.callback.register('gym-system:server:performRep', function(source, equipmentName)
    return PerformRep(source, equipmentName)
end)

lib.callback.register('gym-system:server:getEquipment', function(source)
    return Config.Equipment
end)

lib.callback.register('gym-system:server:getGymLocations', function(source)
    return Config.GymLocations
end)

RegisterNetEvent('gym-system:server:rest', function()
    local source = source
    if not source then return end
    local data = GetGymData(source)
    if not data then return end
    data.gymStamina = math.min(Config.Gym.maxStamina, data.gymStamina + 20)
    data.dirty = true
    TriggerClientEvent('ox_lib:notify', source, { type = 'info', description = 'Rested. Stamina recovered.' })
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[gym-system] Gym progression system initialized. Strength & stamina tracking active.^7')
end)

exports('GetPlayerStrength', function(source)
    local data = GetGymData(source)
    return data and data.strength or 0
end)

exports('GetMeleeMultiplier', function(source)
    local data = GetGymData(source)
    if not data then return 1.0 end
    return Config.StrengthEffects.meleeMultiplier.min + (data.strength / Config.Gym.maxStrength) * (Config.StrengthEffects.meleeMultiplier.max - Config.StrengthEffects.meleeMultiplier.min)
end)

exports('GetSpeedMultiplier', function(source)
    local data = GetGymData(source)
    if not data then return 1.0 end
    return Config.StrengthEffects.runningSpeed.min + (data.strength / Config.Gym.maxStrength) * (Config.StrengthEffects.runningSpeed.max - Config.StrengthEffects.runningSpeed.min)
end)
