Config = Config or {}

Config.TowJob = {
    JobName = 'tow',
    JobLabel = 'Tow Truck Driver',
    Payment = 250,
    BonusPayment = 100,
    MaxMissions = 5,
    MissionRange = 300.0,
    TowDistance = 50.0,
    BlipTime = 60000,

    Locations = {
        Depot = { coords = vector3(895.0, -1150.0, 25.0), heading = 90.0, label = 'Tow Depot' },
        Dropoff = { coords = vector3(870.0, -1140.0, 25.0), heading = 270.0, label = 'Drop-off Point' }
    },

    SpawnPoints = {
        { coords = vector3(900.0, -1150.0, 25.0), heading = 90.0 },
        { coords = vector3(910.0, -1150.0, 25.0), heading = 90.0 }
    },

    StuckLocations = {
        { coords = vector3(120.0, -1100.0, 29.0), label = 'Stuck on highway' },
        { coords = vector3(-800.0, -1200.0, 20.0), label = 'Stuck in ditch' },
        { coords = vector3(500.0, -1500.0, 29.0), label = 'Engine failure' },
        { coords = vector3(-300.0, -800.0, 32.0), label = 'Ran out of gas' },
        { coords = vector3(1000.0, -800.0, 25.0), label = 'Flat tire' },
        { coords = vector3(600.0, -600.0, 30.0), label = 'Accident recovery' },
        { coords = vector3(-500.0, -1000.0, 23.0), label = 'Breakdown' },
        { coords = vector3(1400.0, -900.0, 35.0), label = 'Overheated engine' }
    },

    VehicleModels = { 'towtruck', 'towtruck2', 'flatbed' },

    TargetOptions = {
        depot = { icon = 'fas fa-warehouse', label = 'Tow Job Depot', distance = 2.5 },
        vehicle = { icon = 'fas fa-truck', label = 'Tow Vehicle', distance = 3.0 },
        dropoff = { icon = 'fas fa-flag-checkered', label = 'Drop Off Vehicle', distance = 3.0 }
    }
}
