local QBCore = exports['qbx_core']:GetCoreObject()

function SaveSkin(citizenId, skinData)
    local skinJson = type(skinData) == 'table' and json.encode(skinData) or skinData
    MySQL.update.await(
        'UPDATE players SET metadata = JSON_SET(COALESCE(metadata, "{}"), "$.skin", CAST(? AS JSON)) WHERE citizenid = ?',
        { skinJson, citizenId }
    )
end

function GetSkin(citizenId)
    local result = MySQL.query.await(
        'SELECT JSON_EXTRACT(metadata, "$.skin") as skin FROM players WHERE citizenid = ? LIMIT 1',
        { citizenId }
    )
    if result and #result > 0 and result[1].skin then
        local skin = json.decode(result[1].skin)
        return skin
    end
    return nil
end

function SaveOutfit(citizenId, outfitName, outfitData)
    local outfitJson = type(outfitData) == 'table' and json.encode(outfitData) or outfitData
    local result = MySQL.query.await(
        'SELECT JSON_EXTRACT(metadata, "$.outfits") as outfits FROM players WHERE citizenid = ? LIMIT 1',
        { citizenId }
    )
    local outfits = {}
    if result and #result > 0 and result[1].outfits then
        outfits = json.decode(result[1].outfits) or {}
    end
    if #outfits >= Config.Appearance.maxOutfits then
        return false, 'Max outfits reached'
    end
    table.insert(outfits, { name = outfitName, data = outfitData, createdAt = os.time() })
    MySQL.update.await(
        'UPDATE players SET metadata = JSON_SET(COALESCE(metadata, "{}"), "$.outfits", CAST(? AS JSON)) WHERE citizenid = ?',
        { json.encode(outfits), citizenId }
    )
    return true
end

function GetOutfits(citizenId)
    local result = MySQL.query.await(
        'SELECT JSON_EXTRACT(metadata, "$.outfits") as outfits FROM players WHERE citizenid = ? LIMIT 1',
        { citizenId }
    )
    if result and #result > 0 and result[1].outfits then
        return json.decode(result[1].outfits) or {}
    end
    return {}
end

local function DeleteOutfit(citizenId, outfitIndex)
    local outfits = GetOutfits(citizenId)
    if not outfits[outfitIndex] then return false end
    table.remove(outfits, outfitIndex)
    MySQL.update.await(
        'UPDATE players SET metadata = JSON_SET(COALESCE(metadata, "{}"), "$.outfits", CAST(? AS JSON)) WHERE citizenid = ?',
        { json.encode(outfits), citizenId }
    )
    return true
end

lib.callback.register('illenium-appearance:server:getSkin', function(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return nil end
    return GetSkin(player.PlayerData.citizenid)
end)

lib.callback.register('illenium-appearance:server:saveSkin', function(source, skinData)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    SaveSkin(player.PlayerData.citizenid, skinData)
    return true
end)

lib.callback.register('illenium-appearance:server:getOutfits', function(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return {} end
    return GetOutfits(player.PlayerData.citizenid)
end)

lib.callback.register('illenium-appearance:server:saveOutfit', function(source, outfitName, outfitData)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false, 'Not found' end
    return SaveOutfit(player.PlayerData.citizenid, outfitName, outfitData)
end)

lib.callback.register('illenium-appearance:server:deleteOutfit', function(source, outfitIndex)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    return DeleteOutfit(player.PlayerData.citizenid, tonumber(outfitIndex))
end)

lib.callback.register('illenium-appearance:server:getClothingStores', function(source)
    return Config.ClothingStores
end)

lib.callback.register('illenium-appearance:server:getBarbers', function(source)
    return Config.Barbers
end)

RegisterNetEvent('illenium-appearance:server:updateClothing', function(componentId, drawable, texture, palette)
    local source = source
    if not source then return end
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    local skin = GetSkin(player.PlayerData.citizenid) or {}
    if not skin.components then skin.components = {} end
    local found = false
    for _, comp in ipairs(skin.components) do
        if comp.componentId == componentId then
            comp.drawable = drawable
            comp.texture = texture
            comp.palette = palette
            found = true
            break
        end
    end
    if not found then
        table.insert(skin.components, { componentId = componentId, drawable = drawable, texture = texture, palette = palette })
    end
    SaveSkin(player.PlayerData.citizenid, skin)
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[illenium-appearance] Appearance system initialized. %d stores, %d barbers, %d tattoo parlors.^7',
        #Config.ClothingStores, #Config.Barbers, #Config.TattooParlors)
end)

exports('SaveSkin', SaveSkin)
exports('GetSkin', GetSkin)
exports('GetOutfits', GetOutfits)
exports('SaveOutfit', SaveOutfit)
