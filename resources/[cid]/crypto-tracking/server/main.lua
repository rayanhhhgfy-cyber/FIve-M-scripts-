local QBox = exports['qbx-core']:GetCoreObject()

local RATE_LIMITS = {}
local function checkRateLimit(src, a, m)
    local k = src .. ':' .. a; local n = os.time()
    RATE_LIMITS[k] = RATE_LIMITS[k] or {}; table.insert(RATE_LIMITS[k], n)
    for i = #RATE_LIMITS[k], 1, -1 do if n - RATE_LIMITS[k][i] > 60 then table.remove(RATE_LIMITS[k], i) end end
    return #RATE_LIMITS[k] <= m
end

RegisterNetEvent('crypto:server:search', function(wallet, currency, level)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not p.PlayerData.job.onduty then return end
    local lvlData = Config.CryptoTracking.TrackingLevels[level]
    if not lvlData or p.PlayerData.job.grade.level < lvlData.rank then return end
    MySQL.query('SELECT * FROM crypto_transactions WHERE (from_wallet = ? OR to_wallet = ?) AND currency = ? ORDER BY timestamp DESC LIMIT ?',
        { wallet, wallet, currency, lvlData.maxResults }, function(r)
        local txns = {}
        for _, row in ipairs(r or {}) do
            table.insert(txns, { hash = row.tx_hash, from = row.from_wallet, to = row.to_wallet, amount = row.amount, currency = row.currency, timestamp = row.timestamp })
        end
        TriggerClientEvent('crypto:client:searchResult', src, txns)
        MySQL.insert('INSERT INTO crypto_queries (citizenid, wallet, currency, level, timestamp) VALUES (?, ?, ?, ?, ?)',
            { p.PlayerData.citizenid, wallet, currency, level, os.time() })
    end)
end)

RegisterNetEvent('crypto:server:trackWallet', function(wallet, alias)
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p or not p.PlayerData.job.onduty then return end
    MySQL.insert('INSERT INTO crypto_tracked_wallets (citizenid, wallet, alias, timestamp) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE alias = ?, last_seen = NOW()',
        { p.PlayerData.citizenid, wallet, alias or 'unknown', os.time(), alias or 'unknown' })
    Wrappers.Notify(src, Locale('cid.wallet_tracked'), 'success')
end)

RegisterNetEvent('crypto:server:getHistory', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.query('SELECT * FROM crypto_tracked_wallets WHERE citizenid = ? ORDER BY last_seen DESC',
        { p.PlayerData.citizenid }, function(r)
        TriggerClientEvent('crypto:client:history', src, r or {})
    end)
end)

RegisterNetEvent('crypto:server:getFlags', function()
    local src = source; local p = QBox.Functions.GetPlayer(src)
    if not p then return end
    MySQL.query('SELECT * FROM crypto_flags ORDER BY timestamp DESC LIMIT 50', {}, function(r)
        TriggerClientEvent('crypto:client:flags', src, r or {})
    end)
end)

function FlagTransaction(wallet, amount, reason)
    MySQL.insert('INSERT INTO crypto_flags (wallet, amount, reason, timestamp) VALUES (?, ?, ?, ?)',
        { wallet, amount, reason, os.time() })
    local players = QBox.Functions.GetPlayers()
    for _, sid in ipairs(players) do
        local pl = QBox.Functions.GetPlayer(sid)
        if pl and (pl.PlayerData.job.name == 'cid' or pl.PlayerData.job.name == 'police') and pl.PlayerData.job.onduty then
            TriggerClientEvent('Wrappers:Notify', sid, Locale('cid.new_crypto_flag', reason, amount), 'warning')
        end
    end
end
exports('FlagTransaction', FlagTransaction)
