local QBCore = exports['qbx_core']:GetCoreObject()

local function flashEffect(cam)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if not veh or veh == 0 then return end
    local pos = GetEntityCoords(veh)
    local camPos = cam.coords
    local heading = cam.heading
    SetArtificialLightsState(true)
    DoScreenFadeOut(100)
    Wait(100)
    DoScreenFadeIn(200)
    SetArtificialLightsState(false)
    Wrappers.Notify(Locale('speed_camera.flash'), 'warning')
end

RegisterNetEvent('speed_camera:client:flash', function(cam)
    flashEffect(cam)
end)

CreateThread(function()
    while true do
        Wait(200)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh and veh ~= 0 then
            local speed = GetEntitySpeed(veh) * 3.6
            for _, cam in ipairs(Config.SpeedCamera.cameras) do
                local dist = #(GetEntityCoords(veh) - cam.coords)
                if dist < Config.SpeedCamera.flashRange then
                    Wrappers.TextUI(Locale('speed_camera.speed') .. ': ' .. math.floor(speed) .. ' km/h | ' .. Locale('speed_camera.limit') .. ': ' .. cam.limit .. ' km/h')
                    break
                end
            end
        else
            Wait(500)
        end
    end
end)
