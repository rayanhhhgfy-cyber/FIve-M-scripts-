CreateThread(function()
    while true do
        Wait(1000)
        SetVehicleDensityMultiplierThisFrame(0.85)
        SetPedDensityMultiplierThisFrame(0.85)
        SetRandomVehicleDensityMultiplierThisFrame(0.85)
        SetParkedVehicleDensityMultiplierThisFrame(0.85)
        SetScenarioPedDensityMultiplierThisFrame(0.85)
    end
end)
