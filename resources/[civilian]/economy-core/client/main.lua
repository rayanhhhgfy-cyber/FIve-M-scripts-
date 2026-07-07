RegisterNetEvent('economy:client:fuelPriceUpdate', function(price)
  Wrappers.Notify('Fuel price updated: $' .. price .. '/gal', 'info')
end)

RegisterNetEvent('economy:client:gridMaintenanceComplete', function()
  Wrappers.Notify('Grid maintenance complete', 'success')
end)

RegisterNetEvent('economy:client:openVaultMenu', function()
  QBox.Functions.TriggerCallback('economy:server:getVaultBoxes', function(boxes)
    if #boxes == 0 then
      Wrappers.Notify('No vault boxes rented', 'info')
      return
    end
    local items = {}
    for _, box in ipairs(boxes) do
      table.insert(items, {
        title = 'Vault Box #' .. box.id,
        description = 'Expires: ' .. box.expires_at,
        icon = 'fas fa-box',
        onSelect = function()
          Wrappers.Notify('Vault access granted', 'success')
        end
      })
    end
    Wrappers.ContextMenu({ id = 'vault_boxes', title = 'Your Vault Boxes', menuItems = items })
  end)
end)
