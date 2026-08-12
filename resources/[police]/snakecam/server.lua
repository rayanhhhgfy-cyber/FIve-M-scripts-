exports('snakecam', function(event, item, inventory, slot)
    if event == 'usingItem' then
        local src = inventory.id
        TriggerClientEvent('snakecam:client:use', src)
    end
end)
