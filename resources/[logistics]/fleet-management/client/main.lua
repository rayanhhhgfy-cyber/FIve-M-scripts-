RegisterNetEvent('fleet:client:openVehicleLot', function()
  QBox.Functions.TriggerCallback('fleet:server:getListings', function(listings)
    if #listings == 0 then
      Wrappers.Notify('No vehicles for sale', 'info')
      return
    end
    local items = {}
    for _, l in ipairs(listings) do
      table.insert(items, {
        title = l.plate,
        description = 'Price: $' .. l.price .. ' | Seller: ' .. l.citizenid,
        icon = 'fas fa-car',
        onSelect = function()
          TriggerServerEvent('fleet:server:buyVehicle', l.id)
        end
      })
    end
    Wrappers.ContextMenu({ id = 'vehicle_lot', title = 'Used Vehicle Lot', menuItems = items })
  end)
end)
