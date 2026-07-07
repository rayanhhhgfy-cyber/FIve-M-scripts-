local QBox = exports['qbx-core']:GetCoreObject()
local trackedPlayers = {}
local locationBlips = {}

local function hasPhone() return QBox.Functions.HasItem('iphone17') or QBox.Functions.HasItem('phone_encrypted') end

exports.ox_target:addGlobalPlayer({ options = {{
    name = 'locator_track',
    icon = Config.Locator.TargetOptions.track.icon,
    label = Config.Locator.TargetOptions.track.label,
    distance = Config.Locator.TargetOptions.track.distance,
    canInteract = function() return Config.Locator.AllowTracking and hasPhone() end,
    onSelect = function(entity)
        local pid = NetworkGetPlayerIndexFromPed(entity)
        if pid and pid ~= -1 then
            local sid = GetPlayerServerId(pid)
            TriggerServerEvent('locator:server:track', sid)
        end
    end
}, {
    name = 'locator_share',
    icon = Config.Locator.TargetOptions.share.icon,
    label = Config.Locator.TargetOptions.share.label,
    distance = Config.Locator.TargetOptions.share.distance,
    canInteract = function() return hasPhone() end,
    onSelect = function()
        local coords = GetEntityCoords(PlayerPedId())
        TriggerServerEvent('locator:server:shareLocation', coords)
    end
}}})

RegisterNetEvent('locator:client:updateLocation', function(targetId, coords)
    if locationBlips[targetId] then RemoveBlip(locationBlips[targetId]) end
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, Config.Locator.Colors.tracked)
    SetBlipScale(blip, 0.9)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(Locale('phone.tracked_target'))
    EndTextCommandSetBlipName(blip)
    locationBlips[targetId] = blip
    SetTimeout(Config.Locator.BlipTime, function()
        if locationBlips[targetId] then RemoveBlip(locationBlips[targetId]); locationBlips[targetId] = nil end
    end)
end)

RegisterNetEvent('locator:client:locationShared', function(caller, coords)
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, 1); SetBlipColour(blip, Config.Locator.Colors.friend); SetBlipScale(blip, 0.9)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(caller)
    EndTextCommandSetBlipName(blip)
    Wrappers.Notify(Locale('phone.location_shared', caller), 'info')
    SetTimeout(30000, function() RemoveBlip(blip) end)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.Locator.UpdateInterval)
        if hasPhone() then
            TriggerServerEvent('locator:server:requestTracking')
        end
    end
end)

RegisterNetEvent('locator:client:updateTracked', function(targets)
    -- receives list of tracked targets and their last known positions
end)
