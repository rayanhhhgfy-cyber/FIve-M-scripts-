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
  return #RATE_LIMITS[key] <= Config.Identity.rateLimits[action] or 10
end

local function getNextCID()
  local result = MySQL.scalar.await('SELECT MAX(CAST(citizenid AS UNSIGNED)) FROM cid_registry')
  local nextNum = (result and result > 0) and result + 1 or Config.Identity.cidStartingNumber
  return tostring(nextNum)
end

local function generateStarterItems(src, citizenid)
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local charinfo = player.PlayerData.charinfo
  for _, itemDef in ipairs(Config.Identity.starterItems) do
    local metadata = itemDef.metadata(src, citizenid, charinfo)
    exports.ox_inventory:AddItem(src, itemDef.name, itemDef.count, metadata)
  end
end

local function setCIDState(src, citizenid)
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  player.PlayerData.citizenid = citizenid
  Player(src).state:set(Config.Identity.stateBagKey, citizenid, true)
end

RegisterNetEvent('ox:playerLoaded', function(data)
  local src = source
  if not src then return end
  -- If character-system is active, skip auto-CID generation
  if Config.Identity.useCharacterSystem then return end
  Citizen.SetTimeout(100, function()
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local license = QBox.Functions.GetIdentifier(src)
    if not license then return end
    local existing = MySQL.single.await('SELECT citizenid FROM cid_registry WHERE license = ? AND slot = ?', { license, data.slot or 1 })
    if existing then
      setCIDState(src, existing.citizenid)
      TriggerClientEvent(Config.Identity.eventOnReady, src, existing.citizenid)
      MySQL.update('UPDATE players SET citizenid = ? WHERE citizenid = ?', { existing.citizenid, existing.citizenid })
      return
    end
    local citizenid = getNextCID()

    local insertSuccess = MySQL.prepare.await('INSERT INTO cid_registry (license, citizenid, slot) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE slot = slot', {
      license, citizenid, data.slot or 1
    })
    if not insertSuccess then
      local retry = MySQL.single.await('SELECT citizenid FROM cid_registry WHERE license = ? AND slot = ?', { license, data.slot or 1 })
      if retry then
        setCIDState(src, retry.citizenid)
        TriggerClientEvent(Config.Identity.eventOnReady, src, retry.citizenid)
        return
      end
      citizenid = getNextCID()
      MySQL.insert('INSERT INTO cid_registry (license, citizenid, slot) VALUES (?, ?, ?)', { license, citizenid, data.slot or 1 })
    end
    MySQL.update('UPDATE players SET citizenid = ? WHERE citizenid = ?', { citizenid, player.PlayerData.citizenid or '' })
    setCIDState(src, citizenid)
    generateStarterItems(src, citizenid)
    TriggerClientEvent(Config.Identity.eventOnReady, src, citizenid)
  end)
end)

QBox.Functions.CreateCallback('identity:getCID', function(source, cb)
  local src = source
  if not checkRateLimit(src, 'requestCID') then cb(nil) return end
  local citizenid = Player(src).state[Config.Identity.stateBagKey]
  cb(citizenid or '')
end)

QBox.Functions.CreateCallback('identity:getCharInfo', function(source, cb)
  local src = source
  if not checkRateLimit(src, 'requestCharInfo') then cb(nil) return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then cb(nil) return end
  cb(player.PlayerData.charinfo)
end)

QBox.Functions.CreateCallback('identity:getPlayerByCID', function(source, cb, targetCID)
  local players = QBox.Functions.GetPlayers()
  for _, src in ipairs(players) do
    if Player(src).state[Config.Identity.stateBagKey] == targetCID then
      cb(src)
      return
    end
  end
  cb(nil)
end)

RegisterNetEvent('identity:server:requestCardRegrant', function()
  local src = source
  local citizenid = Player(src).state[Config.Identity.stateBagKey]
  if not citizenid then return end
  local player = QBox.Functions.GetPlayer(src)
  if not player then return end
  local itemCount = exports.ox_inventory:GetItemCount(src, 'id_card', nil, true)
  if itemCount and itemCount > 0 then return end
  local charinfo = player.PlayerData.charinfo
  local metadata = Config.Identity.starterItems[1].metadata(src, citizenid, charinfo)
  exports.ox_inventory:AddItem(src, 'id_card', 1, metadata)
end)

AddEventHandler('playerDropped', function()
  local src = source
  Player(src).state:set(Config.Identity.stateBagKey, nil, true)
end)
