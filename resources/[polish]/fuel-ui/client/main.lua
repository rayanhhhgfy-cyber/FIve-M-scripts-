local QBox = exports['qbx-core']:GetCoreObject()

CreateThread(function()
    while true do
        Wait(Config.FuelUI.checkInterval)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle and vehicle > 0 and Config.FuelUI.enableHUD then
            local fuel = GetVehicleFuelLevel(vehicle)
            local resX, resY = GetActiveScreenResolution()
            local fuelPct = math.floor(fuel)
            DrawRect(0.9, 0.85, 0.05, 0.15, 0, 0, 0, 180)
            SetTextFont(4)
            SetTextScale(0.3, 0.3)
            SetTextColour(255, 255, 255, 255)
            SetTextCentre(true)
            SetTextEntry('STRING')
            AddTextComponentString(Locale('fuel_ui.fuel') .. ': ' .. fuelPct .. '%')
            DrawText(0.9, 0.82)

            if fuelPct < Config.FuelUI.lowFuelThreshold * 100 then
                SetTextFont(4)
                SetTextScale(0.4, 0.4)
                SetTextColour(255, 0, 0, 255)
                SetTextCentre(true)
                SetTextEntry('STRING')
                AddTextComponentString(Locale('fuel_ui.low_fuel'))
                DrawText(0.9, 0.88)
            end
        end
    end
end)

CreateThread(function()
    for _, pump in ipairs(Config.FuelUI.gasStations or {}) do
        exports.ox_target:addBoxZone({
            coords = pump,
            size = vector3(2.0, 2.0, 2.0),
            rotation = 0,
            options = {
                {
                    name = 'fuel_refuel',
                    label = Locale('fuel_ui.refuel'),
                    icon = 'fas fa-gas-pump',
                    onSelect = function()
                        local input = Wrappers.InputDialog({ title = Locale('fuel_ui.refuel'), label = Locale('fuel_ui.liters'), placeholder = 'Amount (1-100)', type = 'number' })
                        if input and tonumber(input) then
                            TriggerServerEvent('fuel:refuel', tonumber(input))
                        end
                    end,
                },
            },
        })
    end
end)
