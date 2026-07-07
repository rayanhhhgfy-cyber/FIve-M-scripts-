local QBCore = exports['qbx_core']:GetCoreObject()
local occupiedBeds = {}

function IsBedOccupied(bedName)
    return occupiedBeds[bedName] ~= nil
end

function OccupyBed(bedName, source)
    if IsBedOccupied(bedName) then return false end
    occupiedBeds[bedName] = source
    return true
end

function ReleaseBed(bedName)
    occupiedBeds[bedName] = nil
end

local function FindAvailableBed(receptionBeds)
    for _, bedName in ipairs(receptionBeds) do
        if not IsBedOccupied(bedName) then
            return bedName
        end
    end
    return nil
end

lib.callback.register('rcore-medical:server:getBeds', function(source)
    return Config.BedLocations
end)

lib.callback.register('rcore-medical:server:occupyBed', function(source, bedName)
    return OccupyBed(bedName, source)
end)

lib.callback.register('rcore-medical:server:releaseBed', function(source, bedName)
    ReleaseBed(bedName)
    return true
end)

lib.callback.register('rcore-medical:server:healOnBed', function(source, bedName)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    local success = OccupyBed(bedName, source)
    if not success then return false, 'Bed occupied' end
    exports['wasabi-ambulance']:HealPlayer(source)
    exports['wasabi-ambulance']:RevivePlayer(source, 'hospital_bed')
    SetTimeout(Config.MedicalBeds.healTime, function()
        ReleaseBed(bedName)
    end)
    return true, 'Healing...'
end)

lib.callback.register('rcore-medical:server:receptionCheckIn', function(source, receptionName)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false, 'Player not found' end

    local reception = nil
    for _, loc in ipairs(Config.Reception.locations) do
        if loc.name == receptionName then reception = loc end
    end
    if not reception then return false, 'Invalid reception' end

    local cash = player.PlayerData.money.cash
    if cash < Config.Reception.checkInPrice then
        return false, 'Not enough cash ($' .. Config.Reception.checkInPrice .. ' required)'
    end

    local bedName = FindAvailableBed(reception.spawnBeds)
    if not bedName then
        return false, 'No beds available'
    end

    OccupyBed(bedName, source)
    player.Functions.RemoveMoney('cash', Config.Reception.checkInPrice, 'hospital_checkin')
    exports['wasabi-ambulance']:HealPlayer(source)
    exports['wasabi-ambulance']:RevivePlayer(source, 'hospital_bed')

    SetTimeout(Config.MedicalBeds.healTime, function()
        ReleaseBed(bedName)
    end)

    return true, bedName
end)

lib.callback.register('rcore-medical:server:startIV', function(source)
    local hasBag = exports['ox_inventory']:Search(source, 'count', Config.IV.ivBagItem)
    if not hasBag or hasBag < 1 then return false, 'No IV bag' end
    exports['ox_inventory']:RemoveItem(source, Config.IV.ivBagItem, 1)
    TriggerClientEvent('rcore-medical:client:startIV', source)
    return true
end)

lib.callback.register('rcore-medical:server:applyIV', function(source, target)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    if player.PlayerData.job.name ~= 'ambulance' then return false end
    local hasBag = exports['ox_inventory']:Search(source, 'count', Config.IV.ivBagItem)
    if not hasBag or hasBag < 1 then return false, 'No IV bag' end
    exports['ox_inventory']:RemoveItem(source, Config.IV.ivBagItem, 1)
    TriggerClientEvent('rcore-medical:client:applyIV', target)
    return true
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[rcore-medical] Hospital bed system initialized. %d beds mapped, %d reception locations.^7', #Config.BedLocations, #Config.Reception.locations)
end)

exports('IsBedOccupied', IsBedOccupied)
exports('OccupyBed', OccupyBed)
exports('ReleaseBed', ReleaseBed)
