local QBCore = exports['qbx-core']:GetCoreObject()

local function orderDrink(location)
    local options = {}
    for _, drink in ipairs(Config.CoffeeShop.drinks) do
        table.insert(options, {
            title = drink.label,
            description = '$' .. drink.price .. ' (' .. drink.caffeine .. Locale('coffee_shop.select_drink') .. ')',
            onSelect = function()
                Wrappers.ProgressBar({
                    duration = 3000,
                    label = Locale('coffee_shop.brew'),
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                    anim = { dict = 'amb@world_human_coffee@male@idle_a', clip = 'idle_c' },
                }, function(cancelled)
                    if cancelled then
                        Wrappers.Notify(Locale('error.cancelled'), 'error')
                        return
                    end
                    TriggerServerEvent('coffee:orderDrink', { drink = drink.name })
                end)
            end,
        })
    end
    Wrappers.ContextMenu({
        id = 'coffee_order_' .. location.label,
        title = location.label .. ' - ' .. Locale('coffee_shop.select_drink'),
        options = options,
    })
end

CreateThread(function()
    for _, location in ipairs(Config.CoffeeShop.locations) do
        exports.ox_target:addBoxZone({
            coords = location.takeCoords,
            size = vec3(1.2, 1.2, 1.5),
            rotation = 0,
            options = {
                {
                    name = 'coffee_order_' .. location.label,
                    label = Locale('coffee_shop.select_drink'),
                    icon = 'fas fa-coffee',
                    onSelect = function()
                        orderDrink(location)
                    end,
                },
            },
        })
    end
end)
