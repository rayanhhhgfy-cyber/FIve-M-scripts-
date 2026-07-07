local QBox = exports['qbx_core']:GetCoreObject()
local RATE_LIMITS = {}

local function rateLimit(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    RATE_LIMITS[key] = RATE_LIMITS[key] or {}
    table.insert(RATE_LIMITS[key], now)
    for i = #RATE_LIMITS[key], 1, -1 do
        if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end
    end
    return #RATE_LIMITS[key] <= maxPerMin
end

local function getPlayer(src)
    local p = QBox.Functions.GetPlayer(src)
    if not p then return nil end
    return p
end

local function isCidJob(jobName)
    for _, allowed in ipairs(Config.MethLab.cidJobs) do
        if jobName == allowed then return true end
    end
    return false
end

RegisterNetEvent('methlab:playerLoaded', function(citizenid)
    local src = source
    local p = getPlayer(src)
    if not p then return end
    MySQL.insert('INSERT IGNORE INTO meth_lab_dealing_reputation (citizenid, rep, total_sales, total_earned) VALUES (?, 0, 0, 0)', { citizenid })
end)

QBox.Functions.CreateCallback('methlab:canDealHere', function(source, cb)
    local src = source
    local p = getPlayer(src)
    if not p then cb(false) return end
    local cops = 0
    local players = QBox.Functions.GetPlayers()
    for _, id in ipairs(players) do
        local player = QBox.Functions.GetPlayer(id)
        if player and player.PlayerData.job.onduty and isCidJob(player.PlayerData.job.name) then
            cops = cops + 1
        end
    end
    cb(cops >= Config.MethLab.dealing.minPolice)
end)

QBox.Functions.CreateCallback('methlab:getBunkerState', function(source, cb, bunkerId)
    local bunker = exports['bunker-builder']:GetBunker(bunkerId)
    if not bunker then cb(nil) return end
    local row = MySQL.single.await('SELECT heat, upgrades_json, storage_data FROM meth_lab_state WHERE bunker_id = ?', { bunkerId })
    if row then
        cb({
            heat = row.heat or 0,
            upgrades = json.decode(row.upgrades_json or '[]') or {},
        })
    else
        MySQL.insert('INSERT INTO meth_lab_state (bunker_id, heat, upgrades_json) VALUES (?, 0, \'[]\')', { bunkerId })
        cb({ heat = 0, upgrades = {} })
    end
end)

RegisterNetEvent('methlab:adminResetHeat', function(bunkerId)
    local src = source
    local groups = Config.MethLab.adminGroups or { 'admin', 'superadmin', 'god' }
    local p = getPlayer(src)
    if not p then return end
    local isAdmin = false
    for _, g in ipairs(groups) do
        if p.PlayerData.group == g then isAdmin = true break end
    end
    if not isAdmin then return end
    MySQL.update('UPDATE meth_lab_state SET heat = 0 WHERE bunker_id = ?', { bunkerId })
    TriggerClientEvent('methlab:updateHeat', -1, 0, bunkerId)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Heat reset for bunker' })
end)

QBox.Functions.CreateCallback('methlab:getDealingRep', function(source, cb)
    local p = getPlayer(source)
    if not p then cb(0) return end
    local row = MySQL.single.await('SELECT rep FROM meth_lab_dealing_reputation WHERE citizenid = ?', { p.PlayerData.citizenid })
    cb(row and row.rep or 0)
end)

AddEventHandler('playerDropped', function()
    local src = source
    RATE_LIMITS[src] = nil
end)

MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS meth_lab_state (
            bunker_id VARCHAR(64) PRIMARY KEY,
            heat INT DEFAULT 0,
            upgrades_json JSON DEFAULT '[]',
            storage_data JSON DEFAULT '{}'
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS meth_lab_cooks (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50) NOT NULL,
            bunker_id VARCHAR(64) NOT NULL,
            recipe VARCHAR(32) NOT NULL,
            purity FLOAT NOT NULL,
            amount INT NOT NULL,
            timestamp INT NOT NULL,
            INDEX idx_citizenid (citizenid),
            INDEX idx_bunker (bunker_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS meth_lab_dealing_reputation (
            citizenid VARCHAR(50) PRIMARY KEY,
            rep INT DEFAULT 0,
            total_sales INT DEFAULT 0,
            total_earned BIGINT DEFAULT 0
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query([[
        ALTER TABLE custom_bunkers
        ADD COLUMN IF NOT EXISTS passcode VARCHAR(10) DEFAULT '2193',
        ADD COLUMN IF NOT EXISTS locked TINYINT(1) DEFAULT 1,
        ADD COLUMN IF NOT EXISTS cid_bypass TINYINT(1) DEFAULT 1,
        ADD COLUMN IF NOT EXISTS interior_type VARCHAR(32) DEFAULT 'bunker_meth_lab'
    ]])
    local bunkers = exports['bunker-builder']:GetAllBunkers() or {}
    for id, _ in pairs(bunkers) do
        MySQL.insert('INSERT IGNORE INTO meth_lab_state (bunker_id, heat, upgrades_json) VALUES (?, 0, \'[]\')', { id })
    end

    Citizen.CreateThread(function()
        Citizen.Wait(2000)
        local items = {
            ['pseudoephedrine'] = { label = 'Pseudoephedrine', weight = 100, stack = true, close = true, description = 'Common cold medicine. Also a key meth precursor.' },
            ['lithium'] = { label = 'Lithium', weight = 200, stack = true, close = true, description = 'Light metal used in batteries and chemistry.' },
            ['anhydrous_ammonia'] = { label = 'Anhydrous Ammonia', weight = 300, stack = true, close = true, description = 'Concentrated ammonia. Volatile and suspicious.' },
            ['red_phosphorus'] = { label = 'Red Phosphorus', weight = 150, stack = true, close = true, description = 'Reactive chemical. Heavily monitored by authorities.' },
            ['p2p'] = { label = 'P2P', weight = 200, stack = true, close = true, description = 'Phenyl-2-propanone. Precursor for high-grade meth.' },
            ['methylamine'] = { label = 'Methylamine', weight = 250, stack = true, close = true, description = 'Industrial chemical. 55 gallon drum not included.' },
            ['battery_acid'] = { label = 'Battery Acid', weight = 400, stack = true, close = true, description = 'Sulfuric acid from car batteries. Nasty stuff.' },
            ['lye'] = { label = 'Lye', weight = 100, stack = true, close = true, description = 'Sodium hydroxide. Drain cleaner and meth ingredient.' },
            ['toxic_waste'] = { label = 'Toxic Waste', weight = 500, stack = true, close = false, description = 'Chemical byproduct. Must be disposed of properly!' },
            ['meth_blue_sky'] = { label = 'Blue Sky Meth', weight = 50, stack = true, close = true, description = 'High-purity methamphetamine. Premium product.' },
            ['meth_crystal'] = { label = 'Crystal Meth', weight = 40, stack = true, close = true, description = 'Ultra-pure crystal meth. Top of the line.' },
            ['meth_street'] = { label = 'Street Meth', weight = 60, stack = true, close = true, description = 'Average quality street meth. Gets the job done.' },
        }
        for name, data in pairs(items) do
            pcall(function()
                exports.ox_inventory:RegisterItem(name, data)
            end)
        end
        print('^2[Meth-Lab-Empire] ^3Registered ^5' .. #items .. ' ^3items via ox_inventory')
    end)
end)

QBox.Commands.Add('methlab', 'Meth Lab Empire admin command', {}, false, function(source)
    local src = source
    local p = getPlayer(src)
    if not p then return end
    local groups = Config.MethLab.adminGroups
    local isAdmin = false
    for _, g in ipairs(groups) do
        if p.PlayerData.group == g then isAdmin = true break end
    end
    if not isAdmin then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Admin only' })
        return
    end
    TriggerClientEvent('methlab:adminMenu', src)
end)
