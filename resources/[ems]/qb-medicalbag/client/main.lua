local spawnedBags = {}

RegisterNetEvent('qb-medicalbag:client:spawnBag', function(coords, heading, bagId)
    local model = GetHashKey(Config.MedicalBag.bagModel)
    RequestModel(model)
    local attempts = 0
    while not HasModelLoaded(model) and attempts < 100 do
        Citizen.Wait(10)
        attempts = attempts + 1
    end
    if not HasModelLoaded(model) then return end
    local bag = CreateObject(model, coords.x, coords.y, coords.z - 0.5, true, false, false)
    SetEntityHeading(bag, heading)
    PlaceObjectOnGroundProperly(bag)
    SetModelAsNoLongerNeeded(model)
    spawnedBags[bagId] = bag
    exports['ox_target']:addLocalEntity(bag, {
        {
            name = 'medbag_open_' .. bagId,
            label = 'Open Medical Bag',
            icon = 'fas fa-briefcase-medical',
            distance = 2.0,
            onSelect = function()
                TriggerServerEvent('qb-medicalbag:server:openBag', bagId)
            end
        },
        {
            name = 'medbag_pickup_' .. bagId,
            label = 'Pick Up',
            icon = 'fas fa-hand',
            distance = 2.0,
            onSelect = function()
                TriggerServerEvent('qb-medicalbag:server:pickupBag', bagId)
                if DoesEntityExist(bag) then DeleteEntity(bag) end
                spawnedBags[bagId] = nil
            end
        }
    })
end)

RegisterNetEvent('qb-medicalbag:client:removeBag', function(bagId)
    if spawnedBags[bagId] then
        if DoesEntityExist(spawnedBags[bagId]) then
            DeleteEntity(spawnedBags[bagId])
        end
        spawnedBags[bagId] = nil
    end
end)

RegisterNetEvent('qb-medicalbag:client:useBag', function()
    local progress = exports['ox_lib']:progressBar({
        duration = Config.MedicalBag.deployTime,
        label = 'Deploying medical bag...',
        useWhileDead = false,
        canCancel = true,
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true
    })
    if progress then
        TriggerServerEvent('qb-medicalbag:server:deployBag')
    end
end)

AddEventHandler('ox_inventory:itemUsed', function(itemName)
    if itemName == Config.MedicalBag.itemName then
        TriggerEvent('qb-medicalbag:client:useBag')
    end
end)

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    print('^2[qb-medicalbag] Client medical bag ready.^7')
end)
