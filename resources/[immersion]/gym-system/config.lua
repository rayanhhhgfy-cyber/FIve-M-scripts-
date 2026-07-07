Config = Config or {}

Config.Gym = {
    enabled = true,
    maxStrength = 100,
    maxStamina = 100,
    strengthPerRep = 0.5,
    staminaPerRep = 0.3,
    repTime = 3000,
    cooldownBetweenSets = 15000,
    maxDailyGain = 10,
    xpMultiplier = 1.0
}

Config.GymLocations = {
    {
        name = 'Downtown Gym',
        coords = { x = -1200.0, y = -1560.0, z = 4.5 },
        blip = { sprite = 311, color = 3 }
    },
    {
        name = 'Sandy Shores Gym',
        coords = { x = 1950.0, y = 3750.0, z = 32.0 },
        blip = { sprite = 311, color = 3 }
    }
}

Config.Equipment = {
    bench_press = {
        label = 'Bench Press',
        icon = 'fas fa-dumbbell',
        coords = { x = -1200.0, y = -1560.0, z = 4.5 },
        heading = 0.0,
        animDict = 'amb@prop_human_seat_chair_mp@male@idle_d',
        animClip = 'idle_d',
        strengthGain = 1.0,
        staminaCost = 5,
        minStrength = 0
    },
    pullup_bar = {
        label = 'Pull-up Bar',
        icon = 'fas fa-hand-rock',
        coords = { x = -1195.0, y = -1565.0, z = 5.5 },
        heading = 90.0,
        animDict = 'amb@prop_human_muscle_chin_ups@male@base',
        animClip = 'base',
        strengthGain = 1.5,
        staminaCost = 8,
        minStrength = 5
    },
    squat_rack = {
        label = 'Squat Rack',
        icon = 'fas fa-weight-hanging',
        coords = { x = -1210.0, y = -1560.0, z = 4.5 },
        heading = 180.0,
        animDict = 'amb@prop_human_muscle_free_weights@male@base',
        animClip = 'base',
        strengthGain = 1.2,
        staminaCost = 6,
        minStrength = 2
    },
    treadmill = {
        label = 'Treadmill',
        icon = 'fas fa-running',
        coords = { x = -1205.0, y = -1555.0, z = 4.5 },
        heading = 270.0,
        animDict = 'amb@world_human_jog_standing@male@base',
        animClip = 'base',
        strengthGain = 0.3,
        staminaGain = 1.0,
        staminaCost = 3,
        minStrength = 0
    }
}

Config.StrengthEffects = {
    meleeMultiplier = { min = 1.0, max = 2.0 },
    runningSpeed = { min = 1.0, max = 1.15 },
    carryWeight = { min = 1.0, max = 1.2 },
    fallDamageReduction = { min = 0.0, max = 0.5 }
}
