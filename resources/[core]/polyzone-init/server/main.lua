AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[polyzone-init] Server PolyZone bridge ready.^7')
end)
