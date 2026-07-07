Config = Config or {}

Config.Spawn = {
    enableCinematic = true,
    cinematicDuration = 5000,
    fadeInDuration = 1000,
    showCharacterSelect = true,
    showLocationPicker = true,
    defaultSpawn = { x = 215.0, y = -810.0, z = 30.0, h = 0.0 }
}

Config.Locations = {
    {
        name = 'Legion Square',
        description = 'The heart of Los Santos. Close to shops, banks, and services.',
        coords = { x = 215.0, y = -810.0, z = 30.0, h = 0.0 },
        image = 'legion.jpg',
        isDefault = true
    },
    {
        name = 'Vespucci Beach',
        description = 'Coastal living with a relaxed vibe. Near the pier and boardwalk.',
        coords = { x = -1550.0, y = -980.0, z = 13.0, h = 180.0 },
        image = 'beach.jpg'
    },
    {
        name = 'Sandy Shores',
        description = 'Rural life in Blaine County. Quiet and cheap living.',
        coords = { x = 1850.0, y = 3700.0, z = 33.0, h = 0.0 },
        image = 'sandy.jpg'
    },
    {
        name = 'Paleto Bay',
        description = 'Northernmost town. Remote but peaceful.',
        coords = { x = -200.0, y = 6400.0, z = 31.0, h = 0.0 },
        image = 'paleto.jpg'
    },
    {
        name = 'Airport',
        description = 'LSIA terminal. Quick access to air travel.',
        coords = { x = -1050.0, y = -3400.0, z = 14.0, h = 0.0 },
        image = 'airport.jpg'
    }
}

Config.Camera = {
    enableFlyover = true,
    flyoverDuration = 4000,
    flyoverHeight = 100.0,
    flyoverDistance = 50.0
}
