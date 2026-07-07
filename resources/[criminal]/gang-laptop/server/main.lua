local QBox = exports['qbx_core']:GetCoreObject()

local RATE_LIMITS = {}
local function checkRateLimit(src, action)
  local key = src .. ':' .. action
  local now = os.time()
  RATE_LIMITS[key] = RATE_LIMITS[key] or {}
  table.insert(RATE_LIMITS[key], now)
  for i = #RATE_LIMITS[key], 1, -1 do
    if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end
  end
  local limit = Config.GangLaptop.rateLimits[action] or 10
  return #RATE_LIMITS[key] <= limit
end

local function isBoss(src)
  local player = QBox.Functions.GetPlayer(src)
  if not player then return false end
  return player.PlayerData.gang.grade.level >= Config.GangLaptop.bossRank
end

local function canManage(src)
  local player = QBox.Functions.GetPlayer(src)
  if not player then return false end
  return player.PlayerData.gang.grade.level >= Config.GangLaptop.underbossRank
end

RegisterNetEvent('gang:server:recruit', function(targetSrc)
  local src = source
  if not checkRateLimit(src, 'recruit') then return end
  if not canManage(src) then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
    return
  end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local target = QBox.Functions.GetPlayer(targetSrc)
  if not target then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Player not found' })
    return
  end
  local gangName = player.PlayerData.gang.name
  target.Functions.SetGang(gangName, 0)
  MySQL.insert('INSERT INTO gang_rosters (citizenid, gang, rank) VALUES (?, ?, 0) ON DUPLICATE KEY UPDATE gang = ?, rank = 0', {
    target.PlayerData.citizenid, gangName, gangName
  })
  TriggerClientEvent('ox_lib:notify', targetSrc, { type = 'success', description = 'You were recruited into ' .. gangName })
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Recruited' })
end)

RegisterNetEvent('gang:server:exile', function(targetCID)
  local src = source
  if not checkRateLimit(src, 'exile') then return end
  if not canManage(src) then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Access denied' })
    return
  end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local target = QBox.Functions.GetPlayerByCitizenId(targetCID)
  if target then
    target.Functions.SetGang('none', 0)
  end
  MySQL.query('DELETE FROM gang_rosters WHERE citizenid = ?', { targetCID })
  exports.ox_inventory:RemoveItem(target and target.PlayerData.source or 0, 'gang_stash_key', 1)
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Member exiled' })
end)

RegisterNetEvent('gang:server:setRank', function(targetCID, newRank)
  local src = source
  if not checkRateLimit(src, 'promote') then return end
  if not isBoss(src) then
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only the Boss can change ranks' })
    return
  end
  if newRank >= Config.GangLaptop.bossRank then return end
  MySQL.update('UPDATE gang_rosters SET rank = ? WHERE citizenid = ?', { newRank, targetCID })
  local target = QBox.Functions.GetPlayerByCitizenId(targetCID)
  if target then
    target.Functions.SetGang(target.PlayerData.gang.name, newRank)
  end
  TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Rank set to ' .. (Config.GangLaptop.ranks[newRank] or tostring(newRank)) })
end)

QBox.Functions.CreateCallback('gang:server:getRoster', function(source, cb)
  local player = QBox.Functions.GetPlayer(source)
  if not player then cb({}) return end
  local gangName = player.PlayerData.gang.name
  if not gangName or gangName == 'none' then cb({}) return end
  local roster = MySQL.query.await('SELECT * FROM gang_rosters WHERE gang = ? ORDER BY rank DESC', { gangName })
  for _, member in ipairs(roster) do
    local p = QBox.Functions.GetPlayerByCitizenId(member.citizenid)
    member.name = p and (p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname) or 'Offline'
    member.online = p and true or false
    member.rankLabel = Config.GangLaptop.ranks[member.rank] or 'Unknown'
  end
  cb(roster)
end)

QBox.Functions.CreateCallback('gang:server:nearbyPlayers', function(source, cb)
  local ped = GetPlayerPed(source)
  local coords = GetEntityCoords(ped)
  local nearby = {}
  local players = QBox.Functions.GetPlayers()
  for _, p in ipairs(players) do
    if p ~= source then
      local otherPed = GetPlayerPed(p)
      local otherCoords = GetEntityCoords(otherPed)
      local dist = #(coords - otherCoords)
      if dist < 5.0 then
        local otherPlayer = QBox.Functions.GetPlayer(p)
        if otherPlayer then
          table.insert(nearby, {
            src = p,
            name = otherPlayer.PlayerData.charinfo.firstname .. ' ' .. otherPlayer.PlayerData.charinfo.lastname,
            cid = otherPlayer.PlayerData.citizenid
          })
        end
      end
    end
  end
  cb(nearby)
end)
