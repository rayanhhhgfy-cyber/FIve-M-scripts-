local outfitPanelOpen = false

RegisterCommand(Config.OutfitManager.OpenCommand, function()
    if outfitPanelOpen then
        SetNuiFocus(false, false)
        outfitPanelOpen = false
        return
    end

    local outfits = lib.callback.await('outfit-manager:server:getOutfits', false)
    if not outfits then outfits = {} end

    SendNUIMessage({
        action = 'open',
        outfits = outfits,
        maxOutfits = Config.OutfitManager.MaxOutfits,
    })

    SetNuiFocus(true, true)
    outfitPanelOpen = true
end, false)

RegisterKeyMapping(Config.OutfitManager.OpenCommand, 'Open Outfit Manager', 'keyboard', Config.OutfitManager.Keybind)

--- Capture current outfit data
local function captureCurrentOutfit()
    local components = {}
    for _, cat in pairs(exports['illenium-appearance']:GetCategories() or {}) do
        local compId = cat.componentId
        if type(compId) == 'number' then
            local drawable = GetPedDrawableVariation(PlayerPedId(), compId)
            local texture = GetPedTextureVariation(PlayerPedId(), compId)
            table.insert(components, { componentId = compId, drawable = drawable, texture = texture, palette = 0 })
        end
    end

    local props = {}
    for i = 0, 4 do
        if GetPedPropIndex(PlayerPedId(), i) ~= -1 then
            table.insert(props, { propId = i, drawable = GetPedPropIndex(PlayerPedId(), i), texture = GetPedPropTextureIndex(PlayerPedId(), i) })
        end
    end

    return { components = components, props = props }
end

--- NUI Callbacks
RegisterNUICallback('saveOutfit', function(data, cb)
    local name = data.name
    if not name or name == '' then cb({ success = false, msg = 'Name required' }) return end

    local outfitData = captureCurrentOutfit()
    local success, msg = lib.callback.await('outfit-manager:server:saveOutfit', false, name, outfitData)

    if success then
        local outfits = lib.callback.await('outfit-manager:server:getOutfits', false)
        cb({ success = true, outfits = outfits or {} })
    else
        cb({ success = false, msg = msg or 'Failed to save' })
    end
end)

RegisterNUICallback('loadOutfit', function(data, cb)
    local outfitIndex = tonumber(data.index)
    if not outfitIndex then cb({ success = false }) return end

    local outfits = lib.callback.await('outfit-manager:server:getOutfits', false)
    if not outfits or not outfits[outfitIndex] then cb({ success = false }) return end

    local outfit = outfits[outfitIndex]
    if outfit.data and outfit.data.components then
        for _, comp in ipairs(outfit.data.components) do
            SetPedComponentVariation(PlayerPedId(), comp.componentId, comp.drawable, comp.texture, comp.palette or 0)
        end
    end
    if outfit.data and outfit.data.props then
        for _, prop in ipairs(outfit.data.props) do
            SetPedPropIndex(PlayerPedId(), prop.propId, prop.drawable, prop.texture, true)
        end
    end

    cb({ success = true, name = outfit.name })
end)

RegisterNUICallback('deleteOutfit', function(data, cb)
    local outfitIndex = tonumber(data.index)
    if not outfitIndex then cb({ success = false }) return end

    local success = lib.callback.await('outfit-manager:server:deleteOutfit', false, outfitIndex)
    local outfits = lib.callback.await('outfit-manager:server:getOutfits', false)
    cb({ success = success, outfits = outfits or {} })
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    outfitPanelOpen = false
    cb({})
end)

--- Close on ESC
RegisterNUICallback('escape', function(_, cb)
    SetNuiFocus(false, false)
    outfitPanelOpen = false
    cb({})
end)
