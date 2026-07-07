local QBCore = exports['qbx_core']:GetCoreObject()

function SaveWardrobeOutfit(citizenId, outfitName, category, outfitData)
    local data = {
        name = outfitName,
        category = category or 'casual',
        data = outfitData,
        createdAt = os.time()
    }
    local result = MySQL.query.await(
        'SELECT JSON_EXTRACT(metadata, "$.wardrobe") as wardrobe FROM players WHERE citizenid = ? LIMIT 1',
        { citizenId }
    )
    local wardrobe = {}
    if result and #result > 0 and result[1].wardrobe then
        wardrobe = json.decode(result[1].wardrobe) or {}
    end
    if #wardrobe >= Config.Outfits.maxOutfits then
        return false, 'Wardrobe full'
    end
    table.insert(wardrobe, data)
    MySQL.update.await(
        'UPDATE players SET metadata = JSON_SET(COALESCE(metadata, "{}"), "$.wardrobe", CAST(? AS JSON)) WHERE citizenid = ?',
        { json.encode(wardrobe), citizenId }
    )
    return true, 'Outfit saved!'
end

function GetWardrobeOutfits(citizenId)
    local result = MySQL.query.await(
        'SELECT JSON_EXTRACT(metadata, "$.wardrobe") as wardrobe FROM players WHERE citizenid = ? LIMIT 1',
        { citizenId }
    )
    if result and #result > 0 and result[1].wardrobe then
        return json.decode(result[1].wardrobe) or {}
    end
    return {}
end

local function DeleteWardrobeOutfit(citizenId, index)
    local wardrobe = GetWardrobeOutfits(citizenId)
    if not wardrobe[index] then return false end
    table.remove(wardrobe, index)
    MySQL.update.await(
        'UPDATE players SET metadata = JSON_SET(COALESCE(metadata, "{}"), "$.wardrobe", CAST(? AS JSON)) WHERE citizenid = ?',
        { json.encode(wardrobe), citizenId }
    )
    return true
end

local function ApplyOutfitToPlayer(source, outfitData)
    if not outfitData or not outfitData.components then return false end
    TriggerClientEvent('linden-outfits:client:applyOutfit', source, outfitData.components)
    return true
end

lib.callback.register('linden-outfits:server:getOutfits', function(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return {} end
    return GetWardrobeOutfits(player.PlayerData.citizenid)
end)

lib.callback.register('linden-outfits:server:saveOutfit', function(source, outfitName, category, outfitData)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false, 'Not found' end
    return SaveWardrobeOutfit(player.PlayerData.citizenid, outfitName, category, outfitData)
end)

lib.callback.register('linden-outfits:server:deleteOutfit', function(source, index)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    return DeleteWardrobeOutfit(player.PlayerData.citizenid, tonumber(index))
end)

lib.callback.register('linden-outfits:server:applyOutfit', function(source, index)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    local wardrobe = GetWardrobeOutfits(player.PlayerData.citizenid)
    local outfit = wardrobe[tonumber(index)]
    if not outfit then return false end
    return ApplyOutfitToPlayer(source, outfit.data)
end)

lib.callback.register('linden-outfits:server:getCategories', function(source)
    return Config.OutfitCategories
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[linden-outfits] Wardrobe system initialized.^7')
end)

exports('GetWardrobeOutfits', GetWardrobeOutfits)
exports('SaveWardrobeOutfit', SaveWardrobeOutfit)
