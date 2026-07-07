local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local panicCooldown = false
local activeAlertBlips = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerData.job = job
end)

local function isOnDuty()
    return playerData.job and playerData.job.type == 'leo' and playerData.job.onduty
end

local function sendInstantPanic()
    if panicCooldown then
        Wrappers.Notify(Locale('police.panic_cooldown'), 'error')
        return
    end
    if Config.PanicButton.RequireDuty and not isOnDuty() then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    panicCooldown = true
    local alertData = Config.PanicButton.Alerts['OfficerNeedsAssistance']
    TriggerServerEvent('panic:server:sendAlert', 'OfficerNeedsAssistance', alertData.label, alertData.urgent)
    SetTimeout(Config.PanicButton.Cooldown, function()
        panicCooldown = false
    end)
end

RegisterCommand('+panic', function()
    sendInstantPanic()
end, false)

RegisterKeyMapping('+panic', 'Panic Button', 'keyboard', 'p')

RegisterNetEvent('panic:client:receiveAlert', function(alertId, label, urgent, officerName, coords, officerSrc)
    if Config.PanicButton.Notification.SoundEnabled then
        PlaySound(-1, Config.PanicButton.Notification.SoundName, Config.PanicButton.Notification.SoundDict, false, 0, true)
    end
    if Config.PanicButton.Notification.ScreenFlash then
        DoScreenFadeOut(100)
        Citizen.Wait(100)
        DoScreenFadeIn(100)
    end
    if Config.PanicButton.Notification.DispatchBlip then
        local blip = AddBlipForCoord(coords)
        SetBlipSprite(blip, 60)
        SetBlipColour(blip, 1)
        SetBlipScale(blip, 1.5)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(label .. ' - ' .. officerName)
        EndTextCommandSetBlipName(blip)
        if activeAlertBlips[officerSrc] then
            RemoveBlip(activeAlertBlips[officerSrc])
        end
        activeAlertBlips[officerSrc] = blip
        SetTimeout(Config.PanicButton.Notification.BlipTime, function()
            if blip then RemoveBlip(blip) end
            activeAlertBlips[officerSrc] = nil
        end)
    end
    if Config.PanicButton.Notification.DispatchMessage then
        Wrappers.Notify(Locale('police.panic_alert_received', label, officerName), urgent and 'error' or 'warning')
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        if IsPedDeadOrDying(ped) and Config.PanicButton.AutomaticAlerts.OnDeath and isOnDuty() then
            TriggerServerEvent('panic:server:sendAlert', 'OfficerNeedsAssistance', 'Officer Down', true)
            Citizen.Wait(30000)
        else
            local health = GetEntityHealth(ped)
            if health > 0 and health < Config.PanicButton.AutomaticAlerts.HealthThreshold and isOnDuty() then
                TriggerServerEvent('panic:server:sendAlert', 'OfficerNeedsAssistance', 'Officer Needs Assistance', true)
                Citizen.Wait(60000)
            end
        end
    end
end)
