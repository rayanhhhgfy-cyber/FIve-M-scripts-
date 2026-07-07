Config = Config or {}

Config.Flatbed = {
    VehicleModel = 'flatbed',
    LoadTime = 7000,
    UnloadTime = 5000,
    MaxLoadWeight = 5000,
    LoadRange = 3.0,
    TransportSpeed = 25.0,

    Offsets = {
        Position = vector3(0.0, 0.5, 0.8),
        Rotation = vector3(0.0, 0.0, 0.0)
    },

    AllowedJobs = { 'tow' },
    RequireJob = false,

    TargetOptions = {
        load = { icon = 'fas fa-truck-loading', label = 'Load Vehicle', distance = 3.0 },
        unload = { icon = 'fas fa-truck-loading', label = 'Unload Vehicle', distance = 3.0 }
    }
}
