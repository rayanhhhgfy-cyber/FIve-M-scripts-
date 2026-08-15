Config = {}
Config.SpawnInterval = 300000 -- 5 minutes
Config.MaxConcurrent = 3
Config.Events = {
    store_robbery = {
        label = "Store Robbery in Progress",
        coords = vector3(25.7, -1347.3, 29.5),
        reward = 500
    },
    crashed_truck = {
        label = "Crashed Delivery Truck",
        coords = vector3(1188.6, -3253.8, 6.0),
        reward = 750
    },
    gas_leak = {
        label = "Gas Leak Hazard",
        coords = vector3(-204.5, -1325.2, 30.8),
        reward = 600
    }
}
