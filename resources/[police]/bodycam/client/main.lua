local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local isRecording = false
local batteryLevel = Config.Bodycam.UI.BatteryMax
local recordTime = 0
local bodycamActive = false
local hudVisible = false

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBox.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    local wasOnDuty = playerData.job and playerData.job.onduty
    playerData.job = job
    local nowOnDuty = job and job.onduty

    if Config.Bodycam.AutoRecordOnDuty and nowOnDuty ~= wasOnDuty then
        if nowOnDuty then
            if hasBodycam() and not bodycamActive then
                bodycamActive = true
                Wrappers.Notify(Locale('police.bodycam_on'), 'success')
                if not isRecording then
                    isRecording = true
                    recordTime = 0
                    TriggerServerEvent('bodycam:server:startRecording')
                end
            end
        else
            if isRecording then
                isRecording = false
                TriggerServerEvent('bodycam:server:stopRecording', recordTime)
            end
            if bodycamActive then
                bodycamActive = false
                Wrappers.Notify(Locale('police.bodycam_off'), 'info')
            end
        end
    end
end)

local function isOnDuty()
    return playerData.job and playerData.job.type == 'leo' and playerData.job.onduty
end

local function hasBodycam()
    return QBox.Functions.HasItem(Config.Bodycam.ItemName)
end

local function toggleBodycam()
    if not hasBodycam() then
        Wrappers.Notify(Locale('police.no_bodycam'), 'error')
        return
    end
    if not isOnDuty() and Config.Bodycam.RequireDuty then
        Wrappers.Notify(Locale('police.not_on_duty'), 'error')
        return
    end
    bodycamActive = not bodycamActive
    if bodycamActive then
        Wrappers.Notify(Locale('police.bodycam_on'), 'success')
    else
        if isRecording then
            isRecording = false
            TriggerServerEvent('bodycam:server:stopRecording', recordTime)
        end
        Wrappers.Notify(Locale('police.bodycam_off'), 'info')
    end
end

RegisterCommand('+bodycam', function()
    toggleBodycam()
end, false)

RegisterKeyMapping('+bodycam', 'Toggle Body Camera', 'keyboard', 'l')

RegisterNetEvent('bodycam:toggleRecord', function()
    if not bodycamActive then
        Wrappers.Notify(Locale('police.bodycam_off_first'), 'error')
        return
    end
    if not hasBodycam() then
        Wrappers.Notify(Locale('police.no_bodycam'), 'error')
        return
    end
    if batteryLevel <= 0 then
        Wrappers.Notify(Locale('police.bodycam_battery_dead'), 'error')
        return
    end
    isRecording = not isRecording
    if isRecording then
        recordTime = 0
        TriggerServerEvent('bodycam:server:startRecording')
        Wrappers.Notify(Locale('police.recording_started'), 'success')
    else
        TriggerServerEvent('bodycam:server:stopRecording', recordTime)
        Wrappers.Notify(Locale('police.recording_stopped'), 'info')
    end
    TriggerServerEvent('bodycam:server:logToggle', isRecording)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if bodycamActive then
            local ped = PlayerPedId()
            if not IsPedInAnyVehicle(ped, false) then
                if isRecording then
                    recordTime = recordTime + 1
                    batteryLevel = math.max(0, batteryLevel - Config.Bodycam.UI.BatteryDrainRate / 60)
                    if batteryLevel <= 0 then
                        isRecording = false
                        TriggerServerEvent('bodycam:server:stopRecording', recordTime)
                        Wrappers.Notify(Locale('police.bodycam_battery_dead'), 'error')
                    end
                    if recordTime >= Config.Bodycam.RecordTimeMax then
                        isRecording = false
                        TriggerServerEvent('bodycam:server:stopRecording', recordTime)
                        Wrappers.Notify(Locale('police.recording_max_reached'), 'info')
                    end
                end
                if Config.Bodycam.UI.ShowHUD then
                    local camCoords = GetGameplayCamCoord()
                    local pedCoords = GetEntityCoords(ped)
                    local forward = GetEntityForwardVector(ped)
                    DrawRect(0.5, 0.95, 0.3, 0.05, 0, 0, 0, 150)
                    if isRecording then
                        local blink = math.floor(GetGameTimer() / Config.Bodycam.UI.RecordBlinkInterval) % 2 == 0
                        if blink then
                            DrawRect(0.38, 0.95, 0.02, 0.03, Config.Bodycam.RecordIndicatorColor.r, Config.Bodycam.RecordIndicatorColor.g, Config.Bodycam.RecordIndicatorColor.b, 200)
                        end
                        local minutes = math.floor(recordTime / 60)
                        local seconds = recordTime % 60
                        SetTextFont(4)
                        SetTextScale(0.35, 0.35)
                        SetTextColour(255, 255, 255, 255)
                        SetTextCentre(true)
                        SetTextEntry('STRING')
                        AddTextComponentString(string.format('%02d:%02d', minutes, seconds) .. ' REC')
                        DrawText(0.44, 0.947)
                    end
                    if Config.Bodycam.UI.ShowBattery then
                        local batColor = { r = 0, g = 255, b = 0 }
                        if batteryLevel < 25 then batColor = { r = 255, g = 0, b = 0 }
                        elseif batteryLevel < 50 then batColor = { r = 255, g = 255, b = 0 } end
                        DrawRect(0.68, 0.95, 0.08, 0.025, 0, 0, 0, 200)
                        DrawRect(0.68, 0.95, 0.075 * (batteryLevel / 100), 0.02, batColor.r, batColor.g, batColor.b, 200)
                        SetTextFont(4)
                        SetTextScale(0.25, 0.25)
                        SetTextColour(255, 255, 255, 255)
                        SetTextCentre(true)
                        SetTextEntry('STRING')
                        AddTextComponentString(math.ceil(batteryLevel) .. '%')
                        DrawText(0.68, 0.947)
                    end
                end
            end
        else
            Citizen.Wait(500)
        end
        Citizen.Wait(0)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if isRecording then
        TriggerServerEvent('bodycam:server:stopRecording', recordTime)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isRecording then
            TriggerServerEvent('bodycam:server:stopRecording', recordTime)
        end
    end
end)
