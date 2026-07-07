local QBox = exports['qbx-core']:GetCoreObject()
local RATE_LIMITS = {}

local function checkRateLimit(src, action, maxPerMin)
    local key = src .. ':' .. action
    local now = os.time()
    RATE_LIMITS[key] = RATE_LIMITS[key] or {}
    table.insert(RATE_LIMITS[key], now)
    for i = #RATE_LIMITS[key], 1, -1 do
        if now - RATE_LIMITS[key][i] > 60 then table.remove(RATE_LIMITS[key], i) end
    end
    return #RATE_LIMITS[key] <= maxPerMin
end

local vehicleFuel = {}

RegisterNetEvent('fuel:refuel', function(amount)
    local src = source
    if not checkRateLimit(src, 'refuel', 3) then return end
    amount = tonumber(amount)
    if not amount or amount < 1 or amount > 100 then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local ped = GetPlayerPed(src)
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not vehicle or vehicle == 0 then return end
    local fuelLevel = GetVehicleFuelLevel(vehicle)
    local maxFuel = 100.0
    local needed = maxFuel - fuelLevel
    local toAdd = math.min(amount, needed)
    if toAdd <= 0 then return Wrappers.Notify(src, Locale('fuel_ui.full_tank'), 'info') end
    local cost = math.floor(toAdd * 2)
    local cash = player.PlayerData.money.cash
    if cash < cost then return Wrappers.Notify(src, Locale('fuel_ui.no_money'), 'error') end
    player.Functions.RemoveMoney('cash', cost, 'fuel')
    SetVehicleFuelLevel(vehicle, fuelLevel + toAdd)
    vehicleFuel[VehiToNet(vehicle)] = fuelLevel + toAdd
    Wrappers.Notify(src, Locale('fuel_ui.refuel') .. ' ' .. string.format('%.1f', toAdd) .. 'L', 'success')
end)

RegisterNetEvent('fuel:jerrycanRefill', function()
    local src = source
    if not checkRateLimit(src, 'jerrycan', 3) then return end
    local player = QBox.Functions.GetPlayer(src)
    if not player then return end
    local hasItem = player.Functions.GetItemByName('jerrycan')
    if not hasItem then return end
    local cash = player.PlayerData.money.cash
    if cash < 20 then return Wrappers.Notify(src, Locale('fuel_ui.no_money'), 'error') end
    player.Functions.RemoveMoney('cash', 20, 'jerrycan')
    player.Functions.AddItem('jerrycan', 1, nil, { fuel = Config.FuelUI.jerrycanRefill })
    Wrappers.Notify(src, 'Jerrycan refilled', 'success')
end)

CreateThread(function()
    while true do
        Wait(Config.FuelUI.checkInterval)
        local players = QBox.Functions.GetPlayers()
        for _, src in ipairs(players) do
            local ped = GetPlayerPed(src)
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle and vehicle > 0 then
                local netId = VehiToNet(vehicle)
                local fuel = vehicleFuel[netId] or GetVehicleFuelLevel(vehicle)
                local class = GetVehicleClass(vehicle)
                local consumption = Config.FuelUI.economyCars[1] or 0.08
                if class == 6 then consumption = Config.FuelUI.sportCars[1] or 0.12 end
                if class == 7 then consumption = Config.FuelUI.superCars[1] or 0.15 end
                fuel = math.max(fuel - consumption, 0)
                SetVehicleFuelLevel(vehicle, fuel)
                vehicleFuel[netId] = fuel
            end
        end
    end
end)
