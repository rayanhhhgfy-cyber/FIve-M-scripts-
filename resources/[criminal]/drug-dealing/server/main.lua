local QBox = exports['qbx-core']:GetCoreObject()

local RATE_LIMITS = {}
local function rl(s, a, m)
    local k = s .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('deal:server:approach', function(zoneId, drug)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'dealApproach', 10) then return end
    local zone = Config.DrugDealing.DealZones[zoneId]
    if not zone then return end
    if math.random() <= Config.DrugDealing.Police.undercoverChance then
        Wrappers.Notify(src, 'Customer looks suspicious...', 'warning')
        if math.random() <= Config.DrugDealing.Police.bustChance then
            local fine = math.random(Config.DrugDealing.Police.fine.min, Config.DrugDealing.Police.fine.max)
            p.Functions.RemoveMoney('cash', fine)
            exports['discord-logs']:LogCustom(src, 'Drug Dealing', 'Busted in ' .. zone.label .. ' - Fine: $' .. fine)
            TriggerClientEvent('deal:client:result', src, { success = false, busted = true, fine = fine })
            return
        end
    end
    if math.random() <= Config.DrugDealing.Risk.robberyChance then
        local count = p.Functions.GetItemCount(drug)
        local lost = math.floor(count * Config.DrugDealing.Risk.robberyLoss)
        if lost > 0 then p.Functions.RemoveItem(drug, lost) end
        exports['discord-logs']:LogCustom(src, 'Drug Dealing', 'Robbed in ' .. zone.label .. ' - Lost ' .. lost .. 'x ' .. drug)
        TriggerClientEvent('deal:client:result', src, { success = false, robbed = true })
        return
    end
    exports['discord-logs']:LogCustom(src, 'Drug Dealing', 'Approached customer in ' .. zone.label)
    TriggerClientEvent('deal:client:customerFound', src, { zone = zoneId, drug = drug })
end)

RegisterNetEvent('deal:server:sell', function(drug, qty, unitPrice)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not rl(src, 'dealSell', 15) then return end
    if not Config.DrugDealing.Drugs[drug] then return end
    local count = QBox.Functions.GetItemCount(p, drug)
    if count < qty then Wrappers.Notify(src, 'Not enough ' .. drug, 'error') return end
    p.Functions.RemoveItem(drug, qty)
    local total = qty * unitPrice
    p.Functions.AddMoney('cash', total)
    local curRep = p.Functions.GetMetaData('drug_rep') or 0
    local repGain = Config.DrugDealing.Drugs[drug].reputationGain * qty
    p.Functions.SetMetaData('drug_rep', curRep + repGain)
    if math.random() <= Config.DrugDealing.PoliceAlertChance then
        local coords = GetEntityCoords(GetPlayerPed(src))
        TriggerClientEvent('police:client:sendAlert', -1, 'drugDeal', coords, GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z)))
    end
    exports['discord-logs']:LogCustom(src, 'Drug Dealing', 'Sold ' .. qty .. 'x ' .. drug .. ' for $' .. total)
    TriggerClientEvent('deal:client:result', src, { success = true, qty = qty, total = total })
end)

MySQL.ready(function()
    MySQL.query('CREATE TABLE IF NOT EXISTS player_drug_rep (citizenid VARCHAR(50) PRIMARY KEY, reputation INT DEFAULT 0, total_sales INT DEFAULT 0)')
end)
