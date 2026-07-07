local inTrunk = false
local isKidnapped = false
local isKidnapping = false
local cam = nil
local disabledTrunk = {
    [`penetrator`] = 'penetrator',
    [`vacca`] = 'vacca',
    [`monroe`] = 'monroe',
    [`turismor`] = 'turismor',
    [`osiris`] = 'osiris',
    [`comet`] = 'comet',
    [`ardent`] = 'ardent',
    [`jester`] = 'jester',
    [`nero`] = 'nero',
    [`nero2`] = 'nero2',
    [`vagner`] = 'vagner',
    [`infernus`] = 'infernus',
    [`zentorno`] = 'zentorno',
    [`comet2`] = 'comet2',
    [`comet3`] = 'comet3',
    [`comet4`] = 'comet4',
    [`bullet`] = 'bullet',
}

local function DrawText3Ds(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x, y, z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function getNearestVeh()
    local pos = GetEntityCoords(PlayerPedId())
    local entityWorld = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 20.0, 0.0)

    local rayHandle = CastRayPointToPoint(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, 10, PlayerPedId(), 0)
    local _, _, _, _, vehicleHandle = GetRaycastResult(rayHandle)
    return vehicleHandle
end

local function TrunkCam(bool)
    local vehicle = GetEntityAttachedTo(PlayerPedId())
    local drawPos = GetOffsetFromEntityInWorldCoords(vehicle, 0, -5.5, 0)
    local vehHeading = GetEntityHeading(vehicle)
    if bool then
        RenderScriptCams(false, false, 0, 1, 0)
        DestroyCam(cam, false)
        if not DoesCamExist(cam) then
            cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
            SetCamActive(cam, true)
            SetCamCoord(cam, drawPos.x, drawPos.y, drawPos.z + 2)
            SetCamRot(cam, -2.5, 0.0, vehHeading, 0.0)
            RenderScriptCams(true, false, 0, true, true)
        end
    else
        RenderScriptCams(false, false, 0, 1, 0)
        DestroyCam(cam, false)
        cam = nil
    end
end

RegisterNetEvent('qb-kidnapping:client:SetKidnapping', function(bool)
    isKidnapping = bool
end)

RegisterNetEvent('qb-trunk:client:KidnapTrunk', function()
    local closestPlayers = QBox.Functions.GetPlayersFromCoords()
    local closestPlayer = -1
    local closestDistance = -1
    local coords = GetEntityCoords(PlayerPedId())
    local player = PlayerId()
    for i = 1, #closestPlayers, 1 do
        if closestPlayers[i] ~= player then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local distance = #(pos - coords)
            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = closestPlayers[i]
                closestDistance = distance
            end
        end
    end
    if closestPlayer ~= -1 and closestDistance < 2 then
        if isKidnapping then
            local closestVehicle = getNearestVeh()
            if closestVehicle ~= 0 then
                TriggerEvent('police:client:KidnapPlayer')
                TriggerServerEvent('police:server:CuffPlayer', GetPlayerServerId(closestPlayer), false)
                Wait(50)
                TriggerServerEvent('qb-trunk:server:KidnapTrunk', GetPlayerServerId(closestPlayer), closestVehicle)
            end
        else
            exports.ox_lib:notify({ type = 'error', description = 'You did not kidnap this person' })
        end
    end
end)

RegisterNetEvent('qb-trunk:client:KidnapGetIn', function(veh)
    local ped = PlayerPedId()
    local closestVehicle = veh
    local vehClass = GetVehicleClass(closestVehicle)
    local plate = GetVehicleNumberPlateText(closestVehicle)
    if Config.TrunkClasses[vehClass].allowed then
        local isBusy = lib.callback.await('qb-trunk:server:getTrunkBusy', false, plate)
        if not disabledTrunk[GetEntityModel(closestVehicle)] then
            if not inTrunk then
                if not isBusy then
                    if not isKidnapped then
                        if GetVehicleDoorAngleRatio(closestVehicle, 5) > 0 then
                            local offset = {
                                x = Config.TrunkClasses[vehClass].x,
                                y = Config.TrunkClasses[vehClass].y,
                                z = Config.TrunkClasses[vehClass].z,
                            }
                            RequestAnimDict('fin_ext_p1-7')
                            while not HasAnimDictLoaded('fin_ext_p1-7') do
                                Wait(0)
                            end
                            TaskPlayAnim(ped, 'fin_ext_p1-7', 'cs_devin_dual-7', 8.0, 8.0, -1, 1, 999.0, 0, 0, 0)
                            AttachEntityToEntity(ped, closestVehicle, 0, offset.x, offset.y, offset.z, 0, 0, 40.0, 1, 1, 1, 1, 1, 1)
                            TriggerServerEvent('qb-trunk:server:setTrunkBusy', plate, true)
                            inTrunk = true
                            Wait(500)
                            SetVehicleDoorShut(closestVehicle, 5, false)
                            exports.ox_lib:notify({ type = 'success', description = "You're in the trunk" })
                            TrunkCam(true)
                            isKidnapped = true
                        else
                            exports.ox_lib:notify({ type = 'error', description = 'The trunk is closed' })
                        end
                    else
                        local vehicle = GetEntityAttachedTo(ped)
                        plate = GetVehicleNumberPlateText(vehicle)
                        if GetVehicleDoorAngleRatio(vehicle, 5) > 0 then
                            local vehCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0, -5.0, 0)
                            DetachEntity(ped, true, true)
                            ClearPedTasks(ped)
                            inTrunk = false
                            TriggerServerEvent('qb-trunk:server:setTrunkBusy', plate, false)
                            SetEntityCoords(ped, vehCoords.x, vehCoords.y, vehCoords.z)
                            SetEntityCollision(PlayerPedId(), true, true)
                            TrunkCam(false)
                        else
                            exports.ox_lib:notify({ type = 'error', description = 'The trunk is closed' })
                        end
                    end
                else
                    exports.ox_lib:notify({ type = 'error', description = 'Someone is already in the trunk' })
                end
            else
                exports.ox_lib:notify({ type = 'error', description = "You're already in the trunk" })
            end
        else
            exports.ox_lib:notify({ type = 'error', description = "You can't get in this trunk" })
        end
    else
        exports.ox_lib:notify({ type = 'error', description = "You can't get in this trunk" })
    end
end)

RegisterNetEvent('qb-trunk:client:GetIn', function()
    local ped = PlayerPedId()
    local closestVehicle = getNearestVeh()
    if closestVehicle ~= 0 then
        local vehClass = GetVehicleClass(closestVehicle)
        local plate = GetVehicleNumberPlateText(closestVehicle)
        if Config.TrunkClasses[vehClass].allowed then
            local isBusy = lib.callback.await('qb-trunk:server:getTrunkBusy', false, plate)
            if not disabledTrunk[GetEntityModel(closestVehicle)] then
                if not inTrunk then
                    if not isBusy then
                        if GetVehicleDoorAngleRatio(closestVehicle, 5) > 0 then
                            local offset = {
                                x = Config.TrunkClasses[vehClass].x,
                                y = Config.TrunkClasses[vehClass].y,
                                z = Config.TrunkClasses[vehClass].z,
                            }
                            RequestAnimDict('fin_ext_p1-7')
                            while not HasAnimDictLoaded('fin_ext_p1-7') do
                                Wait(0)
                            end
                            TaskPlayAnim(ped, 'fin_ext_p1-7', 'cs_devin_dual-7', 8.0, 8.0, -1, 1, 999.0, 0, 0, 0)
                            AttachEntityToEntity(ped, closestVehicle, 0, offset.x, offset.y, offset.z, 0, 0, 40.0, 1, 1, 1, 1, 1, 1)
                            TriggerServerEvent('qb-trunk:server:setTrunkBusy', plate, true)
                            inTrunk = true
                            Wait(500)
                            SetVehicleDoorShut(closestVehicle, 5, false)
                            exports.ox_lib:notify({ type = 'success', description = "You're in the trunk" })
                            TrunkCam(true)
                        else
                            exports.ox_lib:notify({ type = 'error', description = 'The trunk is closed' })
                        end
                    else
                        exports.ox_lib:notify({ type = 'error', description = 'Someone is already in the trunk' })
                    end
                else
                    exports.ox_lib:notify({ type = 'error', description = "You're already in the trunk" })
                end
            else
                exports.ox_lib:notify({ type = 'error', description = "You can't get in this trunk" })
            end
        else
            exports.ox_lib:notify({ type = 'error', description = "You can't get in this trunk" })
        end
    else
        exports.ox_lib:notify({ type = 'error', description = 'No vehicle found' })
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local vehicle = GetEntityAttachedTo(PlayerPedId())
        local drawPos = GetOffsetFromEntityInWorldCoords(vehicle, 0, -5.5, 0)
        local vehHeading = GetEntityHeading(vehicle)
        if cam then
            sleep = 0
            SetCamRot(cam, -2.5, 0.0, vehHeading, 0.0)
            SetCamCoord(cam, drawPos.x, drawPos.y, drawPos.z + 2)
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if inTrunk then
            if not isKidnapped then
                local ped = PlayerPedId()
                local vehicle = GetEntityAttachedTo(ped)
                local drawPos = GetOffsetFromEntityInWorldCoords(vehicle, 0, -2.5, 0)
                local plate = GetVehicleNumberPlateText(vehicle)
                if DoesEntityExist(vehicle) then
                    sleep = 0
                    DrawText3Ds(drawPos.x, drawPos.y, drawPos.z + 0.75, '[E] Get out of the trunk')
                    if IsControlJustPressed(0, 38) then
                        if GetVehicleDoorAngleRatio(vehicle, 5) > 0 then
                            local vehCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0, -5.0, 0)
                            DetachEntity(ped, true, true)
                            ClearPedTasks(ped)
                            inTrunk = false
                            TriggerServerEvent('qb-trunk:server:setTrunkBusy', plate, false)
                            SetEntityCoords(ped, vehCoords.x, vehCoords.y, vehCoords.z)
                            SetEntityCollision(ped, true, true)
                            TrunkCam(false)
                        else
                            exports.ox_lib:notify({ type = 'error', description = 'The trunk is closed' })
                        end
                        Wait(100)
                    end
                    if GetVehicleDoorAngleRatio(vehicle, 5) > 0 then
                        DrawText3Ds(drawPos.x, drawPos.y, drawPos.z + 0.5, '[G] Close the trunk')
                        if IsControlJustPressed(0, 47) then
                            if not IsVehicleSeatFree(vehicle, -1) then
                                TriggerServerEvent('qb-radialmenu:trunk:server:Door', false, plate, 5)
                            else
                                SetVehicleDoorShut(vehicle, 5, false)
                            end
                            Wait(100)
                        end
                    else
                        DrawText3Ds(drawPos.x, drawPos.y, drawPos.z + 0.5, '[G] Open the trunk')
                        if IsControlJustPressed(0, 47) then
                            if not IsVehicleSeatFree(vehicle, -1) then
                                TriggerServerEvent('qb-radialmenu:trunk:server:Door', true, plate, 5)
                            else
                                SetVehicleDoorOpen(vehicle, 5, false, false)
                            end
                            Wait(100)
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)
