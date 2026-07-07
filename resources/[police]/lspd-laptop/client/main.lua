local laptopOpen = false
local crimeCenterOpen = false
local crimeBlips = {}

RegisterCommand('+lspdLaptop', function()
  if laptopOpen then return end
  local playerData = exports['qbx_core']:GetPlayer(PlayerId())
  if not playerData or not playerData.PlayerData then return end
  local job = playerData.PlayerData.job
  if job.name ~= Config.LSPDLaptop.allowedJob then
    Wrappers.Notify('Access denied', 'error')
    return
  end
  laptopOpen = true
  Wrappers.ContextMenu({
    id = 'lspd_laptop_menu',
    title = 'LSPD Laptop',
    menuItems = {
      {
        title = 'Roster Management',
        icon = 'fas fa-users',
        onSelect = function()
          TriggerEvent('lspd:openRoster')
        end
      },
      {
        title = 'Background Check',
        icon = 'fas fa-search',
        onSelect = function()
          TriggerEvent('lspd:backgroundCheck')
        end
      },
      {
        title = 'Active Warrants',
        icon = 'fas fa-gavel',
        onSelect = function()
          TriggerEvent('lspd:viewWarrants')
        end
      },
      {
        title = 'Real-Time Crime Center',
        icon = 'fas fa-map-marked-alt',
        onSelect = function()
          TriggerEvent('lspd:openCrimeCenter')
        end
      },
      {
        title = 'K-9 Ops Center',
        icon = 'fas fa-dog',
        onSelect = function()
          TriggerEvent('lspd:openK9Ops')
        end
      },
    }
  })
end, false)

RegisterKeyMapping('+lspdLaptop', 'Open LSPD Laptop', 'keyboard', Config.LSPDLaptop.toggleKey)

--- ROSTER (existing)
RegisterNetEvent('lspd:openRoster', function()
  QBox.Functions.TriggerCallback('lspd:server:getRoster', function(roster)
    local menuItems = {}
    for _, member in ipairs(roster) do
      local status = member.online and 'ONLINE' or 'OFFLINE'
      table.insert(menuItems, {
        title = member.name .. ' [' .. status .. ']',
        description = 'Grade: ' .. member.grade .. ' | CID: ' .. member.citizenid,
        icon = member.online and 'fas fa-user-check' or 'fas fa-user-slash',
        onSelect = function()
          TriggerEvent('lspd:rosterAction', member)
        end
      })
    end
    table.insert(menuItems, {
      title = 'Hire New Officer',
      icon = 'fas fa-user-plus',
      onSelect = function()
        TriggerEvent('lspd:hirePlayer')
      end
    })
    Wrappers.ContextMenu({ id = 'lspd_roster', title = 'Roster', menuItems = menuItems })
  end)
end)

RegisterNetEvent('lspd:rosterAction', function(member)
  Wrappers.ContextMenu({
    id = 'lspd_roster_action',
    title = member.name,
    menuItems = {
      {
        title = 'Promote',
        icon = 'fas fa-arrow-up',
        onSelect = function()
          TriggerServerEvent('lspd:server:promote', member.citizenid)
        end
      },
      {
        title = 'Demote',
        icon = 'fas fa-arrow-down',
        onSelect = function()
          TriggerServerEvent('lspd:server:demote', member.citizenid)
        end
      },
      {
        title = 'Fire',
        icon = 'fas fa-user-minus',
        onSelect = function()
          TriggerServerEvent('lspd:server:fire', member.citizenid)
        end
      }
    }
  })
end)

RegisterNetEvent('lspd:hirePlayer', function()
  local input = Wrappers.InputDialog({
    title = 'Hire Officer',
    options = {
      { type = 'input', label = 'Citizen ID (CID)', placeholder = '10001', required = true }
    }
  })
  if input then
    TriggerServerEvent('lspd:server:hire', input[1])
  end
end)

RegisterNetEvent('lspd:backgroundCheck', function()
  local input = Wrappers.InputDialog({
    title = 'Background Check',
    options = {
      { type = 'input', label = 'Citizen ID', placeholder = '10001', required = true }
    }
  })
  if input then
    QBox.Functions.TriggerCallback('lspd:server:backgroundCheck', function(result)
    end, input[1])
  end
end)

RegisterNetEvent('lspd:client:backgroundCheckResult', function(data)
  local lines = { 'Name: ' .. data.name, 'CID: ' .. data.citizenid, '' }
  if #data.records == 0 then
    table.insert(lines, 'No criminal records found.')
  else
    table.insert(lines, '=== Criminal Records ===')
    for _, record in ipairs(data.records) do
      table.insert(lines, '- ' .. record.offense .. ' (Fine: $' .. (record.fine or 0) .. ')')
    end
  end
  Wrappers.AlertDialog({
    title = 'Background Check',
    content = table.concat(lines, '\n')
  })
end)

RegisterNetEvent('lspd:viewWarrants', function()
  QBox.Functions.TriggerCallback('lspd:server:getActiveWarrants', function(warrants)
    if #warrants == 0 then
      Wrappers.Notify('No active warrants', 'info')
      return
    end
    for _, w in ipairs(warrants) do
      Wrappers.Notify('Warrant: ' .. w.citizenid .. ' - ' .. w.charges, 'warning')
    end
  end)
end)

--- === CRIME CENTER ===

local function clearCrimeBlips()
  for _, blip in ipairs(crimeBlips) do
    if DoesBlipExist(blip) then RemoveBlip(blip) end
  end
  crimeBlips = {}
end

local function addCrimeBlip(coords, sprite, color, scale, label)
  local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
  SetBlipSprite(blip, sprite)
  SetBlipColour(blip, color)
  SetBlipScale(blip, scale or 0.8)
  SetBlipAsShortRange(blip, false)
  BeginTextCommandSetBlipName('STRING')
  AddTextComponentSubstringPlayerName(label or '')
  EndTextCommandSetBlipName(blip)
  table.insert(crimeBlips, blip)
  return blip
end

local function refreshCrimeCenterDashboard(dashboard)
  if not crimeCenterOpen then return end
  clearCrimeBlips()

  if dashboard then
    for _, officer in pairs(dashboard.officers or {}) do
      addCrimeBlip(officer.coords, 1, Config.LSPDLaptop.crimeCenter.blipColors.officer, 0.7, officer.name .. ' [' .. officer.job .. ']')
    end
    for _, call in ipairs(dashboard.calls or {}) do
      addCrimeBlip(call.coords, 280, Config.LSPDLaptop.crimeCenter.blipColors.call911, 0.9, '911: ' .. call.type)
    end
    for _, drone in pairs(dashboard.drones or {}) do
      addCrimeBlip(drone.coords, 422, Config.LSPDLaptop.crimeCenter.blipColors.drone, 0.6, 'Drone')
    end
    for _, hit in ipairs(dashboard.lprHits or {}) do
      addCrimeBlip(hit.coords, 458, Config.LSPDLaptop.crimeCenter.blipColors.lprHit, 0.5, 'LPR: ' .. hit.plate)
    end
    for _, k9 in pairs(dashboard.k9Units or {}) do
      addCrimeBlip(k9.coords, 354, Config.LSPDLaptop.crimeCenter.blipColors.k9Unit, 0.8, k9.callSign .. ' [' .. k9.status .. ']')
    end
  end

  Wrappers.TextUI('Crime Center Active — Press ESC to close', 'info')

  Citizen.CreateThread(function()
    while crimeCenterOpen do
      Citizen.Wait(5000)
      QBox.Functions.TriggerCallback('crime:server:getFullDashboard', function(updated)
        if crimeCenterOpen and updated then
          refreshCrimeCenterDashboard(updated)
        end
      end)
    end
  end)
end

RegisterNetEvent('lspd:openCrimeCenter', function()
  if crimeCenterOpen then return end
  crimeCenterOpen = true
  ClearGpsFlags()

  Wrappers.Notify('Crime Center opened — live map active', 'success')

  QBox.Functions.TriggerCallback('crime:server:getFullDashboard', function(dashboard)
    if dashboard then
      refreshCrimeCenterDashboard(dashboard)
    end
  end)

  Citizen.CreateThread(function()
    while crimeCenterOpen do
      Citizen.Wait(0)
      if IsControlJustPressed(0, 200) then
        crimeCenterOpen = false
        clearCrimeBlips()
        Wrappers.Notify('Crime Center closed', 'info')
        break
      end
      HideHudComponentThisFrame(6)
      HideHudComponentThisFrame(7)
      HideHudComponentThisFrame(8)
      HideHudComponentThisFrame(9)
    end
  end)
end)

--- Incoming real-time updates
RegisterNetEvent('crime:client:newCall', function(call)
  if not crimeCenterOpen then return end
  addCrimeBlip(call.coords, 280, 1, 0.9, '911: ' .. call.type)
end)

RegisterNetEvent('crime:client:newLprHit', function(hit)
  if not crimeCenterOpen then return end
  addCrimeBlip(hit.coords, 458, 66, 0.5, 'LPR: ' .. hit.plate)
end)

RegisterNetEvent('crime:client:updateGps', function(gpsData)
  -- refreshed via 5s poll
end)

RegisterNetEvent('crime:client:k9Updated', function(k9Data)
  if not crimeCenterOpen then return end
  clearCrimeBlips()
  QBox.Functions.TriggerCallback('crime:server:getFullDashboard', function(d)
    if d then refreshCrimeCenterDashboard(d) end
  end)
end)

--- === K-9 OPS CENTER ===

RegisterNetEvent('lspd:openK9Ops', function()
  Wrappers.ContextMenu({
    id = 'lspd_k9_menu',
    title = 'K-9 Ops Center',
    menuItems = {
      {
        title = 'Deploy K-9 Unit',
        icon = 'fas fa-paw',
        onSelect = function()
          TriggerEvent('k9:openDeployMenu')
        end
      },
      {
        title = 'Active K-9 Units',
        icon = 'fas fa-list',
        onSelect = function()
          TriggerEvent('k9:viewActive')
        end
      },
      {
        title = 'K-9 Activity Logs',
        icon = 'fas fa-history',
        onSelect = function()
          TriggerEvent('k9:viewLogs')
        end
      },
    }
  })
end)

RegisterNetEvent('k9:openDeployMenu', function()
  local breedItems = {}
  for _, breed in ipairs(Config.LSPDLaptop.k9Ops.breeds) do
    table.insert(breedItems, {
      title = breed,
      onSelect = function()
        TriggerEvent('k9:selectSpecialization', breed)
      end
    })
  end
  Wrappers.ContextMenu({ id = 'k9_breed', title = 'Select Breed', menuItems = breedItems })
end)

RegisterNetEvent('k9:selectSpecialization', function(breed)
  local specItems = {}
  for _, spec in ipairs(Config.LSPDLaptop.k9Ops.specializations) do
    table.insert(specItems, {
      title = spec,
      onSelect = function()
        local input = Wrappers.InputDialog({
          title = 'Deploy K-9',
          options = {
            { type = 'input', label = 'Call Sign', placeholder = 'K9-1', required = true }
          }
        })
        if input then
          TriggerServerEvent('k9:server:deploy', breed, spec, input[1])
        end
      end
    })
  end
  Wrappers.ContextMenu({ id = 'k9_spec', title = 'Select Specialization', menuItems = specItems })
end)

RegisterNetEvent('k9:viewActive', function()
  QBox.Functions.TriggerCallback('k9:server:getActiveUnits', function(units)
    if not units or next(units) == nil then
      Wrappers.Notify('No active K-9 units', 'info')
      return
    end
    local items = {}
    for _, unit in pairs(units) do
      table.insert(items, {
        title = unit.callSign .. ' (' .. unit.status .. ')',
        description = unit.breed .. ' | ' .. unit.specialization .. ' | Handler: ' .. unit.handlerName,
        icon = 'fas fa-dog',
        onSelect = function()
          TriggerEvent('k9:unitCommand', unit)
        end
      })
    end
    Wrappers.ContextMenu({ id = 'k9_active', title = 'Active K-9 Units', menuItems = items })
  end)
end)

RegisterNetEvent('k9:unitCommand', function(unit)
  local items = {
    { title = 'Track Scent', icon = 'fas fa-paw', onSelect = function()
      local closest, dist = QBox.Functions.GetClosestPlayer()
      if closest ~= -1 and dist < 10.0 then
        TriggerServerEvent('k9:server:command', unit.id, 'track', GetPlayerServerId(closest))
      else
        Wrappers.Notify('No player nearby', 'error')
      end
    end},
    { title = 'Apprehend', icon = 'fas fa-handcuffs', onSelect = function()
      local closest, dist = QBox.Functions.GetClosestPlayer()
      if closest ~= -1 and dist < 20.0 then
        TriggerServerEvent('k9:server:command', unit.id, 'apprehend', GetPlayerServerId(closest))
      else
        Wrappers.Notify('No player nearby', 'error')
      end
    end},
    { title = 'Search Narcotics', icon = 'fas fa-capsules', onSelect = function()
      TriggerServerEvent('k9:server:command', unit.id, 'search_narcotics')
    end},
    { title = 'Search Explosives', icon = 'fas fa-bomb', onSelect = function()
      TriggerServerEvent('k9:server:command', unit.id, 'search_explosives')
    end},
    { title = 'Guard Position', icon = 'fas fa-shield-alt', onSelect = function()
      TriggerServerEvent('k9:server:command', unit.id, 'guard')
    end},
    { title = 'Stay', icon = 'fas fa-stop-circle', onSelect = function()
      TriggerServerEvent('k9:server:command', unit.id, 'stay')
    end},
    { title = 'Heel (Follow)', icon = 'fas fa-walking', onSelect = function()
      TriggerServerEvent('k9:server:command', unit.id, 'heel')
    end},
    { title = 'Recall Unit', icon = 'fas fa-undo', onSelect = function()
      TriggerServerEvent('k9:server:recall', unit.id)
    end},
  }
  Wrappers.ContextMenu({ id = 'k9_command', title = unit.callSign .. ' Commands', menuItems = items })
end)

RegisterNetEvent('k9:viewLogs', function()
  QBox.Functions.TriggerCallback('k9:server:getK9Logs', function(logs)
    if not logs or #logs == 0 then
      Wrappers.Notify('No K-9 activity logs', 'info')
      return
    end
    local lines = {}
    for _, log in ipairs(logs) do
      table.insert(lines, 'Unit #' .. log.unit_id .. ' | ' .. log.action .. ' | ' .. (log.created_at or ''))
    end
    Wrappers.AlertDialog({
      title = 'K-9 Activity Logs',
      content = table.concat(lines, '\n')
    })
  end)
end)
