local QBCore = exports['qbx-core']:GetCoreObject()
local activeShift = false
local currentRestaurant = nil

local function getPlayerJob()
    local Player = QBCore.Functions.GetPlayerData()
    return Player.job.name
end

local function startShift(restaurant)
    if activeShift then
        Wrappers.Notify(Locale('restaurant_jobs.shift_complete'), 'error')
        return
    end
    TriggerServerEvent('restaurant:startShift', { restaurant = restaurant.name })
    activeShift = true
    currentRestaurant = restaurant
    Wrappers.Notify(Locale('restaurant_jobs.start_shift'), 'success')
end

local function cookItem(restaurant)
    if not activeShift or currentRestaurant ~= restaurant then
        Wrappers.Notify(Locale('restaurant_jobs.need_job'), 'error')
        return
    end
    local options = {}
    for _, item in ipairs(restaurant.menu) do
        table.insert(options, {
            title = item.label,
            description = Locale('restaurant_jobs.cook') .. ' - $' .. item.price,
            onSelect = function()
                Wrappers.ProgressBar({
                    duration = item.time,
                    label = Locale('restaurant_jobs.cooking'),
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                    anim = { dict = 'amb@prop_human_bbq@male@idle_a', clip = 'idle_b' },
                }, function(cancelled)
                    if cancelled then
                        Wrappers.Notify(Locale('restaurant_jobs.food_burned'), 'error')
                        return
                    end
                    Wrappers.SkillCheck({ 'easy', 'medium' }, function(success)
                        if success then
                            TriggerServerEvent('restaurant:cookItem', { restaurant = restaurant.name, menuItem = item.name })
                            Wrappers.Notify(Locale('restaurant_jobs.food_perfect'), 'success')
                        else
                            Wrappers.Notify(Locale('restaurant_jobs.food_burned'), 'error')
                        end
                    end)
                end)
            end,
        })
    end
    Wrappers.ContextMenu({
        id = 'restaurant_cook_' .. restaurant.name,
        title = restaurant.label .. ' - ' .. Locale('restaurant_jobs.cook'),
        options = options,
    })
end

local function checkOrders(restaurant)
    if not activeShift or currentRestaurant ~= restaurant then
        Wrappers.Notify(Locale('restaurant_jobs.need_job'), 'error')
        return
    end
    local orderText = ''
    for _, item in ipairs(restaurant.menu) do
        orderText = orderText .. item.label .. ' - $' .. item.price .. '\n'
    end
    Wrappers.TextUI(orderText)
    Wait(5000)
    Wrappers.HideTextUI()
end

local function serveCustomer(restaurant)
    if not activeShift or currentRestaurant ~= restaurant then
        Wrappers.Notify(Locale('restaurant_jobs.need_job'), 'error')
        return
    end
    local options = {}
    for _, item in ipairs(restaurant.menu) do
        table.insert(options, {
            title = item.label,
            description = '$' .. item.price,
            onSelect = function()
                TriggerServerEvent('restaurant:serveCustomer', { restaurant = restaurant.name, menuItem = item.name })
            end,
        })
    end
    table.insert(options, {
        title = Locale('restaurant_jobs.shift_complete'),
        description = '',
        onSelect = function()
            local totalSales = #restaurant.menu * restaurant.payment
            TriggerServerEvent('restaurant:completeShift', { restaurant = restaurant.name, totalSales = totalSales })
            activeShift = false
            currentRestaurant = nil
        end,
    })
    Wrappers.ContextMenu({
        id = 'restaurant_serve_' .. restaurant.name,
        title = restaurant.label .. ' - ' .. Locale('restaurant_jobs.serve'),
        options = options,
    })
end

CreateThread(function()
    for _, restaurant in ipairs(Config.Restaurants) do
        exports.ox_target:addBoxZone({
            coords = restaurant.stations.register,
            size = vec3(1.5, 1.5, 1.5),
            rotation = 0,
            options = {
                {
                    name = restaurant.name .. '_register',
                    label = Locale('restaurant_jobs.start_shift'),
                    icon = 'fas fa-cash-register',
                    onSelect = function()
                        startShift(restaurant)
                    end,
                },
            },
        })
        exports.ox_target:addBoxZone({
            coords = restaurant.stations.grill,
            size = vec3(1.5, 1.5, 1.5),
            rotation = 0,
            options = {
                {
                    name = restaurant.name .. '_grill',
                    label = Locale('restaurant_jobs.cook'),
                    icon = 'fas fa-fire',
                    onSelect = function()
                        cookItem(restaurant)
                    end,
                },
            },
        })
        exports.ox_target:addBoxZone({
            coords = restaurant.stations.prep,
            size = vec3(1.5, 1.5, 1.5),
            rotation = 0,
            options = {
                {
                    name = restaurant.name .. '_prep',
                    label = Locale('restaurant_jobs.check_order'),
                    icon = 'fas fa-clipboard-list',
                    onSelect = function()
                        checkOrders(restaurant)
                    end,
                },
            },
        })
        exports.ox_target:addBoxZone({
            coords = restaurant.stations.counter,
            size = vec3(1.5, 1.5, 1.5),
            rotation = 0,
            options = {
                {
                    name = restaurant.name .. '_counter',
                    label = Locale('restaurant_jobs.serve'),
                    icon = 'fas fa-hand-holding-usd',
                    onSelect = function()
                        serveCustomer(restaurant)
                    end,
                },
            },
        })
    end
end)
