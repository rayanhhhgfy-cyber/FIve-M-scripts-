local activeShifts = {}
local shiftCooldowns = {}
local fareTimers = {}

MySQL.query('CREATE TABLE IF NOT EXISTS taxi_shifts (id INT AUTO_INCREMENT PRIMARY KEY, citizenid VARCHAR(50) NOT NULL, start_time INT NOT NULL, end_time INT DEFAULT NULL, earnings INT DEFAULT 0, fares_completed INT DEFAULT 0)')

MySQL.query('CREATE TABLE IF NOT EXISTS taxi_fares (id INT AUTO_INCREMENT PRIMARY KEY, shift_id INT, citizenid VARCHAR(50), fare_amount INT, passenger_type VARCHAR(20), completed_at INT, FOREIGN KEY (shift_id) REFERENCES taxi_shifts(id))')

local function IsOnCooldown(src)
    if shiftCooldowns[src] and shiftCooldowns[src] > os.time() then
        return true
    end
    return false
end

local function LogToDiscord(message, color)
    if Config.DiscordWebhook == '' then return end
    local embed = {
        {
            ['color'] = color or 16753920,
            ['title'] = 'Taxi Job Log',
            ['description'] = message,
            ['footer'] = { ['text'] = os.date('%Y-%m-%d %H:%M:%S') }
        }
    }
    PerformHttpRequest(Config.DiscordWebhook, function() end, 'POST', json.encode({ embeds = embed }), { ['Content-Type'] = 'application/json' })
end

local function GetNPCDestination()
    local fare = Config.NPCFares[math.random(#Config.NPCFares)]
    return fare
end

local function GenerateNPCFare()
    local dest = GetNPCDestination()
    local basePay = dest.payment or Config.BaseFare
    local tipChance = math.random(1, 100)
    local tip = 0
    if tipChance <= 15 then
        tip = math.random(1, 10)
    end
    return {
        pickup = vector3(Config.Garage.x + math.random(-200, 200), Config.Garage.y + math.random(-200, 200), Config.Garage.z),
        destination = dest.coords,
        payment = basePay + tip,
        passengerType = 'npc'
    }
end

RegisterNetEvent('taxi:server:startShift', function()
    local src = source
    local Player = exports.ox_lib:GetPlayer(src)
    if not Player then return end
    if IsOnCooldown(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Taxi', description = 'Please wait before starting a new shift', type = 'error' })
        return
    end
    local citizenid = Player.PlayerData.citizenid
    MySQL.insert('INSERT INTO taxi_shifts (citizenid, start_time) VALUES (?, ?)', { citizenid, os.time() }, function(insertId)
        if insertId then
            activeShifts[src] = {
                id = insertId,
                citizenid = citizenid,
                startTime = os.time(),
                faresCompleted = 0,
                earnings = 0
            }
            shiftCooldowns[src] = os.time() + Config.ShiftCooldown
            TriggerClientEvent('taxi:client:startShift', src)
            LogToDiscord('Player ' .. GetPlayerName(src) .. ' started a taxi shift', 3066993)
            local fareTimer = Citizen.CreateThread(function()
                while activeShifts[src] do
                    Citizen.Wait(math.random(30000, 90000))
                    if activeShifts[src] then
                        local elapsed = os.time() - activeShifts[src].startTime
                        if elapsed < Config.MaxShiftDuration then
                            local fare = GenerateNPCFare()
                            TriggerClientEvent('taxi:client:fareCall', src, fare)
                        else
                            TriggerClientEvent('taxi:client:forceEndShift', src)
                            activeShifts[src] = nil
                            LogToDiscord('Player ' .. GetPlayerName(src) .. ' shift auto-ended (max duration)', 15158332)
                        end
                    end
                end
            end)
            fareTimers[src] = fareTimer
        end
    end)
end)

RegisterNetEvent('taxi:server:endShift', function()
    local src = source
    if not activeShifts[src] then return end
    local shift = activeShifts[src]
    MySQL.update('UPDATE taxi_shifts SET end_time = ?, earnings = ?, fares_completed = ? WHERE id = ?', { os.time(), shift.earnings, shift.faresCompleted, shift.id })
    if fareTimers[src] then
        Citizen.StopThread(fareTimers[src])
        fareTimers[src] = nil
    end
    local totalEarnings = shift.earnings
    activeShifts[src] = nil
    TriggerClientEvent('taxi:client:endShift', src)
    LogToDiscord('Player ' .. GetPlayerName(src) .. ' ended taxi shift. Earnings: $' .. totalEarnings, 16753920)
end)

RegisterNetEvent('taxi:server:completeFare', function(fareAmount, passengerType)
    local src = source
    if not activeShifts[src] then return end
    local Player = exports.ox_lib:GetPlayer(src)
    if not Player then return end
    local amount = math.floor(fareAmount)
    if amount < 0 or amount > 10000 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Taxi', description = 'Invalid fare amount', type = 'error' })
        return
    end
    activeShifts[src].faresCompleted = activeShifts[src].faresCompleted + 1
    activeShifts[src].earnings = activeShifts[src].earnings + amount
    Player.Functions.AddMoney('cash', amount)
    MySQL.insert('INSERT INTO taxi_fares (shift_id, citizenid, fare_amount, passenger_type, completed_at) VALUES (?, ?, ?, ?, ?)', {
        activeShifts[src].id,
        activeShifts[src].citizenid,
        amount,
        passengerType or 'npc',
        os.time()
    })
    LogToDiscord(GetPlayerName(src) .. ' completed a fare: $' .. amount .. ' (' .. (passengerType or 'npc') .. ')', 3066993)
end)

RegisterNetEvent('taxi:server:hailTaxi', function(driverNetId, pickupCoords)
    local src = source
    local driver = NetworkGetEntityFromNetworkId(driverNetId)
    if not driver or not DoesEntityExist(driver) then return end
    local driverPed = GetPedInVehicleSeat(driver, -1)
    if not driverPed or not IsPedAPlayer(driverPed) then return end
    local driverSrc = NetworkGetPlayerIndexFromPed(driverPed)
    if not driverSrc then return end
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local dist = #(playerCoords - vector3(pickupCoords.x, pickupCoords.y, pickupCoords.z))
    if dist > Config.HailRange + 5.0 then return end
    TriggerClientEvent('taxi:client:passengerHail', driverSrc, NetworkGetNetworkIdFromEntity(GetPlayerPed(src)), pickupCoords)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Taxi', description = 'Taxi hailed! A driver is on the way.', type = 'success' })
end)

RegisterNetEvent('taxi:server:requestFare', function()
    local src = source
    if not activeShifts[src] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Taxi', description = 'You are not on shift', type = 'error' })
        return
    end
    local fare = GenerateNPCFare()
    TriggerClientEvent('taxi:client:fareCall', src, fare)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if activeShifts[src] then
        local shift = activeShifts[src]
        MySQL.update('UPDATE taxi_shifts SET end_time = ?, earnings = ?, fares_completed = ? WHERE id = ?', { os.time(), shift.earnings, shift.faresCompleted, shift.id })
        if fareTimers[src] then
            Citizen.StopThread(fareTimers[src])
            fareTimers[src] = nil
        end
        activeShifts[src] = nil
        LogToDiscord(GetPlayerName(src) .. ' disconnected during taxi shift', 15158332)
    end
end)
