local QBox = exports['qbx-core']:GetCoreObject()
local trackingRequests = {}

local RATE_LIMITS = {}
local function rl(s, a, m)
    local k = s .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('locator:server:track', function(targetId)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'locatorTrack', 10) then return end
    local target = QBox.Functions.GetPlayer(targetId)
    if not target then Wrappers.Notify(src, Locale('phone.player_not_found'), 'error') return end
    local coords = GetEntityCoords(GetPlayerPed(targetId))
    TriggerClientEvent('locator:client:updateLocation', src, targetId, coords)
    exports['discord-logs']:LogCustom(src, 'Locator Track', 'Tracked ' .. target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname)
end)

RegisterNetEvent('locator:server:shareLocation', function(coords)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'locatorShare', 10) then return end
    local name = p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname
    local players = QBox.Functions.GetPlayers()
    for _, sid in ipairs(players) do
        local pl = QBox.Functions.GetPlayer(sid)
        if pl and pl.PlayerData.charinfo.phone == p.PlayerData.charinfo.phone then
            TriggerClientEvent('locator:client:locationShared', sid, name, coords)
        end
    end
end)
