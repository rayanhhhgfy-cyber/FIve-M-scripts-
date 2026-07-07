local QBox = exports['qbx-core']:GetCoreObject()
local missionsInProgress = {}

local RATE_LIMITS = {}
local function rl(s, a, m)
    local k = s .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('tow:server:getMission', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or p.PlayerData.job.name ~= 'tow' then return end
    if not rl(src, 'towMission', 10) then return end
    local loc = Config.TowJob.StuckLocations[math.random(#Config.TowJob.StuckLocations)]
    missionsInProgress[src] = { location = loc, startTime = os.time() }
    TriggerClientEvent('tow:client:startMission', src, loc.coords, loc.label)
end)

RegisterNetEvent('tow:server:completeMission', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not missionsInProgress[src] then return end
    local payment = Config.TowJob.Payment + math.random(Config.TowJob.BonusPayment + 1) - 1
    p.Functions.AddMoney('cash', payment)
    MySQL.insert('INSERT INTO tow_missions (citizenid, payment, completed_at) VALUES (?, ?, NOW())', { p.PlayerData.citizenid, payment })
    missionsInProgress[src] = nil
    Wrappers.Notify(src, Locale('logistics.payment', payment), 'success')
end)
