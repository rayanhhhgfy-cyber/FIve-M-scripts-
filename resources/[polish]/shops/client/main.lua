local QBCore = exports['qbx_core']:GetCoreObject()

CreateThread(function()
    for _, shop in ipairs(Config.Shops) do
        local options = {}
        for _, product in ipairs(shop.products) do
            options[#options + 1] = {
                title = product.label .. ' - $' .. product.price,
                onSelect = function()
                    local input = Wrappers.InputDialog({
                        title = Locale('shops.select_quantity'),
                        options = {
                            { type = 'number', label = Locale('shops.product'), placeholder = '1', required = true, min = 1, max = 100 },
                        },
                    })
                    if input then
                        TriggerServerEvent('shop:buy', shop.name, product.name, tonumber(input[1]))
                    end
                end,
            }
        end
        exports['ox_target']:addBoxZone({
            coords = shop.coords,
            size = vector3(2.0, 2.0, 2.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'shop_menu_' .. shop.name,
                    label = shop.label,
                    icon = 'fas fa-store',
                    onSelect = function()
                        Wrappers.ContextMenu({
                            id = 'shop_menu_' .. shop.name,
                            title = shop.label,
                            options = options,
                        })
                        Wrappers.ShowContextMenu('shop_menu_' .. shop.name)
                    end,
                },
            },
        })
    end
end)
