local QBCore = exports['qbx_core']:GetCoreObject()

function GenerateWeaponSerial()
    local chars = Config.Weapons.serialChars
    local serial = Config.Inventory.serialPrefix
    for i = 1, Config.Inventory.serialLength do
        serial = serial .. chars:sub(math.random(1, #chars), math.random(1, #chars))
    end
    return serial
end

function ValidateSerial(serial)
    if not serial or type(serial) ~= 'string' then return false end
    if string.len(serial) ~= Config.Inventory.serialPrefix:len() + Config.Inventory.serialLength then
        return false
    end
    return true
end

exports('GenerateWeaponSerial', GenerateWeaponSerial)
exports('ValidateSerial', ValidateSerial)

local function RegisterWeaponWithSerial(source, weaponName, serial)
    if not Config.Inventory.weaponSerials then return end
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    local citizenid = player.PlayerData.citizenid
    MySQL.insert.await(
        'INSERT INTO weapon_serials (citizenid, weapon, serial, registered_at) VALUES (?, ?, ?, NOW())',
        { citizenid, weaponName, serial }
    )
end

exports('RegisterWeapon', RegisterWeaponWithSerial)

function CheckWeaponOwnership(source, serial)
    if not serial then return false end
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    local result = MySQL.query.await(
        'SELECT citizenid FROM weapon_serials WHERE serial = ? LIMIT 1',
        { serial }
    )
    if result and #result > 0 then
        return result[1].citizenid == player.PlayerData.citizenid
    end
    return false
end

exports('CheckWeaponOwnership', CheckWeaponOwnership)

function GetWeaponHistory(serial)
    local result = MySQL.query.await(
        'SELECT * FROM weapon_serials WHERE serial = ? ORDER BY registered_at DESC',
        { serial }
    )
    return result or {}
end

exports('GetWeaponHistory', GetWeaponHistory)

local function SyncInventoryConfig()
    local shops = {}
    for shopType, shopData in pairs(Config.Shops) do
        shops[shopType] = {
            name = shopType,
            label = shopData.label,
            slots = shopData.slots,
            items = shopData.items
        }
    end
    TriggerClientEvent('ox_inventory:shops', -1, shops)
end

RegisterNetEvent('ox-inventory-cfg:server:purchaseWeapon', function(weaponName, price)
    local source = source
    if not source then return end
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    local cash = player.PlayerData.money.cash
    if cash < price then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Not enough cash' })
        return
    end
    local serial = GenerateWeaponSerial()
    local success = exports['ox_inventory']:AddItem(source, weaponName, 1, nil, nil, { serial = serial })
    if success then
        player.Functions.RemoveMoney('cash', price)
        RegisterWeaponWithSerial(source, weaponName, serial)
        TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Purchased ' .. weaponName .. ' [Serial: ' .. serial .. ']' })
    end
end)

RegisterNetEvent('ox-inventory-cfg:server:craftWeapon', function(weaponName, parts)
    local source = source
    if not source then return end
    local serial = GenerateWeaponSerial()
    local success = exports['ox_inventory']:AddItem(source, weaponName, 1, nil, nil, { serial = serial })
    if success then
        RegisterWeaponWithSerial(source, weaponName, serial)
        TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Crafted ' .. weaponName .. ' [Serial: ' .. serial .. ']' })
    end
end)

RegisterNetEvent('ox-inventory-cfg:server:checkSerial', function(serial)
    local source = source
    if not source then return end
    local owned = CheckWeaponOwnership(source, serial)
    if owned then
        TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'This weapon is registered to you.' })
    else
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'This weapon is NOT registered to you.' })
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[ox-inventory-cfg] Weapon serial system active. Serial format: %s-XXXXXXXX^7', Config.Inventory.serialPrefix)
    SyncInventoryConfig()
end)

exports('SyncShops', SyncInventoryConfig)
