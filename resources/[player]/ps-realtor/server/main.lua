local QBCore = exports['qbx_core']:GetCoreObject()
local activeListings = {}

local function GenerateListingId()
    return 'LST-' .. string.format('%06d', math.random(999999))
end

function CreateListing(citizenId, propertyId, price, description, listingType)
    local listingId = GenerateListingId()
    local expiresAt = os.time() * 1000 + Config.Realtor.listingDuration
    MySQL.insert.await(
        'INSERT INTO property_listings (listing_id, citizenid, property_id, price, description, listing_type, expires_at, is_active) VALUES (?, ?, ?, ?, ?, ?, ?, 1)',
        { listingId, citizenId, propertyId, price, description, listingType, expiresAt }
    )
    return listingId
end

local function GetActiveListings()
    local result = MySQL.query.await(
        'SELECT * FROM property_listings WHERE is_active = 1 AND expires_at > ? ORDER BY created_at DESC',
        { os.time() * 1000 }
    )
    return result or {}
end

local function GetListing(listingId)
    local result = MySQL.query.await('SELECT * FROM property_listings WHERE listing_id = ? LIMIT 1', { listingId })
    if result and #result > 0 then return result[1] end
    return nil
end

local function PurchaseProperty(source, listingId)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false, 'Not found' end
    local listing = GetListing(listingId)
    if not listing then return false, 'Listing not found' end
    if not listing.is_active then return false, 'Listing is no longer active' end
    if listing.expires_at < os.time() * 1000 then
        MySQL.update.await('UPDATE property_listings SET is_active = 0 WHERE listing_id = ?', { listingId })
        return false, 'Listing has expired'
    end
    if player.PlayerData.money.bank < listing.price then
        return false, 'Insufficient funds'
    end
    player.Functions.RemoveMoney('bank', listing.price)
    local sellerResult = MySQL.query.await('SELECT * FROM player_houses WHERE property_id = ? LIMIT 1', { listing.property_id })
    if sellerResult and #sellerResult > 0 then
        local seller = QBCore.Functions.GetPlayerByCitizenId(sellerResult[1].citizenid)
        if seller then
            local commission = math.floor(listing.price * Config.Realtor.commissionRate)
            local sellerPayout = listing.price - commission
            local sellerAccounts = exports['Renewed-Banking']:GetAccounts(sellerResult[1].citizenid)
            if #sellerAccounts > 0 then
                exports['Renewed-Banking']:Deposit(sellerAccounts[1].id, sellerPayout, 'Property sale: ' .. listing.property_id)
            end
            TriggerClientEvent('ox_lib:notify', seller.PlayerData.source, { type = 'info', description = 'Your property sold for $' .. listing.price })
        end
    end
    local buyerCitizenId = player.PlayerData.citizenid
    MySQL.update.await('UPDATE player_houses SET citizenid = ?, keys = ? WHERE property_id = ?',
        { buyerCitizenId, json.encode({ buyerCitizenId }), listing.property_id })
    MySQL.update.await('UPDATE property_listings SET is_active = 0, buyer_citizenid = ? WHERE listing_id = ?', { buyerCitizenId, listingId })
    return true, 'Property purchased!'
end

lib.callback.register('ps-realtor:server:getListings', function(source)
    return GetActiveListings()
end)

lib.callback.register('ps-realtor:server:createListing', function(source, propertyId, price, description, listingType)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false, 'Not found' end
    if player.PlayerData.money.cash < Config.Realtor.listingFee then
        return false, 'Listing fee required: $' .. Config.Realtor.listingFee
    end
    local typeConfig = Config.ListingTypes[listingType]
    if not typeConfig then return false, 'Invalid type' end
    if price < typeConfig.minPrice or price > typeConfig.maxPrice then
        return false, 'Price out of range for ' .. typeConfig.label
    end
    player.Functions.RemoveMoney('cash', Config.Realtor.listingFee)
    local listingId = CreateListing(player.PlayerData.citizenid, propertyId, price, description, listingType)
    return true, listingId
end)

lib.callback.register('ps-realtor:server:purchase', function(source, listingId)
    return PurchaseProperty(source, listingId)
end)

lib.callback.register('ps-realtor:server:cancelListing', function(source, listingId)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    local listing = GetListing(listingId)
    if not listing then return false end
    if listing.citizenid ~= player.PlayerData.citizenid then
        return false, 'Not your listing'
    end
    MySQL.update.await('UPDATE property_listings SET is_active = 0 WHERE listing_id = ?', { listingId })
    return true
end)

lib.callback.register('ps-realtor:server:getRealtorLocations', function(source)
    return Config.RealtorLocations
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[ps-realtor] Real estate system active.^7')
end)

exports('GetListings', GetActiveListings)
exports('CreateListing', CreateListing)
