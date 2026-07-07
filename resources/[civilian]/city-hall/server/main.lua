local QBox = exports['qbx-core']:GetCoreObject()

--- Issue ID card
lib.callback.register('cityhall:server:requestID', function(source)
    local player = QBox.Functions.GetPlayer(source)
    if not player then return false, 'Not found' end

    local citizenid = player.PlayerData.citizenid
    local price = Config.CityHall.Prices.idCard

    -- Check if player already has an ID card
    local itemCount = exports.ox_inventory:Search(source, 'count', 'identification')
    if itemCount and itemCount > 0 then
        return false, 'You already have your ID card'
    end

    -- Check funds
    if player.PlayerData.money.cash < price then
        return false, string.format('You need $%s cash', price)
    end

    -- Charge
    player.Functions.RemoveMoney('cash', price)

    -- Issue ID card
    local charinfo = player.PlayerData.charinfo or {}
    local firstname = charinfo.firstname or 'Unknown'
    local lastname = charinfo.lastname or ''
    local birthdate = charinfo.birthdate or 'Unknown'

    exports.ox_inventory:AddItem(source, 'identification', 1, {
        label = ('%s %s'):format(firstname, lastname),
        description = string.format('DOB: %s | CID: %s', birthdate, citizenid),
        info = {
            firstname = firstname,
            lastname = lastname,
            cid = citizenid,
            dob = birthdate,
            issued = os.date('%Y-%m-%d'),
        },
    })

    return true, string.format('ID card issued — $%s charged', price)
end)

--- Issue bank card
lib.callback.register('cityhall:server:requestBankCard', function(source)
    local player = QBox.Functions.GetPlayer(source)
    if not player then return false, 'Not found' end

    local price = Config.CityHall.Prices.bankCard

    -- Check if already has card
    local itemCount = exports.ox_inventory:Search(source, 'count', 'mastercard')
    if itemCount and itemCount > 0 then
        return false, 'You already have a bank card'
    end

    if player.PlayerData.money.cash < price then
        return false, string.format('You need $%s cash', price)
    end

    player.Functions.RemoveMoney('cash', price)
    exports.ox_inventory:AddItem(source, 'mastercard', 1)

    return true, string.format('Bank card issued — $%s charged', price)
end)
