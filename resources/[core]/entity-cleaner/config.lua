Config = Config or {}

Config.Cleaner = {
    enabled = true,
    interval = 300000,
    dryRun = false,
    logCleanups = true
}

Config.VehicleThresholds = {
    abandonedAge = 600000,
    abandonedDistance = 200.0,
    noPlayersInVehicle = true,
    engineOff = true,
    excludeJobVehicles = true,
    excludeGroupVehicles = true,
    jobVehicles = { 'police', 'ambulance', 'mechanic', 'taxi' },
    blacklistModels = { 'bmx', 'scorcher', 'cruiser', 'fixter', 'tribike', 'tribike2', 'tribike3' },
    exemptPlates = {},
    maxToRemove = 10
}

Config.PedThresholds = {
    abandonedAge = 300000,
    abandonedDistance = 150.0,
    excludePlayerPeds = true,
    excludeMissionPeds = false,
    maxToRemove = 20
}

Config.ObjectThresholds = {
    abandonedAge = 600000,
    abandonedDistance = 100.0,
    excludeMissionObjects = true,
    blacklistModels = {},
    maxToRemove = 30
}

Config.ParticleThresholds = {
    maxParticles = 100,
    cleanupInterval = 120000
}

Config.PropThresholds = {
    maxProps = 200,
    cleanupInterval = 180000
}

Config.SafeZones = {
    { name = 'Legion Square', coords = vector3(215.0, -810.0, 30.0), radius = 100.0 },
    { name = 'Beach', coords = vector3(-1550.0, -980.0, 13.0), radius = 150.0 },
    { name = 'Airport', coords = vector3(-1050.0, -3400.0, 14.0), radius = 200.0 }
}
