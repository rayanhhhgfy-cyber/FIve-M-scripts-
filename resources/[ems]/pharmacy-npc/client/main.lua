local QBCore = exports['qbx_core']:GetCoreObject()

local function OpenPharmacy(locationName)
    local emsCount = lib.callback.await('pharmacy-npc:server:getEmsCount', false)
    if Config.Pharmacy.requireNoEMS and emsCount > 0 then
        Wrappers.Notify({ type = 'info', description = 'EMS staff are online. Visit them for medical supplies.', duration = 5000 })
        return
    end
    local items = lib.callback.await('pharmacy-npc:server:getItems', false)
    if not items or next(items) == nil then
        Wrappers.Notify({ type = 'info', description = 'Pharmacy is currently closed.' })
        return
    end
    local options = {}
    for itemName, item in pairs(items) do
        table.insert(options, {
            title = item.label .. ' — $' .. item.price,
            description = 'Stock: ' .. item.stock,
            icon = 'fas fa-capsules',
            onSelect = function()
                local input = lib.inputDialog('Purchase ' .. item.label, {
                    { type = 'number', label = 'Quantity', value = 1, min = 1, max = Config.Pharmacy.maxItemsPerPurchase }
                })
                if input then
                    local success, msg = lib.callback.await('pharmacy-npc:server:purchaseItem', false, itemName, tonumber(input[1]))
                    Wrappers.Notify({ type = success and 'success' or 'error', description = msg })
                end
            end
        })
    end
    lib.registerContext({
        id = 'pharmacy_menu_' .. locationName,
        title = 'Pharmacy',
        options = options
    })
    lib.showContext('pharmacy_menu_' .. locationName)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for _, loc in ipairs(Config.PharmacyLocations) do
            local dist = #(coords - vector3(loc.coords.x, loc.coords.y, loc.coords.z))
            if dist < 3.0 then
                exports['ox_target']:addLocalEntity(ped, {
                    {
                        name = 'pharmacy_' .. loc.name,
                        label = 'Open Pharmacy',
                        icon = 'fas fa-prescription-bottle',
                        distance = 2.0,
                        onSelect = function()
                            OpenPharmacy(loc.name)
                        end
                    }
                })
            end
        end
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[pharmacy-npc] Client pharmacy NPC ready.^7')
end)
