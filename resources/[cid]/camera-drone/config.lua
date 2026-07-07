Config = Config or {}

Config.Drone = {
    ItemName = 'drone',
    ItemLabel = 'Surveillance Drone',
    Model = 'prop_quadcopter',
    MaxAltitude = 100.0,
    MinAltitude = 1.0,
    Speed = 8.0,
    BoostSpeed = 15.0,
    BoostDuration = 5000,
    BatteryMax = 100,
    BatteryDrain = 0.5,
    HoverMode = true,
    MaxRange = 300.0,
    ReturnToHome = true,
    AutoLand = true,
    CameraFOV = 90.0,
    NightVision = true,
    ThermalVision = true,
    RequireDuty = true,
    MinRank = 3,
    AllowedJobs = { 'cid', 'police' },
    MaxActiveDrones = 2,
    DeployTime = 3000,
    StoreTime = 2000,

    Controls = {
        Forward = 32,
        Backward = 33,
        Left = 34,
        Right = 35,
        Up = 85,
        Down = 86,
        Boost = 21,
        Camera = 24,
        NightVision = 57,
        Thermal = 56,
        Land = 47,
        Return = 48
    },

    Camera = {
        ZoomLevels = { 1.0, 2.0, 4.0, 8.0 },
        ScreenshotKey = 20,
        PhotoStorage = 50
    }
}
