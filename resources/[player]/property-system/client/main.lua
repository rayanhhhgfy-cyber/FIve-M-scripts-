local QBox = exports['qbx-core']:GetCoreObject()

RegisterNetEvent('property:client:openMenu', function()
    QBox.Functions.TriggerCallback('property:server:list', function(properties)
        if not properties then return end
        local items = {}
        for _, p in ipairs(properties) do
            table.insert(items, {
                title = p.label,
                description = '$' .. p.price .. ' | ' .. p.type .. ' | ' .. p.garage.slots .. ' car garage',
                icon = 'fas fa-home',
                onSelect = function()
                    local actions = {
                        { title = 'Buy $' .. p.price, icon = 'fas fa-shopping-cart', onSelect = function() TriggerServerEvent('property:server:buy', p.id) end },
                        { title = 'Sell (60% refund)', icon = 'fas fa-dollar-sign', onSelect = function() TriggerServerEvent('property:server:sell', p.id) end },
                        { title = 'Visit', icon = 'fas fa-walking', onSelect = function()
                            SetEntityCoords(PlayerPedId(), p.interior[1], p.interior[2], p.interior[3])
                            SetEntityHeading(PlayerPedId(), 0.0)
                        end},
                    }
                    Wrappers.ContextMenu({ id = 'property_' .. p.id, title = p.label, menuItems = actions })
                end,
            })
        end
        Wrappers.ContextMenu({ id = 'property_list', title = 'Properties', menuItems = items })
    end)
end)

Citizen.CreateThread(function()
    while not QBox.Functions.GetPlayerData().citizenid do Citizen.Wait(100) end
    for _, p in ipairs(Config.Properties.properties) do
        exports.ox_target:addBoxZone({
            coords = p.coords,
            size = vector3(1.5, 1.5, 2.5),
            rotation = 0,
            options = {
                {
                    name = 'property_' .. p.id,
                    icon = 'fas fa-door-open',
                    label = p.label,
                    distance = 3.0,
                    onSelect = function()
                        local owned = false
                        QBox.Functions.TriggerCallback('property:server:getOwner', function(owner)
                            if owner == QBox.Functions.GetPlayerData().citizenid then
                                local actions = {
                                    { title = 'Enter', icon = 'fas fa-sign-in-alt', onSelect = function()
                                        SetEntityCoords(PlayerPedId(), p.interior[1], p.interior[2], p.interior[3])
                                    end},
                                    { title = 'Garage (' .. p.garage.slots .. ' slots)', icon = 'fas fa-warehouse', onSelect = function()
                                        Wrappers.Notify('Opening garage...', 'info')
                                    end},
                                    { title = 'Sell Property', icon = 'fas fa-dollar-sign', onSelect = function()
                                        TriggerServerEvent('property:server:sell', p.id)
                                    end},
                                }
                                Wrappers.ContextMenu({ id = 'property_owned_' .. p.id, title = p.label, menuItems = actions })
                            else
                                local actions = {
                                    { title = 'Buy $' .. p.price, icon = 'fas fa-shopping-cart', onSelect = function() TriggerServerEvent('property:server:buy', p.id) end },
                                }
                                Wrappers.ContextMenu({ id = 'property_for_sale_' .. p.id, title = p.label, menuItems = actions })
                            end
                        end, p.id)
                    end,
                },
            },
        })
    end
end)
