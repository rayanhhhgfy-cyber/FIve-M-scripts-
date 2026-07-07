local QBox = exports['qbx-core']:GetCoreObject()
local playerData = {}
local deployedStrobes = {}
local strobeObjects = {}
local strobeActive = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() playerData = QBox.Functions.GetPlayerData() end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(j) playerData.job = j end)

local function isCID() return playerData.job and (playerData.job.name == 'cid' or playerData.job.name == 'police') end
local function isOnDuty() return playerData.job and playerData.job.onduty end
local function rank() return playerData.job and playerData.job.grade.level or 0 end

Citizen.CreateThread(function()
    for i = 1, Config.Strobes.MaxActive do
        exports.ox_target:addSphereZone({
            coords = vector3(0, 0, 0), radius = 0.5, debug = false,
            options = {{
                name = 'strobe_pickup_' .. i,
                icon = Config.Strobes.TargetOptions.pickup.icon,
                label = Config.Strobes.TargetOptions.pickup.label,
                distance = Config.Strobes.TargetOptions.pickup.distance,
                canInteract = function() return deployedStrobes[i] ~= nil end,
                onSelect = function() TriggerEvent('strobes:pickup', i) end
            }}
        })
    end
end)

RegisterNetEvent('strobes:deploy', function()
    if not isCID() or not isOnDuty() then Wrappers.Notify(Locale('cid.not_authorized'), 'error') return end
    if rank() < Config.Strobes.MinRank then Wrappers.Notify(Locale('cid.rank_too_low'), 'error') return end
    if not QBox.Functions.HasItem(Config.Strobes.ItemName) then Wrappers.Notify(Locale('cid.no_strobe'), 'error') return end
    local active = 0; for _, v in pairs(deployedStrobes) do if v then active = active + 1 end end
    if active >= Config.Strobes.MaxActive then Wrappers.Notify(Locale('cid.max_strobes'), 'error') return end
    local ped = PlayerPedId(); local coords = GetEntityCoords(ped); local heading = GetEntityHeading(ped)
    Wrappers.ProgressBar({ label = Locale('cid.deploying_strobe'), duration = Config.Strobes.DeployTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        QBox.Functions.RemoveItem(Config.Strobes.ItemName, 1)
        TriggerServerEvent('strobes:server:deploy', coords, heading)
    end)
end)

RegisterNetEvent('strobes:client:deploy', function(id, coords, heading)
    local slot = nil
    for i = 1, Config.Strobes.MaxActive do if not deployedStrobes[i] then slot = i; break end end
    if not slot then return end
    local obj = CreateObject(GetHashKey('prop_test_electrical'), coords.x, coords.y, coords.z - 0.5, true, false, false)
    SetEntityHeading(obj, heading); FreezeEntityPosition(obj, true)
    strobeObjects[slot] = obj
    deployedStrobes[slot] = { coords = coords, time = os.time(), active = true }
    strobeActive[slot] = true
    local zone = exports.ox_target:getSphereZone('strobe_pickup_' .. slot)
    if zone then zone:setCoords(coords) end
    Wrappers.Notify(Locale('cid.strobe_deployed'), 'success')
end)

RegisterNetEvent('strobes:pickup', function(id)
    if not deployedStrobes[id] then return end
    Wrappers.ProgressBar({ label = Locale('cid.picking_up_strobe'), duration = Config.Strobes.PickupTime, useWhileDead = false, canCancel = true }, function(cancelled)
        if cancelled then return end
        TriggerServerEvent('strobes:server:pickup', id)
    end)
end)

RegisterNetEvent('strobes:client:pickup', function(id)
    if strobeObjects[id] then DeleteObject(strobeObjects[id]); strobeObjects[id] = nil end
    deployedStrobes[id] = nil; strobeActive[id] = false
    QBox.Functions.AddItem(Config.Strobes.ItemName, 1)
    Wrappers.Notify(Locale('cid.strobe_picked_up'), 'success')
    local zone = exports.ox_target:getSphereZone('strobe_pickup_' .. id)
    if zone then zone:setCoords(vector3(0, 0, 0)) end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.Strobes.FlashInterval)
        for id, data in pairs(deployedStrobes) do
            if strobeActive[id] and data then
                local lightOn = math.floor(GetGameTimer() / Config.Strobes.FlashInterval) % 2 == 0
                if lightOn then
                    DrawLightWithRange(data.coords.x, data.coords.y, data.coords.z, Config.Strobes.LightColor.r, Config.Strobes.LightColor.g, Config.Strobes.LightColor.b, Config.Strobes.LightRange, Config.Strobes.LightIntensity)
                    local ped = PlayerPedId(); local pCoords = GetEntityCoords(ped)
                    local dist = #(pCoords - data.coords)
                    if dist < Config.Strobes.DisorientRadius then
                        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.3)
                    end
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        local now = os.time()
        for id, data in pairs(deployedStrobes) do
            if data and now - data.time > Config.Strobes.BatteryTime then
                TriggerEvent('strobes:pickup', id)
            end
        end
    end
end)
