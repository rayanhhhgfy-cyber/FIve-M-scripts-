local QBox = exports['qbx-core']:GetCoreObject()
local isRobbing = false
local robbedRegisters = {}
local lastRobbery = 0

local function hasItem(item) return QBox.Functions.HasItem(item) end

local function canRob()
    local cur = os.time()
    if cur - lastRobbery < Config.StoreRobbery.Cooldown then Wrappers.Notify('Store is on high alert', 'error') return false end
    local police = QBox.Functions.GetPlayersFromJob('police')
    if #police < Config.StoreRobbery.MinPolice then Wrappers.Notify('Not enough police', 'error') return false end
    if not hasItem(Config.StoreRobbery.RequiredItem) then Wrappers.Notify('You need a lockpick', 'error') return false end
    return true
end

Citizen.CreateThread(function()
    for i, loc in ipairs(Config.StoreRobbery.Locations) do
        local hasRegister = loc.registerId ~= nil
        if hasRegister then
            exports.ox_target:addBoxZone({
                coords = loc.coords, size = vec3(1.5, 1.5, 2.0), rotation = 0, debug = false,
                options = {{
                    name = 'store_register_' .. i,
                    icon = Config.StoreRobbery.TargetOptions.register.icon,
                    label = Config.StoreRobbery.TargetOptions.register.label,
                    distance = Config.StoreRobbery.TargetOptions.register.distance,
                    canInteract = function() return not robbedRegisters[i] end,
                    onSelect = function() TriggerEvent('store:robRegister', i) end
                }}
            })
        end
        exports.ox_target:addBoxZone({
            coords = loc.coords, size = vec3(2.0, 2.0, 2.0), rotation = 0, debug = false,
            options = {{
                name = 'store_shelf_' .. i,
                icon = Config.StoreRobbery.TargetOptions.shelf.icon,
                label = Config.StoreRobbery.TargetOptions.shelf.label,
                distance = Config.StoreRobbery.TargetOptions.shelf.distance,
                onSelect = function() TriggerEvent('store:searchShelf', i) end
            }}
        })
    end
end)

RegisterNetEvent('store:robRegister', function(id)
    if isRobbing or not canRob() then return end
    isRobbing = true
    Wrappers.ProgressBar({ label = 'Robbing register...', duration = Config.StoreRobbery.LootTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then isRobbing = false return end
        TriggerServerEvent('store:server:robRegister', id)
    end)
end)

RegisterNetEvent('store:searchShelf', function(id)
    if isRobbing or not canRob() then return end
    isRobbing = true
    Wrappers.ProgressBar({ label = 'Searching shelves...', duration = Config.StoreRobbery.LootTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then isRobbing = false return end
        TriggerServerEvent('store:server:searchShelf', id)
    end)
end)

RegisterNetEvent('store:client:robberyResult', function(data)
    isRobbing = false
    lastRobbery = os.time()
    if data.registerId then robbedRegisters[data.registerId] = true end
    Wrappers.Notify('You got $' .. data.cash .. ' and some items', 'success')
end)

RegisterNetEvent('store:client:searchResult', function(data)
    isRobbing = false
    Wrappers.Notify('You found some items', 'success')
end)

RegisterNetEvent('store:client:policeAlert', function(street)
    Wrappers.Notify('Store robbery reported on ' .. street, 'warning')
end)
