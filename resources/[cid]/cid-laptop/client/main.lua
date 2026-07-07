local laptopOpen = false

RegisterCommand('+cidLaptop', function()
  if laptopOpen then return end
  local playerData = exports['qbx_core']:GetPlayer(PlayerId())
  if not playerData then return end
  if playerData.PlayerData.job.name ~= Config.CIDLaptop.allowedJob then
    Wrappers.Notify('Access denied', 'error')
    return
  end
  laptopOpen = true
  Wrappers.ContextMenu({
    id = 'cid_laptop_menu',
    title = 'CID Operations Laptop',
    menuItems = {
      { title = 'Agent Roster', icon = 'fas fa-user-secret', onSelect = function() TriggerEvent('cid:openRoster') end },
      { title = 'Flagged Transactions', icon = 'fas fa-money-check-alt', onSelect = function() TriggerEvent('cid:viewFlagged') end },
      { title = 'Hire Agent', icon = 'fas fa-user-plus', onSelect = function() TriggerEvent('cid:hireAgent') end },
      { title = 'Real-Time Crime Center', icon = 'fas fa-map-marked-alt', onSelect = function() TriggerEvent('lspd:openCrimeCenter') end },
    }
  })
end, false)

RegisterKeyMapping('+cidLaptop', 'Open CID Laptop', 'keyboard', Config.CIDLaptop.toggleKey)

RegisterNetEvent('cid:openRoster', function()
  QBox.Functions.TriggerCallback('cid:server:getRoster', function(roster)
    local items = {}
    for _, member in ipairs(roster) do
      local status = member.online and 'ONLINE' or 'OFFLINE'
      table.insert(items, {
        title = member.name .. ' [' .. status .. ']',
        description = 'Grade: ' .. member.grade .. ' | CID: ' .. member.citizenid,
        icon = member.online and 'fas fa-user-check' or 'fas fa-user-slash',
        onSelect = function()
          Wrappers.ContextMenu({
            id = 'cid_roster_action',
            title = member.name,
            menuItems = {
              { title = 'Promote', icon = 'fas fa-arrow-up', onSelect = function() TriggerServerEvent('cid:server:promote', member.citizenid) end },
              { title = 'Demote', icon = 'fas fa-arrow-down', onSelect = function() TriggerServerEvent('cid:server:demote', member.citizenid) end },
              { title = 'Fire', icon = 'fas fa-user-minus', onSelect = function() TriggerServerEvent('cid:server:fire', member.citizenid) end },
            }
          })
        end
      })
    end
    Wrappers.ContextMenu({ id = 'cid_roster', title = 'Agent Roster', menuItems = items })
  end)
end)

RegisterNetEvent('cid:hireAgent', function()
  local input = Wrappers.InputDialog({ title = 'Hire Agent', options = { { type = 'input', label = 'Citizen ID', required = true } } })
  if input then TriggerServerEvent('cid:server:hire', input[1]) end
end)

RegisterNetEvent('cid:viewFlagged', function()
  QBox.Functions.TriggerCallback('cid:server:getFlaggedTransactions', function(txns)
    if #txns == 0 then Wrappers.Notify('No flagged transactions', 'info') return end
    for _, txn in ipairs(txns) do
      Wrappers.AlertDialog({
        title = 'Flagged Transaction',
        content = 'From: ' .. txn.from_cid .. '\nTo: ' .. txn.to_cid .. '\nAmount: $' .. txn.amount
      })
      TriggerServerEvent('cid:server:reviewTransaction', txn.id)
    end
  end)
end)
