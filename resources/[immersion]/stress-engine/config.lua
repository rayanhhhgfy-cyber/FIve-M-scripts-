Config = Config or {}

Config.Stress = {
    enabled = true,
    updateInterval = 500,
    relaxInterval = 10000,
    maxStress = 100,
    minStressForEffects = 20
}

Config.VisualEffects = {
    screenShake = {
        enabled = true,
        minIntensity = 0.1,
        maxIntensity = 1.0,
        shakeType = 'SMALL_EXPLOSION_SHAKE'
    },
    aimJitter = {
        enabled = true,
        minJitter = 0.0,
        maxJitter = 2.0,
        jitterSpeed = 0.5
    },
    blur = {
        enabled = true,
        minBlur = 0.0,
        maxBlur = 1.5
    },
    chromatic = {
        enabled = true,
        minAmount = 0.0,
        maxAmount = 0.05
    },
    vignette = {
        enabled = true,
        minAmount = 0.0,
        maxAmount = 0.4
    }
}

Config.StressTriggers = {
    damage = { amount = 15, cooldown = 1000 },
    kill = { amount = 40, cooldown = 1000 },
    death = { amount = 60, cooldown = 1000 },
    police_chase = { amount = 2, cooldown = 5000 },
    crash = { amount = 10, cooldown = 2000 },
    fall = { amount = 8, cooldown = 2000 },
    weapon_drawn = { amount = 1, cooldown = 10000 },
    combat = { amount = 3, cooldown = 3000 }
}

Config.Relaxation = {
    idle = { amountPerInterval = 1.0, requiresStill = true, stillTime = 15000 },
    smoking = { amountPerInterval = 5.0, item = 'cigarettes', interval = 5000 },
    drinking = { amountPerInterval = 3.0, item = 'beer', interval = 5000 },
    sitting = { amountPerInterval = 1.5, requiresStill = true },
    walking = { amountPerInterval = 0.5 },
    tv = { amountPerInterval = 2.0, requiresStill = true }
}
