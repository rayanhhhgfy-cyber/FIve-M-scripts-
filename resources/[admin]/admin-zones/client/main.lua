local activeZones = {}
local zoneTargets = {}

local function getPlayerJob()
    local p = exports['qbx_core']:GetPlayerData()
    return p and p.job or { name = 'unemployed', grade = 0, onduty = false }
end

local function canAccessZone(zone)
    local job = getPlayerJob()
    if zone.allowed_jobs and #zone.allowed_jobs > 0 then
        local hasJob = false
        for _, j in ipairs(zone.allowed_jobs) do
            if j == job.name then hasJob = true; break end
        end
        if not hasJob then return false end
    end
    if job.grade < zone.min_grade then return false end
    if zone.require_duty == 1 and not job.onduty then return false end
    return true
end

local function loadZones()
    local zones = lib.callback.await('admin-zones:server:getActiveZones', false)
    for _, zone in ipairs(zones or {}) do
        createZoneTarget(zone)
    end
end

local function addZoneItemToPlayer(item, zoneId)
    TriggerServerEvent('admin-zones:server:takeItem', zoneId, item.item_name)
end

local function openArmory(zone)
    local items = lib.callback.await('admin-zones:server:getZoneItems', false, zone.id)
    if not items or #items == 0 then
        exports.ox_lib:notify({ type = 'info', description = 'No items configured in this armory' })
        return
    end
    local jobGrade = getPlayerJob().grade
    local menuItems = {}
    for _, item in ipairs(items) do
        if jobGrade >= item.min_rank then
            menuItems[#menuItems + 1] = {
                title = item.label,
                description = 'Take ' .. item.item_name,
                icon = 'box',
                onSelect = function()
                    addZoneItemToPlayer(item, zone.id)
                end
            }
        end
    end
    if #menuItems == 0 then
        exports.ox_lib:notify({ type = 'info', description = 'No items available for your rank' })
        return
    end
    exports.ox_lib:registerContext({
        id = 'zone_armory_' .. zone.id,
        title = zone.name .. ' (Armory)',
        options = menuItems
    })
    exports.ox_lib:showContext('zone_armory_' .. zone.id)
end

local function openShop(zone)
    local items = lib.callback.await('admin-zones:server:getZoneItems', false, zone.id)
    if not items or #items == 0 then
        exports.ox_lib:notify({ type = 'info', description = 'No items in this shop' })
        return
    end
    local jobGrade = getPlayerJob().grade
    local menuItems = {}
    for _, item in ipairs(items) do
        if jobGrade >= item.min_rank then
            local priceStr = item.price == 0 and 'Free' or '$' .. item.price
            menuItems[#menuItems + 1] = {
                title = item.label .. ' (' .. priceStr .. ')',
                description = item.currency == 'black_money' and 'Black Money' or 'Cash',
                icon = 'cart-shopping',
                onSelect = function()
                    TriggerServerEvent('admin-zones:server:buyItem', zone.id, item.item_name, item.price, item.currency)
                end
            }
        end
    end
    if #menuItems == 0 then
        exports.ox_lib:notify({ type = 'info', description = 'No items available' })
        return
    end
    exports.ox_lib:registerContext({
        id = 'zone_shop_' .. zone.id,
        title = zone.name .. ' (Shop)',
        options = menuItems
    })
    exports.ox_lib:showContext('zone_shop_' .. zone.id)
end

local function openStorage(zone)
    local job = getPlayerJob()
    local stashName = 'zone_stash_' .. zone.id .. '_' .. job.name
    exports.ox_inventory:openInventory('stash', stashName)
end

local function openWardrobe(zone)
    local items = lib.callback.await('admin-zones:server:getZoneItems', false, zone.id)
    if not items or #items == 0 then
        exports.ox_lib:notify({ type = 'info', description = 'No uniforms configured' })
        return
    end
    local menuItems = {}
    for _, item in ipairs(items) do
        menuItems[#menuItems + 1] = {
            title = 'Put on ' .. item.label,
            icon = 'shirt',
            onSelect = function()
                TriggerServerEvent('admin-zones:server:takeItem', zone.id, item.item_name)
            end
        }
    end
    exports.ox_lib:registerContext({
        id = 'zone_wardrobe_' .. zone.id,
        title = zone.name .. ' (Wardrobe)',
        options = menuItems
    })
    exports.ox_lib:showContext('zone_wardrobe_' .. zone.id)
end

local function toggleDuty(zone)
    TriggerServerEvent('admin-zones:server:toggleDuty')
end

local function openGarage(zone)
    local vehicles = lib.callback.await('admin-zones:server:getZoneItems', false, zone.id)
    local menuItems = {}
    if vehicles and #vehicles > 0 then
        for _, v in ipairs(vehicles) do
            menuItems[#menuItems + 1] = {
                title = 'Spawn ' .. v.label,
                icon = 'car',
                onSelect = function()
                    TriggerServerEvent('admin-zones:server:spawnVehicle', zone.id, v.item_name)
                end
            }
        end
    else
        for _, model in ipairs(Config.AdminZones.defaultVehicles) do
            menuItems[#menuItems + 1] = {
                title = 'Spawn ' .. model,
                icon = 'car',
                onSelect = function()
                    TriggerServerEvent('admin-zones:server:spawnVehicle', zone.id, model)
                end
            }
        end
    end
    exports.ox_lib:registerContext({
        id = 'zone_garage_' .. zone.id,
        title = zone.name .. ' (Garage)',
        options = menuItems
    })
    exports.ox_lib:showContext('zone_garage_' .. zone.id)
end

function createZoneTarget(zone)
    if not zone or not zone.coords then return end
    local coords = vec3(zone.coords.x, zone.coords.y, zone.coords.z)
    local zoneTypeConfig = Config.AdminZones.zoneTypes[zone.zone_type] or { label = zone.zone_type, icon = 'circle' }
    local label = zone.name .. ' (' .. zoneTypeConfig.label .. ')'
    local icon = zoneTypeConfig.icon

    local handler
    if zone.zone_type == 'armory' then
        handler = function() openArmory(zone) end
    elseif zone.zone_type == 'shop' then
        handler = function() openShop(zone) end
    elseif zone.zone_type == 'storage' then
        handler = function() openStorage(zone) end
    elseif zone.zone_type == 'wardrobe' then
        handler = function() openWardrobe(zone) end
    elseif zone.zone_type == 'duty' then
        handler = function() toggleDuty(zone) end
    elseif zone.zone_type == 'garage' then
        handler = function() openGarage(zone) end
    else
        return
    end

    local targetId = exports.ox_target:addBoxZone({
        coords = coords,
        size = vec3(zone.radius or 2.0, zone.radius or 2.0, 2.5),
        rotation = 0,
        debug = false,
        options = {
            {
                name = 'admin_zone_' .. zone.id,
                label = label,
                icon = 'fas fa-' .. icon,
                canInteract = function()
                    return canAccessZone(zone)
                end,
                onSelect = handler,
                distance = Config.AdminZones.interactionDistance
            }
        }
    })
    zoneTargets[zone.id] = targetId
end

function removeZoneTarget(zoneId)
    if zoneTargets[zoneId] then
        exports.ox_target:removeZone(zoneTargets[zoneId])
        zoneTargets[zoneId] = nil
    end
end

RegisterNetEvent('admin-zones:client:addZone', function(zone)
    if not zone then return end
    activeZones[zone.id] = zone
    createZoneTarget(zone)
end)

RegisterNetEvent('admin-zones:client:removeZone', function(zoneId)
    if not zoneId then return end
    activeZones[zoneId] = nil
    removeZoneTarget(zoneId)
end)

RegisterNetEvent('admin-zones:client:refreshZones', function()
    for id, _ in pairs(activeZones) do
        removeZoneTarget(id)
    end
    activeZones = {}
    loadZones()
end)

RegisterNetEvent('admin-zones:client:spawnVehicle', function(model)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local qbx = exports['qbx_core']:GetCoreObject()
    qbx.Functions.SpawnVehicle(model, function(veh)
        if veh and DoesEntityExist(veh) then
            SetVehicleOnGroundProperly(veh)
            SetEntityInvincible(veh, false)
            SetVehicleEngineOn(veh, true, true, false)
            TaskWarpPedIntoVehicle(ped, veh, -1)
        end
    end, coords, heading, true, false)
end)

Citizen.CreateThread(function()
    Citizen.Wait(3000)
    loadZones()
end)
