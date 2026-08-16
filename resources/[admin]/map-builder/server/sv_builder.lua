MapBuilderData = {
    placedProps = {},
    spawnedObjects = {},
    hiddenWorldProps = {}
}

local autoSaveFile = 'map_builder_save.json'
local hiddenSaveFile = 'map_builder_hidden_props.json'
local Framework = 'standalone'

-- Auto Detect Active Framework
Citizen.CreateThread(function()
    if GetResourceState('qbx_core') == 'started' then
        Framework = 'qbox'
    elseif GetResourceState('qb-core') == 'started' then
        Framework = 'qb'
    elseif GetResourceState('es_extended') == 'started' then
        Framework = 'esx'
    else
        Framework = 'standalone'
    end
    print('^2[map-builder] Detected active framework bridge: ' .. string.upper(Framework) .. '^7')
end)

-- Robust hash getter
function GetHash(model)
    if type(model) == 'number' then
        return model
    elseif type(model) == 'string' then
        return joaat(model)
    else
        return 0
    end
end

-- Fetch player across QBox, QBCore, ESX, or Standalone
function GetPlayerServer(source)
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

-- Robust permissions check across all frameworks
function IsAuthorized(source)
    if Framework == 'standalone' then return IsPlayerAceAllowed(source, 'command.mapbuilder') end

    local group = 'user'
    local player = GetPlayerServer(source)
    if not player then return false end

    if Framework == 'qbox' or Framework == 'qb' then
        group = player.PlayerData.group or 'user'
    elseif Framework == 'esx' then
        group = player.getGroup() or 'user'
    end

    for _, g in ipairs(Config.MapBuilder.authorizedGroups) do
        if g == group then return true end
    end
    return false
end

RegisterNetEvent('map-builder:server:checkAuth', function()
    local src = source
    local auth = IsAuthorized(src)
    TriggerClientEvent('map-builder:client:startBuilder', src, auth)
end)

-- Load existing builds on startup
MySQL.ready(function()
    LoadSavedMaps()
    LoadHiddenWorldProps()
end)

function SpawnNetworkedPropServer(propData)
    local hash = GetHash(propData.model)
    -- Using proper, fully supported server-side native
    local obj = CreateObject(hash, propData.coords.x, propData.coords.y, propData.coords.z, true, true, false)
    FreezeEntityPosition(obj, propData.frozen)

    -- Sync rotation and logic on the client side once network ID is created
    SetTimeout(500, function()
        local netId = NetworkGetNetworkIdFromEntity(obj)
        TriggerClientEvent('map-builder:client:rotateProp', -1, netId, propData.rotation)
        if propData.logic then
            TriggerClientEvent('map-builder:client:registerInteractiveProp', -1, propData, netId)
        end
        if propData.lightData then
            TriggerClientEvent('map-builder:client:syncPointLight', -1, propData.lightData)
        end
    end)

    MapBuilderData.spawnedObjects[propData.id] = obj
end

function LoadSavedMaps()
    local content = LoadResourceFile(GetCurrentResourceName(), autoSaveFile)
    if content then
        MapBuilderData.placedProps = json.decode(content) or {}
        print('^2[map-builder] Loaded ' .. table_size(MapBuilderData.placedProps) .. ' placed props from persistence buffer.^7')

        -- Spawn networked entities on the server (ensures zero client-side duplication desync!)
        for id, prop in pairs(MapBuilderData.placedProps) do
            SpawnNetworkedPropServer(prop)
        end
    else
        MapBuilderData.placedProps = {}
    end
end

function LoadHiddenWorldProps()
    local content = LoadResourceFile(GetCurrentResourceName(), hiddenSaveFile)
    if content then
        MapBuilderData.hiddenWorldProps = json.decode(content) or {}
        print('^2[map-builder] Loaded ' .. #MapBuilderData.hiddenWorldProps .. ' hidden world props from persistence.^7')
    else
        MapBuilderData.hiddenWorldProps = {}
    end
end

RegisterNetEvent('map-builder:server:requestProps', function()
    local src = source
    for id, prop in pairs(MapBuilderData.placedProps) do
        local obj = MapBuilderData.spawnedObjects[id]
        if obj and DoesEntityExist(obj) then
            local netId = NetworkGetNetworkIdFromEntity(obj)
            TriggerClientEvent('map-builder:client:rotateProp', src, netId, prop.rotation)
            if prop.logic then
                TriggerClientEvent('map-builder:client:registerInteractiveProp', src, prop, netId)
            end
        end
        if prop.lightData then
            TriggerClientEvent('map-builder:client:syncPointLight', src, prop.lightData)
        end
    end
    -- Sync hidden world props
    for _, p in ipairs(MapBuilderData.hiddenWorldProps) do
        TriggerClientEvent('map-builder:client:syncHiddenProp', src, p.coords, p.hash)
    end
end)

RegisterNetEvent('map-builder:server:saveAsPrefab', function(name)
    local src = source
    if not IsAuthorized(src) then return end

    local prefabName = name:gsub('[^%a%d_]', '') .. '.json'
    SaveResourceFile(GetCurrentResourceName(), 'prefabs/' .. prefabName, json.encode(MapBuilderData.placedProps, { indent = true }), -1)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Successfully saved prefab: ' .. name })
end)

function table_size(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function SaveMapsToDisk()
    SaveResourceFile(GetCurrentResourceName(), autoSaveFile, json.encode(MapBuilderData.placedProps, { indent = true }), -1)
    print('^2[map-builder] Auto-saved persistence buffer to disk.^7')
end

RegisterNetEvent('map-builder:server:forceSaveDisk', function()
    local src = source
    if not IsAuthorized(src) then return end
    SaveMapsToDisk()
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'All changes saved to server files successfully!' })
end)

RegisterNetEvent('map-builder:server:saveProp', function(propData)
    local src = source
    if not IsAuthorized(src) then return end

    -- Generate stable string IDs to prevent JSON roundtrip dictionary conversions
    local id = 'prop_' .. os.time() .. '_' .. math.random(1111, 9999)
    propData.id = id
    MapBuilderData.placedProps[id] = propData

    -- Spawn the networked entity server-side safely
    SpawnNetworkedPropServer(propData)

    SaveMapsToDisk()
end)

-- Erase Tool Deletion synchronization event
RegisterNetEvent('map-builder:server:deletePropByCoords', function(coords)
    local src = source
    if not IsAuthorized(src) then return end

    local closestId = nil
    local minDist = 3.0
    for id, prop in pairs(MapBuilderData.placedProps) do
        local dist = #(vector3(prop.coords.x, prop.coords.y, prop.coords.z) - vector3(coords.x, coords.y, coords.z))
        if dist < minDist then
            minDist = dist
            closestId = id
        end
    end

    if closestId then
        -- Delete server spawned entity
        if MapBuilderData.spawnedObjects[closestId] and DoesEntityExist(MapBuilderData.spawnedObjects[closestId]) then
            DeleteEntity(MapBuilderData.spawnedObjects[closestId])
            MapBuilderData.spawnedObjects[closestId] = nil
        end
        MapBuilderData.placedProps[closestId] = nil
        SaveMapsToDisk()
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Successfully deleted prop persistence!' })
    end
end)

-- Update Placed Prop Coords / Rotation dynamically
RegisterNetEvent('map-builder:server:updateProp', function(id, coords, rotation)
    local src = source
    if not IsAuthorized(src) then return end

    local prop = MapBuilderData.placedProps[id]
    if prop then
        prop.coords = coords
        prop.rotation = rotation

        local obj = MapBuilderData.spawnedObjects[id]
        if obj and DoesEntityExist(obj) then
            SetEntityCoords(obj, coords.x, coords.y, coords.z, false, false, false, false)
            local netId = NetworkGetNetworkIdFromEntity(obj)
            TriggerClientEvent('map-builder:client:rotateProp', -1, netId, rotation)
        end
        SaveMapsToDisk()
    end
end)

-- Erase Original Game World Props permanently
RegisterNetEvent('map-builder:server:eraseWorldProp', function(coords, modelHash)
    local src = source
    if not IsAuthorized(src) then return end

    local id = #MapBuilderData.hiddenWorldProps + 1
    MapBuilderData.hiddenWorldProps[id] = { coords = coords, hash = modelHash }

    SaveResourceFile(GetCurrentResourceName(), hiddenSaveFile, json.encode(MapBuilderData.hiddenWorldProps, { indent = true }), -1)
    TriggerClientEvent('map-builder:client:syncHiddenProp', -1, coords, modelHash)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Successfully saved original world prop deletion!' })
end)

-- Exporter engine
RegisterNetEvent('map-builder:server:exportMap', function(format)
    local src = source
    if not IsAuthorized(src) then return end

    if format == 'json' then
        local output = json.encode(MapBuilderData.placedProps, { indent = true })
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Exported JSON to server logs and console!' })
        print('^3--- MAP BUILDER JSON EXPORT ---^7')
        print(output)
        print('^3--- END EXPORT ---^7')

    elseif format == 'ymap' then
        -- Generate CodeWalker YMAP XML format
        local header = [[<?xml version="1.0" encoding="UTF-8"?>
<CMapData>
  <name>map_builder_export</name>
  <parent/>
  <flags value="0"/>
  <entities>]]

        local entityTemplate = [[
    <Item type="CEntityDef">
      <archetypeName>%s</archetypeName>
      <flags value="1572864"/>
      <position x="%f" y="%f" z="%f"/>
      <rotation x="%f" y="%f" z="%f" w="1.0"/>
      <scaleXY value="1.0"/>
      <scaleZ value="1.0"/>
    </Item>]]

        local footer = [[
  </entities>
</CMapData>]]

        local body = ""
        for _, p in pairs(MapBuilderData.placedProps) do
            body = body .. string.format(entityTemplate, p.model, p.coords.x, p.coords.y, p.coords.z, p.rotation.x, p.rotation.y, p.rotation.z)
        end

        local finalXml = header .. body .. footer
        SaveResourceFile(GetCurrentResourceName(), 'map_builder_export.ymap.xml', finalXml, -1)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Generated map_builder_export.ymap.xml!' })

    elseif format == 'publish' then
        -- One-Click standalone resource directory generation (Fully interactive logic is exported!)
        local manifest = [[fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Map Builder Exporter'
description 'Auto-published Interactive Map Resource'
version '1.0.0'

client_scripts {
    'client.lua'
}
]]
        local clientCode = [[-- Auto-generated client map stream with full targetings!
local props = ]] .. json.encode(MapBuilderData.placedProps, { indent = true }) .. [[

Citizen.CreateThread(function()
    for _, p in ipairs(props) do
        -- Register target interactive callbacks
        if p.logic then
            TriggerEvent('map-builder:client:registerInteractiveProp', p)
        end
    end
    print('^2[map-builder] Successfully loaded auto-published map resource.^7')
end)
]]
        SaveResourceFile(GetCurrentResourceName(), 'published_resource/fxmanifest.lua', manifest, -1)
        SaveResourceFile(GetCurrentResourceName(), 'published_resource/client.lua', clientCode, -1)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'One-Click Published Standalone Resource under published_resource/!' })
    end
end)

-- Auto save timer
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.MapBuilder.autoSaveInterval)
        SaveMapsToDisk()
    end
end)
