local QBCore = exports['qbx_core']:GetCoreObject()
local currentHouse = nil

function EnterHouse(propertyId)
    local house = lib.callback.await('ps-housing:server:getHouse', false, propertyId)
    if not house then
        Wrappers.Notify({ type = 'error', description = 'House not found' })
        return
    end
    local canAccess = lib.callback.await('ps-housing:server:canAccess', false, propertyId)
    if not canAccess then
        Wrappers.Notify({ type = 'error', description = 'You do not have access' })
        return
    end
    currentHouse = house
    local shell = Config.Shells[house.shell_id]
    if shell and shell.interior then
        local interior = shell.interior
        LoadInterior(GetInteriorAtCoords(shell.coords.x, shell.coords.y, shell.coords.z))
        if interior.ipl then
            RequestIpl(interior.ipl)
        end
        SetInteriorActive(GetInteriorAtCoords(shell.coords.x, shell.coords.y, shell.coords.z), true)
    end
    local exitCoords = json.decode(house.exit_coords or '{}')
    if exitCoords and exitCoords.x then
        SetEntityCoords(PlayerPedId(), exitCoords.x, exitCoords.y, exitCoords.z)
    end
    TriggerEvent('ox_lib:notify', { type = 'success', description = 'Entered ' .. house.label })
end

function ExitHouse()
    if not currentHouse then return end
    local entrance = json.decode(currentHouse.coords or '{}')
    if entrance and entrance.x then
        SetEntityCoords(PlayerPedId(), entrance.x, entrance.y, entrance.z)
    end
    currentHouse = nil
end

local function OpenHouseMenu(propertyId)
    local house = lib.callback.await('ps-housing:server:getHouse', false, propertyId)
    if not house then return end
    local canAccess = lib.callback.await('ps-housing:server:canAccess', false, propertyId)
    local options = {
        {
            title = canAccess and 'Enter' or 'Locked',
            description = house.label,
            icon = canAccess and 'fas fa-door-open' or 'fas fa-lock',
            onSelect = function()
                if canAccess then EnterHouse(propertyId) end
            end
        }
    }
    if canAccess then
        table.insert(options, {
            title = house.is_locked and 'Unlock' or 'Lock',
            icon = house.is_locked and 'fas fa-unlock' or 'fas fa-lock',
            onSelect = function()
                local newState = lib.callback.await('ps-housing:server:toggleLock', false, propertyId)
                Wrappers.Notify({ type = 'info', description = newState and 'Locked' or 'Unlocked' })
            end
        })
        table.insert(options, {
            title = 'Manage Keys',
            icon = 'fas fa-key',
            onSelect = function()
                local input = lib.inputDialog('Manage Keys', {
                    { type = 'input', label = 'CitizenID to add/remove', placeholder = 'QB...', required = true },
                    { type = 'select', label = 'Action', options = { { value = 'add', label = 'Add Key' }, { value = 'remove', label = 'Remove Key' } }, default = 'add' }
                })
                if input then
                    local success = lib.callback.await('ps-housing:server:' .. (input[2] == 'add' and 'addKey' or 'removeKey'), false, propertyId, input[1])
                    Wrappers.Notify({ type = success and 'success' or 'error', description = success and 'Keys updated' or 'Failed' })
                end
            end
        })
        if Config.Housing.enableStashes then
            table.insert(options, {
                title = 'Stash',
                icon = 'fas fa-box',
                onSelect = function()
                    TriggerEvent('ox_inventory:openInventory', 'stash', 'house_' .. propertyId)
                end
            })
        end
        if Config.Housing.enableWardrobes then
            table.insert(options, {
                title = 'Wardrobe',
                icon = 'fas fa-tshirt',
                onSelect = function()
                    TriggerEvent('linden-outfits:client:openWardrobe', propertyId)
                end
            })
        end
    end
    lib.registerContext({
        id = 'house_menu',
        title = house.label,
        options = options
    })
    lib.showContext('house_menu')
end

RegisterNetEvent('ps-housing:client:openHouse', function(propertyId)
    OpenHouseMenu(propertyId)
end)

RegisterNetEvent('ps-housing:client:enterHouse', function(propertyId)
    EnterHouse(propertyId)
end)

RegisterNetEvent('ps-housing:client:exitHouse', function()
    ExitHouse()
end)

RegisterNetEvent('ps-housing:client:interact', function()
    OpenHouseMenu(currentPropertyId)
end)

exports('EnterHouse', EnterHouse)
exports('ExitHouse', ExitHouse)
exports('GetCurrentHouse', function() return currentHouse end)
