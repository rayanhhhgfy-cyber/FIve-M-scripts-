local QBCore = exports['qbx_core']:GetCoreObject()

CreateThread(function()
    for _, machine in ipairs(Config.Vending.machines) do
        exports['ox_target']:addModel(machine.model, {
            {
                name = 'vending_machine_buy',
                label = Locale('vending.vending_machine'),
                icon = 'fas fa-shopping-cart',
                distance = Config.Vending.maxDistance,
                onSelect = function(data)
                    local entity = data.entity
                    if not entity then return end
                    local modelHash = GetEntityModel(entity)
                    local options = {}
                    for _, item in ipairs(machine.items) do
                        options[#options + 1] = {
                            title = item.label .. ' - $' .. item.price,
                            onSelect = function()
                                if Config.Vending.useAnim then
                                    local dict = 'mp_common'
                                    Wrappers.RequestAnimDict(dict)
                                    local ped = PlayerPedId()
                                    TaskPlayAnim(ped, dict, 'givetake1_a', 8.0, -8.0, 1500, 16, 0, false, false, false)
                                end
                                TriggerServerEvent('vending:machineBuy', modelHash, item.name)
                            end,
                        }
                    end
                    Wrappers.ContextMenu({
                        id = 'vending_menu',
                        title = Locale('vending.select_item'),
                        options = options,
                    })
                    Wrappers.ShowContextMenu('vending_menu')
                end,
            },
        })
    end
end)
