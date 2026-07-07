local QBox = exports['qbx-core']:GetCoreObject()

Citizen.CreateThread(function()
    for i, loc in ipairs(Config.BlackMarket.Locations) do
        exports.ox_target:addBoxZone({
            coords = loc.coords, size = vec3(loc.radius * 2, loc.radius * 2, 2.0), rotation = 0, debug = false,
            options = {{
                name = 'blackmarket_' .. i,
                icon = Config.BlackMarket.TargetOptions.browse.icon,
                label = loc.label,
                distance = Config.BlackMarket.TargetOptions.browse.distance,
                onSelect = function() TriggerEvent('blackmarket:open', i) end
            }}
        })
    end
end)

RegisterNetEvent('blackmarket:open', function(locId)
    local loc = Config.BlackMarket.Locations[locId]
    if not loc then return end
    TriggerServerEvent('blackmarket:server:getStock', locId)
end)

RegisterNetEvent('blackmarket:client:showStock', function(locId, stock)
    local items = {}
    for _, s in ipairs(stock or {}) do
        if s.stock > 0 then
            table.insert(items, { title = s.label .. ' ($' .. s.price .. ')', description = Locale('phone.stock_remaining', s.stock), onSelect = function()
                Wrappers.InputDialog({ title = s.label, inputs = {
                    { type = 'number', label = Locale('phone.quantity'), name = 'qty', default = 1, min = 1, max = s.stock }
                }}, function(v)
                    if v then TriggerServerEvent('blackmarket:server:purchase', locId, s.item, tonumber(v.qty), s.price) end
                end)
            end})
        end
    end
    if #items == 0 then table.insert(items, { title = Locale('phone.out_of_stock'), description = '' }) end
    Wrappers.ContextMenu({ id = 'blackmarket_items', title = Locale('phone.black_market'), menuItems = items })
end)
