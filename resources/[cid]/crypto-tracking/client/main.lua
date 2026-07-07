local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() playerData = QBox.Functions.GetPlayerData() end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(j) playerData.job = j end)

local function isCID() return playerData.job and (playerData.job.name == 'cid' or playerData.job.name == 'police') end
local function isOnDuty() return playerData.job and playerData.job.onduty end
local function rank() return playerData.job and playerData.job.grade.level or 0 end

local terminalZones = {
    { coords = vector3(114.0, -744.0, 45.5), radius = 1.5 },
    { coords = vector3(116.0, -744.0, 45.5), radius = 1.5 }
}

Citizen.CreateThread(function()
    for i, zone in ipairs(terminalZones) do
        exports.ox_target:addBoxZone({
            coords = zone.coords, size = vec3(zone.radius * 2, zone.radius * 2, 2.0), rotation = 0, debug = false,
            options = {{
                name = 'crypto_terminal_' .. i,
                icon = Config.CryptoTracking.TargetOptions.terminal.icon,
                label = Config.CryptoTracking.TargetOptions.terminal.label,
                group = Config.CryptoTracking.TargetOptions.terminal.group,
                distance = Config.CryptoTracking.TargetOptions.terminal.distance,
                canInteract = function() return isCID() and isOnDuty() end,
                onSelect = function() TriggerEvent('crypto:tracking:open') end
            }}
        })
    end
end)

RegisterNetEvent('crypto:tracking:open', function()
    if not isCID() or not isOnDuty() then Wrappers.Notify(Locale('cid.not_authorized'), 'error') return end
    local lvlItems = {}
    for lvlId, lvlData in pairs(Config.CryptoTracking.TrackingLevels) do
        if rank() >= lvlData.rank then
            table.insert(lvlItems, { title = lvlData.label, description = lvlData.maxResults .. ' results', onSelect = function() TriggerEvent('crypto:search', lvlId) end })
        end
    end
    table.insert(lvlItems, { title = Locale('cid.track_wallet'), onSelect = function() TriggerEvent('crypto:trackWallet') end })
    table.insert(lvlItems, { title = Locale('cid.transaction_history'), onSelect = function() TriggerServerEvent('crypto:server:getHistory') end })
    table.insert(lvlItems, { title = Locale('cid.flagged_transactions'), onSelect = function() TriggerServerEvent('crypto:server:getFlags') end })
    Wrappers.ContextMenu({ id = 'crypto_tracking', title = Locale('cid.crypto_tracking'), menuItems = lvlItems })
end)

RegisterNetEvent('crypto:search', function(level)
    local lvlData = Config.CryptoTracking.TrackingLevels[level]
    if not lvlData then return end
    Wrappers.InputDialog({ title = Locale('cid.crypto_search'), inputs = {
        { type = 'input', label = Locale('cid.wallet_address'), name = 'wallet', required = true },
        { type = 'select', label = Locale('cid.currency'), name = 'currency', options = {
            { value = 'bitcoin', label = 'Bitcoin' }, { value = 'ethereum', label = 'Ethereum' },
            { value = 'monero', label = 'Monero' }, { value = 'litecoin', label = 'Litecoin' }
        }}
    }}, function(v)
        if v then TriggerServerEvent('crypto:server:search', v.wallet, v.currency, level) end
    end)
end)

RegisterNetEvent('crypto:trackWallet', function()
    Wrappers.InputDialog({ title = Locale('cid.track_wallet'), inputs = {
        { type = 'input', label = Locale('cid.wallet_address'), name = 'wallet', required = true },
        { type = 'input', label = Locale('cid.alias'), name = 'alias', required = false }
    }}, function(v)
        if v then TriggerServerEvent('crypto:server:trackWallet', v.wallet, v.alias) end
    end)
end)

RegisterNetEvent('crypto:client:searchResult', function(txns)
    local items = {}
    for _, txn in ipairs(txns or {}) do
        table.insert(items, { title = txn.hash:sub(1, 16) .. '...', description = txn.from .. ' -> ' .. txn.to .. ' | ' .. txn.amount .. ' ' .. txn.currency, onSelect = function() TriggerEvent('crypto:txnDetail', txn) end })
    end
    if #items == 0 then table.insert(items, { title = Locale('cid.no_transactions'), description = '' }) end
    Wrappers.ContextMenu({ id = 'crypto_results', title = Locale('cid.transactions'), menuItems = items })
end)

RegisterNetEvent('crypto:txnDetail', function(txn)
    Wrappers.Notify(Locale('cid.txn_detail', txn.hash, txn.from, txn.to, txn.amount, txn.currency, txn.timestamp), 'info')
end)

RegisterNetEvent('crypto:client:history', function(history)
    local items = {}
    for _, h in ipairs(history or {}) do
        table.insert(items, { title = h.wallet:sub(1, 20) .. '...', description = h.alias .. ' - ' .. h.last_seen })
    end
    Wrappers.ContextMenu({ id = 'crypto_history', title = Locale('cid.tracked_wallets'), menuItems = items })
end)

RegisterNetEvent('crypto:client:flags', function(flags)
    local items = {}
    for _, f in ipairs(flags or {}) do
        table.insert(items, { title = f.wallet:sub(1, 20) .. '...', description = f.reason .. ' ($' .. f.amount .. ')' })
    end
    Wrappers.ContextMenu({ id = 'crypto_flags', title = Locale('cid.flagged_transactions'), menuItems = items })
end)
