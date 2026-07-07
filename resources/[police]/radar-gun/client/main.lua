local radarActive = false

function useRadarGun()
    local ped = cache.ped
    if radarActive then
        radarActive = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        ClearTimecycleModifier()
        exports.ox_lib:notify({ type = 'info', description = 'Radar gun stowed' })
        return
    end
    radarActive = true
    local cam = lib.requestAnimDict('cellphone@')
    TaskPlayAnim(ped, 'cellphone@', 'cellphone_text_read_base', 8.0, 8.0, -1, 49, 0, false, false, false)
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    SetTimecycleModifier('scanline_cam_achievement')
    SetTimecycleModifierStrength(0.3)
    CreateThread(function()
        while radarActive do
            Wait(100)
            HideHudComponentThisFrame(14)
            HideHudComponentThisFrame(15)
            local veh = lib.getClosestVehicle(GetEntityCoords(ped), 50.0, true)
            local speed = 0
            local plate = ''
            local model = ''
            if veh then
                speed = math.floor(GetEntitySpeed(veh) * 3.6)
                plate = GetVehicleNumberPlateText(veh)
                model = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(veh)))
                if not model or model == 'NULL' then model = 'Unknown' end
            end
            SendNUIMessage({ action = 'update', speed = speed, plate = plate, model = model })
        end
    end)
end

RegisterNUICallback('radarClose', function(_, cb)
    radarActive = false
    SetNuiFocus(false, false)
    ClearTimecycleModifier()
    cb({})
end)

exports('useRadarGun', useRadarGun)
