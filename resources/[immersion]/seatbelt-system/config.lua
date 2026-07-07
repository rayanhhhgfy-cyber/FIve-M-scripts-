Config = Config or {}

Config.Seatbelt = {
    enabled = true,
    toggleKey = 30,
    toggleCommand = 'belt',
    checkInterval = 100,
    warningInterval = 5000
}

Config.Ejection = {
    enabled = true,
    minSpeedForEjection = 30.0,
    ejectionChance = 0.3,
    maxEjectionSpeed = 150.0,
    windshieldBreakChance = 0.7,
    ragdollDuration = 5000
}

Config.Shake = {
    enabled = true,
    heavyBrakeShake = { intensity = 0.5, duration = 1000 },
    collisionShake = { intensity = 1.0, duration = 2000 },
    highSpeedShake = { minSpeed = 100.0, intensity = 0.2 }
}

Config.Damage = {
    collisionDamageMultiplier = 1.5,
    ejectionDamage = 50,
    speedDamageMultiplier = 0.5
}

Config.Sounds = {
    enabled = true,
    beltWarning = { name = 'seatbelt_warning', volume = 0.5 },
    collision = { name = 'collision', volume = 0.8 },
    windshieldBreak = { name = 'glass_break', volume = 0.7 }
}
