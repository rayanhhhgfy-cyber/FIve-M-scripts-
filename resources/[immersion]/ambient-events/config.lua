Config = Config or {}

Config.AmbientEvents = {
    IntervalMinutes = 15,
    MaxConcurrentEvents = 3,
    RewardPayout = 1250,

    Types = {
        armed_robbery = {
            label = "Armed Store Robbery in Progress",
            category = "police",
            coords = vector3(28.2, -1349.8, 29.5),
            reward = 1500,
        },
        crashed_truck = {
            label = "Crashed Cargo Truck Spilled Goods",
            category = "police",
            coords = vector3(1188.4, -3252.1, 6.0),
            reward = 1200,
        },
        gas_leak = {
            label = "Hazardous Gas Leak Reported",
            category = "ems",
            coords = vector3(273.8, -1580.2, 29.2),
            reward = 1000,
        },
        prison_transport = {
            label = "Disabled Prison Transport Bus",
            category = "police",
            coords = vector3(1850.2, 2586.0, 45.6),
            reward = 1800,
        }
    }
}
