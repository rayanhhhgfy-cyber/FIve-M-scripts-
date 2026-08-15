local QBox = exports['qbx_core']:GetCoreObject()

CreateThread(function()
    for _, shop in ipairs(Config.Shops or {}) do
        exports.ox_target:addBoxZone({
            coords = shop.coords,
            size = vector3(2, 2, 2),
            options = {
                {
                    label = 'Buy ' .. shop.label .. ' ($' .. shop.price .. ')',
                    icon = 'fas fa-shopping-cart',
                    onSelect = function()
                        TriggerServerEvent('shop-ownership:server:buyShop', shop.shop_id)
                    end
                }
            }
        })
    end
end)
