local placedBag = nil

RegisterNetEvent('linden-outfitbag:client:spawnBag', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local model = GetHashKey(Config.BagModels[math.random(#Config.BagModels)])
    RequestModel(model)
    local attempts = 0
    while not HasModelLoaded(model) and attempts < 100 do
        Citizen.Wait(10)
        attempts = attempts + 1
    end
    if not HasModelLoaded(model) then return end
    local bag = CreateObject(model, coords.x, coords.y - 1.0, coords.z - 0.5, true, false, false)
    SetEntityHeading(bag, heading)
    SetModelAsNoLongerNeeded(model)
    PlaceObjectOnGroundProperly(bag)
    placedBag = bag
    exports['ox_target']:addLocalEntity(bag, {
        {
            name = 'outfit_bag_open',
            label = 'Open Outfit Bag',
            icon = 'fas fa-suitcase',
            distance = 2.0,
            onSelect = function()
                TriggerEvent('ox_inventory:openInventory', 'stash', 'outfitbag_' .. NetworkGetNetworkIdFromEntity(bag))
            end
        },
        {
            name = 'outfit_bag_pickup',
            label = 'Pick Up',
            icon = 'fas fa-hand',
            distance = 2.0,
            onSelect = function()
                exports['ox_inventory']:AddItem(PlayerPedId(), Config.OutfitBag.itemName, 1)
                DeleteEntity(bag)
                placedBag = nil
            end
        }
    })
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[linden-outfitbag] Client ready.^7')
end)

exports('GetPlacedBag', function() return placedBag end)
