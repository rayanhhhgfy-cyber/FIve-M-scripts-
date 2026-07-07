Config = Config or {}

Config.PizzaJob = {
    shopCoords = vector3(810.06, -753.32, 26.78),
    deliveryZones = {
        vector3(-1420.34, -599.87, 30.12),
        vector3(-1096.22, -615.15, 25.67),
        vector3(-815.67, -696.34, 28.45),
        vector3(-651.44, -560.23, 35.56),
        vector3(-445.33, -345.67, 34.89),
    },
    vehicle = 'panto',
    paymentPerDelivery = 25,
    bonusPerPerfect = 10,
    maxDeliveriesPerShift = 15,
    timeLimitPerDelivery = 180,
}

Config.Rewards = {
    pizza = { item = 'pizza', min = 1, max = 2 },
}
