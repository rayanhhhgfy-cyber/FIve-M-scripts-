local playerSkills = {}
local playerCooldowns = {}
local RATE_LIMITS = {}
local QBox = exports['qbx-core']:GetCoreObject()

Citizen.CreateThread(function()
    MySQL.ready(function()
        MySQL.query('CREATE TABLE IF NOT EXISTS mining_skills (citizenid VARCHAR(50) PRIMARY KEY, skill_level INT DEFAULT 0)', {})
        MySQL.query('CREATE TABLE IF NOT EXISTS mining_logs (id INT AUTO_INCREMENT PRIMARY KEY, citizenid VARCHAR(50), action VARCHAR(50), ore_type VARCHAR(50), amount INT, earned INT DEFAULT 0, timestamp INT DEFAULT 0)', {})
    end)
end)

RegisterNetEvent('mining:collectOre', function(oreType, amount)
    local src = source
    if not src or src == 0 then return end
    local license = GetPlayerIdentifierByType(src, 'license')
    if not license then return end

    local cooldownKey = 'mine_' .. license
    local now = os.time()
    if playerCooldowns[cooldownKey] and (now - playerCooldowns[cooldownKey]) < 2 then return end
    playerCooldowns[cooldownKey] = now

    local p = QBox.Functions.GetPlayer(src)
    if not p then return end

    amount = math.floor(amount)
    if amount <= 0 or amount > 100 then return end

    if not Config.Mining.Ores[oreType] then return end

    local itemName = oreType
    local itemLabel = Config.Mining.Ores[oreType].label
    local weight = Config.Mining.Ores[oreType].weight * amount

    local canCarry = exports.ox_inventory:CanCarryItem(src, itemName, amount)
    if not canCarry then
        Wrappers.Notify(src, Locale('mining.inventory_full') or 'Inventory is full!', 'error')
        return
    end

    exports.ox_inventory:AddItem(src, itemName, amount)
    MySQL.insert('INSERT INTO mining_logs (citizenid, action, ore_type, amount, timestamp) VALUES (?, ?, ?, ?, ?)',
        { p.PlayerData.citizenid, 'mine', oreType, amount, os.time() })

    local message = string.format('**Mining Collect**\nPlayer: %s (%s)\nOre: %s\nAmount: %d\nDate: %s',
        GetPlayerName(src), license, itemLabel, amount, os.date('%Y-%m-%d %H:%M:%S'))
    exports['discord-logs']:LogCustom('mining_logs', message)
end)

RegisterNetEvent('mining:processOre', function(oreType)
    local src = source
    if not src or src == 0 then return end
    local license = GetPlayerIdentifierByType(src, 'license')
    if not license then return end

    local cooldownKey = 'process_' .. license
    local now = os.time()
    if playerCooldowns[cooldownKey] and (now - playerCooldowns[cooldownKey]) < 3 then return end
    playerCooldowns[cooldownKey] = now

    local p = QBox.Functions.GetPlayer(src)
    if not p then return end

    if not Config.Mining.Ores[oreType] or not Config.Mining.ProcessedOres[oreType] then return end

    local oreCount = exports.ox_inventory:GetItemCount(src, oreType)
    if oreCount < 1 then
        Wrappers.Notify(src, Locale('mining.no_ore_to_process') or 'You have no ore to process', 'error')
        return
    end

    local processedItem = oreType .. '_processed'
    exports.ox_inventory:RemoveItem(src, oreType, 1)
    exports.ox_inventory:AddItem(src, processedItem, 1)

    MySQL.insert('INSERT INTO mining_logs (citizenid, action, ore_type, amount, timestamp) VALUES (?, ?, ?, ?, ?)',
        { p.PlayerData.citizenid, 'process', oreType, 1, os.time() })

    local message = string.format('**Mining Process**\nPlayer: %s (%s)\nOre: %s\nDate: %s',
        GetPlayerName(src), license, oreType, os.date('%Y-%m-%d %H:%M:%S'))
    exports['discord-logs']:LogCustom('mining_logs', message)
end)

RegisterNetEvent('mining:sellItem', function(itemName, amount, itemType)
    local src = source
    if not src or src == 0 then return end
    local license = GetPlayerIdentifierByType(src, 'license')
    if not license then return end

    local cooldownKey = 'sell_' .. license
    local now = os.time()
    if playerCooldowns[cooldownKey] and (now - playerCooldowns[cooldownKey]) < 2 then
        TriggerClientEvent('mining:sellResult', src, false, Locale('mining.cooldown') or 'Please wait before selling again.')
        return
    end
    playerCooldowns[cooldownKey] = now

    local p = QBox.Functions.GetPlayer(src)
    if not p then return end

    amount = math.floor(amount)
    if amount <= 0 or amount > 1000 then return end

    local pricePerUnit = 0
    local actualItemName = itemName
    local itemLabel = itemName

    if itemType == 'ore' then
        if not Config.Mining.Ores[itemName] then
            TriggerClientEvent('mining:sellResult', src, false, Locale('mining.invalid_item') or 'Invalid item')
            return
        end
        pricePerUnit = Config.Mining.Ores[itemName].price
        itemLabel = Config.Mining.Ores[itemName].label
        actualItemName = itemName
    elseif itemType == 'processed' then
        if not Config.Mining.ProcessedOres[itemName] then
            TriggerClientEvent('mining:sellResult', src, false, Locale('mining.invalid_item') or 'Invalid item')
            return
        end
        pricePerUnit = Config.Mining.ProcessedOres[itemName].price
        itemLabel = Config.Mining.ProcessedOres[itemName].label
        actualItemName = itemName .. '_processed'
    else
        TriggerClientEvent('mining:sellResult', src, false, Locale('mining.invalid_item') or 'Invalid item')
        return
    end

    local currentCount = exports.ox_inventory:GetItemCount(src, actualItemName)
    if currentCount < amount then
        TriggerClientEvent('mining:sellResult', src, false, Locale('mining.not_enough') or 'Not enough items')
        return
    end

    local totalPrice = pricePerUnit * amount
    exports.ox_inventory:RemoveItem(src, actualItemName, amount)
    p.Functions.AddMoney('cash', totalPrice)

    MySQL.insert('INSERT INTO mining_logs (citizenid, action, ore_type, amount, earned, timestamp) VALUES (?, ?, ?, ?, ?, ?)',
        { p.PlayerData.citizenid, 'sell', itemName, amount, totalPrice, os.time() })

    local message = string.format('**Mining Sale**\nPlayer: %s (%s)\nItem: %s\nAmount: %d\nEarned: $%d\nDate: %s',
        GetPlayerName(src), license, itemLabel, amount, totalPrice, os.date('%Y-%m-%d %H:%M:%S'))
    exports['discord-logs']:LogCustom('mining_sales', message)

    TriggerClientEvent('mining:sellResult', src, true,
        Locale('mining.sold', amount, itemLabel, totalPrice) or string.format('Sold %d %s for $%d', amount, itemLabel, totalPrice))
end)

RegisterNetEvent('mining:updateSkill', function(skillLevel)
    local src = source
    local p = QBox.Functions.GetPlayer(src)
    if not p then return end

    skillLevel = math.floor(skillLevel)
    if skillLevel < 0 or skillLevel > 100 then return end

    local citizenid = p.PlayerData.citizenid
    playerSkills[citizenid] = skillLevel

    MySQL.update('INSERT INTO mining_skills (citizenid, skill_level) VALUES (?, ?) ON DUPLICATE KEY UPDATE skill_level = ?',
        { citizenid, skillLevel, skillLevel })
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    if license then
        playerCooldowns['mine_' .. license] = nil
        playerCooldowns['process_' .. license] = nil
        playerCooldowns['sell_' .. license] = nil
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        playerCooldowns = {}
    end
end)
