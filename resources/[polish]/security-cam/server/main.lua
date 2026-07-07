local QBCore = exports['qbx_core']:GetCoreObject()
local RATE_LIMITS = {}
local activeSessions = {}

local function checkRateLimit(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    if not RATE_LIMITS[key] then
        RATE_LIMITS[key] = { count = 1, start = now }
        return true
    end
    if now - RATE_LIMITS[key].start >= 60 then
        RATE_LIMITS[key] = { count = 1, start = now }
        return true
    end
    if RATE_LIMITS[key].count >= maxPerMin then
        return false
    end
    RATE_LIMITS[key].count = RATE_LIMITS[key].count + 1
    return true
end

local function Notify(src, msg, type)
    TriggerClientEvent('ox_lib:notify', src, { type = type or 'info', description = msg })
end

local function hasAccess(player)
    local jobName = player.PlayerData.job.name
    for _, group in ipairs(Config.SecurityCam.groups) do
        if jobName == group then return true end
    end
    return false
end

RegisterNetEvent('security_cam:view', function(cameraId)
    local src = source
    if not src then return end
    if not checkRateLimit(src, 'view', 2) then return Notify(src, Locale('security_cam.no_access'), 'error') end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    if not hasAccess(player) then return Notify(src, Locale('security_cam.no_access'), 'error') end
    cameraId = tonumber(cameraId)
    local camera = nil
    for _, c in ipairs(Config.SecurityCam.cameras) do
        if c.id == cameraId then
            camera = c
            break
        end
    end
    if not camera then return end
    activeSessions[src] = { cameraId = cameraId, startTime = GetGameTimer() }
    TriggerClientEvent('security_cam:client:view', src, camera)
end)

RegisterNetEvent('security_cam:switch', function(direction)
    local src = source
    if not src or not direction then return end
    if not checkRateLimit(src, 'switch', 2) then return end
    local session = activeSessions[src]
    if not session then return end
    local cameras = Config.SecurityCam.cameras
    local currentIdx = nil
    for i, c in ipairs(cameras) do
        if c.id == session.cameraId then
            currentIdx = i
            break
        end
    end
    if not currentIdx then return end
    local newIdx
    if direction == 'next' then
        newIdx = currentIdx + 1
        if newIdx > #cameras then newIdx = 1 end
    else
        newIdx = currentIdx - 1
        if newIdx < 1 then newIdx = #cameras end
    end
    local newCam = cameras[newIdx]
    session.cameraId = newCam.id
    TriggerClientEvent('security_cam:client:switch', src, newCam)
end)

RegisterNetEvent('security_cam:stop', function()
    local src = source
    if not src then return end
    activeSessions[src] = nil
    TriggerClientEvent('security_cam:client:stop', src)
end)

AddEventHandler('playerDropped', function()
    local src = source
    activeSessions[src] = nil
end)
