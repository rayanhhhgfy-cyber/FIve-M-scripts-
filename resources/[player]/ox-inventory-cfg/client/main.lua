AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[ox-inventory-cfg] Inventory config loaded. Weapon serial tracking active.^7')
end)

exports('GenerateSerial', function() return lib.callback.await('ox-inventory-cfg:server:generateSerial', false) end)
