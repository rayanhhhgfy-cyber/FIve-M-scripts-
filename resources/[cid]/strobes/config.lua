Config = Config or {}

Config.Strobes = {
    ItemName = 'tactical_strobe',
    ItemLabel = 'Tactical Strobe',
    LightIntensity = 6.0,
    LightRange = 25.0,
    FlashInterval = 200,
    FlashDuration = 50,
    LightColor = { r = 255, g = 255, b = 255 },
    DeployTime = 2000,
    PickupTime = 1500,
    BatteryTime = 300,
    MaxActive = 3,
    ReqEquipment = true,
    AllowedJobs = { 'cid', 'police' },
    MinRank = 1,
    RequireDuty = true,
    DisorientRadius = 10.0,
    DisorientDuration = 2000,

    TargetOptions = {
        deploy = { icon = 'fas fa-lightbulb', label = 'Deploy Strobe', group = 'cid', distance = 2.0 },
        pickup = { icon = 'fas fa-hand', label = 'Pick Up Strobe', distance = 2.0 }
    }
}
