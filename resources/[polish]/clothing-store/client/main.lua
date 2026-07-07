local QBox = exports['qbx-core']:GetCoreObject()

CreateThread(function()
    for _, loc in ipairs(Config.Clothing.locations) do
        local zone = BoxZone:new({ coords = loc, size = vector3(2.0, 2.0, 2.0), rotation = 0, debug = false })
        exports.ox_target:addBoxZone({
            coords = loc,
            size = vector3(2.0, 2.0, 2.0),
            rotation = 0,
            options = {
                {
                    name = 'clothing_open',
                    label = Locale('clothing_store.open'),
                    icon = 'fas fa-tshirt',
                    onSelect = function()
                        TriggerServerEvent('clothing:openStore')
                    end,
                },
            },
        })
    end
end)

RegisterNetEvent('clothing:openUI', function()
    local options = {
        { title = Locale('clothing_store.open'), onSelect = function()
            exports['illenium-appearance']:openMenu()
        end },
        { title = Locale('clothing_store.save_outfit'), onSelect = function()
            local input = Wrappers.InputDialog({ title = Locale('clothing_store.save_outfit'), label = Locale('clothing_store.outfit_name'), placeholder = 'Outfit Name', type = 'input' })
            if input then TriggerServerEvent('clothing:saveOutfit', input) end
        end },
        { title = Locale('clothing_store.load_outfit'), onSelect = function()
            local input = Wrappers.InputDialog({ title = Locale('clothing_store.load_outfit'), label = Locale('clothing_store.outfit_name'), placeholder = 'Outfit Name', type = 'input' })
            if input then TriggerServerEvent('clothing:loadOutfit', input) end
        end },
    }
    Wrappers.ContextMenu({ id = 'clothing_store', title = Locale('clothing_store.open'), options = options })
end)

RegisterNetEvent('clothing:applyOutfit', function(outfit)
    local ped = PlayerPedId()
    if outfit.model ~= GetEntityModel(ped) then
        SetPedDefaultOutfit(ped)
    end
    if outfit.drawables then
        for i = 0, 11 do
            if outfit.drawables[i] then
                SetPedComponentEnabled(ped, i, outfit.drawables[i].drawable, outfit.drawables[i].texture, outfit.drawables[i].palette or 0)
            end
        end
    end
    if outfit.props then
        for i = 0, 4 do
            if outfit.props[i] then
                SetPedPropIndex(ped, i, outfit.props[i].drawable, outfit.props[i].texture, true)
            end
        end
    end
    Wrappers.Notify(Locale('clothing_store.load_outfit'), 'success')
end)
