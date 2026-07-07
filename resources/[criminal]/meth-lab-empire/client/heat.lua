local QBox = exports['qbx-core']:GetCoreObject()
local currentHeat = 0
local heatVisible = false
local raidWarningActive = false

RegisterNetEvent('methlab:updateHeat', function(heat, bunkerId)
    currentHeat = heat
    if heat > 0 then
        heatVisible = true
    else
        heatVisible = false
    end
    if heat >= 80 and not raidWarningActive and bunkerId then
        raidWarningActive = true
        TriggerEvent('methlab:raidWarning', bunkerId)
    end
end)

RegisterNetEvent('methlab:raidWarning', function(bunkerId)
    notify('⚠ CRITICAL: Heat level critical! Police raid imminent!', 'error')
    TriggerEvent('chat:addMessage', {
        color = { 255, 0, 0 },
        multiline = true,
        args = { 'METH LAB', 'RAID WARNING! Bunker is at critical heat. Police are en route! Get out now!' }
    })
    local ped = PlayerPedId()
    for i = 1, Config.MethLab.raid.prepTime do
        Citizen.Wait(1000)
        if i % 10 == 0 then
            notify('Raid incoming in ' .. (Config.MethLab.raid.prepTime - i) .. ' seconds', 'error')
        end
    end
    notify('POLICE RAID!', 'error')
    TriggerServerEvent('methlab:executeRaid', bunkerId)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if heatVisible and currentHeat > 0 then
            local level = getHeatLevel()
            DrawHeatMeter(currentHeat, level)
        else
            Citizen.Wait(1000)
        end
    end
end)

function getHeatLevel()
    for i, threshold in ipairs(Config.MethLab.heat.thresholds) do
        if currentHeat <= threshold.max then
            return threshold
        end
    end
    return Config.MethLab.heat.thresholds[#Config.MethLab.heat.thresholds]
end

function DrawHeatMeter(heat, level)
    local width = 0.22
    local height = 0.018
    local x = 0.5 - width / 2
    local y = 0.78

    DrawRect(x, y, width, height, 30, 30, 30, 180)

    local fillWidth = (heat / 100) * width
    local r, g, b = 50, 255, 50
    if heat > 40 then r, g, b = 255, 200, 50 end
    if heat > 60 then r, g, b = 255, 100, 50 end
    if heat > 80 then r, g, b = 255, 50, 50 end

    DrawRect(x + fillWidth / 2, y, fillWidth, height, r, g, b, 220)

    local label = 'HEAT: ' .. math.floor(heat) .. '%'
    SetTextFont(4)
    SetTextProportional(false)
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 255, 255, 200)
    SetTextDropshadow(0, 0, 0, 0, 100)
    SetTextEdge(1, 0, 0, 0, 100)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(label)
    DrawText(x + width / 2, y - 0.025)

    SetTextFont(4)
    SetTextProportional(false)
    SetTextScale(0.25, 0.25)
    SetTextColour(level.color.r or r, level.color.g or g, level.color.b or b, 200)
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(level.label)
    DrawText(x + width / 2, y + 0.015)
end
