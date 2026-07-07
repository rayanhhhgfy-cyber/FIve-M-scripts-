local QBCore = exports['qbx_core']:GetCoreObject()
local RATE_LIMITS = {}
local playerPings = {}

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

CreateThread(function()
    while true do
        Wait(Config.SpeedCamera.checkInterval)
        local cameras = Config.SpeedCamera.cameras
        local players = GetPlayers()
        for i = 1, #players do
            local src = tonumber(players[i])
            if src then
                local ped = GetPlayerPed(src)
                if ped and ped ~= 0 then
                    local veh = GetVehiclePedIsIn(ped, false)
                    if veh and veh ~= 0 then
                        local seat = GetPedInVehicleSeat(veh, -1)
                        if seat == ped then
                            local pos = GetEntityCoords(veh)
                            local speed = GetEntitySpeed(veh) * 3.6
                            local lastPing = playerPings[src] or 0
                            if GetGameTimer() - lastPing > 10000 then
                                for _, cam in ipairs(cameras) do
                                    local dist = #(pos - cam.coords)
                                    if dist < Config.SpeedCamera.flashRange then
                                        if speed > cam.limit then
                                            if not checkRateLimit(src, 'camera_' .. cam.coords.x, 1) then break end
                                            local overspeed = math.floor(speed - cam.limit)
                                            local fine = math.floor(overspeed * Config.SpeedCamera.finePerMphOver)
                                            playerPings[src] = GetGameTimer()
                                            TriggerClientEvent('speed_camera:client:flash', src, cam)
                                            MySQL.insert.await('INSERT INTO speed_camera_fines (citizenid, license_plate, speed, limit, fine, date) VALUES (?, ?, ?, ?, ?, NOW())', {
                                                QBCore.Functions.GetPlayer(src).PlayerData.citizenid,
                                                QBCore.Functions.GetPlate(veh),
                                                math.floor(speed),
                                                cam.limit,
                                                fine,
                                            })
                                            if QBCore.Functions.GetPlayer(src).PlayerData.money.cash >= fine then
                                                QBCore.Functions.GetPlayer(src).Functions.RemoveMoney('cash', fine)
                                            elseif QBCore.Functions.GetPlayer(src).PlayerData.money.bank >= fine then
                                                QBCore.Functions.GetPlayer(src).Functions.RemoveMoney('bank', fine)
                                            end
                                            Notify(src, Locale('speed_camera.fine') .. ': $' .. fine, 'warning')
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('speed_camera:payFine', function(fineId)
    local src = source
    if not src or not fineId then return end
    if not checkRateLimit(src, 'payFine', 2) then return end
    local result = MySQL.query.await('SELECT * FROM speed_camera_fines WHERE id = ? AND citizenid = ?', {
        fineId,
        QBCore.Functions.GetPlayer(src).PlayerData.citizenid,
    })
    if not result or #result == 0 then return end
    local fine = result[1]
    if QBCore.Functions.GetPlayer(src).PlayerData.money.cash >= fine.fine then
        QBCore.Functions.GetPlayer(src).Functions.RemoveMoney('cash', fine.fine)
        MySQL.query.await('UPDATE speed_camera_fines SET paid = 1 WHERE id = ?', { fineId })
        Notify(src, Locale('speed_camera.paid'), 'success')
    elseif QBCore.Functions.GetPlayer(src).PlayerData.money.bank >= fine.fine then
        QBCore.Functions.GetPlayer(src).Functions.RemoveMoney('bank', fine.fine)
        MySQL.query.await('UPDATE speed_camera_fines SET paid = 1 WHERE id = ?', { fineId })
        Notify(src, Locale('speed_camera.paid'), 'success')
    else
        Notify(src, Locale('shops.no_money'), 'error')
    end
end)
