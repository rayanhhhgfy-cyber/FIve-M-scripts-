local laptopOpen = false

RegisterCommand('+mechanicLaptop', function()
  if laptopOpen then return end
  local playerData = exports['qbx_core']:GetPlayer(PlayerId())
  if not playerData or not playerData.PlayerData then return end
  if playerData.PlayerData.job.name ~= Config.MechanicLaptop.allowedJob then
    Wrappers.Notify('Access denied', 'error')
    return
  end
  laptopOpen = true
  Wrappers.ContextMenu({
    id = 'mechanic_laptop_menu',
    title = 'Mechanic Shop Laptop',
    menuItems = {
      { title = 'Staff Roster', icon = 'fas fa-users', onSelect = function() TriggerEvent('mechanic:openRoster') end },
      { title = 'Send Invoice', icon = 'fas fa-file-invoice-dollar', onSelect = function() TriggerEvent('mechanic:openInvoice') end },
      { title = 'Order Parts', icon = 'fas fa-box', onSelect = function() TriggerEvent('mechanic:openPartsOrder') end },
    }
  })
end, false)

RegisterKeyMapping('+mechanicLaptop', 'Open Mechanic Laptop', 'keyboard', Config.MechanicLaptop.toggleKey)

RegisterNetEvent('mechanic:openRoster', function()
  QBox.Functions.TriggerCallback('mechanic:server:getRoster', function(roster)
    local items = {}
    for _, member in ipairs(roster) do
      local status = member.online and 'ONLINE' or 'OFFLINE'
      table.insert(items, {
        title = member.name .. ' [' .. status .. ']',
        description = member.rankLabel .. ' | CID: ' .. member.citizenid,
        icon = member.online and 'fas fa-user-check' or 'fas fa-user-slash',
        onSelect = function()
          Wrappers.ContextMenu({
            id = 'mechanic_roster_action',
            title = member.name,
            menuItems = {
              { title = 'Promote', icon = 'fas fa-arrow-up', onSelect = function() TriggerServerEvent('mechanic:server:promote', member.citizenid) end },
              { title = 'Demote', icon = 'fas fa-arrow-down', onSelect = function() TriggerServerEvent('mechanic:server:demote', member.citizenid) end },
              { title = 'Fire', icon = 'fas fa-user-minus', onSelect = function() TriggerServerEvent('mechanic:server:fire', member.citizenid) end },
            }
          })
        end
      })
    end
    table.insert(items, {
      title = 'Hire Technician',
      icon = 'fas fa-user-plus',
      onSelect = function()
        local input = Wrappers.InputDialog({ title = 'Hire Technician', options = { { type = 'input', label = 'Citizen ID', required = true } } })
        if input then TriggerServerEvent('mechanic:server:hire', input[1]) end
      end
    })
    Wrappers.ContextMenu({ id = 'mechanic_roster', title = 'Staff Roster', menuItems = items })
  end)
end)

RegisterNetEvent('mechanic:openInvoice', function()
  QBox.Functions.TriggerCallback('mechanic:server:nearbyPlayers', function(nearby)
    if #nearby == 0 then
      Wrappers.Notify('No players nearby', 'info')
      return
    end
    local items = {}
    for _, p in ipairs(nearby) do
      table.insert(items, {
        title = 'Bill ' .. p.name,
        description = 'CID: ' .. p.cid,
        icon = 'fas fa-dollar-sign',
        onSelect = function()
          local input = Wrappers.InputDialog({
            title = 'Create Invoice',
            options = {
              { type = 'input', label = 'Services (comma separated)', placeholder = 'Oil change, Brake pads', required = true },
              { type = 'number', label = 'Total ($)', placeholder = '500', required = true },
            }
          })
          if input then
            local services = {}
            for _, s in ipairs(string.split(input[1], ',')) do
              table.insert(services, { label = s:gsub('^%s+', ''):gsub('%s+$', ''), price = 0 })
            end
            TriggerServerEvent('mechanic:server:sendInvoice', p.src, services, tonumber(input[2]))
          end
        end
      })
    end
    Wrappers.ContextMenu({ id = 'mechanic_invoice', title = 'Select Customer', menuItems = items })
  end)
end)

RegisterNetEvent('mechanic:openPartsOrder', function()
  QBox.Functions.TriggerCallback('mechanic:server:getPartsSupply', function(parts)
    local items = {}
    for _, part in ipairs(parts) do
      table.insert(items, {
        title = part.label,
        description = '$' .. part.cost .. ' | Stock: ' .. part.stock,
        icon = 'fas fa-tools',
        onSelect = function()
          local input = Wrappers.InputDialog({
            title = 'Order ' .. part.label,
            options = { { type = 'number', label = 'Quantity', placeholder = '1', required = true } }
          })
          if input then
            TriggerServerEvent('mechanic:server:orderParts', part.item, tonumber(input[1]))
          end
        end
      })
    end
    Wrappers.ContextMenu({ id = 'mechanic_parts', title = 'Order Parts', menuItems = items })
  end)
end)

RegisterNetEvent('mechanic:client:receiveInvoice', function(data)
  Wrappers.AlertDialog({
    title = 'Invoice from ' .. data.mechanicName,
    content = 'Items: ' .. json.encode(data.items) .. '\nTotal: $' .. data.total,
    buttons = {
      { label = 'Pay', action = function()
        TriggerServerEvent('mechanic:server:payInvoice', data)
      end},
      { label = 'Decline', action = function() end}
    }
  })
end)
