local QBox = exports['qbx-core']:GetCoreObject()
local activeHeists = {}

local RATE_LIMITS = {}
local function rl(s, a, m)
    local k = s .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('art:server:hackPanel', function(id)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'artHack', 3) or activeHeists[id] then return end
    if not p.Functions.RemoveItem(Config.ArtHeist.RequiredItems.hackingDevice, 1) then return end
    activeHeists[id] = { src = src, paintings = 0, start = os.time() }
    setmetatable(activeHeists[id], { __mode = 'v' })
    if math.random() <= Config.ArtHeist.PoliceAlertChance then
        local coords = Config.ArtHeist.Locations[id].coords
        TriggerClientEvent('police:client:sendAlert', -1, 'artHeist', coords, GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z)))
    end
    exports['discord-logs']:LogCustom(src, 'Art Heist', 'Hacked panel at location ' .. id)
    TriggerClientEvent('art:client:hackSuccess', src, id)
end)

RegisterNetEvent('art:server:takePainting', function(locId, paintingId)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'artPainting', 5) then return end
    if not activeHeists[locId] or activeHeists[locId].src ~= src then return end
    if os.time() - activeHeists[locId].start > Config.ArtHeist.Escape.timeout then
        activeHeists[locId] = nil
        Wrappers.Notify(src, 'Security re-engaged, get out!', 'error')
        return
    end
    local painting = Config.ArtHeist.Paintings[paintingId]
    if not painting then return end
    if not p.Functions.RemoveItem(Config.ArtHeist.RequiredItems.drillingTool, 1) then return end
    p.Functions.AddItem('painting', 1)
    p.Functions.AddMoney('cash', painting.value)
    activeHeists[locId].paintings = activeHeists[locId].paintings + 1
    exports['discord-logs']:LogCustom(src, 'Art Heist', 'Took ' .. painting.name .. ' ($' .. painting.value .. ')')
    TriggerClientEvent('art:client:paintingTaken', src, { name = painting.name, value = painting.value })
    if activeHeists[locId].paintings >= Config.ArtHeist.Rewards.paintings.max then
        TriggerClientEvent('art:client:heistComplete', src, activeHeists[locId].paintings)
        activeHeists[locId] = nil
    end
end)
