local QBCore = exports['qbx_core']:GetCoreObject()

function OpenWardrobe()
    local outfits = lib.callback.await('linden-outfits:server:getOutfits', false)
    local categories = lib.callback.await('linden-outfits:server:getCategories', false)
    local options = {}
    for i, outfit in ipairs(outfits) do
        local cat = categories[outfit.category]
        local catIcon = cat and cat.icon or 'fas fa-tshirt'
        table.insert(options, {
            title = outfit.name,
            description = 'Category: ' .. (cat and cat.label or outfit.category),
            icon = catIcon,
            onSelect = function()
                local action = lib.inputDialog('Outfit: ' .. outfit.name, {
                    { type = 'select', label = 'Action', options = {
                        { value = 'apply', label = 'Wear Outfit' },
                        { value = 'delete', label = 'Delete' }
                    }, default = 'apply' }
                })
                if action and action[1] == 'apply' then
                    local success = lib.callback.await('linden-outfits:server:applyOutfit', false, i)
                    Wrappers.Notify({ type = success and 'success' or 'error', description = success and 'Outfit applied' or 'Failed' })
                elseif action and action[1] == 'delete' then
                    local success = lib.callback.await('linden-outfits:server:deleteOutfit', false, i)
                    Wrappers.Notify({ type = success and 'success' or 'error', description = success and 'Outfit deleted' or 'Failed' })
                end
            end
        })
    end
    table.insert(options, {
        title = 'Save Current Outfit',
        icon = 'fas fa-save',
        onSelect = function()
            local catOptions = {}
            for catId, cat in pairs(categories) do
                table.insert(catOptions, { value = catId, label = cat.label })
            end
            local input = lib.inputDialog('Save Outfit', {
                { type = 'input', label = 'Outfit Name', placeholder = 'Casual Style', required = true },
                { type = 'select', label = 'Category', options = catOptions, default = 'casual' }
            })
            if input then
                local currentOutfit = { components = {} }
                for compId = 0, 11 do
                    local drawable = GetPedDrawableVariation(PlayerPedId(), compId)
                    local texture = GetPedTextureVariation(PlayerPedId(), compId)
                    table.insert(currentOutfit.components, { componentId = compId, drawable = drawable, texture = texture, palette = 0 })
                end
                local success, msg = lib.callback.await('linden-outfits:server:saveOutfit', false, input[1], input[2], currentOutfit)
                Wrappers.Notify({ type = success and 'success' or 'error', description = msg })
            end
        end
    })
    lib.registerContext({
        id = 'wardrobe_menu',
        title = 'Wardrobe',
        options = options
    })
    lib.showContext('wardrobe_menu')
end

RegisterNetEvent('linden-outfits:client:openWardrobe', function()
    OpenWardrobe()
end)

RegisterNetEvent('linden-outfits:client:applyOutfit', function(components)
    for _, comp in ipairs(components) do
        SetPedComponentVariation(PlayerPedId(), comp.componentId, comp.drawable, comp.texture, comp.palette or 0)
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[linden-outfits] Client wardrobe ready.^7')
end)

exports('OpenWardrobe', OpenWardrobe)
