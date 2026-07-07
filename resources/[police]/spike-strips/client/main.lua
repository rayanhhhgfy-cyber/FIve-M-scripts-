local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local deployedStrips = {}
local stripObjects = {}
local cooldown = false

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerData.job = job
end)

local function isOnDuty()
    return playerData.job and playerData.job.type == 'leo' and playerData.job.onduty
end

local function hasItem()
    return QBox.Functions.HasItem(Config.SpikeStrips.RequiredItem)
end

Citizen.CreateThread(function()
    while not QBox.Functions.GetPlayerData().citizenid do
        Citizen.Wait(100)
    end
    playerData = QBox.Functions.GetPlayerData()

    for i = 1, Config.SpikeStrips.MaxActive do
        exports.ox_target:addSphereZone({
            coords = vector3(0, 0, 0),
            radius = 0.5,
            debug = false,
            options = {
                {
                    name = 'spikestrip_pickup_' .. i,
                    icon = Config.SpikeStrips.TargetOptions.pickup.icon,
                    label = Config.SpikeStrips.TargetOptions.pickup.label,
                    distance = Config.SpikeStrips.TargetOptions.pickup.distance,
                    canInteract = function()
                        return deployedStrips[i] ~= nil
                    end,
                    onSelect = function()
                        TriggerEvent('spikestrips:pickup', i)
                    end
                }
            }
        })
    end
end)

RegisterCommand('+spikestrip', function()
    TriggerEvent('spikestrips:deploy')
end, false)

RegisterKeyMapping('+spikestrip', 'Deploy Spike Strip', 'keyboard', 'z')

RegisterNetEvent('spikestrips:deploy', function()
    if cooldown then
        Wrappers.Notify(Locale('police.cooldown_active'), 'error')
        return
    end
    if Config.SpikeStrips.RequireDuty and not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    if not hasItem() then
        Wrappers.Notify(Locale('police.no_spikestrip'), 'error')
        return
    end
    local activeCount = 0
    for _, v in pairs(deployedStrips) do
        if v then activeCount = activeCount + 1 end
    end
    if activeCount >= Config.SpikeStrips.MaxActive then
        Wrappers.Notify(Locale('police.max_strips'), 'error')
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    Wrappers.ProgressBar({
        label = Locale('police.deploying_strips'),
        duration = Config.SpikeStrips.DeployTime,
        useWhileDead = false,
        canCancel = true
    }, function(cancelled)
        if cancelled then return end
        if not QBox.Functions.HasItem(Config.SpikeStrips.RequiredItem) then
            Wrappers.Notify(Locale('police.no_spikestrip'), 'error')
            return
        end
        QBox.Functions.RemoveItem(Config.SpikeStrips.RequiredItem, 1)
        TriggerServerEvent('spikestrips:server:deploy', coords, heading)
    end)
end)

RegisterNetEvent('spikestrips:client:deploy', function(id, coords, heading)
    local stripZone = nil
    for i = 1, Config.SpikeStrips.MaxActive do
        if not deployedStrips[i] then
            stripZone = i
            break
        end
    end
    if not stripZone then return end

    local objects = {}
    local offset = -Config.SpikeStrips.StripLength / 2
    for j = 0, 4 do
        local obj = CreateObject(GetHashKey('prop_roadcone02a'), coords.x + offset + j * 1.2, coords.y, coords.z - 1.0, true, false, false)
        SetEntityHeading(obj, heading)
        FreezeEntityPosition(obj, true)
        SetEntityCollision(obj, true, true)
        objects[j + 1] = obj
    end
    stripObjects[stripZone] = objects
    deployedStrips[stripZone] = { coords = coords, heading = heading, time = os.time(), active = true }
    local zone = exports.ox_target:getSphereZone('spikestrip_pickup_' .. stripZone)
    if zone then
        zone:setCoords(coords)
    end
    Wrappers.Notify(Locale('police.strips_deployed'), 'success')
end)

RegisterNetEvent('spikestrips:pickup', function(id)
    if not deployedStrips[id] then return end
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local dist = #(coords - deployedStrips[id].coords)
    if dist > 5.0 then
        Wrappers.Notify(Locale('police.too_far'), 'error')
        return
    end
    Wrappers.ProgressBar({
        label = Locale('police.picking_up_strips'),
        duration = Config.SpikeStrips.PickupTime,
        useWhileDead = false,
        canCancel = true
    }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('spikestrips:server:pickup', id)
    end)
end)

RegisterNetEvent('spikestrips:client:pickup', function(id)
    if stripObjects[id] then
        for _, obj in ipairs(stripObjects[id]) do
            DeleteObject(obj)
        end
        stripObjects[id] = nil
    end
    deployedStrips[id] = nil
    QBox.Functions.AddItem(Config.SpikeStrips.RequiredItem, 1)
    Wrappers.Notify(Locale('police.strips_picked_up'), 'success')
    local zone = exports.ox_target:getSphereZone('spikestrip_pickup_' .. id)
    if zone then
        zone:setCoords(vector3(0, 0, 0))
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            for id, strip in pairs(deployedStrips) do
                if strip.active then
                    local vCoords = GetEntityCoords(veh)
                    local dist = #(vCoords - strip.coords)
                    if dist < 3.0 then
                        local speed = GetEntitySpeed(veh) * 3.6
                        if speed > 20 then
                            if math.random(100) <= Config.SpikeStrips.PopChance then
                                local numPops = math.random(1, Config.SpikeStrips.MaxPops)
                                for i = 1, numPops do
                                    local wheel = math.random(4) - 1
                                    if not IsVehicleTyreBurst(veh, wheel, false) then
                                        SetVehicleTyreBurst(veh, wheel, false, 1000.0)
                                    end
                                end
                                if Config.SpikeStrips.DamageVehicle then
                                    SetVehicleBodyHealth(veh, GetVehicleBodyHealth(veh) - Config.SpikeStrips.DamageMultiplier * speed)
                                end
                                deployedStrips[id].active = false
                                Wrappers.Notify(Locale('police.vehicle_hit_strips'), 'warning')
                            end
                        end
                    end
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        local now = os.time()
        for id, strip in pairs(deployedStrips) do
            if now - strip.time > Config.SpikeStrips.DespawnTime then
                TriggerEvent('spikestrips:pickup', id)
            end
        end
    end
end)
