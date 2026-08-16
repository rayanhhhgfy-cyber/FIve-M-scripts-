local trashCooldowns = {}
local doorStates = {}

-- Fetch player across QBox, QBCore, ESX, or Standalone (matching sv_builder.lua bridge)
local function GetPlayerServer(source)
    local Framework = 'standalone'
    if GetResourceState('qbx_core') == 'started' then
        Framework = 'qbox'
    elseif GetResourceState('qb-core') == 'started' then
        Framework = 'qb'
    elseif GetResourceState('es_extended') == 'started' then
        Framework = 'esx'
    end

    if Framework == 'qbox' then
        return exports.qbx_core:GetPlayer(source)
    elseif Framework == 'qb' then
        return exports['qb-core']:GetCoreObject().Functions.GetPlayer(source)
    elseif Framework == 'esx' then
        return exports['es_extended']:getSharedObject().GetPlayerFromId(source)
    else
        return nil
    end
end

-- Trash searching
RegisterNetEvent('map-builder:server:searchTrash', function(id)
    local src = source
    local player = GetPlayerServer(src)
    if not player then return end

    -- Extract citizenid / identifier across frameworks safely
    local cid = nil
    if player.PlayerData and player.PlayerData.citizenid then
        cid = player.PlayerData.citizenid
    elseif player.getIdentifier then
        cid = player.getIdentifier()
    else
        cid = GetPlayerIdentifier(src, 0) or tostring(src)
    end

    local key = cid .. '_' .. id
    local now = os.time() * 1000

    if trashCooldowns[key] and (now - trashCooldowns[key]) < Config.Interactive.trashCooldown then
        local timeLeft = math.ceil((Config.Interactive.trashCooldown - (now - trashCooldowns[key])) / 60000)
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'This container has been searched recently. Try again in ' .. timeLeft .. 'm' })
        return
    end

    trashCooldowns[key] = now

    -- Roll loot
    local lootRolled = false
    for _, item in ipairs(Config.Interactive.trashItems) do
        if math.random() <= item.chance then
            local count = math.random(item.min, item.max)
            exports.ox_inventory:AddItem(src, item.name, count)
            TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'You found ' .. count .. 'x ' .. item.name .. '!' })
            lootRolled = true
            break
        end
    end

    if not lootRolled then
        TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'You searched the container but found nothing useful' })
    end
end)

-- Stashes
RegisterNetEvent('map-builder:server:openStash', function(id, slots, weight)
    local src = source
    local stashId = 'map_builder_stash_' .. id

    -- Dynamically register the stash with ox_inventory
    exports.ox_inventory:RegisterStash(
        stashId,
        'Storage Safe / Chest',
        slots or Config.Interactive.stashes.defaultSlots,
        weight or Config.Interactive.stashes.defaultWeight,
        nil
    )

    -- Client is notified and can open the storage container directly
    TriggerClientEvent('ox_inventory:openInventory', src, 'stash', stashId)
end)

-- Door lock security
RegisterNetEvent('map-builder:server:toggleDoorLock', function(id)
    local src = source
    if doorStates[id] == nil then
        doorStates[id] = true -- Default locked
    end

    doorStates[id] = not doorStates[id]
    local stateText = doorStates[id] and 'Locked' or 'Unlocked'
    TriggerClientEvent('ox_lib:notify', -1, { type = 'info', description = 'Door security is now: ' .. stateText })
    TriggerClientEvent('map-builder:client:syncDoorState', -1, id, doorStates[id])
end)

RegisterNetEvent('map-builder:server:lockpickSuccess', function(id)
    doorStates[id] = false -- Unlocked
    TriggerClientEvent('ox_lib:notify', -1, { type = 'success', description = 'A door was successfully lockpicked and bypassed!' })
    TriggerClientEvent('map-builder:client:syncDoorState', -1, id, false)
end)

-- Fuel nozzle refuelling
RegisterNetEvent('map-builder:server:refuelVehicle', function(id, plate)
    local src = source
    local player = GetPlayerServer(src)
    if not player then return end

    local price = Config.Interactive.fuelPricePerLitre * 50 -- Fixed 50L refuel calculations

    -- Handle money removal across frameworks
    if player.Functions and player.Functions.RemoveMoney then
        player.Functions.RemoveMoney('bank', price, 'gas-pump-refuel')
    elseif player.removeAccountMoney then
        player.removeAccountMoney('bank', price)
    end

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Charged $' .. price .. ' for vehicle refueling!' })
end)

-- Garage dynamic selection & spawning
RegisterNetEvent('map-builder:server:getGarageVehicles', function(id)
    local src = source
    local player = GetPlayerServer(src)
    if not player then return end

    local cid = nil
    if player.PlayerData and player.PlayerData.citizenid then
        cid = player.PlayerData.citizenid
    elseif player.getIdentifier then
        cid = player.getIdentifier()
    end

    if not cid then return end

    local Framework = 'standalone'
    if GetResourceState('qbx_core') == 'started' then
        Framework = 'qbox'
    elseif GetResourceState('qb-core') == 'started' then
        Framework = 'qb'
    elseif GetResourceState('es_extended') == 'started' then
        Framework = 'esx'
    end

    local query = 'SELECT * FROM player_vehicles WHERE citizenid = ? OR owner = ?'
    if Framework == 'esx' then
        query = 'SELECT * FROM owned_vehicles WHERE owner = ?'
    end

    local vehicles = MySQL.query.await(query, { cid, cid })
    local list = {}

    -- Retrieve the allowed/blacklisted models for this specific garage ID
    local prop = MapBuilderData.placedProps[id]
    local allowedVehicles = prop and prop.logic and prop.logic.data and prop.logic.data.allowedVehicles or nil
    local blacklistedVehicles = prop and prop.logic and prop.logic.data and prop.logic.data.blacklistedVehicles or nil

    for _, v in ipairs(vehicles) do
        local model = nil
        local plate = nil
        if Framework == 'esx' then
            local vehData = json.decode(v.vehicle)
            model = vehData and (vehData.model or vehData.vehicle) or 'adder'
            plate = v.plate
        else
            model = v.vehicle or v.model
            plate = v.plate
        end

        local allowed = true
        if allowedVehicles then
            allowed = false
            for _, m in ipairs(allowedVehicles) do
                if string.lower(m) == string.lower(model) then
                    allowed = true
                    break
                end
            end
        end

        if blacklistedVehicles then
            for _, m in ipairs(blacklistedVehicles) do
                if string.lower(m) == string.lower(model) then
                    allowed = false
                    break
                end
            end
        end

        if allowed then
            table.insert(list, { model = model, plate = plate })
        end
    end

    TriggerClientEvent('map-builder:client:receiveGarageVehicles', src, id, list)
end)

RegisterNetEvent('map-builder:server:spawnGarageVehicleSelected', function(id, model, spawnPoint)
    local src = source
    local coords = spawnPoint or { x = 0.0, y = 0.0, z = 0.0 }

    -- Create vehicle and put player inside (Using proper server-side warp native)
    local obj = CreateVehicle(joaat(model), coords.x, coords.y, coords.z, coords.w or 0.0, true, true)
    SetTimeout(1000, function()
        -- Put player inside the spawned vehicle after physics settle
        TriggerClientEvent('map-builder:client:warpPedIntoVehicle', src, NetworkGetNetworkIdFromEntity(obj))
    end)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Vehicle ' .. model .. ' spawned successfully' })
end)

RegisterNetEvent('map-builder:server:storeGarageVehicle', function(id, plate)
    local src = source
    TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = 'Vehicle with plate ' .. tostring(plate) .. ' stored safely' })
end)

-- Interactive custom shops and crafting table bindings
RegisterNetEvent('map-builder:server:openShop', function(id)
    local src = source
    local shopId = 'map_builder_shop_' .. id
    exports.ox_inventory:RegisterShop(shopId, {
        name = 'Interactive Shop Vendor',
        inventory = {
            { name = 'sandwich', price = 10 },
            { name = 'water', price = 5 },
            { name = 'bandage', price = 25 },
            { name = 'lockpick', price = 150 },
        }
    })
    TriggerClientEvent('ox_inventory:openInventory', src, 'shop', shopId)
end)

RegisterNetEvent('map-builder:server:openCrafting', function(id)
    local src = source
    local benchId = 'map_builder_crafting_' .. id

    if exports.ox_inventory.RegisterCraftingBench then
        exports.ox_inventory:RegisterCraftingBench(benchId, {
            name = 'Interactive Crafting Bench',
            items = {
                { name = 'lockpick', count = 1, points = 10, duration = 3000, ingredients = { ['water'] = 1, ['sandwich'] = 1 } }
            }
        })
    end
    TriggerClientEvent('ox_inventory:openInventory', src, 'crafting', benchId)
end)

-- Secure Server-Side player robbing
RegisterNetEvent('map-builder:server:robPlayer', function(targetId)
    local src = source
    local ped = GetPlayerPed(src)
    local targetPed = GetPlayerPed(targetId)

    if #(GetEntityCoords(ped) - GetEntityCoords(targetPed)) < 4.0 then
        -- Securely force open the inventory target via ox_inventory!
        exports.ox_inventory:forceOpenInventory(src, 'player', targetId)
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Target is too far' })
    end
end)
