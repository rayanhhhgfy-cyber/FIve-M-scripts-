local inHouse = false
local currentHouseId = nil
local furnitureMode = false
local selectedFurniture = nil
local placedFurniture = {}

local function getInteriorCoords(houseId)
    local house = nil
    for _, h in ipairs(Config.AdvancedHousing.properties) do
        if h.id == houseId then house = h; break end
    end
    if not house then return nil end
    return Config.AdvancedHousing.interiorCoords[house.interior]
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    CreatePropertyTargets()
end)

function CreatePropertyTargets()
    for _, house in ipairs(Config.AdvancedHousing.properties) do
        exports['ox_target']:addBoxZone({
            coords = house.coords,
            size = vector3(2.0, 2.0, 2.0),
            rotation = 0,
            debug = false,
            options = {
                { label = 'Enter ' .. house.name, icon = 'fas fa-door-open', onSelect = function() EnterProperty(house.id) end },
                { label = 'Buy $' .. house.price, icon = 'fas fa-dollar-sign', onSelect = function()
                    QBox.Functions.TriggerCallback('housing:hasAccess', function(owned)
                        if owned then
                            Wrappers.Notify('You already own this property', 'info')
                        else
                            TriggerServerEvent('housing:buy', house.id)
                        end
                    end, house.id)
                end },
                { label = 'Sell', icon = 'fas fa-hand-holding-usd', onSelect = function()
                    TriggerServerEvent('housing:sell', house.id)
                end },
            },
        })
    end
end

function EnterProperty(houseId)
    if inHouse then
        ExitProperty()
        return
    end
    QBox.Functions.TriggerCallback('housing:hasAccess', function(access)
        if access then
            local interior = getInteriorCoords(houseId)
            if interior then
                currentHouseId = houseId
                inHouse = true
                DoScreenFadeOut(500)
                Citizen.Wait(500)
                SetEntityCoords(PlayerPedId(), interior.enter)
                SetEntityHeading(PlayerPedId(), 0.0)
                DoScreenFadeIn(500)
                CreateInteriorTargets(houseId)
                LoadPlacedFurniture(houseId)
                Wrappers.Notify('Press O for house options', 'info')
            end
        else
            Wrappers.Notify('You don\'t have access', 'error')
        end
    end, houseId)
end

function ExitProperty()
    if not currentHouseId then return end
    local house = nil
    for _, h in ipairs(Config.AdvancedHousing.properties) do
        if h.id == currentHouseId then house = h; break end
    end
    if house then
        DoScreenFadeOut(500)
        Citizen.Wait(500)
        SetEntityCoords(PlayerPedId(), house.coords)
        SetEntityHeading(PlayerPedId(), 0.0)
        DoScreenFadeIn(500)
    end
    inHouse = false
    currentHouseId = nil
    ClearAllPedProps(PlayerPedId())
end

function CreateInteriorTargets(houseId)
    local interior = getInteriorCoords(houseId)
    if not interior then return end
    exports['ox_target']:addBoxZone({
        coords = interior.exit,
        size = vector3(1.0, 1.0, 2.0),
        rotation = 0,
        debug = false,
        options = {
            { label = 'Exit', icon = 'fas fa-door-closed', onSelect = function() ExitProperty() end },
        },
    })
    exports['ox_target']:addBoxZone({
        coords = interior.enter + vector3(0.0, 0.0, 1.0),
        size = vector3(1.0, 1.0, 1.0),
        rotation = 0,
        debug = false,
        options = {
            { label = 'House Options', icon = 'fas fa-cog', onSelect = function() ShowHouseMenu(houseId) end },
            { label = 'Alarm Panel', icon = 'fas fa-shield-alt', onSelect = function() ShowAlarmMenu(houseId) end },
        },
    })
end

function ShowHouseMenu(houseId)
    local items = {
        { title = 'Furniture Mode', icon = 'fas fa-couch', onSelect = function() ToggleFurnitureMode(houseId) end },
        { title = 'Guest Keys', icon = 'fas fa-key', onSelect = function() ShowGuestMenu(houseId) end },
        { title = 'Garage (' .. Config.AdvancedHousing.properties[houseId] and Config.AdvancedHousing.properties[houseId].garageSlots or 0 .. ' slots)', icon = 'fas fa-warehouse', onSelect = function() ShowGarageMenu(houseId) end },
    }
    Wrappers.ContextMenu({ id = 'house_menu', title = 'House Options', menuItems = items })
end

function ToggleFurnitureMode(houseId)
    furnitureMode = not furnitureMode
    if furnitureMode then
        QBox.Functions.TriggerCallback('housing:getFurnitureCatalog', function(catalog)
            local items = {}
            for _, furn in ipairs(catalog) do
                table.insert(items, { title = furn.name .. ' ($' .. furn.price .. ')', description = furn.category, onSelect = function()
                    selectedFurniture = furn
                    Wrappers.Notify('Aim at placement spot, press G to place, X to cancel', 'info')
                end })
            end
            Wrappers.ContextMenu({ id = 'furn_catalog', title = 'Furniture Catalog', menuItems = items })
        end)
    else
        selectedFurniture = nil
        Wrappers.Notify('Furniture mode off', 'info')
    end
end

function LoadPlacedFurniture(houseId)
    placedFurniture = {}
    QBox.Functions.TriggerCallback('housing:getFurniture', function(furnList)
        placedFurniture = furnList or {}
        for _, f in ipairs(placedFurniture) do
            local model = nil
            for _, fc in ipairs(Config.AdvancedHousing.furniture) do
                if fc.id == f.furnId then model = fc.model; break end
            end
            if model then
                local obj = GetClosestObjectOfType(f.coords, 2.0, GetHashKey(model), false, false, false)
                if obj == 0 then
                    RequestModel(GetHashKey(model))
                    while not HasModelLoaded(GetHashKey(model)) do Citizen.Wait(100) end
                    obj = CreateObjectNoOffset(GetHashKey(model), f.coords.x, f.coords.y, f.coords.z, false, false, false)
                    SetEntityRotation(obj, f.rotation.x, f.rotation.y, f.rotation.z, 2, true)
                    FreezeEntityPosition(obj, true)
                end
            end
        end
    end, houseId)
end

RegisterNetEvent('housing:refreshFurniture', function(houseId, furnList)
    if currentHouseId ~= houseId then return end
    placedFurniture = furnList or {}
end)

function ShowGuestMenu(houseId)
    QBox.Functions.TriggerCallback('housing:getGuests', function(guests)
        local items = {
            { title = 'Add Guest', icon = 'fas fa-user-plus', onSelect = function()
                local input = Wrappers.InputDialog({ title = 'Add Guest', options = {
                    { type = 'input', label = 'Player Citizen ID', placeholder = 'e.g. ABC123' },
                    { type = 'input', label = 'Player Name', placeholder = 'e.g. John Doe' },
                }})
                if input then
                    TriggerServerEvent('housing:guestAdd', houseId, input[1], input[2])
                end
            end },
        }
        if guests then
            for _, g in ipairs(guests) do
                table.insert(items, { title = g.name .. ' (' .. g.cid .. ')', icon = 'fas fa-user', onSelect = function()
                    TriggerServerEvent('housing:guestRemove', houseId, g.cid)
                end })
            end
        end
        Wrappers.ContextMenu({ id = 'guest_menu', title = 'Guest Keys', menuItems = items })
    end, houseId)
end

function ShowAlarmMenu(houseId)
    QBox.Functions.TriggerCallback('housing:getAlarmState', function(alarm)
        local items = {}
        if alarm.active then
            table.insert(items, { title = (alarm.armed and 'Disarm' or 'Arm') .. ' Alarm', icon = 'fas fa-shield-alt', onSelect = function()
                TriggerServerEvent('housing:toggleAlarm', houseId)
            end })
            table.insert(items, { title = 'Remove Alarm', icon = 'fas fa-trash', onSelect = function()
                -- future: remove alarm
            end })
        else
            table.insert(items, { title = 'Install Basic Alarm ($' .. Config.AdvancedHousing.alarm.prices.install .. ')', icon = 'fas fa-shield-alt', onSelect = function()
                TriggerServerEvent('housing:installAlarm', houseId, 'basic')
            end })
            table.insert(items, { title = 'Install Premium Alarm ($' .. Config.AdvancedHousing.alarm.prices.install .. ')', icon = 'fas fa-shield-virus', onSelect = function()
                TriggerServerEvent('housing:installAlarm', houseId, 'premium')
            end })
        end
        Wrappers.ContextMenu({ id = 'alarm_menu', title = 'Alarm System', menuItems = items })
    end, houseId)
end

function ShowGarageMenu(houseId)
    QBox.Functions.TriggerCallback('housing:getStoredVehicles', function(vehicles)
        local items = {}
        for _, v in ipairs(vehicles) do
            table.insert(items, { title = v.model .. ' (' .. v.plate .. ')', icon = 'fas fa-car', onSelect = function()
                TriggerServerEvent('housing:retrieveVehicle', houseId, v.plate)
            end })
        end
        table.insert(items, { title = 'Store Current Vehicle', icon = 'fas fa-parking', onSelect = function()
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh == 0 then Wrappers.Notify('Not in a vehicle', 'error') return end
            local plate = GetVehicleNumberPlateText(veh)
            local model = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(veh)))
            TriggerServerEvent('housing:storeVehicle', houseId, plate, model)
            DeleteVehicle(veh)
        end })
        Wrappers.ContextMenu({ id = 'garage_menu', title = 'Garage', menuItems = items })
    end, houseId)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if furnitureMode and selectedFurniture then
            if IsControlJustPressed(0, 47) then -- G key
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local forward = GetEntityForwardVector(ped)
                local place = coords + forward * 2.0
                QBox.Functions.TriggerCallback('housing:getFurniture', function(existing)
                    TriggerServerEvent('housing:placeFurniture', currentHouseId, selectedFurniture.id, vector3(place.x, place.y, place.z - 1.0), vector3(0.0, 0.0, 0.0))
                end, currentHouseId)
            end
            if IsControlJustPressed(0, 73) then -- X key
                selectedFurniture = nil
                furnitureMode = false
                Wrappers.Notify('Placement cancelled', 'info')
            end
        end
        if inHouse and IsControlJustPressed(0, 74) then -- O key
            ShowHouseMenu(currentHouseId)
        end
        if inHouse and IsControlJustPressed(0, 177) then -- BACKSPACE to exit
            ExitProperty()
        end
    end
end)
