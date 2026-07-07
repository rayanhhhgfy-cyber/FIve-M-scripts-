local QBCore = exports['qbx-core']:GetCoreObject()
local RATE_LIMITS = {}

local activeDeliveries = {}

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

local function hasItem(src, itemName)
    local count = exports.ox_inventory:Search(src, 'count', itemName)
    return (count or 0) >= 1
end

local function addItem(src, itemName, count)
    exports.ox_inventory:AddItem(src, itemName, count or 1)
end

local function removeItem(src, itemName, count)
    exports.ox_inventory:RemoveItem(src, itemName, count or 1)
end

local function getRandomDeliveryZone()
    local zones = Config.PizzaJob.deliveryZones
    return zones[math.random(#zones)]
end

RegisterNetEvent('pizza:startDelivery', function()
    local src = source
    if not checkRateLimit(src, 'startDelivery', 1) then
        Wrappers.Notify(src, Locale('error.rate_limit'), 'error')
        return
    end
    if activeDeliveries[src] then
        Wrappers.Notify(src, Locale('pizza_this.delivery_cancelled'), 'error')
        return
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local cash = Player.PlayerData.money.cash or 0
    local cost = 0
    local zone = getRandomDeliveryZone()
    local vehicleModel = joaat(Config.PizzaJob.vehicle)
    if not IsModelInCdimage(vehicleModel) or not IsModelAVehicle(vehicleModel) then
        Wrappers.Notify(src, Locale('error.vehicle_invalid'), 'error')
        return
    end
    local plate = 'PIZZA' .. tostring(math.random(100, 999))
    local netId = 0
    local veh = CreateVehicle(vehicleModel, Config.PizzaJob.shopCoords.x, Config.PizzaJob.shopCoords.y, Config.PizzaJob.shopCoords.z + 1.0, 0.0, true, false)
    if not veh or veh == 0 then
        Wrappers.Notify(src, Locale('error.vehicle_spawn'), 'error')
        return
    end
    SetVehicleNumberPlateText(veh, plate)
    SetVehicleOnGroundProperly(veh)
    SetEntityAsMissionEntity(veh, true, true)
    netId = NetworkGetNetworkIdFromEntity(veh)
    activeDeliveries[src] = {
        vehicle = veh,
        netId = netId,
        zone = zone,
        startTime = os.time(),
        deliveries = 0,
    }
    local reward = Config.Rewards.pizza
    local pizzaCount = math.random(reward.min, reward.max)
    addItem(src, reward.item, pizzaCount)
    TriggerClientEvent('pizza:startDeliveryClient', src, zone, netId, plate)
    Wrappers.Notify(src, Locale('pizza_this.start_delivery'), 'success')
end)

RegisterNetEvent('pizza:completeDelivery', function()
    local src = source
    if not checkRateLimit(src, 'completeDelivery', 1) then
        Wrappers.Notify(src, Locale('error.rate_limit'), 'error')
        return
    end
    local delivery = activeDeliveries[src]
    if not delivery then
        Wrappers.Notify(src, Locale('error.no_delivery'), 'error')
        return
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not hasItem(src, 'pizza') then
        Wrappers.Notify(src, Locale('error.no_pizza'), 'error')
        return
    end
    removeItem(src, 'pizza', 1)
    local elapsed = os.time() - delivery.startTime
    local bonus = 0
    if elapsed <= Config.PizzaJob.timeLimitPerDelivery then
        bonus = Config.PizzaJob.bonusPerPerfect
        Wrappers.Notify(src, Locale('pizza_this.perfect_delivery'), 'success')
    end
    local payment = Config.PizzaJob.paymentPerDelivery + bonus
    Player.Functions.AddMoney('cash', payment, nil)
    delivery.deliveries = delivery.deliveries + 1
    if delivery.deliveries >= Config.PizzaJob.maxDeliveriesPerShift then
        if DoesEntityExist(delivery.vehicle) then
            DeleteVehicle(delivery.vehicle)
        end
        activeDeliveries[src] = nil
        Wrappers.Notify(src, Locale('pizza_this.return_vehicle'), 'success')
    else
        local newZone = getRandomDeliveryZone()
        delivery.zone = newZone
        delivery.startTime = os.time()
        local reward = Config.Rewards.pizza
        local pizzaCount = math.random(reward.min, reward.max)
        addItem(src, reward.item, pizzaCount)
        TriggerClientEvent('pizza:newDeliveryClient', src, newZone)
    end
    Wrappers.Notify(src, Locale('pizza_this.payment_received'), 'success')
end)

RegisterNetEvent('pizza:cancelDelivery', function()
    local src = source
    if not checkRateLimit(src, 'cancelDelivery', 1) then
        Wrappers.Notify(src, Locale('error.rate_limit'), 'error')
        return
    end
    local delivery = activeDeliveries[src]
    if not delivery then return end
    if DoesEntityExist(delivery.vehicle) then
        DeleteVehicle(delivery.vehicle)
    end
    activeDeliveries[src] = nil
    Wrappers.Notify(src, Locale('pizza_this.delivery_cancelled'), 'error')
end)
