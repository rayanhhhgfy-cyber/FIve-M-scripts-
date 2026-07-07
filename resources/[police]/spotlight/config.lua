Config = Config or {}

Config.Spotlight = {
    ItemName = 'spotlight',
    ItemLabel = 'Police Spotlight',
    MaxRange = 100.0,
    LightIntensity = 8.0,
    LightColor = { r = 255, g = 255, b = 255 },
    LightRadius = 30.0,
    ConeAngle = 15.0,
    ToggleKey = 'U',
    RequireDuty = true,
    MinRank = 1,
    AllowedJobs = { 'police', 'sheriff', 'statepolice' },
    BatteryMax = 100,
    BatteryDrainRate = 0.5,
    HelicopterOnly = false,
    VehicleOnly = true,
    AllowManualAim = true,
    AimSpeed = 2.0
}
