local laptopOpen = false

RegisterCommand('+gangLaptop', function()
  if laptopOpen then return end
  local playerData = exports['qbx_core']:GetPlayer(PlayerId())
  if not playerData or not playerData.PlayerData then return end
  local gang = playerData.PlayerData.gang
  if not gang or gang.name == 'none' then
    Wrappers.Notify('Not in a gang', 'error')
    return
  end
  laptopOpen = true
  Wrappers.ContextMenu({
    id = 'gang_laptop_menu',
    title = 'Gang Operations',
    menuItems = {
      { title = 'Member Roster', icon = 'fas fa-users', onSelect = function() TriggerEvent('gang:openRoster') end },
      { title = 'Recruit Nearby', icon = 'fas fa-user-plus', onSelect = function() TriggerEvent('gang:recruitNearby') end },
    }
  })
end, false)

RegisterKeyMapping('+gangLaptop', 'Open Gang Laptop', 'keyboard', Config.GangLaptop.toggleKey)

RegisterNetEvent('gang:openRoster', function()
  QBox.Functions.TriggerCallback('gang:server:getRoster', function(roster)
    local items = {}
    for _, member in ipairs(roster) do
      local status = member.online and 'ONLINE' or 'OFFLINE'
      table.insert(items, {
        title = member.name .. ' [' .. status .. ']',
        description = member.rankLabel .. ' | CID: ' .. member.citizenid,
        icon = member.online and 'fas fa-user-check' or 'fas fa-user-slash',
        onSelect = function()
          Wrappers.ContextMenu({
            id = 'gang_member_action',
            title = member.name,
            menuItems = {
              { title = 'Set Recruit', icon = 'fas fa-angle-double-down', onSelect = function() TriggerServerEvent('gang:server:setRank', member.citizenid, 1) end },
              { title = 'Set Enforcer', icon = 'fas fa-shield-alt', onSelect = function() TriggerServerEvent('gang:server:setRank', member.citizenid, 2) end },
              { title = 'Set Underboss', icon = 'fas fa-crown', onSelect = function() TriggerServerEvent('gang:server:setRank', member.citizenid, 3) end },
              { title = 'Exile', icon = 'fas fa-user-slash', onSelect = function() TriggerServerEvent('gang:server:exile', member.citizenid) end },
            }
          })
        end
      })
    end
    Wrappers.ContextMenu({ id = 'gang_roster', title = 'Gang Roster', menuItems = items })
  end)
end)

RegisterNetEvent('gang:recruitNearby', function()
  QBox.Functions.TriggerCallback('gang:server:nearbyPlayers', function(nearby)
    if #nearby == 0 then
      Wrappers.Notify('No players nearby', 'info')
      return
    end
    local items = {}
    for _, p in ipairs(nearby) do
      table.insert(items, {
        title = 'Recruit ' .. p.name,
        description = 'CID: ' .. p.cid,
        icon = 'fas fa-user-plus',
        onSelect = function()
          TriggerServerEvent('gang:server:recruit', p.src)
        end
      })
    end
    Wrappers.ContextMenu({ id = 'gang_recruit', title = 'Recruit Nearby', menuItems = items })
  end)
end)
