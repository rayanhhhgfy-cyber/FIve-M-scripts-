local QBox = exports['qbx-core']:GetCoreObject()

local RATE_LIMITS = {}
local function checkRateLimit(src, a, m)
    local k = src .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

local dailyQueries = {}

RegisterNetEvent('anonymity:server:query', function(queryType, value)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not p.PlayerData.job.onduty then return end
    local qData = Config.AnonymityBridge.QueryTypes[queryType]
    if not qData or p.PlayerData.job.grade.level < qData.rank then return end
    if not checkRateLimit(src, 'anonymityQuery', 120) then return end
    local today = os.date('%Y-%m-%d')
    dailyQueries[src] = dailyQueries[src] or {}
    dailyQueries[src][today] = (dailyQueries[src][today] or 0) + 1
    local anonLevel = 'Basic'
    for lvlId, lvlData in pairs(Config.AnonymityBridge.AnonymityLevels) do
        if p.PlayerData.job.grade.level >= lvlData.rank then anonLevel = lvlId end
    end
    if dailyQueries[src][today] > Config.AnonymityBridge.AnonymityLevels[anonLevel].queriesPerDay then
        Wrappers.Notify(src, Locale('cid.query_limit_reached'), 'error')
        return
    end
    if queryType == 'phone' then
        MySQL.query('SELECT charinfo, citizenid FROM players WHERE JSON_EXTRACT(charinfo, "$.phone") = ?', { value }, function(r)
            if r and #r > 0 then
                local ci = json.decode(r[1].charinfo)
                TriggerClientEvent('anonymity:client:result', src, Locale('cid.phone_result', value, ci.firstname .. ' ' .. ci.lastname, r[1].citizenid))
            else
                TriggerClientEvent('anonymity:client:result', src, Locale('cid.no_results_anonymity'))
            end
        end)
    elseif queryType == 'plate' then
        MySQL.query('SELECT p.charinfo, pv.citizenid, pv.vehicle FROM players p JOIN player_vehicles pv ON p.citizenid = pv.citizenid WHERE pv.plate = ?', { value:upper() }, function(r)
            if r and #r > 0 then
                local ci = json.decode(r[1].charinfo)
                TriggerClientEvent('anonymity:client:result', src, Locale('cid.plate_result', value, ci.firstname .. ' ' .. ci.lastname, r[1].vehicle))
            else
                TriggerClientEvent('anonymity:client:result', src, Locale('cid.no_results_anonymity'))
            end
        end)
    elseif queryType == 'name' then
        MySQL.query('SELECT citizenid, charinfo FROM players WHERE JSON_EXTRACT(charinfo, "$.firstname") LIKE ? OR JSON_EXTRACT(charinfo, "$.lastname") LIKE ?', { '%' .. value .. '%', '%' .. value .. '%' }, function(r)
            if r and #r > 0 then
                local msg = Locale('cid.name_results')
                for _, row in ipairs(r) do
                    local ci = json.decode(row.charinfo)
                    msg = msg .. '\n- ' .. ci.firstname .. ' ' .. ci.lastname .. ' | Phone: ' .. ci.phone
                end
                TriggerClientEvent('anonymity:client:result', src, msg)
            else
                TriggerClientEvent('anonymity:client:result', src, Locale('cid.no_results_anonymity'))
            end
        end)
    elseif queryType == 'address' then
        MySQL.query('SELECT citizenid, charinfo FROM players WHERE JSON_EXTRACT(charinfo, "$.address") LIKE ?', { '%' .. value .. '%' }, function(r)
            if r and #r > 0 then
                local ci = json.decode(r[1].charinfo)
                TriggerClientEvent('anonymity:client:result', src, Locale('cid.address_result', value, ci.firstname .. ' ' .. ci.lastname))
            else
                TriggerClientEvent('anonymity:client:result', src, Locale('cid.no_results_anonymity'))
            end
        end)
    elseif queryType == 'financial' then
        MySQL.query('SELECT citizenid, charinfo FROM players WHERE citizenid = ? OR JSON_EXTRACT(charinfo, "$.firstname") LIKE ? OR JSON_EXTRACT(charinfo, "$.lastname") LIKE ?', { value, '%' .. value .. '%', '%' .. value .. '%' }, function(r)
            if r and #r > 0 then
                local ci = json.decode(r[1].charinfo)
                TriggerClientEvent('anonymity:client:result', src, Locale('cid.financial_result', ci.firstname .. ' ' .. ci.lastname, 'REDACTED', 'Classified'))
            else
                TriggerClientEvent('anonymity:client:result', src, Locale('cid.no_results_anonymity'))
            end
        end)
    elseif queryType == 'deep' then
        local results = {}
        MySQL.query('SELECT citizenid, charinfo FROM players WHERE citizenid = ? OR JSON_EXTRACT(charinfo, "$.firstname") LIKE ? OR JSON_EXTRACT(charinfo, "$.lastname") LIKE ?', { value:upper(), '%' .. value .. '%', '%' .. value .. '%' }, function(r)
            if r and #r > 0 then
                local ci = json.decode(r[1].charinfo)
                MySQL.query('SELECT plate, vehicle, stolen FROM player_vehicles WHERE citizenid = ?', { r[1].citizenid }, function(vehicles)
                    local msg = Locale('cid.deep_result_header', ci.firstname .. ' ' .. ci.lastname, r[1].citizenid)
                    if vehicles then
                        for _, v in ipairs(vehicles) do
                            msg = msg .. '\n- ' .. v.vehicle .. ' (' .. v.plate .. ')'
                        end
                    end
                    TriggerClientEvent('anonymity:client:result', src, msg)
                end)
            else
                TriggerClientEvent('anonymity:client:result', src, Locale('cid.no_results_anonymity'))
            end
        end)
    end
    if Config.AnonymityBridge.AuditLog then
        MySQL.insert('INSERT INTO anonymity_queries (citizenid, query_type, query_value, timestamp) VALUES (?, ?, ?, ?)',
            { p.PlayerData.citizenid, queryType, value, os.time() })
        exports['discord-logs']:LogCustom(src, 'Anonymity Query', queryType .. ': ' .. value)
    end
end)

RegisterNetEvent('anonymity:server:getHistory', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.query('SELECT * FROM anonymity_queries WHERE citizenid = ? ORDER BY timestamp DESC LIMIT 20',
        { p.PlayerData.citizenid }, function(r)
        TriggerClientEvent('anonymity:client:history', src, r or {})
    end)
end)
