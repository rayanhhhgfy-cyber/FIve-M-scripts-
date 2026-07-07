local QBox = exports['qbx-core']:GetCoreObject()
local isPlacing = false
local isRemoving = false
local placeObject = nil
local placeModel = nil
local placeCoords = nil
local placeRotation = 0.0
local placeOffset = 3.0
local spawnedObjects = {}

local function isGod()
    return QBox.Functions.GetPlayerData().group == 'god'
end

RegisterNetEvent('place-anywhere:openMenu', function()
    if not isGod() then return end
    local items = {
        { title = 'Select & Place', icon = 'fas fa-arrows-alt', description = 'Choose a model and place it', onSelect = function() openModelPicker() end },
        { title = 'Remove Mode', icon = 'fas fa-trash-alt', description = 'Target a placed object to remove it', onSelect = function() enterRemoveMode() end },
        { title = 'Custom Model...', icon = 'fas fa-edit', description = 'Spawn any object model by name', onSelect = function()
            Wrappers.InputDialog({ title = 'Place Object', options = { { type = 'input', label = 'Model Name', placeholder = 'prop_roadcone02a' } }}, function(v)
                if v and v[1] then startPlacement(v[1]) end
            end)
        end },
    }
    Wrappers.ContextMenu({ id = 'place_menu', title = 'PLACE ANYWHERE', menuItems = items })
end)

function openModelPicker()
    local items = {}
    for _, m in ipairs(Config.PlaceAnywhere.quickModels) do
        table.insert(items, { title = m.label, icon = 'fas fa-cube', onSelect = function() startPlacement(m.model) end })
    end
    table.insert(items, { title = 'Custom...', icon = 'fas fa-edit', onSelect = function()
        Wrappers.InputDialog({ title = 'Object Model', options = { { type = 'input', placeholder = 'prop_roadcone02a' } }}, function(v)
            if v and v[1] then startPlacement(v[1]) end
        end)
    end })
    Wrappers.ContextMenu({ id = 'place_models', title = 'Select Object', menuItems = items })
end

function startPlacement(model)
    if not isGod() then return end
    if not Config.PlaceAnywhere.allowedModels and true then
        -- All models allowed if no whitelist restriction logic needed
    end
    isPlacing = true
    isRemoving = false
    placeModel = model
    placeRotation = 0.0
    Wrappers.Notify('Placement mode: WASD=move, Scroll=rotate, Enter=place, Backspace=cancel', 'info')
end

function enterRemoveMode()
    if not isGod() then return end
    isRemoving = true
    isPlacing = false
    Wrappers.Notify('Target a placed object to remove it, /place to exit', 'info')
    QBox.Functions.TriggerCallback('place-anywhere:getObjects', function(objects)
        if not objects or next(objects) == nil then
            Wrappers.Notify('No placed objects found', 'info')
            isRemoving = false
            return
        end
        local items = {}
        for id, obj in pairs(objects) do
            local coords = json.decode(obj.coords)
            table.insert(items, {
                title = obj.model,
                description = 'ID:' .. id .. ' @ ' .. math.floor(coords.x) .. ', ' .. math.floor(coords.y),
                onSelect = function()
                    TriggerServerEvent('place-anywhere:delete', id)
                end
            })
        end
        Wrappers.ContextMenu({ id = 'remove_objects', title = 'Remove Placed Object', menuItems = items })
    end)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isPlacing then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local camRot = GetGameplayCamRot(0)
            local _, _, z = table.unpack(camRot)
            local dx = -math.sin(z * math.pi / 180.0) * placeOffset
            local dy = math.cos(z * math.pi / 180.0) * placeOffset
            local targetPos = vector3(coords.x + dx, coords.y + dy, coords.z)

            if IsControlJustPressed(0, 96) then placeOffset = math.max(1.0, placeOffset - 0.5) end -- PageDown
            if IsControlJustPressed(0, 97) then placeOffset = math.min(10.0, placeOffset + 0.5) end -- PageUp
            if IsControlJustPressed(0, 15) then placeRotation = placeRotation - Config.PlaceAnywhere.rotateSpeed end -- Scroll?
            -- Use keys for rotate: Q and E
            if IsControlPressed(0, 44) then placeRotation = placeRotation - Config.PlaceAnywhere.rotateSpeed * 5.0 end -- Q
            if IsControlPressed(0, 38) then placeRotation = placeRotation + Config.PlaceAnywhere.rotateSpeed * 5.0 end -- E

            if not placeObject or not DoesEntityExist(placeObject) then
                RequestModel(placeModel)
                while not HasModelLoaded(placeModel) do Citizen.Wait(10) end
                placeObject = CreateObject(placeModel, targetPos.x, targetPos.y, targetPos.z, false, false, false)
                SetEntityAlpha(placeObject, 180, false)
                FreezeEntityPosition(placeObject, true)
                SetEntityCollision(placeObject, false, false)
            else
                SetEntityCoords(placeObject, targetPos.x, targetPos.y, targetPos.z)
                SetEntityHeading(placeObject, placeRotation)
            end

            -- Place (Enter)
            if IsControlJustPressed(0, 18) then
                local finalCoords = GetEntityCoords(placeObject)
                local finalHeading = GetEntityHeading(placeObject)
                if placeObject and DoesEntityExist(placeObject) then
                    local netId = ObjToNet(placeObject)
                    SetNetworkIdExistsOnAllMachines(netId, true)
                    SetEntityAlpha(placeObject, 255, false)
                    SetEntityCollision(placeObject, true, true)
                    FreezeEntityPosition(placeObject, true)
                end
                TriggerServerEvent('place-anywhere:save', {
                    model = placeModel,
                    coords = { x = finalCoords.x, y = finalCoords.y, z = finalCoords.z },
                    rotation = { x = 0.0, y = 0.0, z = finalHeading },
                })
                cancelPlacement()
            end

            -- Cancel (Backspace)
            if IsControlJustPressed(0, 106) then
                cancelPlacement()
                Wrappers.Notify('Placement cancelled', 'info')
            end
        end
    end
end)

function cancelPlacement()
    isPlacing = false
    if placeObject and DoesEntityExist(placeObject) then
        DeleteObject(placeObject)
    end
    placeObject = nil
    placeModel = nil
end

RegisterNetEvent('place-anywhere:spawnObject', function(id, model, coords, rotation)
    RequestModel(model)
    while not HasModelLoaded(model) do Citizen.Wait(10) end
    local obj = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(obj, rotation.z or 0.0)
    FreezeEntityPosition(obj, true)
    SetEntityCollision(obj, true, true)
    spawnedObjects[id] = obj
end)

RegisterNetEvent('place-anywhere:syncDelete', function(id)
    if spawnedObjects[id] and DoesEntityExist(spawnedObjects[id]) then
        DeleteObject(spawnedObjects[id])
    end
    spawnedObjects[id] = nil
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    cancelPlacement()
    for _, obj in pairs(spawnedObjects) do
        if DoesEntityExist(obj) then DeleteObject(obj) end
    end
end)
