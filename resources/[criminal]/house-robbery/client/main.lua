local QBox = exports['qbx-core']:GetCoreObject()
local insideHouse = nil
local isSearching = false
local lastRobbery = 0

local function canRob()
    local cur = os.time()
    if cur - lastRobbery < Config.HouseRobbery.Cooldown then Wrappers.Notify('Too soon for another job', 'error') return false end
    local police = QBox.Functions.GetPlayersFromJob('police')
    if #police < Config.HouseRobbery.MinPolice then Wrappers.Notify('Not enough police', 'error') return false end
    return true
end

local function hasLockpick()
    for item, _ in pairs(Config.HouseRobbery.RequiredItems) do
        if QBox.Functions.HasItem(item) then return item end
    end
    return nil
end

Citizen.CreateThread(function()
    for i, house in ipairs(Config.HouseRobbery.Houses) do
        exports.ox_target:addBoxZone({
            coords = house.coords, size = vec3(3.0, 3.0, 3.0), rotation = 0, debug = false,
            options = {{
                name = 'house_enter_' .. i,
                icon = Config.HouseRobbery.TargetOptions.enter.icon,
                label = Config.HouseRobbery.TargetOptions.enter.label,
                distance = Config.HouseRobbery.TargetOptions.enter.distance,
                canInteract = function() return not insideHouse end,
                onSelect = function() TriggerEvent('house:breakIn', i) end
            }, {
                name = 'house_search_' .. i,
                icon = Config.HouseRobbery.TargetOptions.search.icon,
                label = Config.HouseRobbery.TargetOptions.search.label,
                distance = Config.HouseRobbery.TargetOptions.search.distance,
                canInteract = function() return insideHouse == i and not isSearching end,
                onSelect = function() TriggerEvent('house:search', i) end
            }, {
                name = 'house_leave_' .. i,
                icon = Config.HouseRobbery.TargetOptions.leave.icon,
                label = Config.HouseRobbery.TargetOptions.leave.label,
                distance = Config.HouseRobbery.TargetOptions.leave.distance,
                canInteract = function() return insideHouse ~= nil end,
                onSelect = function() TriggerEvent('house:leave') end
            }}
        })
    end
end)

RegisterNetEvent('house:breakIn', function(id)
    if not canRob() then return end
    local lockpick = hasLockpick()
    if not lockpick then Wrappers.Notify('You need a lockpick', 'error') return end
    Wrappers.ProgressBar({ label = 'Picking lock...', duration = Config.HouseRobbery.LockpickTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('house:server:breakIn', id, lockpick)
    end)
end)

RegisterNetEvent('house:search', function(id)
    if isSearching then return end
    isSearching = true
    Wrappers.ProgressBar({ label = 'Searching house...', duration = Config.HouseRobbery.SearchTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then isSearching = false return end
        TriggerServerEvent('house:server:search', id)
    end)
end)

RegisterNetEvent('house:leave', function()
    if not insideHouse then return end
    Wrappers.ProgressBar({ label = 'Sneaking out...', duration = 3000, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('house:server:leave')
    end)
end)

RegisterNetEvent('house:client:breakIn', function(id)
    insideHouse = id
    Wrappers.Notify('You broke into the house', 'success')
end)

RegisterNetEvent('house:client:searchResult', function(data)
    isSearching = false
    local msg = 'Found $' .. data.cash
    if data.items and #data.items > 0 then msg = msg .. ' and items' end
    Wrappers.Notify(msg, 'success')
end)

RegisterNetEvent('house:client:leave', function()
    insideHouse = nil
    lastRobbery = os.time()
    Wrappers.Notify('You left the house', 'info')
end)

RegisterNetEvent('house:client:policeAlert', function(street)
    Wrappers.Notify('Burglary reported on ' .. street, 'warning')
end)
