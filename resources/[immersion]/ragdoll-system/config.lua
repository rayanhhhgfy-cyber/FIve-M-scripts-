Config = Config or {}

Config.Ragdoll = {
    enabled = true,
    fallHeightThreshold = 5.0,
    vehicleImpactThreshold = 30.0,
    ragdollMinDuration = 1000,
    ragdollMaxDuration = 5000,
    enableCommand = true,
    toggleCommand = 'ragdoll',
    toggleKey = 'u'
}

Config.FallDamage = {
    enabled = true,
    minHeightForDamage = 3.0,
    damageMultiplier = 10.0,
    maxDamage = 100,
    ragdollOnFall = true
}

Config.VehicleImpact = {
    enabled = true,
    minSpeed = 20.0,
    ragdollDuration = 3000,
    stressAmount = 15
}

Config.Combat = {
    ragdollOnMeleeHit = true,
    ragdollOnExplosion = true,
    ragdollDuration = 2000
}

Config.ToggleRagdoll = {
    enableAutoRagdoll = false,
    autoRagdollChance = 0.1,
    autoRagdollMinSpeed = 50.0
}
