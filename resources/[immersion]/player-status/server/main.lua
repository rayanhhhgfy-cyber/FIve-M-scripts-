local QBCore = exports['qbx_core']:GetCoreObject()
local playerStatus = {}

local function InitializePlayerStatus(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    local metadata = player.PlayerData.metadata
    playerStatus[source] = {
        hunger = metadata.hunger or Config.Status.maxHunger,
        thirst = metadata.thirst or Config.Status.maxThirst,
        stress = metadata.stress or 0,
        stamina = metadata.stamina or Config.Status.maxStamina,
        dirty = false
    }
    return playerStatus[source]
end

local function GetStatus(source)
    if not playerStatus[source] then
        InitializePlayerStatus(source)
    end
    return playerStatus[source]
end

local function ClampStatus(value, maxVal)
    return math.max(0, math.min(maxVal, value))
end

local function SaveStatus(source)
    local status = playerStatus[source]
    if not status or not status.dirty then return end
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    local metadata = player.PlayerData.metadata
    metadata.hunger = status.hunger
    metadata.thirst = status.thirst
    metadata.stress = status.stress
    metadata.stamina = status.stamina
    player.Functions.SetMetaData('hunger', status.hunger)
    player.Functions.SetMetaData('thirst', status.thirst)
    player.Functions.SetMetaData('stress', status.stress)
    player.Functions.SetMetaData('stamina', status.stamina)
    status.dirty = false
end

local function ApplyDecay(source)
    local status = GetStatus(source)
    if not status then return end
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    local ped = GetPlayerPed(source)
    local isRunning = false
    local isSprinting = false
    if ped and ped > 0 then
        isRunning = IsPedRunning(ped)
        isSprinting = IsPedSprinting(ped)
    end
    local hungerMult = 1.0
    local thirstMult = 1.0
    if isRunning then
        hungerMult = Config.Decay.hungerRunningMultiplier
        thirstMult = Config.Decay.thirstRunningMultiplier
    end
    status.hunger = ClampStatus(status.hunger - Config.Decay.hungerPerInterval * hungerMult, Config.Status.maxHunger)
    status.thirst = ClampStatus(status.thirst - Config.Decay.thirstPerInterval * thirstMult, Config.Status.maxThirst)
    if isSprinting then
        status.stamina = ClampStatus(status.stamina - Config.Decay.staminaSprintingMultiplier, Config.Status.maxStamina)
    elseif isRunning then
        status.stamina = ClampStatus(status.stamina - Config.Decay.staminaRunningMultiplier, Config.Status.maxStamina)
    else
        status.stamina = ClampStatus(status.stamina + 1, Config.Status.maxStamina)
    end
    status.dirty = true
    TriggerClientEvent('player-status:client:update', source, status)
end

function ConsumeItem(source, itemName)
    local foodData = Config.FoodItems[itemName]
    if not foodData then return false end
    local status = GetStatus(source)
    if not status then return false end
    status.hunger = ClampStatus(status.hunger + (foodData.hunger or 0), Config.Status.maxHunger)
    status.thirst = ClampStatus(status.thirst + (foodData.thirst or 0), Config.Status.maxThirst)
    status.stress = ClampStatus(status.stress + (foodData.stress or 0), Config.Status.maxStress)
    status.stamina = ClampStatus(status.stamina + (foodData.stamina or 0), Config.Status.maxStamina)
    status.dirty = true
    SaveStatus(source)
    TriggerClientEvent('player-status:client:update', source, status)
    return true
end

function AddStress(source, amount)
    local status = GetStatus(source)
    if not status then return end
    status.stress = ClampStatus(status.stress + amount, Config.Status.maxStress)
    status.dirty = true
    SaveStatus(source)
    TriggerClientEvent('player-status:client:update', source, status)
end

function RemoveStress(source, amount)
    local status = GetStatus(source)
    if not status then return end
    status.stress = ClampStatus(status.stress - amount, Config.Status.maxStress)
    status.dirty = true
    SaveStatus(source)
    TriggerClientEvent('player-status:client:update', source, status)
end

lib.callback.register('player-status:server:getStatus', function(source)
    return GetStatus(source)
end)

lib.callback.register('player-status:server:consumeItem', function(source, itemName)
    return ConsumeItem(source, itemName)
end)

RegisterNetEvent('player-status:server:addStress', function(amount)
    local source = source
    if not source then return end
    AddStress(source, amount or 0)
end)

RegisterNetEvent('player-status:server:removeStress', function(amount)
    local source = source
    if not source then return end
    RemoveStress(source, amount or 0)
end)

RegisterNetEvent('player-status:server:addStamina', function(amount)
    local source = source
    if not source then return end
    local status = GetStatus(source)
    if not status then return end
    status.stamina = ClampStatus(status.stamina + (amount or 0), Config.Status.maxStamina)
    status.dirty = true
    TriggerClientEvent('player-status:client:update', source, status)
end)

RegisterNetEvent('player-status:server:damageTaken', function()
    local source = source
    if not source then return end
    AddStress(source, Config.StressTriggers.damageTaken)
end)

RegisterNetEvent('player-status:server:killReceived', function()
    local source = source
    if not source then return end
    AddStress(source, Config.StressTriggers.killerReceived)
end)

AddEventHandler('playerConnecting', function()
    local source = source
    if not source then return end
    InitializePlayerStatus(source)
end)

AddEventHandler('playerDropped', function()
    local source = source
    if not source then return end
    SaveStatus(source)
    playerStatus[source] = nil
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.Status.saveInterval)
        for src in pairs(playerStatus) do
            SaveStatus(src)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.Status.decayInterval)
        if Config.Status.enabled then
            for src in pairs(playerStatus) do
                ApplyDecay(src)
            end
        end
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[player-status] Status system initialized. Hunger, thirst, stress, stamina tracking active.^7')
end)

exports('GetPlayerStatus', GetStatus)
exports('AddStress', AddStress)
exports('RemoveStress', RemoveStress)
exports('ConsumeItem', ConsumeItem)
