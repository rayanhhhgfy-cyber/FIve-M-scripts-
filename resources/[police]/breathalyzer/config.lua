Config = Config or {}

Config.Breathalyzer = {
    TestTime = 4000,
    Range = 2.5,
    Cooldown = 10000,
    ItemName = 'breathalyzer',
    ItemLabel = 'Breathalyzer',
    DrunkThreshold = 0.05,
    VeryDrunkThreshold = 0.12,
    ExtremeDrunkThreshold = 0.20,
    RequireDuty = true,
    MinRank = 0,
    AllowedJobs = { 'police', 'sheriff', 'statepolice' },
    BACDecayRate = 0.01,
    BACDecayInterval = 300000,

    TargetOptions = {
        icon = 'fas fa-wind',
        label = 'Test Breath',
        group = 'police',
        distance = 2.0
    }
}
