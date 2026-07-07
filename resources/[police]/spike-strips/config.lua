Config = Config or {}

Config.SpikeStrips = {
    Model = 'prop_roadcone02a',
    StripLength = 5.0,
    StripWidth = 1.0,
    DeployTime = 2500,
    PickupTime = 2000,
    PopChance = 85,
    MaxPops = 4,
    DamageMultiplier = 0.3,
    DespawnTime = 300,
    MaxActive = 3,
    Cooldown = 30000,
    BurstTires = true,
    DamageVehicle = true,
    RequireDuty = true,
    MinRank = 0,
    AllowedJobs = { 'police', 'sheriff', 'statepolice' },
    RequiredItem = 'spikestrip',
    ItemLabel = 'Spike Strip',

    DeployZones = {
        { coords = vector3(430.0, -995.0, 25.0), radius = 50.0 },
        { coords = vector3(360.0, -1605.0, 24.0), radius = 50.0 }
    },

    TargetOptions = {
        deploy = {
            icon = 'fas fa-chevron-down',
            label = 'Deploy Spike Strip',
            group = 'police',
            distance = 2.0
        },
        pickup = {
            icon = 'fas fa-hand',
            label = 'Pick Up Strip',
            distance = 2.0
        }
    }
}
