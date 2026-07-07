local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local deployedBarricades = {}
local barricadeObjects = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() playerData = QBox.Functions.GetPlayerData() end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(j) playerData.job = j end)

local function canUse()
    if Config.Barricades.RequireJob then
        return playerData.job and (playerData.job.name == 'police' or playerData.job.name == 'tow')
    end
    return true
end

Citizen.CreateThread(function()
    for i = 1, Config.Barricades.MaxActive do
        exports.ox_target:addSphereZone({
            coords = vector3(0, 0, 0), radius = 0.5, debug = false,
            options = {{
                name = 'barricade_pickup_' .. i,
                icon = Config.Barricades.TargetOptions.pickup.icon,
                label = Config.Barricades.TargetOptions.pickup.label,
                distance = Config.Barricades.TargetOptions.pickup.distance,
                canInteract = function() return deployedBarricades[i] ~= nil and canUse() end,
                onSelect = function() TriggerEvent('barricades:pickup', i) end
            }}
        })
    end
end)

RegisterNetEvent('barricades:openMenu', function()
    if not canUse() then Wrappers.Notify(Locale('logistics.not_authorized'), 'error') return end
    local active = 0; for _, v in pairs(deployedBarricades) do if v then active = active + 1 end end
    local items = {}
    for typeId, tData in pairs(Config.Barricades.Types) do
        local count = 0; for _, v in pairs(deployedBarricades) do if v and v.type == typeId then count = count + 1 end end
        if count < tData.limit then
            table.insert(items, { title = tData.label, description = Locale('logistics.barricade_limit', count, tData.limit), onSelect = function() TriggerEvent('barricades:deploy', typeId) end })
        end
    end
    if #items == 0 then table.insert(items, { title = Locale('logistics.all_deployed'), description = '' }) end
    Wrappers.ContextMenu({ id = 'barricade_menu', title = Locale('logistics.barricades'), menuItems = items })
end)

RegisterNetEvent('barricades:deploy', function(typeId)
    local tData = Config.Barricades.Types[typeId]
    if not tData then return end
    local active = 0; for _, v in pairs(deployedBarricades) do if v then active = active + 1 end end
    if active >= Config.Barricades.MaxActive then Wrappers.Notify(Locale('logistics.max_barricades'), 'error') return end
    local ped = PlayerPedId(); local coords = GetEntityCoords(ped); local heading = GetEntityHeading(ped)
    Wrappers.ProgressBar({ label = Locale('logistics.deploying', tData.label), duration = tData.deployTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('barricades:server:deploy', typeId, coords, heading)
    end)
end)

RegisterNetEvent('barricades:client:deploy', function(id, typeId, coords, heading)
    local tData = Config.Barricades.Types[typeId]
    if not tData then return end
    local slot = nil
    for i = 1, Config.Barricades.MaxActive do if not deployedBarricades[i] then slot = i; break end end
    if not slot then return end
    local model = GetHashKey(tData.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Citizen.Wait(0) end
    local obj = CreateObject(model, coords.x, coords.y, coords.z - 0.5, true, false, false)
    SetEntityHeading(obj, heading); FreezeEntityPosition(obj, true); SetEntityCollision(obj, true, true)
    barricadeObjects[slot] = obj
    deployedBarricades[slot] = { coords = coords, type = typeId, time = os.time() }
    local zone = exports.ox_target:getSphereZone('barricade_pickup_' .. slot)
    if zone then zone:setCoords(coords) end
    Wrappers.Notify(Locale('logistics.deployed', tData.label), 'success')
end)

RegisterNetEvent('barricades:pickup', function(id)
    if not deployedBarricades[id] then return end
    Wrappers.ProgressBar({ label = Locale('logistics.removing'), duration = Config.Barricades.PickupTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('barricades:server:pickup', id)
    end)
end)

RegisterNetEvent('barricades:client:pickup', function(id)
    if barricadeObjects[id] then DeleteObject(barricadeObjects[id]); barricadeObjects[id] = nil end
    deployedBarricades[id] = nil
    Wrappers.Notify(Locale('logistics.removed'), 'success')
    local zone = exports.ox_target:getSphereZone('barricade_pickup_' .. id)
    if zone then zone:setCoords(vector3(0, 0, 0)) end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        local now = os.time()
        for id, data in pairs(deployedBarricades) do
            if data and now - data.time > Config.Barricades.DespawnTime then
                TriggerEvent('barricades:pickup', id)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Config.Barricades.UI.ShowCount then
            local active = 0; for _, v in pairs(deployedBarricades) do if v then active = active + 1 end end
            if active > 0 then
                SetTextFont(4); SetTextScale(0.4, 0.4)
                SetTextColour(Config.Barricades.UI.Color.r, Config.Barricades.UI.Color.g, Config.Barricades.UI.Color.b, 255)
                SetTextCentre(true); SetTextEntry('STRING')
                AddTextComponentString(Locale('logistics.barricade_count', active, Config.Barricades.MaxActive))
                DrawText(0.5, 0.95)
            end
        end
        Citizen.Wait(1000)
    end
end)
