local QBCore = exports['qbx_core']:GetCoreObject()

RegisterNetEvent('mechanics:client:doRepair', function(vehicleNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not vehicle or vehicle == 0 then return end
    local success = Wrappers.ProgressBar({
        duration = Config.Mechanics.repairTime,
        label = Locale('mechanics.repairing'),
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, mouse = false, combat = true },
        anim = { dict = 'mini@repair', clip = 'fixing_a_player', flag = 16 },
    })
    if success then
        TriggerServerEvent('mechanics:completeRepair', vehicleNetId)
    end
end)

CreateThread(function()
    for i, location in ipairs(Config.Mechanics.locations) do
        local ped = exports['ox_target']:addBoxZone({
            coords = location.coords,
            size = vector3(2.0, 2.0, 2.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'mechanic_repair_' .. i,
                    label = Locale('mechanics.repair'),
                    icon = 'fas fa-wrench',
                    job = Config.Mechanics.requiredJob,
                    onSelect = function()
                        local ped = PlayerPedId()
                        local vehicle = Wrappers.GetClosestVehicle(GetEntityCoords(ped), 5.0)
                        if not vehicle then return Wrappers.Notify(Locale('mechanics.no_vehicle'), 'error') end
                        TriggerServerEvent('mechanics:startRepair', NetworkGetNetworkIdFromEntity(vehicle))
                    end,
                },
                {
                    name = 'mechanic_bill_' .. i,
                    label = Locale('mechanics.bill'),
                    icon = 'fas fa-dollar-sign',
                    job = Config.Mechanics.requiredJob,
                    onSelect = function()
                        local closest, dist = Wrappers.GetClosestPlayer(GetEntityCoords(PlayerPedId()), 5.0)
                        if not closest then return Wrappers.Notify(Locale('mechanics.no_vehicle'), 'error') end
                        local input = Wrappers.InputDialog({
                            title = Locale('mechanics.bill'),
                            options = {
                                { type = 'number', label = Locale('mechanics.bill_amount'), placeholder = '0', required = true },
                            },
                        })
                        if input then
                            TriggerServerEvent('mechanics:bill', GetPlayerServerId(closest), tonumber(input[1]))
                        end
                    end,
                },
            },
        })
    end
end)
