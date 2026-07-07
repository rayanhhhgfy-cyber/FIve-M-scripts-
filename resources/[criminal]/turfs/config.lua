Config = Config or {}

Config.Turfs = {
    {
        id = 'east_ls',
        label = 'East Los Santos',
        coords = vec3(250.0, -1800.0, 28.0),
        radius = 80.0,
        color = 1
    },
    {
        id = 'south_ls',
        label = 'South Central',
        coords = vec3(100.0, -2000.0, 20.0),
        radius = 80.0,
        color = 1
    },
    {
        id = 'vespucci',
        label = 'Vespucci Beach',
        coords = vec3(-1200.0, -1600.0, 5.0),
        radius = 80.0,
        color = 1
    },
    {
        id = 'davis',
        label = 'Davis',
        coords = vec3(50.0, -1950.0, 22.0),
        radius = 70.0,
        color = 1
    },
    {
        id = 'rancho',
        label = 'Rancho',
        coords = vec3(400.0, -1600.0, 29.0),
        radius = 70.0,
        color = 1
    },
    {
        id = 'mirror_park',
        label = 'Mirror Park',
        coords = vec3(1000.0, -700.0, 58.0),
        radius = 65.0,
        color = 1
    }
}

Config.Capture = {
    duration = 60,
    requiredPlayers = 2,
    maxPlayers = 8,
    range = 30.0,
    cooldown = 1800,
    influencePerCapture = 25,
    passiveInfluenceInterval = 300
}

Config.Influence = {
    decayRate = 0.1,
    maxPerGang = 1000,
    rewards = {
        [100] = { label = 'Minor Presence', bonus = 1000 },
        [300] = { label = 'Established', bonus = 2500 },
        [500] = { label = 'Dominant', bonus = 5000 },
        [750] = { label = 'Stronghold', bonus = 10000 },
        [1000] = { label = 'Fortress', bonus = 20000 }
    }
}

Config.Blip = {
    sprite = 162,
    scale = 0.9
}

Config.Police = {
    alertChance = 0.4,
    minPolice = 2
}
