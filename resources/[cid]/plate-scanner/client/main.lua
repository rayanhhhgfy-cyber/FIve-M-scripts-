local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local scannedPlates = {}
local scanCooldown = false

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() playerData = QBox.Functions.GetPlayerData() end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(j) playerData.job = j end)

local function isCID() return playerData.job and (playerData.job.name == 'cid' or playerData.job.name == 'police') end
local function isOnDuty() return playerData.job and playerData.job.onduty end

RegisterCommand('+platescan', function() TriggerEvent('plate:manualScan') end, false)
RegisterKeyMapping('+platescan', 'Scan License Plate', 'keyboard', 'z')

RegisterNetEvent('plate:manualScan', function()
    if not isCID() or not isOnDuty() then Wrappers.Notify(Locale('cid.not_authorized'), 'error') return end
    if scanCooldown then Wrappers.Notify(Locale('cid.scan_cooldown'), 'error') return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        local targetVeh = QBox.Functions.GetClosestVehicle()
        if targetVeh ~= 0 then
            scanCooldown = true
            local plate = GetVehicleNumberPlateText(targetVeh)
            TriggerServerEvent('plate:server:scan', plate)
            SetTimeout(Config.PlateScanner.ScanCooldown, function() scanCooldown = false end)
        else
            Wrappers.Notify(Locale('cid.no_vehicle_near'), 'error')
        end
    else
        scanCooldown = true
        local plate = GetVehicleNumberPlateText(veh)
        TriggerServerEvent('plate:server:scan', plate)
        SetTimeout(Config.PlateScanner.ScanCooldown, function() scanCooldown = false end)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.PlateScanner.ScanInterval)
        if Config.PlateScanner.AutoScan and isCID() and isOnDuty() then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                local plate = GetVehicleNumberPlateText(veh)
                if plate and plate ~= '' and not scannedPlates[plate] then
                    TriggerServerEvent('plate:server:scan', plate)
                end
            else
                local targetVeh = QBox.Functions.GetClosestVehicle()
                if targetVeh ~= 0 then
                    local pCoords = GetEntityCoords(ped)
                    local vCoords = GetEntityCoords(targetVeh)
                    if #(pCoords - vCoords) < Config.PlateScanner.ScanRange then
                        local plate = GetVehicleNumberPlateText(targetVeh)
                        if plate and plate ~= '' and not scannedPlates[plate] then
                            TriggerServerEvent('plate:server:scan', plate)
                        end
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('plate:client:scanResult', function(plate, flags, owner)
    scannedPlates[plate] = true
    local hasFlag = false
    for _, flag in ipairs(flags or {}) do
        if flag ~= 'Clean' then hasFlag = true; break end
    end
    if Config.PlateScanner.UI.SoundEnabled then
        PlaySound(-1, hasFlag and Config.PlateScanner.UI.SoundMatch or Config.PlateScanner.UI.SoundMatch, Config.PlateScanner.UI.SoundDict, false, 0, true)
    end
    local color = hasFlag and Config.PlateScanner.UI.ColorAlert or Config.PlateScanner.UI.ColorClean
    local msg = 'PLATE: ' .. plate .. '\nOWNER: ' .. (owner or 'UNKNOWN')
    for _, flag in ipairs(flags or {}) do
        local fData = Config.PlateScanner.Flags[flag]
        if fData then
            msg = msg .. '\n' .. fData.label
            if Config.PlateScanner.UI.ShowOverlay then
                SetTextFont(4); SetTextScale(0.6, 0.6)
                SetTextColour(color.r, color.g, color.b, 255)
                SetTextCentre(true); SetTextEntry('STRING')
                AddTextComponentString(fData.label)
                DrawText(0.5, 0.2)
            end
        end
    end
    Wrappers.Notify(msg, hasFlag and 'warning' or 'success')
    SetTimeout(Config.PlateScanner.UI.OverlayDuration, function() scannedPlates[plate] = nil end)
end)
