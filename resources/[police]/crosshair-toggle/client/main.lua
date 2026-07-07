local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local crosshairEnabled = false
local currentStyle = 'dot'

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerData.job = job
end)

local function canUseCrosshair()
    if Config.Crosshair.RequireDuty then
        if not playerData.job or playerData.job.type ~= 'leo' or not playerData.job.onduty then
            return false
        end
    end
    if Config.Crosshair.RequireJob then
        if not playerData.job then return false end
        local jobMatch = false
        for _, job in ipairs(Config.Crosshair.AllowedJobs) do
            if playerData.job.name == job then jobMatch = true break end
        end
        if not jobMatch then return false end
    end
    return true
end

RegisterCommand('+crosshair', function()
    TriggerEvent('crosshair:toggle')
end, false)

RegisterKeyMapping('+crosshair', 'Toggle Crosshair', 'keyboard', 'f2')

RegisterNetEvent('crosshair:toggle', function()
    if not canUseCrosshair() then
        Wrappers.Notify(Locale('police.not_authorized_crosshair'), 'error')
        return
    end
    crosshairEnabled = not crosshairEnabled
    TriggerServerEvent('crosshair:server:toggled', crosshairEnabled)
    Wrappers.Notify(crosshairEnabled and Locale('police.crosshair_on') or Locale('police.crosshair_off'), 'info')
end)

RegisterNetEvent('crosshair:changeStyle', function(style)
    if Config.Crosshair.Styles[style] then
        currentStyle = style
        Wrappers.Notify(Locale('police.crosshair_style', Config.Crosshair.Styles[style].label), 'success')
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if crosshairEnabled and canUseCrosshair() then
            local ped = PlayerPedId()
            local inVehicle = IsPedInAnyVehicle(ped, false)
            if Config.Crosshair.HideInVehicle and inVehicle then
                Citizen.Wait(500)
                return
            end
            local aiming = IsPedAiming(ped) or IsControlPressed(0, 25)
            if Config.Crosshair.AlwaysVisible or (Config.Crosshair.ShowOnAim and aiming) or (Config.Crosshair.ShowOnHip and not aiming and not inVehicle) then
                local camCoords = GetGameplayCamCoord()
                local camRot = GetGameplayCamRot(2)
                local _, _, forward = GetCamForwardVector()
                local screenX, screenY = getScreenCenter()
                if currentStyle == 'dot' then
                    local size = Config.Crosshair.CrosshairSize or Config.Crosshair.Styles.dot.size
                    DrawRect(screenX, screenY, 0.002 * size, 0.002 * size, Config.Crosshair.CrosshairColor.r, Config.Crosshair.CrosshairColor.g, Config.Crosshair.CrosshairColor.b, Config.Crosshair.CrosshairColor.a)
                elseif currentStyle == 'cross' then
                    local size = Config.Crosshair.Styles.cross.size
                    DrawRect(screenX - 0.01 * size, screenY, 0.015 * size, 0.002 * size, Config.Crosshair.CrosshairColor.r, Config.Crosshair.CrosshairColor.g, Config.Crosshair.CrosshairColor.b, Config.Crosshair.CrosshairColor.a)
                    DrawRect(screenX + 0.01 * size, screenY, 0.015 * size, 0.002 * size, Config.Crosshair.CrosshairColor.r, Config.Crosshair.CrosshairColor.g, Config.Crosshair.CrosshairColor.b, Config.Crosshair.CrosshairColor.a)
                    DrawRect(screenX, screenY - 0.01 * size, 0.002 * size, 0.015 * size, Config.Crosshair.CrosshairColor.r, Config.Crosshair.CrosshairColor.g, Config.Crosshair.CrosshairColor.b, Config.Crosshair.CrosshairColor.a)
                    DrawRect(screenX, screenY + 0.01 * size, 0.002 * size, 0.015 * size, Config.Crosshair.CrosshairColor.r, Config.Crosshair.CrosshairColor.g, Config.Crosshair.CrosshairColor.b, Config.Crosshair.CrosshairColor.a)
                elseif currentStyle == 'circle' then
                    local size = Config.Crosshair.Styles.circle.size
                    local numPoints = 20
                    for i = 0, numPoints do
                        local angle = (i / numPoints) * 2.0 * math.pi
                        local px = screenX + math.cos(angle) * 0.01 * size
                        local py = screenY + math.sin(angle) * 0.01 * size
                        DrawRect(px, py, 0.003, 0.003, Config.Crosshair.CrosshairColor.r, Config.Crosshair.CrosshairColor.g, Config.Crosshair.CrosshairColor.b, Config.Crosshair.CrosshairColor.a)
                    end
                end
            end
        else
            Citizen.Wait(500)
        end
        Citizen.Wait(0)
    end
end)

local function getScreenCenter()
    local resX, resY = GetActiveScreenResolution()
    return 0.5, 0.5
end

local function GetCamForwardVector()
    local camRot = GetGameplayCamRot(2)
    local yaw = math.rad(camRot.z)
    local pitch = math.rad(camRot.x)
    local x = -math.sin(yaw) * math.cos(pitch)
    local y = math.cos(yaw) * math.cos(pitch)
    local z = math.sin(pitch)
    return vector3(x, y, z), x, y, z
end

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    crosshairEnabled = false
end)
