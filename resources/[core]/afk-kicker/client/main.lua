local lastPosition = nil
local activityTimer = 0

function ReportActivity()
    TriggerServerEvent('afk-kicker:server:activity')
end

local function CheckMovement()
    local ped = PlayerPedId()
    if not ped or ped == 0 then return end
    local pos = GetEntityCoords(ped)
    if lastPosition then
        local dist = #(pos - lastPosition)
        if dist > Config.AFK.ActivityTriggers.movementThreshold then
            ReportActivity()
        end
    end
    lastPosition = pos
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        if Config.AFK.enabled then
            CheckMovement()
            activityTimer = activityTimer + 5000
            if activityTimer >= 30000 then
                ReportActivity()
                activityTimer = 0
            end
        end
    end
end)

RegisterNetEvent('afk-kicker:client:warning', function(timeRemaining)
    Wrappers.Notify({
        type = 'warning',
        description = string.format(Config.Messages.afk_warning, timeRemaining),
        duration = 10000
    })
    ReportActivity()
end)

Citizen.CreateThread(function()
    Citizen.Wait(10000)
    if Config.AFK.enabled then
        SetTimeout(1000, function()
            ReportActivity()
        end)
        SetTimeout(5000, function()
            ReportActivity()
        end)
    end
end)

exports('ReportActivity', ReportActivity)
