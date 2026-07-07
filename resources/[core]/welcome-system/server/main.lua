local QBCore = exports['qbx_core']:GetCoreObject()
local joinedPlayers = {}
local firstJoin = {}

local function HasPlayerJoinedBefore(license)
    if firstJoin[license] ~= nil then return true end
    local result = MySQL.query.await('SELECT COUNT(*) as count FROM players WHERE license = ?', { license })
    if result and #result > 0 and result[1].count > 0 then
        firstJoin[license] = true
        return true
    end
    return false
end

function GiveStarterKit(source)
    if not Config.StarterKit.enabled then return end
    for _, item in ipairs(Config.StarterKit.items) do
        exports['ox_inventory']:AddItem(source, item.name, item.count, nil, item.slot, item.metadata)
    end
    if Config.StarterKit.money.cash > 0 then
        local player = QBCore.Functions.GetPlayer(source)
        if player then
            player.Functions.AddMoney('cash', Config.StarterKit.money.cash)
            player.Functions.AddMoney('bank', Config.StarterKit.money.bank)
        end
    end
end

RegisterNetEvent('welcome-system:server:playerSpawned')
AddEventHandler('welcome-system:server:playerSpawned', function()
    local source = source
    if not source then return end
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    local license = GetPlayerIdentifierByType(source, 'license')
    if not license then return end
    if joinedPlayers[source] then return end
    joinedPlayers[source] = true
    local isNewPlayer = not HasPlayerJoinedBefore(license)
    if isNewPlayer then
        firstJoin[license] = true
        GiveStarterKit(source)
        TriggerClientEvent('welcome-system:client:showWelcome', source, true, player.PlayerData.charinfo.firstname)
    else
        TriggerClientEvent('welcome-system:client:showWelcome', source, false, player.PlayerData.charinfo.firstname)
    end
end)

RegisterNetEvent('welcome-system:server:acceptRules')
AddEventHandler('welcome-system:server:acceptRules', function()
    local source = source
    if not source then return end
    TriggerClientEvent('welcome-system:client:welcomeComplete', source)
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    joinedPlayers[source] = nil
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[welcome-system] Welcome system ready.^7')
end)

exports('GiveStarterKit', GiveStarterKit)
exports('SetFirstJoin', function(license) firstJoin[license] = true end)
