local QBCore = exports['qbx_core']:GetCoreObject()
local currentSkin = nil

local function OpenClothingMenu(storeName)
    local skin = lib.callback.await('illenium-appearance:server:getSkin', false)
    if not skin then skin = { components = {}, props = {} } end
    currentSkin = skin
    local options = {}
    for catId, cat in pairs(Config.ClothingCategories) do
        table.insert(options, {
            title = cat.label,
            icon = 'fas fa-tshirt',
            onSelect = function()
                local compId = cat.componentId
                local currentDrawable = 0
                local currentTexture = 0
                if skin.components then
                    for _, comp in ipairs(skin.components) do
                        if comp.componentId == tonumber(compId) or comp.componentId == compId then
                            currentDrawable = comp.drawable or 0
                            currentTexture = comp.texture or 0
                            break
                        end
                    end
                end
                local input = lib.inputDialog(cat.label .. ' Customization', {
                    { type = 'number', label = 'Drawable ID', value = currentDrawable, min = 0, max = 200 },
                    { type = 'number', label = 'Texture ID', value = currentTexture, min = 0, max = 50 },
                    { type = 'number', label = 'Palette', value = 0, min = 0, max = 10 }
                })
                if input then
                    TriggerServerEvent('illenium-appearance:server:updateClothing', tonumber(compId) or compId, tonumber(input[1]), tonumber(input[2]), tonumber(input[3]))
                    SetPedComponentVariation(PlayerPedId(), tonumber(compId) or compId, tonumber(input[1]), tonumber(input[2]), tonumber(input[3]))
                    Wrappers.Notify({ type = 'success', description = cat.label .. ' updated' })
                end
            end
        })
    end
    table.insert(options, {
        title = 'Save Outfit',
        icon = 'fas fa-save',
        onSelect = function()
            local input = lib.inputDialog('Save Outfit', {
                { type = 'input', label = 'Outfit Name', placeholder = 'Casual Style', required = true, max = 50 }
            })
            if input then
                local currentOutfit = { components = {}, props = {} }
                for catId, cat in pairs(Config.ClothingCategories) do
                    local compId = cat.componentId
                    if type(compId) == 'number' then
                        local drawable = GetPedDrawableVariation(PlayerPedId(), compId)
                        local texture = GetPedTextureVariation(PlayerPedId(), compId)
                        table.insert(currentOutfit.components, { componentId = compId, drawable = drawable, texture = texture, palette = 0 })
                    end
                end
                local success, msg = lib.callback.await('illenium-appearance:server:saveOutfit', false, input[1], currentOutfit)
                Wrappers.Notify({ type = success and 'success' or 'error', description = msg or 'Outfit saved!' })
            end
        end
    })
    table.insert(options, {
        title = 'Load Outfit',
        icon = 'fas fa-folder-open',
        onSelect = function()
            local outfits = lib.callback.await('illenium-appearance:server:getOutfits', false)
            local outfitOptions = {}
            for i, outfit in ipairs(outfits or {}) do
                table.insert(outfitOptions, {
                    title = outfit.name,
                    description = 'Saved ' .. os.date('%m/%d/%Y', outfit.createdAt),
                    onSelect = function()
                        if outfit.data and outfit.data.components then
                            for _, comp in ipairs(outfit.data.components) do
                                SetPedComponentVariation(PlayerPedId(), comp.componentId, comp.drawable, comp.texture, comp.palette or 0)
                            end
                            Wrappers.Notify({ type = 'success', description = 'Outfit loaded' })
                        end
                    end
                })
            end
            if #outfitOptions == 0 then
                table.insert(outfitOptions, { title = 'No saved outfits', readOnly = true })
            end
            lib.registerContext({
                id = 'load_outfit_menu',
                title = 'Load Outfit',
                options = outfitOptions
            })
            lib.showContext('load_outfit_menu')
        end
    })
    lib.registerContext({
        id = 'clothing_menu',
        title = storeName or 'Clothing Store',
        options = options
    })
    lib.showContext('clothing_menu')
end

local function OpenBarberMenu()
    local input = lib.inputDialog('Barber Shop', {
        { type = 'select', label = 'Style', options = {
            { value = 'hair', label = 'Hairstyle' },
            { value = 'beard', label = 'Beard' },
            { value = 'eyebrows', label = 'Eyebrows' },
            { value = 'makeup', label = 'Makeup' }
        }, default = 'hair' },
        { type = 'number', label = 'Style ID', value = 0, min = 0, max = 200 },
        { type = 'number', label = 'Color', value = 0, min = 0, max = 100 },
        { type = 'number', label = 'Highlight Color', value = 0, min = 0, max = 100 }
    })
    if input then
        local hairOverlays = {
            hair = 2, beard = 5, eyebrows = 4, makeup = 9
        }
        local overlayId = hairOverlays[input[1]]
        if overlayId then
            SetPedHeadOverlay(PlayerPedId(), overlayId, tonumber(input[2]), 1.0)
            SetPedHeadOverlayColor(PlayerPedId(), overlayId, 1, tonumber(input[3]), tonumber(input[4]))
            Wrappers.Notify({ type = 'success', description = 'Style updated' })
        end
    end
end

local function OpenTattooMenu()
    local input = lib.inputDialog('Tattoo Parlor', {
        { type = 'number', label = 'Tattoo Slot', value = 0, min = 0, max = 50 },
        { type = 'number', label = 'Tattoo Index', value = 0, min = 0, max = 300 },
        { type = 'input', label = 'Tattoo Collection', value = 'mpAirRace_Tattoos', required = true }
    })
    if input then
        local collection = GetHashKey(input[3])
        local tattoo = GetHashKey('tattoo_' .. input[2] .. '_' .. input[2])
        ClearPedDecorations(PlayerPedId())
        AddPedDecorationFromHashes(PlayerPedId(), collection, tattoo)
        Wrappers.Notify({ type = 'success', description = 'Tattoo applied' })
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for _, store in ipairs(Config.ClothingStores) do
            local dist = #(coords - vector3(store.coords.x, store.coords.y, store.coords.z))
            if dist < 5.0 then
                exports['ox_target']:addLocalEntity(ped, {
                    {
                        name = 'clothing_' .. store.name,
                        label = 'Open Clothing Store',
                        icon = 'fas fa-tshirt',
                        distance = 2.0,
                        onSelect = function()
                            OpenClothingMenu(store.name)
                        end
                    }
                })
            end
        end
        for _, barber in ipairs(Config.Barbers) do
            local dist = #(coords - vector3(barber.coords.x, barber.coords.y, barber.coords.z))
            if dist < 5.0 then
                exports['ox_target']:addLocalEntity(ped, {
                    {
                        name = 'barber_' .. barber.name,
                        label = 'Open Barber Shop',
                        icon = 'fas fa-cut',
                        distance = 2.0,
                        onSelect = function()
                            OpenBarberMenu()
                        end
                    }
                })
            end
        end
        for _, tatt in ipairs(Config.TattooParlors) do
            local dist = #(coords - vector3(tatt.coords.x, tatt.coords.y, tatt.coords.z))
            if dist < 5.0 then
                exports['ox_target']:addLocalEntity(ped, {
                    {
                        name = 'tattoo_' .. tatt.name,
                        label = 'Tattoo Parlor',
                        icon = 'fas fa-paint-brush',
                        distance = 2.0,
                        onSelect = function()
                            OpenTattooMenu()
                        end
                    }
                })
            end
        end
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[illenium-appearance] Client appearance system ready.^7')
end)

exports('OpenClothing', OpenClothingMenu)
exports('OpenBarber', OpenBarberMenu)
