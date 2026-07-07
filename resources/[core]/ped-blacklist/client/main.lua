local function CheckPlayerModel()
    local ped = PlayerPedId()
    if not ped or ped == 0 then return end
    local model = GetEntityModel(ped)
    TriggerServerEvent('ped-blacklist:server:checkModel', model)
end

Citizen.CreateThread(function()
    Citizen.Wait(10000)
    if Config.Blacklist.enabled then
        CheckPlayerModel()
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(Config.Blacklist.checkInterval)
                CheckPlayerModel()
            end
        end)
    end
end)

local originalSpawnVehicle = SpawnVehicle
if originalSpawnVehicle then
    SpawnVehicle = function(vehicleName, coords, heading, isNetwork, cb)
        TriggerServerEvent('ped-blacklist:server:checkVehicleSpawn', vehicleName)
        return originalSpawnVehicle(vehicleName, coords, heading, isNetwork, cb)
    end
end

exports('CheckPedModel', CheckPlayerModel)
