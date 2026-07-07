local QBCore = exports['qbx-core']:GetCoreObject()
local oxygenLevel = -1
local oxygenActive = false

local function setupDiveTargets()
    for idx, loc in ipairs(Config.Diving.locations) do
        local model = GetHashKey('prop_beach_dip_b')
        RequestModel(model)
        local attempts = 0
        while not HasModelLoaded(model) and attempts < 50 do
            Wait(10)
            attempts = attempts + 1
        end

        local obj = GetClosestObjectOfType(loc.x, loc.y, loc.z, 2.0, model, false, false, false)
        if obj == 0 then
            obj = CreateObject(model, loc.x, loc.y, loc.z - 1.0, false, false, false)
            FreezeEntityPosition(obj, true)
            SetEntityAsMissionEntity(obj, true, true)
        end

        if DoesEntityExist(obj) then
            exports.ox_target:addLocalEntity(obj, {
                {
                    name = 'diving_search_' .. idx,
                    label = Locale('diving.search'),
                    icon = 'fa-solid fa-water',
                    onSelect = function()
                        Wrappers.ProgressBar({
                            duration = Config.Diving.searchTime,
                            label = Locale('diving.search'),
                            useWhileDead = false,
                            canCancel = true,
                            disable = { move = true, car = true, combat = true },
                            anim = { dict = 'amb@world_human_bum_wash@male@high@idle_a', clip = 'idle_a' },
                            prop = {},
                        }, function(cancelled)
                            if not cancelled then
                                TriggerServerEvent('diving:searchTreasure')
                            end
                        end)
                    end,
                },
                {
                    name = 'diving_equip_' .. idx,
                    label = Locale('diving.gear_equipped'),
                    icon = 'fa-solid fa-scuba',
                    onSelect = function()
                        TriggerServerEvent('diving:equipGear')
                        oxygenActive = true
                    end,
                },
                {
                    name = 'diving_surface_' .. idx,
                    label = Locale('diving.surfaced'),
                    icon = 'fa-solid fa-arrow-up',
                    onSelect = function()
                        TriggerServerEvent('diving:surface')
                        oxygenActive = false
                        oxygenLevel = -1
                    end,
                },
            })
        end
    end
end

local function setupSellTarget()
    local sellLoc = Config.Diving.sellLocation
    local model = GetHashKey('prop_boat_01a')
    RequestModel(model)
    local attempts = 0
    while not HasModelLoaded(model) and attempts < 50 do
        Wait(10)
        attempts = attempts + 1
    end

    local obj = GetClosestObjectOfType(sellLoc.x, sellLoc.y, sellLoc.z, 3.0, model, false, false, false)
    if obj == 0 then
        obj = CreateObject(model, sellLoc.x, sellLoc.y, sellLoc.z, false, false, false)
        FreezeEntityPosition(obj, true)
        SetEntityAsMissionEntity(obj, true, true)
    end

    if DoesEntityExist(obj) then
        exports.ox_target:addLocalEntity(obj, {
            {
                name = 'diving_sell',
                label = Locale('diving.sell_treasure'),
                icon = 'fa-solid fa-sack-dollar',
                onSelect = function()
                    local treasureOptions = {}
                    for _, t in ipairs(Config.Diving.treasure) do
                        table.insert(treasureOptions, {
                            title = t.label .. ' - $' .. t.price,
                            description = Locale('diving.sell_treasure'),
                            onSelect = function()
                                TriggerServerEvent('diving:sellTreasure', t.name)
                            end,
                        })
                    end
                    Wrappers.ContextMenu({
                        id = 'diving_sell_menu',
                        title = Locale('diving.sell_treasure'),
                        options = treasureOptions,
                    })
                end,
            },
        })
    end
end

RegisterNetEvent('diving:oxygenUpdate', function(oxygen)
    oxygenLevel = oxygen
    if oxygen < 0 then
        oxygenActive = false
    else
        oxygenActive = true
    end
end)

RegisterNetEvent('diving:lowOxygen', function()
    oxygenActive = false
    oxygenLevel = -1
    Wrappers.Notify(Locale('diving.low_oxygen'), 'error')
end)

RegisterNetEvent('diving:treasureFound', function(treasure)
    Wrappers.Notify(Locale('diving.found_item', treasure.label), 'success')
end)

CreateThread(function()
    while true do
        Wait(1000)
        if oxygenActive and oxygenLevel >= 0 then
            if oxygenLevel <= 20 then
                Wrappers.TextUI(Locale('diving.low_oxygen') .. ': ' .. oxygenLevel .. 's')
            else
                Wrappers.TextUI(Locale('diving.search') .. ' | O2: ' .. oxygenLevel .. 's')
            end
        end
    end
end)

CreateThread(function()
    setupDiveTargets()
    setupSellTarget()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        Wrappers.HideTextUI()
    end
end)
