local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local droneActive = false
local droneObject = nil
local batteryLevel = Config.Drone.BatteryMax
local nightVision = false
local thermalVision = false
local cameraZoom = 1

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() playerData = QBox.Functions.GetPlayerData() end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(j) playerData.job = j end)

local function isCID() return playerData.job and (playerData.job.name == 'cid' or playerData.job.name == 'police') end
local function isOnDuty() return playerData.job and playerData.job.onduty end
local function rank() return playerData.job and playerData.job.grade.level or 0 end

RegisterNetEvent('drone:deploy', function()
    if droneActive then return end
    if not isCID() or not isOnDuty() then Wrappers.Notify(Locale('cid.not_authorized'), 'error') return end
    if rank() < Config.Drone.MinRank then Wrappers.Notify(Locale('cid.rank_too_low'), 'error') return end
    if not QBox.Functions.HasItem(Config.Drone.ItemName) then Wrappers.Notify(Locale('cid.no_drone'), 'error') return end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then Wrappers.Notify(Locale('cid.cannot_in_vehicle'), 'error') return end
    Wrappers.ProgressBar({ label = Locale('cid.deploying_drone'), duration = Config.Drone.DeployTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        local coords = GetEntityCoords(ped) + vector3(0.0, 0.0, 3.0)
        local model = GetHashKey(Config.Drone.Model)
        RequestModel(model)
        while not HasModelLoaded(model) do Citizen.Wait(0) end
        droneObject = CreateObject(model, coords.x, coords.y, coords.z, true, false, false)
        SetEntityCollision(droneObject, false, false)
        SetEntityAlpha(droneObject, 200, false)
        FreezeEntityPosition(droneObject, true)
        droneActive = true
        batteryLevel = Config.Drone.BatteryMax
        TriggerServerEvent('drone:server:deployed')
        Wrappers.Notify(Locale('cid.drone_deployed'), 'success')
    end)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if droneActive and droneObject then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(droneObject)
            local camCoords = GetGameplayCamCoord()
            if IsControlPressed(0, Config.Drone.Controls.Up) and coords.z < Config.Drone.MaxAltitude then
                SetEntityCoords(droneObject, coords.x, coords.y, coords.z + 0.5)
            end
            if IsControlPressed(0, Config.Drone.Controls.Down) and coords.z > Config.Drone.MinAltitude then
                SetEntityCoords(droneObject, coords.x, coords.y, coords.z - 0.5)
            end
            if IsControlPressed(0, Config.Drone.Controls.Forward) then
                local fwd = GetEntityForwardVector(droneObject)
                SetEntityCoords(droneObject, coords.x + fwd.x * 0.3, coords.y + fwd.y * 0.3, coords.z)
            end
            if IsControlPressed(0, Config.Drone.Controls.Backward) then
                local fwd = GetEntityForwardVector(droneObject)
                SetEntityCoords(droneObject, coords.x - fwd.x * 0.3, coords.y - fwd.y * 0.3, coords.z)
            end
            if IsControlPressed(0, Config.Drone.Controls.Left) then
                SetEntityCoords(droneObject, coords.x - 0.3, coords.y, coords.z)
            end
            if IsControlPressed(0, Config.Drone.Controls.Right) then
                SetEntityCoords(droneObject, coords.x + 0.3, coords.y, coords.z)
            end
            if IsControlJustPressed(0, Config.Drone.Controls.Boost) then
                local fwd = GetEntityForwardVector(droneObject)
                SetEntityVelocity(droneObject, fwd * Config.Drone.BoostSpeed)
            end
            if IsControlJustPressed(0, Config.Drone.Controls.NightVision) then
                nightVision = not nightVision
                SetNightVision(nightVision)
                if nightVision then thermalVision = false end
            end
            if IsControlJustPressed(0, Config.Drone.Controls.Thermal) then
                thermalVision = not thermalVision
                SetThermalVision(thermalVision)
                if thermalVision then nightVision = false end
            end
            if IsControlJustPressed(0, Config.Drone.Controls.Camera) then
                local dist = #(GetEntityCoords(ped) - coords)
                if dist > Config.Drone.MaxRange then
                    Wrappers.Notify(Locale('cid.drone_out_of_range'), 'warning')
                end
                SetCamFov(camCoords, Config.Drone.CameraFOV / cameraZoom)
                cameraZoom = cameraZoom + 1
                if cameraZoom > #Config.Drone.Camera.ZoomLevels then cameraZoom = 1 end
            end
            if IsControlJustPressed(0, Config.Drone.Controls.Land) then
                TriggerEvent('drone:store')
            end
            if IsControlJustPressed(0, Config.Drone.Controls.Return) and Config.Drone.ReturnToHome then
                local pedCoords = GetEntityCoords(ped)
                SetEntityCoords(droneObject, pedCoords.x, pedCoords.y, pedCoords.z + 5.0)
                Wrappers.Notify(Locale('cid.drone_returning'), 'info')
            end
            batteryLevel = math.max(0, batteryLevel - Config.Drone.BatteryDrain / 60)
            if batteryLevel <= 0 then
                TriggerEvent('drone:store')
                Wrappers.Notify(Locale('cid.drone_battery_dead'), 'error')
            end
            SetTextFont(4); SetTextScale(0.4, 0.4); SetTextColour(255, 255, 255, 255); SetTextCentre(true)
            SetTextEntry('STRING'); AddTextComponentString(Locale('cid.drone_battery', math.ceil(batteryLevel) .. '%'))
            DrawText(0.5, 0.02)
            SetEntityHeading(droneObject, GetEntityHeading(droneObject))
        else
            Citizen.Wait(500)
        end
        Citizen.Wait(0)
    end
end)

RegisterNetEvent('drone:store', function()
    if not droneActive then return end
    Wrappers.ProgressBar({ label = Locale('cid.storing_drone'), duration = Config.Drone.StoreTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        if droneObject then DeleteObject(droneObject) droneObject = nil end
        droneActive = false
        if nightVision then SetNightVision(false) nightVision = false end
        if thermalVision then SetThermalVision(false) thermalVision = false end
        cameraZoom = 1
        TriggerServerEvent('drone:server:stored')
        Wrappers.Notify(Locale('cid.drone_stored'), 'success')
    end)
end)

AddEventHandler('onResourceStop', function(r)
    if GetCurrentResourceName() == r and droneObject then DeleteObject(droneObject) end
end)
