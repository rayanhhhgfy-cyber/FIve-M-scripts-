Config = Config or {}

Config.MapBuilder = {
    command = 'mapbuilder',
    authorizedGroups = { 'admin', 'superadmin', 'god' },
    autoSaveInterval = 300000, -- 5 minutes
    maxDistanceMeasure = 1000.0,
    brushMaxRadius = 50.0,
    defaultFlySpeed = 0.5,
    maxFlySpeed = 5.0,
}

Config.Interactive = {
    -- Cooldowns in milliseconds
    trashCooldown = 1800000, -- 30 minutes
    trashItems = {
        { name = 'lockpick', chance = 0.15, min = 1, max = 2 },
        { name = 'sandwich', chance = 0.30, min = 1, max = 1 },
        { name = 'water', chance = 0.35, min = 1, max = 1 },
        { name = 'phone', chance = 0.05, min = 1, max = 1 },
        { name = 'bandage', chance = 0.20, min = 1, max = 3 },
    },

    stashes = {
        defaultSlots = 50,
        defaultWeight = 100000, -- 100kg
    },

    fuelPricePerLitre = 2.0,
}
