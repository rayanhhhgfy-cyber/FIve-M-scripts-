AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[seatbelt-system] Server bridge active.^7')
end)

RegisterNetEvent('seatbelt-system:server:ejected', function(damage)
    local source = source
    if not source then return end
    TriggerEvent('player-status:server:addStress', 25)
end)
