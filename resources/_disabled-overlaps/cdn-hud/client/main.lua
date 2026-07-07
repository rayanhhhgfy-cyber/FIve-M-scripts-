local QBCore = exports['qbx_core']:GetCoreObject()
local seatbeltOn = false
local hudVisible = true

local function sendHudUpdate()
    if not hudVisible then
        SendNUIMessage({ type = 'hudUpdate', visible = false })
        return
    end
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local inVehicle = vehicle and vehicle > 0
    local hp = GetEntityHealth(ped) - 100
    local maxHp = GetEntityMaxHealth(ped) - 100
    local armor = GetPedArmour(ped)
    local pos = GetEntityCoords(ped)
    local street1, street2 = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
    local streetName = GetStreetNameFromHashKey(street1)
    local crossingName = street2 > 0 and GetStreetNameFromHashKey(street2) or nil
    local playerData = QBCore.Functions.GetPlayerData()
    local hunger = playerData.metadata.hunger or 100
    local thirst = playerData.metadata.thirst or 100
    local stress = playerData.metadata.stress or 0
    local stamina = playerData.metadata.stamina or 100
    local currentSpeed = 0
    local currentFuel = 100.0
    if inVehicle then
        currentSpeed = math.floor(GetEntitySpeed(vehicle) * 3.6)
        currentFuel = Entity(vehicle).state.fuel or GetVehicleFuelLevel(vehicle) or 100.0
    end
    local streetText = streetName
    if crossingName then streetText = streetText .. ' | ' .. crossingName end
    local hours = GetClockHours()
    local minutes = GetClockMinutes()
    local timeStr = string.format('%02d:%02d', hours, minutes)
    local jobLabel = (playerData.job and playerData.job.label) or ''
    local gradeLabel = (playerData.job and playerData.job.grade and playerData.job.grade.name) or ''
    local cash = (playerData.money and playerData.money.cash) or 0
    local bank = (playerData.money and playerData.money.bank) or 0
    local voiceRange = 0
    pcall(function() voiceRange = exports['pma-voice']:getVoiceProperty('radioRange') or 0 end)
    local voiceStr = voiceRange > 0 and math.floor(voiceRange) .. 'm' or ''
    SendNUIMessage({
        type = 'hudUpdate',
        hp = hp,
        maxHp = maxHp,
        armor = armor,
        hunger = hunger,
        thirst = thirst,
        stress = stress,
        stamina = stamina,
        speed = currentSpeed,
        fuel = currentFuel,
        seatbelt = seatbeltOn,
        street = streetText,
        cash = cash,
        bank = bank,
        job = jobLabel,
        grade = gradeLabel,
        time = timeStr,
        voice = voiceStr,
        inVehicle = inVehicle,
        visible = hudVisible
    })
end

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    if not Config.HUD.enabled then return end
    while true do
        Citizen.Wait(Config.HUD.updateInterval or 250)
        sendHudUpdate()
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.Seatbelt.detectionInterval or 500)
        if Config.Seatbelt.enabled then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle and vehicle > 0 and not seatbeltOn then
                local speed = GetEntitySpeed(vehicle) * 3.6
                if speed > (Config.Seatbelt.ejectSpeedThreshold or 50.0) then
                    if math.random(100) < 15 then
                        SetPedRagdoll(ped, 1200, 1200, 0, 0, 0, 0)
                    end
                end
            end
        end
    end
end)

RegisterCommand('seatbelt', function()
    seatbeltOn = not seatbeltOn
    local msg = seatbeltOn and 'Seatbelt ON' or 'Seatbelt OFF'
    Wrappers.Notify({ type = seatbeltOn and 'success' or 'warning', description = msg })
end, false)

RegisterKeyMapping('seatbelt', 'Toggle Seatbelt', 'keyboard', 'b')

RegisterCommand('togglehud', function()
    hudVisible = not hudVisible
    sendHudUpdate()
    Wrappers.Notify({ type = 'info', description = hudVisible and 'HUD ON' or 'HUD OFF' })
end, false)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[cdn-hud] NUI HUD initialized.^7')
end)

exports('IsSeatbeltOn', function() return seatbeltOn end)
exports('ToggleSeatbelt', function()
    seatbeltOn = not seatbeltOn
    local msg = seatbeltOn and 'Seatbelt ON' or 'Seatbelt OFF'
    Wrappers.Notify({ type = seatbeltOn and 'success' or 'warning', description = msg })
end)