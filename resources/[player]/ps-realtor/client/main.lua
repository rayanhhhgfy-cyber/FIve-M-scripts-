local QBCore = exports['qbx_core']:GetCoreObject()

local function OpenRealtorMenu()
    local listings = lib.callback.await('ps-realtor:server:getListings', false)
    local options = {}
    for _, listing in ipairs(listings) do
        table.insert(options, {
            title = string.format('%s — $%s', listing.property_id, exports['ox_lib']:FormatNumber(listing.price)),
            description = listing.description or 'No description',
            icon = 'fas fa-home',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = 'Purchase Property',
                    content = string.format('Buy %s for $%s?\n%s', listing.property_id, exports['ox_lib']:FormatNumber(listing.price), listing.description or ''),
                    centered = true,
                    cancel = true,
                    labels = { confirm = 'Purchase', cancel = 'Cancel' }
                })
                if alert == 'confirm' then
                    local success, msg = lib.callback.await('ps-realtor:server:purchase', false, listing.listing_id)
                    Wrappers.Notify({ type = success and 'success' or 'error', description = msg or 'Purchase complete' })
                end
            end
        })
    end
    table.insert(options, {
        title = 'List Your Property',
        icon = 'fas fa-tag',
        onSelect = function()
            local houses = lib.callback.await('ps-housing:server:getHouses', false)
            if #houses == 0 then
                Wrappers.Notify({ type = 'error', description = 'You do not own any properties' })
                return
            end
            local houseOptions = {}
            for _, house in ipairs(houses) do
                table.insert(houseOptions, { value = house.property_id, label = house.label .. ' (' .. house.property_id .. ')' })
            end
            local input = lib.inputDialog('List Property', {
                { type = 'select', label = 'Property', options = houseOptions },
                { type = 'number', label = 'Price', placeholder = '100000', required = true, min = 10000 },
                { type = 'textarea', label = 'Description', placeholder = 'Beautiful property...', required = false },
                { type = 'select', label = 'Type', options = {
                    { value = 'house', label = 'House' },
                    { value = 'apartment', label = 'Apartment' },
                    { value = 'commercial', label = 'Commercial' }
                }, default = 'house' }
            })
            if input then
                local success, msg = lib.callback.await('ps-realtor:server:createListing', false, input[1], tonumber(input[2]), input[3] or '', input[4])
                Wrappers.Notify({ type = success and 'success' or 'error', description = msg or 'Listed!' })
            end
        end
    })
    lib.registerContext({
        id = 'realtor_menu',
        title = 'Real Estate',
        options = options
    })
    lib.showContext('realtor_menu')
end

RegisterNetEvent('ps-realtor:client:openMenu', function()
    OpenRealtorMenu()
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for _, loc in ipairs(Config.RealtorLocations) do
            local dist = #(coords - vector3(loc.coords.x, loc.coords.y, loc.coords.z))
            if dist < 2.0 then
                exports['ox_target']:addLocalEntity(ped, {
                    {
                        name = 'realtor_' .. loc.name,
                        label = 'Open Real Estate',
                        icon = 'fas fa-building',
                        distance = 2.0,
                        onSelect = function()
                            OpenRealtorMenu()
                        end
                    }
                })
            end
        end
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[ps-realtor] Client ready.^7')
end)

exports('OpenRealtor', OpenRealtorMenu)
