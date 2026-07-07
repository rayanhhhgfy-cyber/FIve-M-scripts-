local lastHealth = 0
local lastCoords = nil

CreateThread(function()
    while true do
        Wait(Config.Anticheat.detectionInterval)
        local ped = PlayerPedId()
        local health = GetEntityHealth(ped)
        local coords = GetEntityCoords(ped)

        if lastHealth > 0 and health > lastHealth + 50 then
            TriggerServerEvent('anticheat:report', 'Suspicious health increase')
        end
        if lastCoords then
            local dist = #(coords - lastCoords)
            if dist > 250.0 then
                TriggerServerEvent('anticheat:report', 'Suspicious teleport')
            end
        end
        lastHealth = health
        lastCoords = coords
    end
end)
