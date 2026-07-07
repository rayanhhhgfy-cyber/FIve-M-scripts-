local QBCore = exports['qbx_core']:GetCoreObject()
local seatbeltOn = false
local lastVehicle = 0
local lastVelocity = 0
local warningShown = false

function ToggleSeatbelt()
    seatbeltOn = not seatbeltOn
    local msg = seatbeltOn and 'Seatbelt ON' or 'Seatbelt OFF'
    Wrappers.Notify({ type = seatbeltOn and 'success' or 'warning', description = msg })
    if Config.Sounds.enabled then
        -- Trigger sound event
    end
end

local function EjectPlayer(vehicle)
    if not Config.Ejection.enabled then return end
    if seatbeltOn then return end
    local speed = GetEntitySpeed(vehicle) * 3.6
    if speed < Config.Ejection.minSpeedForEjection then return end
    local normalizedSpeed = (speed - Config.Ejection.minSpeedForEjection) / (Config.Ejection.maxEjectionSpeed - Config.Ejection.minSpeedForEjection)
    local chance = Config.Ejection.ejectionChance + normalizedSpeed * 0.5
    if math.random() < chance then
        local ped = PlayerPedId()
        TaskLeaveAnyVehicle(ped, 0, 16)
        Citizen.Wait(100)
        SetPedRagdoll(ped, Config.Ejection.ragdollDuration, Config.Ejection.ragdollDuration, 0, 0, 0, 0)
        if Config.Seatbelt.enabled then
            local damage = math.floor(Config.Ejection.ejectionDamage * (1 + normalizedSpeed))
            SetEntityHealth(ped, GetEntityHealth(ped) - damage)
            TriggerServerEvent('seatbelt-system:server:ejected', damage)
        end
        Wrappers.Notify({ type = 'error', description = '~r~EJECTED!', duration = 3000 })
    end
end

local function CheckCollision(vehicle)
    local velocity = GetEntityVelocity(vehicle)
    local speed = math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y + velocity.z * velocity.z)
    local deltaV = math.abs(speed - lastVelocity)
    if deltaV > 5.0 and lastVelocity > 0 then
        if seatbeltOn then
            if Config.Shake.enabled then
                ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', Config.Shake.collisionShake.intensity)
            end
            if Config.Sounds.enabled then
                -- Play collision sound
            end
        else
            local shakeIntensity = Config.Shake.collisionShake.intensity * 2.0
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', shakeIntensity)
            EjectPlayer(vehicle)
            if math.random() < Config.Ejection.windshieldBreakChance then
                local windowIndex = math.random(4) - 1
                SmashVehicleWindow(vehicle, windowIndex)
            end
        end
    end
    lastVelocity = speed
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.Seatbelt.checkInterval)
        if not Config.Seatbelt.enabled then Citizen.Wait(1000) end
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle and vehicle > 0 then
            if not seatbeltOn then
                local speed = GetEntitySpeed(vehicle) * 3.6
                if speed > Config.Ejection.minSpeedForEjection and not warningShown then
                    Wrappers.Notify({ type = 'warning', description = '~r~FASTEN SEATBELT!', duration = 3000 })
                    warningShown = true
                end
                if speed < 10 then
                    warningShown = false
                end
                if Config.Shake.enabled and speed > Config.Shake.highSpeedShake.minSpeed then
                    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', Config.Shake.highSpeedShake.intensity)
                end
            end
            if vehicle ~= lastVehicle then
                lastVelocity = 0
                lastVehicle = vehicle
            end
            CheckCollision(vehicle)
        else
            lastVehicle = 0
            lastVelocity = 0
            warningShown = false
        end
    end
end)

RegisterCommand(Config.Seatbelt.toggleCommand, function()
    ToggleSeatbelt()
end, false)

RegisterKeyMapping(Config.Seatbelt.toggleCommand, 'Toggle Seatbelt', 'keyboard', 'b')

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[seatbelt-system] Seatbelt physics, ejection, and screen-shake active.^7')
end)

exports('IsSeatbeltOn', function() return seatbeltOn end)
exports('ToggleSeatbelt', ToggleSeatbelt)
