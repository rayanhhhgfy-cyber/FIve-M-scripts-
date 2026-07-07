local QBCore = exports['qbx_core']:GetCoreObject()
local purchaseCooldowns = {}

local function GetEmsOnline()
    local count = 0
    for _, id in ipairs(GetPlayers()) do
        local p = QBCore.Functions.GetPlayer(tonumber(id))
        if p and p.PlayerData.job.name == Config.Pharmacy.emsJobName and p.PlayerData.job.onduty then
            count = count + 1
        end
    end
    return count
end

lib.callback.register('pharmacy-npc:server:getItems', function(source)
    if Config.Pharmacy.requireNoEMS and GetEmsOnline() > 0 then
        return {}
    end
    return Config.PharmacyItems
end)

lib.callback.register('pharmacy-npc:server:purchaseItem', function(source, itemName, quantity)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false, 'No player' end
    if Config.Pharmacy.requireNoEMS and GetEmsOnline() > 0 then
        return false, 'EMS staff available. Visit a medic.'
    end
    local item = Config.PharmacyItems[itemName]
    if not item then return false, 'Invalid item' end
    quantity = tonumber(quantity) or 1
    if quantity < 1 or quantity > Config.Pharmacy.maxItemsPerPurchase then
        return false, 'Invalid quantity'
    end
    local cooldown = purchaseCooldowns[source]
    if cooldown and GetGameTimer() - cooldown < Config.Pharmacy.cooldown then
        return false, 'Please wait before purchasing again'
    end
    local totalPrice = item.price * quantity
    if player.PlayerData.money.cash < totalPrice then
        return false, 'Not enough cash'
    end
    player.Functions.RemoveMoney('cash', totalPrice)
    exports['ox_inventory']:AddItem(source, itemName, quantity)
    purchaseCooldowns[source] = GetGameTimer()
    return true, 'Purchased ' .. quantity .. 'x ' .. item.label .. ' for $' .. totalPrice
end)

lib.callback.register('pharmacy-npc:server:getEmsCount', function(source)
    return GetEmsOnline()
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[pharmacy-npc] Autonomous pharmacy NPC system active. %d locations.^7', #Config.PharmacyLocations)
end)
