local QBCore = exports['qbx_core']:GetCoreObject()

RegisterNetEvent('tattoo:client:openShop', function()
    Wrappers.ContextMenu({
        id = 'tattoo_shop_menu',
        title = Locale('tattoo_shop.select_tattoo'),
        options = {
            {
                title = Locale('tattoo_shop.open'),
                description = Locale('tattoo_shop.cost') .. ': $' .. Config.Tattoo.pricePerTattoo,
                onSelect = function()
                    TriggerEvent('illenium-appearance:client:openTattooShop')
                end,
            },
        },
    })
    Wrappers.ShowContextMenu('tattoo_shop_menu')
end)

CreateThread(function()
    for _, loc in ipairs(Config.Tattoo.locations) do
        exports['ox_target']:addBoxZone({
            coords = loc,
            size = vector3(1.5, 1.5, 2.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'tattoo_shop_open',
                    label = Locale('tattoo_shop.open'),
                    icon = 'fas fa-tattoo',
                    onSelect = function()
                        TriggerServerEvent('tattoo:openShop')
                    end,
                },
            },
        })
    end
end)
