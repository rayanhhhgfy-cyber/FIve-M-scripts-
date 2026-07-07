local QBox = exports['qbx-core']:GetCoreObject()
local ox_target = exports.ox_target
local ox_lib = exports.ox_lib

local activeCapture = nil
local captureProgress = 0
local isCapturing = false

local function drawZoneMarker(turf)
    local r, g, b = 255, 255, 255
    if turf.owner then
        local colors = { [1] = { 255, 0, 0 }, [2] = { 0, 255, 0 }, [3] = { 0, 100, 255 }, [4] = { 255, 255, 0 }, [5] = { 255, 0, 255 } }
        local c = colors[turf.ownerColor] or { 255, 255, 255 }
        r, g, b = c[1], c[2], c[3]
    end
    DrawMarker(1, turf.coords.x, turf.coords.y, turf.coords.z - 2, 0, 0, 0, 0, 0, 0, turf.radius * 2, turf.radius * 2, 1.0, r, g, b, 80, false, false, 2, false, nil, nil, false)
end

local function getPlayerGang()
    local player = QBox.Functions.GetPlayer()
    if not player then return nil end
    return player.PlayerData.gang or player.PlayerData.metadata.gang
end

local function startCapture(turfId)
    if isCapturing then return end
    local gang = getPlayerGang()
    if not gang then
        return Wrappers.Notify('error', 'No Gang', 'You must be in a gang to capture turfs')
    end
    isCapturing = true
    TriggerServerEvent('turfs:server:startCapture', turfId)
end

local function stopCapture()
    if not isCapturing then return end
    isCapturing = false
    activeCapture = nil
    captureProgress = 0
    TriggerServerEvent('turfs:server:stopCapture')
end

local function showTurfMenu(turfId)
    local options = {}
    local turf = nil
    for _, t in ipairs(Config.Turfs) do
        if t.id == turfId then turf = t end
    end
    if not turf then return end
    options[#options + 1] = {
        title = turf.label,
        description = 'Start capturing this turf',
        onSelect = function()
            startCapture(turfId)
        end
    }
    options[#options + 1] = {
        title = 'View Info',
        description = 'See turf details',
        onSelect = function()
            TriggerServerEvent('turfs:server:getTurfInfo', turfId)
        end
    }
    ox_lib:registerContext({
        id = 'turf_menu_' .. turfId,
        title = turf.label,
        options = options
    })
    ox_lib:showContext('turf_menu_' .. turfId)
end

local function setupTargets()
    for _, turf in ipairs(Config.Turfs) do
        local targetId = 'turf_zone_' .. turf.id
        ox_target:removeZone(targetId)
        ox_target:addBoxZone({
            name = targetId,
            coords = turf.coords,
            size = vec3(6.0, 6.0, 2.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'capture_turf_' .. turf.id,
                    label = 'Capture Turf',
                    icon = 'fas fa-flag',
                    onSelect = function()
                        showTurfMenu(turf.id)
                    end,
                    canInteract = function()
                        return not isCapturing
                    end
                }
            }
        })
    end
end

local function createBlips()
    for _, turf in ipairs(Config.Turfs) do
        local blip = AddBlipForRadius(turf.coords, turf.radius)
        SetBlipColour(blip, turf.color)
        SetBlipAlpha(blip, 100)
        local marker = AddBlipForCoord(turf.coords)
        SetBlipSprite(marker, Config.Blip.sprite)
        SetBlipScale(marker, Config.Blip.scale)
        SetBlipAsShortRange(marker, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(turf.label)
        EndTextCommandSetBlipName(marker)
    end
end

Citizen.CreateThread(function()
    setupTargets()
    createBlips()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    setupTargets()
end)

RegisterNetEvent('turfs:client:captureProgress', function(turfId, progress, total)
    if not isCapturing then return end
    captureProgress = progress
    if progress >= total then
        Wrappers.Notify('success', 'Turf Captured', 'Your gang now controls this territory')
        stopCapture()
    end
end)

RegisterNetEvent('turfs:client:captureFailed', function(reason)
    Wrappers.Notify('error', 'Capture Failed', reason)
    stopCapture()
end)

RegisterNetEvent('turfs:client:turfInfo', function(info)
    ox_lib:notify({
        title = 'Turf Info',
        description = info,
        type = 'inform'
    })
end)

RegisterNetEvent('turfs:client:policeAlert', function(turfName)
    Wrappers.Notify('error', 'Police Alert', 'Police have been notified of activity at ' .. turfName)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local inTurf = false
        for _, turf in ipairs(Config.Turfs) do
            local dist = #(coords - turf.coords)
            if dist < turf.radius then
                drawZoneMarker(turf)
                inTurf = true
            end
        end
        if not inTurf and isCapturing then
            stopCapture()
        end
        if isCapturing and activeCapture then
            DrawText2D('Capturing: ' .. math.floor(captureProgress) .. '%', 0.5, 0.85, 0.5, 0.5, 255, 255, 255, 255)
        end
    end
end)
